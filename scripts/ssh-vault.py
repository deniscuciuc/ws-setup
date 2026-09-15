#!/usr/bin/env python3
"""Migrate OpenSSH key pairs to Bitwarden without logging private material.

inventory is local/read-only; upload explicitly writes vault items; restore-public
writes only public keys to a new directory for use with Bitwarden Desktop's agent.
"""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

PREFIX = "workstation-ssh/"


def public_identity(text):
    fields = text.strip().split()
    if len(fields) < 2 or fields[0] not in ("ssh-ed25519", "ssh-rsa"):
        raise ValueError("Expected an Ed25519 or RSA public key; use native Bitwarden import for other formats")
    blob = base64.b64decode(fields[1], validate=True)
    fingerprint = "SHA256:" + base64.b64encode(hashlib.sha256(blob).digest()).decode().rstrip("=")
    return " ".join(fields[:2]), fingerprint


def pairs(directory):
    directory = Path(directory).expanduser().resolve(strict=True)
    if not directory.is_dir():
        raise ValueError("Expected an SSH directory")
    found = []
    for public in sorted(directory.glob("*.pub")):
        private = public.with_suffix("")
        if public.is_symlink() or private.is_symlink() or not private.is_file():
            continue
        if not re.fullmatch(r"[A-Za-z0-9_-][A-Za-z0-9_.-]*", private.name):
            raise ValueError("Unsupported key filename; use letters, numbers, dots, underscores or hyphens")
        identity, fingerprint = public_identity(public.read_text(encoding="utf-8"))
        found.append((private, identity, fingerprint))
    if not found:
        raise ValueError("No supported key pairs found; every key needs its matching .pub file")
    return found


def bw(*args, payload=None, json_output=True):
    data = None if payload is None else base64.b64encode(json.dumps(payload).encode()).decode() + "\n"
    result = subprocess.run(["bw", *args], input=data, text=True, capture_output=True)
    if result.returncode:
        # Vendor error responses can echo submitted data. Never print them here.
        raise ValueError("Bitwarden command failed; check bw status, unlock/session and server access, then retry")
    if not json_output:
        return None
    try:
        return json.loads(result.stdout) if result.stdout.strip() else None
    except json.JSONDecodeError:
        raise ValueError("Unexpected Bitwarden response; no response body was printed") from None


def vault_items():
    if bw("status").get("status") != "unlocked":
        raise ValueError("Unlock Bitwarden and set BW_SESSION in this terminal first")
    bw("sync", json_output=False)
    return [item for item in bw("list", "items", "--search", PREFIX)
            if item.get("name", "").startswith(PREFIX) and not item.get("deletedDate")]


def prepare(directory):
    result = []
    # Validate every pair before making the first vault write.
    for path, public, fingerprint in pairs(directory):
        derived = subprocess.run(["ssh-keygen", "-y", "-P", "", "-f", str(path)],
                                 stdin=subprocess.DEVNULL, text=True, capture_output=True)
        if derived.returncode:
            raise ValueError(f"Cannot read {path.name}: encrypted/unsupported key or file permissions. Import it using Bitwarden Desktop; the source was not changed")
        if public_identity(derived.stdout)[0] != public:
            raise ValueError(f"Public/private mismatch: {path.name}")
        private = path.read_text(encoding="utf-8").replace("\r\n", "\n")
        if not private.startswith("-----BEGIN OPENSSH PRIVATE KEY-----"):
            raise ValueError(f"{path.name}: use Bitwarden Desktop for legacy private-key formats")
        result.append({"name": PREFIX + path.name, "type": 5,
                       "sshKey": {"privateKey": private, "publicKey": public,
                                  "keyFingerprint": fingerprint}})
    return result


def upload(directory):
    prepared = prepare(directory)
    existing = vault_items()
    for item in prepared:
        matches = [old for old in existing if old.get("name") == item["name"]]
        if matches:
            if len(matches) != 1 or matches[0].get("type") != 5 or matches[0].get("sshKey") != item["sshKey"]:
                raise ValueError("Vault name collision or different key: " + item["name"] + "; no existing item was overwritten")
    for item in prepared:
        if any(old.get("name") == item["name"] for old in existing):
            print("Already present: " + item["name"])
            continue
        created = bw("create", "item", payload=item)
        verified = bw("get", "item", created["id"])
        if verified.get("sshKey") != item["sshKey"]:
            raise ValueError("Read-back verification failed; inspect the new vault item before retrying")
        print("Uploaded and verified: " + item["name"] + " " + item["sshKey"]["keyFingerprint"])


def restore_public(directory):
    items = vault_items()
    outputs = {}
    for item in items:
        name = item["name"][len(PREFIX):]
        if item.get("type") != 5 or not re.fullmatch(r"[A-Za-z0-9_-][A-Za-z0-9_.-]*", name):
            raise ValueError("Invalid SSH item name/type in migration namespace")
        if name in outputs:
            raise ValueError("Duplicate vault name: " + name)
        public, fingerprint = public_identity(item["sshKey"]["publicKey"])
        if fingerprint != item["sshKey"]["keyFingerprint"]:
            raise ValueError("Vault public-key fingerprint mismatch: " + name)
        outputs[name] = public
    if not outputs:
        raise ValueError("No migrated SSH items found")
    directory = Path(directory).expanduser().absolute()
    directory.mkdir(mode=0o700, parents=False, exist_ok=False)
    for name, public in outputs.items():
        with (directory / (name + ".pub")).open("x", encoding="utf-8", newline="\n") as output:
            output.write(public + "\n")
    print(f"Restored {len(outputs)} public keys. Private keys remain in Bitwarden; configure its desktop SSH agent.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["inventory", "upload", "restore-public"])
    parser.add_argument("directory", help="Source .ssh directory, or a new public-key restore directory")
    args = parser.parse_args()
    if args.command == "inventory":
        for path, _, fingerprint in pairs(args.directory):
            print(path.name + " " + fingerprint)
    elif args.command == "upload":
        upload(args.directory)
    else:
        restore_public(args.directory)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError) as error:
        # Avoid tracebacks/locals containing private key data.
        print("ERROR: " + str(error), file=sys.stderr)
        sys.exit(1)
