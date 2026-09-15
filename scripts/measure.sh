#!/usr/bin/env bash
set -euo pipefail
printf '# Workstation measurements (%s)\n' "$(date -Iseconds)"
uname -sr
printf '\n## Storage\n'
df -h / "$HOME"
printf '\n## Memory\n'
free -h
printf '\n## Boot\n'
if [[ -d /run/systemd/system ]]; then
  systemd-analyze time || true
  systemd-analyze critical-chain || true
  systemctl --failed --no-pager || true
  systemctl is-enabled fstrim.timer || true
fi
printf '\n## Non-TTY shell startup (excludes interactive rendering)\n'
python3 - <<'PY'
import os, statistics, subprocess, time
samples = []
for _ in range(5):
    start = time.perf_counter()
    subprocess.run(['bash', '-lic', ':'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=dict(os.environ, TERM='dumb'), check=True)
    samples.append((time.perf_counter()-start)*1000)
print(f'Median: {statistics.median(samples):.0f} ms')
PY
printf '\nTime actual project builds and terminal opens separately; record the project revision and power profile.\n'
