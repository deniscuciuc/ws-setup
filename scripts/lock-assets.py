#!/usr/bin/env python3
"""Resolve official release assets. Default prints a candidate; --write saves it.

GitHub's published SHA-256 digest is preferred. Older releases and vendor-only
downloads are hashed over HTTPS and labelled accordingly. Review the diff before
shipping a new lock; normal installation never resolves 'latest'.
"""
import argparse
import hashlib
import json
import re
import subprocess
import tempfile
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    "bw": ("bitwarden/clients", r"bw-linux-[\d.]+\.zip", "zip", {"bw": "bw"}),
    "tofu": ("opentofu/opentofu", r"tofu_[\d.]+_amd64\.deb", "deb", {}),
    "yq": ("mikefarah/yq", r"yq_linux_amd64", "binary", {"": "yq"}),
    "just": ("casey/just", r"just-[\d.]+-x86_64-unknown-linux-musl\.tar\.gz", "tar", {"just": "just"}),
    "sops": ("getsops/sops", r"sops-v[\d.]+\.linux\.amd64", "binary", {"": "sops"}),
    "trivy": ("aquasecurity/trivy", r"trivy_[\d.]+_Linux-64bit\.tar\.gz", "tar", {"trivy": "trivy"}),
    "chezmoi": ("twpayne/chezmoi", r"chezmoi_.*_linux_amd64\.tar\.gz", "tar", {"chezmoi": "chezmoi"}),
    "mise": ("jdx/mise", r"mise-v[\d.]+-linux-x64", "binary", {"": "mise"}),
    "uv": ("astral-sh/uv", r"uv-x86_64-unknown-linux-gnu\.tar\.gz", "tar", {"uv-x86_64-unknown-linux-gnu/uv": "uv", "uv-x86_64-unknown-linux-gnu/uvx": "uvx"}),
    "starship": ("starship/starship", r"starship-x86_64-unknown-linux-gnu\.tar\.gz", "tar", {"starship": "starship"}),
    "compose": ("docker/compose", r"docker-compose-linux-x86_64", "binary", {"": "docker-compose"}),
    "codex": ("openai/codex", r"codex-x86_64-unknown-linux-musl\.tar\.gz", "tar", {"codex-x86_64-unknown-linux-musl": "codex"}),
    "sqlcmd": ("microsoft/go-sqlcmd", r"sqlcmd-linux-amd64\.tar\.bz2", "tar", {"sqlcmd": "sqlcmd"}),
    "mongosh": ("mongodb-js/mongosh", r"mongodb-mongosh_[\d.]+_amd64\.deb", "deb", {}),
    "compass": ("mongodb-js/compass", r"mongodb-compass_[\d.]+_amd64\.deb", "deb", {}),
    "bruno": ("usebruno/bruno", r"bruno_[\d.]+_amd64_linux\.deb", "deb", {}),
    "blesh": ("akinomyoga/ble.sh", r"ble-0\.4\.0-devel3-2\.tar\.xz", "blesh", {}),
    "font": ("ryanoasis/nerd-fonts", r"JetBrainsMono\.tar\.xz", "font", {}),
}
KEYS = {
    "cloudflared-key": "https://pkg.cloudflare.com/cloudflare-main.gpg",
    "onlyoffice-key": "https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE",
    "brave-key": "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg",
    "vscode-key": "https://packages.microsoft.com/keys/microsoft.asc",
    "claude-desktop-key": "https://downloads.claude.ai/claude-desktop/key.asc",
    "dbeaver-key": "https://dbeaver.io/debs/dbeaver.gpg.key",
    "steam-key": "https://repo.steampowered.com/steam/archive/stable/steam.gpg",
}

VENDOR_DEBS = {
    "gitkraken": "https://release.gitkraken.com/linux/gitkraken-amd64.deb",
    "discord": "https://discord.com/api/download?platform=linux&format=deb",
}


def resolve_vendor_deb(name):
    # Capture the exact redirect and package version. A moving vendor URL is
    # still checksum locked: upstream replacement fails closed until reviewed.
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "download.deb"
        with request(VENDOR_DEBS[name]) as response, path.open("wb") as output:
            url = response.geturl()
            for chunk in iter(lambda: response.read(1024 * 1024), b""):
                output.write(chunk)
        package = subprocess.check_output(["dpkg-deb", "-f", str(path), "Package"], text=True).strip()
        arch = subprocess.check_output(["dpkg-deb", "-f", str(path), "Architecture"], text=True).strip()
        if package != name or arch != "amd64" or not url.startswith("https://"):
            raise RuntimeError(f"Unexpected vendor package: {package}/{arch}/{url}")
        version = subprocess.check_output(["dpkg-deb", "-f", str(path), "Version"], text=True).strip()
        with path.open("rb") as downloaded:
            sha = hashlib.file_digest(downloaded, "sha256").hexdigest()
        return {"version": version, "url": url, "sha256": sha,
                "verification": "maintainer-hashed-https", "kind": "deb", "binaries": {}}


