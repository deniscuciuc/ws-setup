import base64
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("ssh_vault", Path(__file__).resolve().parents[1] / "scripts/ssh-vault.py")
vault = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vault)


class SshVault(unittest.TestCase):
    def key(self, directory, name="test", password=""):
        path = Path(directory) / name
        subprocess.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", password, "-f", str(path)], check=True)
        return path

    def test_pairs_and_upload_are_verified_and_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            self.key(directory)
            stored = []

            def fake(*args, payload=None, **kwargs):
                if args == ("status",): return {"status": "unlocked"}
                if args == ("sync",): return None
                if args[:2] == ("list", "items"): return stored
                if args[:2] == ("create", "item"):
                    stored.append(dict(payload, id="test-id"))
                    return stored[-1]
                if args[:2] == ("get", "item"): return stored[-1]
                raise AssertionError(args)

            with patch.object(vault, "bw", side_effect=fake):
                vault.upload(directory)
                vault.upload(directory)
                self.assertEqual(len(stored), 1)
                output = Path(directory) / "restored"
                vault.restore_public(output)
                self.assertEqual([p.name for p in output.iterdir()], ["test.pub"])
                self.assertEqual(vault.public_identity((output / "test.pub").read_text()), vault.public_identity(Path(directory, "test.pub").read_text()))
                with self.assertRaises(FileExistsError): vault.restore_public(output)

    def test_encrypted_and_mismatched_keys_fail_before_vault_access(self):
        with tempfile.TemporaryDirectory() as directory:
            self.key(directory, password="test-only")
            with patch.object(vault, "bw") as remote:
                with self.assertRaisesRegex(ValueError, "encrypted/unsupported"): vault.upload(directory)
                remote.assert_not_called()
        with tempfile.TemporaryDirectory() as directory:
            first = self.key(directory)
            second = self.key(directory, "other")
            first.with_suffix(".pub").write_text(second.with_suffix(".pub").read_text())
            with self.assertRaisesRegex(ValueError, "mismatch"): vault.prepare(directory)

    def test_collision_does_not_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            self.key(directory)
            with patch.object(vault, "vault_items", return_value=[{"name": "workstation-ssh/test", "type": 1}]), patch.object(vault, "bw") as remote:
                with self.assertRaisesRegex(ValueError, "collision"): vault.upload(directory)
                remote.assert_not_called()

    def test_secrets_use_stdin_and_vendor_errors_are_not_echoed(self):
        secret = "private-test-material"
        result = subprocess.CompletedProcess([], 1, secret, secret)
        with patch.object(vault.subprocess, "run", return_value=result) as run:
            with self.assertRaises(ValueError) as raised:
                vault.bw("create", "item", payload={"privateKey": secret})
            self.assertNotIn(secret, str(raised.exception))
            self.assertNotIn(secret, repr(run.call_args.args))
            self.assertEqual(json.loads(base64.b64decode(run.call_args.kwargs["input"])), {"privateKey": secret})

    def test_restore_rejects_path_traversal(self):
        with patch.object(vault, "vault_items", return_value=[{"name": "workstation-ssh/../outside", "type": 5}]):
            with self.assertRaisesRegex(ValueError, "Invalid SSH item"): vault.restore_public("unused")


if __name__ == "__main__":
    unittest.main()
