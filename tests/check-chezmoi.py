#!/usr/bin/env python3
"""Exercise source files with normal Git modes in an isolated home directory."""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

source = Path(os.environ.get("DOTFILES_SOURCE", "/dotfiles"))
with tempfile.TemporaryDirectory(prefix="ws-chezmoi-") as directory:
    root = Path(directory)
    copy = root / "source"
    shutil.copytree(source, copy, ignore=shutil.ignore_patterns(".git", "__pycache__"))
    for path in copy.rglob("*"):
        if path.is_file():
            path.chmod(0o644)
    home = root / "home"
    home.mkdir()
    (home / ".bashrc").write_text("export MY_PRESERVED_SETTING=1\n")
    env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"), XDG_DATA_HOME=str(home / ".local/share"), XDG_CACHE_HOME=str(home / ".cache"), XDG_STATE_HOME=str(home / ".local/state"))
    command = ["chezmoi", "--source", str(copy), "--destination", str(home)]
    for _ in range(2):
        subprocess.run([*command, "apply", "--force"], env=env, check=True, umask=0o022)
        result = subprocess.check_output([*command, "diff", "--no-pager"], env=env, text=True, umask=0o022)
        assert result == "", result
    assert "MY_PRESERVED_SETTING=1" in (home / ".bashrc").read_text()
    assert (home / ".local/bin/ws-backup").stat().st_mode & 0o100
    assert (home / ".codex").stat().st_mode & 0o777 == 0o700
    assert (home / ".codex/config.toml").stat().st_mode & 0o777 == 0o600
    assert not (home / "docs").exists() and not (home / "tests").exists()
    assert not (home / ".config/nvim").exists()
print("Chezmoi modifier scripts, file modes, repeat application and ignored docs passed.")
