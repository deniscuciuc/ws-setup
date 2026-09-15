#!/usr/bin/env python3
"""Verify login shells and systemd desktop environment without signing in."""
import os
import subprocess

env = dict(os.environ, LANG="C.UTF-8", TERM="dumb")
env.pop("DOCKER_HOST", None)
expected = "unix://" + env["XDG_RUNTIME_DIR"] + "/podman/podman.sock"
script = 'printf "%s\\n%s\\n%s\\n" "$EDITOR" "$DOCKER_HOST" "$PATH"'
for args in [["bash", "-lc", script], ["bash", "-lic", script]]:
    result = subprocess.run(args, env=env, text=True, capture_output=True, check=True)
    editor, endpoint, path = result.stdout.splitlines()
    assert editor == "nano" and endpoint == expected, result.stdout
    assert env["HOME"] + "/.local/bin" in path.split(":")
    assert env["HOME"] + "/.local/share/mise/shims" in path.split(":")
generator = "/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator"
result = subprocess.check_output([generator], env=env, text=True)
values = dict(line.split("=", 1) for line in result.splitlines() if "=" in line)
assert values["DOCKER_HOST"] == expected, values
assert env["HOME"] + "/.local/bin" in values["PATH"].split(":"), values
assert env["HOME"] + "/.local/share/mise/shims" in values["PATH"].split(":"), values
env["DOCKER_HOST"] = "ssh://intentional-remote"
result = subprocess.check_output(["bash", "-lc", script], env=env, text=True)
assert result.splitlines()[1] == env["DOCKER_HOST"]
print("Login, non-TTY, desktop environment and explicit Docker endpoint override passed.")
