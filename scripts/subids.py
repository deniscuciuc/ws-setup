#!/usr/bin/env python3
"""Preserve existing subordinate IDs; allocate a non-overlapping range if absent."""
import os
import pwd
import subprocess
import sys
from pathlib import Path


def allocation(text, user):
    entries = []
    for line in text.splitlines():
        if not line or line.startswith("#"):
            continue
        owner, start, count = line.split(":")
        entries.append((owner, int(start), int(count)))
    mine = [e for e in entries if e[0] == user or e[0] == str(pwd.getpwnam(user).pw_uid)]
    if mine:
        if not any(count >= 65536 for _, _, count in mine):
            raise ValueError("Existing sub-ID ranges are too small; review /etc/subuid and /etc/subgid manually.")
        return None
    start = 100000
    for _, lower, count in sorted(entries, key=lambda e: e[1]):
        if start + 65536 <= lower:
            break
        if start < lower + count:
            start = lower + count
    if start + 65536 >= 2**32:
        raise ValueError("No available subordinate ID range")
    return f"{start}-{start + 65535}"


def main():
    user = sys.argv[1]
    if pwd.getpwnam(user).pw_uid != os.getuid() or os.getuid() == 0:
        raise ValueError("Run for the invoking non-root user only")
    options = []
    for filename, option in [("/etc/subuid", "--add-subuids"), ("/etc/subgid", "--add-subgids")]:
        path = Path(filename)
        value = allocation(path.read_text() if path.exists() else "", user)
        if value:
            options += [option, value]
    if options:
        subprocess.run(["sudo", "usermod", *options, user], check=True)


if __name__ == "__main__":
    main()