def request(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "ws-setup-lock/1"}), timeout=120)


def read_json(url):
    with request(url) as response:
        return json.load(response)


def hash_url(url):
    digest = hashlib.sha256()
    with request(url) as response:
        for chunk in iter(lambda: response.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resolve_github(name, spec):
    repo, pattern, kind, binaries = spec
    if name == "bw":
        releases = read_json(f"https://api.github.com/repos/{repo}/releases?per_page=100")
        release = next(r for r in releases if r["tag_name"].startswith("cli-v") and not r["prerelease"] and not r["draft"])
    else:
        release = read_json(f"https://api.github.com/repos/{repo}/releases/latest")
    assets = [a for a in release["assets"] if re.fullmatch(pattern, a["name"])]
    if len(assets) != 1:
        raise RuntimeError(f"{name}: expected one {pattern!r}; found {[a['name'] for a in assets]}")
    asset = assets[0]
    digest = asset.get("digest") or ""
    published = bool(re.fullmatch(r"sha256:[0-9a-f]{64}", digest))
    return {
        "version": release["tag_name"], "url": asset["browser_download_url"],
        "sha256": digest.removeprefix("sha256:") if published else hash_url(asset["browser_download_url"]),
        "verification": "github-release-digest" if published else "maintainer-hashed-https",
        "kind": kind, "binaries": binaries,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--only", help="Comma-separated entries; preserve other locked entries")
    args = parser.parse_args()
    destination = ROOT / "config/assets.lock.json"
    names = args.only.split(",") if args.only else [*SPECS, *KEYS, *VENDOR_DEBS, "claude", "chatgpt"]
    result = json.loads(destination.read_text()) if args.only and destination.exists() else {"schema": 1, "architecture": "amd64", "assets": {}}
    for name in names:
        if name in SPECS:
            entry = resolve_github(name, SPECS[name])
        elif name in VENDOR_DEBS:
            entry = resolve_vendor_deb(name)
        elif name in KEYS:
            entry = {"version": "key-" + datetime.now(timezone.utc).strftime("%Y-%m-%d"),
                     "url": KEYS[name], "sha256": hash_url(KEYS[name]),
                     "verification": "maintainer-hashed-https", "kind": "key", "binaries": {}}
        elif name == "claude":
            base = "https://downloads.claude.ai/claude-code-releases"
            with request(f"{base}/stable") as response:
                version = response.read().decode().strip()
            if not re.fullmatch(r"\d+\.\d+\.\d+", version):
                raise RuntimeError("Invalid Claude stable version")
            manifest = read_json(f"{base}/{version}/manifest.json")
            sha = manifest["platforms"]["linux-x64"]["checksum"]
            entry = {"version": version, "url": f"{base}/{version}/linux-x64/claude", "sha256": sha,
                     "verification": "vendor-manifest", "kind": "binary", "binaries": {"": "claude"}}
        elif name == "chatgpt":
            base = "https://persistent.oaistatic.com/codex-app-prod/linux/deb"
            with request(base + "/dists/stable/main/binary-amd64/Packages") as response:
                paragraphs = response.read().decode().strip().split("\n\n")
            packages = [dict(line.split(": ", 1) for line in paragraph.splitlines() if ": " in line and not line.startswith(" ")) for paragraph in paragraphs]
            candidates = [p for p in packages if p.get("Package") == "chatgpt" and p.get("Architecture") == "amd64"]
            if len(candidates) != 1 or not re.fullmatch(r"pool/[A-Za-z0-9_./+~-]+\.deb", candidates[0]["Filename"]) or ".." in candidates[0]["Filename"]:
                raise RuntimeError("Review the changed OpenAI APT index format before updating")
            package = candidates[0]
            url = base + "/" + package["Filename"]
            sha = hash_url(url)
            if sha != package["SHA256"]:
                raise RuntimeError("OpenAI package does not match its APT index checksum")
            # The immutable pool URL avoids depending on a changing latest URL.
            # Initial trust is HTTPS + reviewed lock; installed APT updates are signed.
            entry = {"version": package["Version"],
                     "url": url, "sha256": sha, "verification": "maintainer-hashed-https",
                     "kind": "deb", "binaries": {}}
        else:
            raise RuntimeError(f"Unknown asset: {name}")
        result["assets"][name] = entry
        print(f"Resolved {name}: {entry['version']}", file=__import__("sys").stderr)
    result["resolved_at"] = datetime.now(timezone.utc).isoformat()
    text = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.write:
        temporary = destination.with_suffix(".tmp")
        temporary.write_text(text, encoding="utf-8", newline="\n")
        temporary.replace(destination)
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
