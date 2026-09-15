#!/usr/bin/env python3
"""X11/XWayland window smoke test. Use only in a disposable graphical session."""
import argparse
import json
import os
import re
import signal
import subprocess
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--native", action="store_true", help="Only native packages; Snap/Flatpak launch acceptance stays pending")
parser.add_argument("--only", help="One application name, for a focused retry")
parser.add_argument("--timeout", type=int, default=25, help="Seconds per launch; Steam's first bootstrap can need longer")
args = parser.parse_args()
if os.environ.get("WS_DISPOSABLE_TEST") != "1" or not os.environ.get("DISPLAY"):
    parser.error("Set WS_DISPOSABLE_TEST=1 in a disposable desktop/Xvfb session")
apps = {
    "Brave": ["brave-browser", "about:blank"],
    "VS Code": ["code", "--new-window"],
    "Claude Desktop": ["claude-desktop"],
    "ChatGPT": ["chatgpt"],
    "DBeaver": ["dbeaver"],
    "Compass": ["mongodb-compass"],
    "Bruno": ["bruno"],
    "Kitty": ["kitty"],
    "Steam": ["steam"],
    "GitKraken": ["gitkraken"],
    "Discord": ["discord"],
    "ONLYOFFICE": ["desktopeditors"],
}
if not args.native:
    apps.update({"Podman Desktop": ["flatpak", "run", "io.podman_desktop.PodmanDesktop"],
                 **{name: ["snap", "run", name] for name in ["todoist", "telegram-desktop", "spotify", "bitwarden", "redisinsight"]}})
if args.only:
    if args.only not in apps:
        parser.error("Unknown application name")
    apps = {args.only: apps[args.only]}
output = Path.home() / ".local/state/ws-setup/gui-tests"
output.mkdir(parents=True, exist_ok=True)


def windows():
    result = subprocess.check_output(["xwininfo", "-root", "-tree"], text=True)
    return {line.strip() for line in result.splitlines() if re.search(r'0x[0-9a-f]+ "[^\"]+"', line)}


results = {}
patterns_extra = {"GitKraken": "gitkraken", "Discord": "discord", "ONLYOFFICE": "onlyoffice|desktopeditors"}
patterns = {"Brave": "brave", "VS Code": 'visual studio code|"code"', "Claude Desktop": "claude", "ChatGPT": "chatgpt", "DBeaver": "dbeaver", "Compass": "compass", "Bruno": "bruno", "Kitty": "kitty", "Steam": "steam", "Podman Desktop": "podman", "todoist": "todoist", "telegram-desktop": "telegram", "spotify": "spotify", "bitwarden": "bitwarden", "redisinsight": "redis"}


def matches(name, window):
    size = re.search(r"\s+(\d+)x(\d+)[+-]", window)
    return size and int(size[1]) >= 160 and int(size[2]) >= 100 and re.search(patterns_extra.get(name, patterns.get(name)), window, re.I)


for name, command in apps.items():
    before = windows()
    process = None
    with (output / (name.replace(" ", "-") + ".log")).open("w") as log:
        try:
            process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            deadline = time.monotonic() + args.timeout
            opened = set()
            while time.monotonic() < deadline:
                time.sleep(1)
                opened = {window for window in windows() - before if matches(name, window)}
                if opened:
                    break
            results[name] = {"window_created": bool(opened), "windows": sorted(opened), "exit_code": process.poll()}
        except OSError as error:
            results[name] = {"window_created": False, "error": str(error)}
        finally:
            if process is not None:
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                    process.wait(timeout=5)
                except (ProcessLookupError, subprocess.TimeoutExpired):
                    pass
    print(name + ": " + ("window created" if results[name]["window_created"] else "FAILED (see log)"), flush=True)
(output / ("results-" + args.only.replace(" ", "-") + ".json" if args.only else "results.json")).write_text(json.dumps(results, indent=2) + "\n")
print("Window creation is only a smoke test. Complete sign-in, rendering and workflow checks manually.")
raise SystemExit(0 if all(value["window_created"] for value in results.values()) else 1)
