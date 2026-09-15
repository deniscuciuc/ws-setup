#!/usr/bin/env python3
"""Exercise a configured interactive Bash under a PTY, including deferred ble.sh."""
import os
import pty
import select
import re
import signal
import time

pid, fd = pty.fork()
if pid == 0:
    os.environ["TERM"] = "xterm-256color"
    os.environ["LANG"] = "C.UTF-8"
    os.execvp("bash", ["bash", "--noprofile", "-i"])
output = bytearray()
deadline = time.monotonic() + 20
sent = False
try:
    while time.monotonic() < deadline:
        if select.select([fd], [], [], 0.2)[0]:
            try:
                chunk = os.read(fd, 65536)
            except OSError:
                break
            if not chunk:
                break
            output.extend(chunk)
            # Answer terminal position queries so ble.sh can finish attaching.
            if b"\x1b[6n" in chunk:
                os.write(fd, b"\x1b[1;1R")
        if not sent and time.monotonic() > deadline - 15:
            os.write(fd, b"printf '\\nPTY_OK shell=%s ble=%s\\n' \"$BASH_VERSION\" \"${BLE_VERSION:-missing}\"; declare -F __fzf_history__ _fzf_complete >/dev/null && printf 'FZF_OK\\n'; [[ $(type -t cat) == file && $(type -t find) == file && $(printf 'match\\nother\\n' | grep match) == match ]] && printf 'COMMANDS_OK\\n'; exit\n")
            sent = True
    else:
        raise RuntimeError("Interactive Bash did not exit within 20 seconds")
finally:
    os.close(fd)
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    os.waitpid(pid, 0)
text = output.decode(errors="replace")
if not re.search(r"\r?\nPTY_OK shell=\d[^\r\n]+ble=0\.", text) or "\r\nFZF_OK\r\n" not in text or "\r\nCOMMANDS_OK\r\n" not in text or any(error in text for error in ["ble=missing", "command not found", "No such file", "failed to find", "is not a function"]):
    print(text)
    raise SystemExit("Interactive shell initialization failed")
print("Interactive Bash, ble.sh, fzf widgets and standard commands passed.")
