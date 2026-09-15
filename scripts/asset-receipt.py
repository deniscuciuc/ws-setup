#!/usr/bin/env python3
"""Check installation state using actual file hashes or installed deb versions."""
import hashlib
import json
import stat
import subprocess
import sys
from pathlib import Path


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    action, filename, *args = sys.argv[1:]
    path = Path(filename)
    if action == "check":
        try:
            entry = json.loads(path.read_text())
            if "package" in entry:
                actual = subprocess.check_output(["dpkg-query", "-W", "-f=${Status}\t${Version}", entry["package"]], stderr=subprocess.DEVNULL, text=True)
                status, version = actual.split("\t")
                return 0 if status == "install ok installed" and subprocess.call(["dpkg", "--compare-versions", version, "ge", entry["deb_version"]]) == 0 else 1
            return 0 if entry["files"] and all(digest(p) == h and stat.S_IMODE(Path(p).stat().st_mode) == entry.get("modes", {}).get(p) for p, h in entry["files"].items()) else 1
        except (OSError, ValueError, KeyError, subprocess.CalledProcessError):
            return 1
    sha, version, *items = args
    entry = {"sha256": sha, "version": version}
    if action == "deb":
        entry.update(package=items[0], deb_version=items[1])
    elif action == "files":
        entry["files"] = {p: digest(p) for p in items}
        entry["modes"] = {p: stat.S_IMODE(Path(p).stat().st_mode) for p in items}
    else:
        raise ValueError(action)
    path.write_text(json.dumps(entry, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
