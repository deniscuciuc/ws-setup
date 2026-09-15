import hashlib
import importlib.util
import json
import os
import pwd
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def bash(script, **kwargs):
    return subprocess.run(["bash", "-c", script], cwd=ROOT, text=True, capture_output=True, **kwargs)


class Helpers(unittest.TestCase):
    def test_diagnostics_repairs_existing_install_and_adds_only_missing_group(self):
        for groups in ["tester sudo", "tester sudo wireshark"]:
            result = bash(r'''
set -euo pipefail
source lib/modules.sh
sudo() {
  printf '%s\n' "$*"
  if [[ $1 == debconf-set-selections ]]; then cat; fi
}
apt_manifest() { printf 'apt %s\n' "$1"; }
pending() { :; }
id() {
  if [[ $1 == -un ]]; then echo tester; else echo "$TEST_GROUPS"; fi
}
install_diagnostics
''', env=dict(os.environ, TEST_GROUPS=groups))
            self.assertEqual(result.returncode, 0, result.stderr)
            calls = result.stdout.splitlines()
            self.assertIn('wireshark-common wireshark-common/install-setuid boolean true', calls)
            self.assertGreater(calls.index('env DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common'), calls.index('apt diagnostics'))
            self.assertEqual('usermod -aG wireshark tester' in calls, 'wireshark' not in groups)

    def test_modules_resolve_dependencies_in_order(self):
        result = bash('source lib/common.sh; source lib/catalog.sh; PROFILE=core; ONLY=desktop; resolve_modules; printf "%s\\n" "${SELECTED[@]}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        modules = result.stdout.splitlines()
        self.assertEqual(len(modules), len(set(modules)))
        for earlier, later in [("base", "shell"), ("shell", "dotfiles"), ("dotfiles", "containers"), ("containers", "desktop"), ("apps", "desktop")]:
            self.assertLess(modules.index(earlier), modules.index(later))
        result = bash('source lib/common.sh; source lib/catalog.sh; PROFILE=workstation; ONLY=""; resolve_modules; printf "%s\\n" "${SELECTED[@]}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(set(result.stdout.splitlines()), {"base", "shell", "dotfiles", "runtimes", "ai", "containers", "database", "apps", "database-gui", "desktop", "drivers", "tools", "maintenance"})
        result = bash('source lib/common.sh; source lib/catalog.sh; PROFILE=workstation; ONLY=devops,diagnostics; resolve_modules; printf "%s\\n" "${SELECTED[@]}"')
        self.assertEqual(result.stdout.splitlines(), ["base", "devops", "diagnostics"])

    def test_bad_arguments_fail_without_state(self):
        for args in [["--only", "unknown"], ["--profile", "invalid"], ["--only"], ["wrong-command"]]:
            with tempfile.TemporaryDirectory() as temp:
                env = dict(os.environ, XDG_STATE_HOME=temp + "/state", XDG_CACHE_HOME=temp + "/cache")
                result = subprocess.run(["bash", "setup.sh", *args], cwd=ROOT, env=env, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(Path(temp, "state").exists())
                self.assertFalse(Path(temp, "cache").exists())

    def test_update_includes_managed_optional_modules_only(self):
        with tempfile.TemporaryDirectory() as temp:
            receipts = Path(temp, "state/ws-setup/modules")
            receipts.mkdir(parents=True)
            for module in ["base", "tools", "devops"]:
                (receipts / module).write_text("previous-run")
            env = dict(os.environ, XDG_STATE_HOME=temp + "/state", XDG_CACHE_HOME=temp + "/cache")
            result = bash('source setup.sh; preflight() { printf "%s\\n" "${SELECTED[@]}"; exit 0; }; main update', env=env)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), ["base", "tools", "devops"])

    def test_modified_legacy_block_is_not_deleted(self):
        module = load("migrate-bashrc")
        text = "export CUSTOM=1\n" + module.BLOCK + "\nalias mine=true\n"
        clean = module.migrate(text)
        self.assertIn("export CUSTOM=1", clean)
        self.assertIn("alias mine=true", clean)
        self.assertNotIn("exec zsh", clean)
        self.assertEqual(module.migrate(clean), clean)
        with self.assertRaises(ValueError):
            module.migrate(text.replace("exec zsh -l", "exec zsh -il"))

    def test_subids_preserve_and_avoid_overlap(self):
        module = load("subids")
        user = pwd.getpwuid(os.getuid()).pw_name
        self.assertIsNone(module.allocation(f"{user}:165536:65536\n", user))
        self.assertEqual(module.allocation("other:100000:65536\n", user), "165536-231071")
        with self.assertRaises(ValueError):
            module.allocation(f"{user}:100000:50\n", user)

    def test_configuration_backup_and_idempotency(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp, "home", "config")
            target.parent.mkdir()
            target.write_text("original\n")
            env = dict(os.environ, STATE_DIR=temp + "/state", RUN_ID="test", TARGET=str(target))
            script = 'source lib/common.sh; printf "new\\n" | write_user_file "$TARGET"; printf "new\\n" | write_user_file "$TARGET"'
            result = bash(script, env=env)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(target.read_text(), "new\n")
            backup = Path(temp, "state/backups/test", str(target).lstrip("/"))
            self.assertEqual(backup.read_text(), "original\n")

    def test_cached_download_hash_is_checked(self):
        with tempfile.TemporaryDirectory() as temp:
            cached = Path(temp, "asset")
            cached.write_bytes(b"good")
            sha = hashlib.sha256(b"good").hexdigest()
            # This unreachable hostname is never contacted when the cache verifies.
            script = 'source lib/common.sh; download_verified https://invalid.invalid/file "$SHA" "$DEST"'
            env = dict(os.environ, SHA=sha, DEST=str(cached))
            self.assertEqual(bash(script, env=env).returncode, 0)
            # A corrupt cache cannot be accepted; failing downloader leaves it unchanged.
            fakebin = Path(temp, "bin")
            fakebin.mkdir()
            curl = fakebin / "curl"
            curl.write_text("#!/bin/sh\nexit 22\n")
            curl.chmod(0o755)
            env["PATH"] = str(fakebin) + ":" + env["PATH"]
            cached.write_bytes(b"corrupt")
            self.assertNotEqual(bash(script, env=env).returncode, 0)
            self.assertEqual(cached.read_bytes(), b"corrupt")
            self.assertEqual(list(Path(temp).glob("asset.*")), [])

    def test_receipt_detects_modified_binary(self):
        with tempfile.TemporaryDirectory() as temp:
            binary = Path(temp, "tool")
            binary.write_text("original")
            receipt = Path(temp, "receipt.json")
            command = ["python3", str(ROOT / "scripts/asset-receipt.py")]
            subprocess.run([*command, "files", str(receipt), "a" * 64, "1", str(binary)], check=True)
            self.assertEqual(subprocess.call([*command, "check", str(receipt)]), 0)
            binary.chmod(0o755)
            self.assertNotEqual(subprocess.call([*command, "check", str(receipt)]), 0)
            binary.chmod(0o644)
            binary.write_text("modified")
            self.assertNotEqual(subprocess.call([*command, "check", str(receipt)]), 0)

    def test_module_failure_blocks_dependents_and_reports_failure(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp, "candidate")
            (root / "scripts").mkdir(parents=True)
            (root / "lib").mkdir()
            shutil.copy(ROOT / "lib/doctor.sh", root / "lib/doctor.sh")
            (root / "scripts/run-module.sh").write_text('#!/bin/bash\necho "running $1"\nif [[ $1 == shell ]]; then echo "unavailable required package" >&2; exit 100; fi\n')
            env = dict(os.environ, FAKE_ROOT=str(root), XDG_STATE_HOME=temp + "/state", XDG_CACHE_HOME=temp + "/cache")
            result = bash('source setup.sh; preflight() { :; }; sudo() { :; }; REPO_ROOT=$FAKE_ROOT; main --only runtimes,ai,database', env=env)
            self.assertNotEqual(result.returncode, 0)
            report = Path(temp, "state/ws-setup/latest-report.md").read_text()
            for text in ["| shell | FAILED (exit 100)", "| dotfiles | BLOCKED", "| runtimes | BLOCKED", "| database | OK"]:
                self.assertIn(text, report)
            self.assertIn("Setup is incomplete", result.stdout)

    def test_dirty_dotfiles_checkout_is_preserved(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp, ".local/share/chezmoi")
            source.mkdir(parents=True)
            subprocess.run(["git", "init", "-q", str(source)], check=True)
            local = source / "uncommitted-work"
            local.write_text("preserve me")
            env = dict(os.environ, HOME=temp, DOTFILES_SOURCE="")
            result = bash('source lib/common.sh; source lib/dotfiles.sh; install_dotfiles', env=env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("source is dirty", result.stderr)
            self.assertEqual(local.read_text(), "preserve me")

    def test_read_only_commands_do_not_create_state(self):
        for command in ["plan", "doctor"]:
            with tempfile.TemporaryDirectory() as temp:
                env = dict(os.environ, HOME=temp, XDG_STATE_HOME=temp + "/state", XDG_CACHE_HOME=temp + "/cache")
                subprocess.run(["bash", "setup.sh", command, "--only", "base"], env=env, cwd=ROOT, capture_output=True)
                self.assertFalse(Path(temp, "state").exists())
                self.assertFalse(Path(temp, "cache").exists())

    def test_desktop_preflight_rejects_missing_session(self):
        env = dict(os.environ)
        for name in ["DISPLAY", "WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS"]:
            env.pop(name, None)
        result = bash('source setup.sh; parse_args --only apps; preflight', env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("graphical Ubuntu session", result.stderr)

    def test_lock_has_no_unverified_downloads(self):
        lock = json.loads((ROOT / "config/assets.lock.json").read_text())
        resolver = load("lock-assets")
        required = set(resolver.SPECS) | set(resolver.KEYS) | set(resolver.VENDOR_DEBS) | {"claude", "chatgpt"}
        self.assertEqual(set(lock["assets"]), required)
        for name, entry in lock["assets"].items():
            self.assertRegex(entry["sha256"], r"^[0-9a-f]{64}$", name)
            self.assertTrue(entry["url"].startswith("https://"), name)
            self.assertIn(entry["verification"], ["github-release-digest", "maintainer-hashed-https", "vendor-manifest"])


if __name__ == "__main__":
    unittest.main()
