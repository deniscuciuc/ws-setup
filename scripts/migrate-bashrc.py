#!/usr/bin/env python3
"""Remove only the exact Bash-to-Zsh block emitted by the old ws-setup."""
import sys
from pathlib import Path

BLOCK = '''# ws-setup: auto-switch to zsh
if [[ $- == *i* ]] && [ -z "${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
  exec zsh -l
fi'''


def migrate(text):
    text = text.replace("\r\n", "\n")
    if "# ws-setup: auto-switch to zsh" in text and BLOCK not in text:
        raise ValueError("The old ws-setup Zsh block was edited. Remove that launcher manually; other Bash settings will be preserved.")
    return text.replace(BLOCK, "")


if __name__ == "__main__":
    print(migrate(Path(sys.argv[1]).read_text()), end="")
