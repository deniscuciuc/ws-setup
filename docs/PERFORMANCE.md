# Hardware and performance

The goal is a responsive development workstation with measured changes. The audited PC has enough RAM for substantial parallel work; its nearly full Windows development volume is an immediate problem to eliminate during migration.

## Baseline

```bash
bash scripts/measure.sh
btop
ncdu ~/Development
```

Record boot time, idle RAM after a fresh login, storage free space, shell startup and a representative project's clean/warm build times. Keep the same project commit, power profile and workload when comparing runs. Non-TTY shell timing excludes ble.sh/terminal rendering; also time opening a real terminal manually.

Use the SSD's Linux filesystem for repositories and Podman storage. Keep adequate free space. Audit large caches before deleting them; database volumes and uncommitted repositories are not caches. Restic retention and container cleanup are explicit operations, never automatic install steps.

## NVIDIA and Steam

Setup detects NVIDIA display hardware and uses `ubuntu-drivers install` to select Ubuntu's recommended driver. It installs the matching 32-bit graphics library for Steam. CUDA and GPU container tooling remain optional.

After reboot:

```bash
nvidia-smi
vulkaninfo --summary
systemctl --failed
```

Test all monitors, refresh rates, hardware-accelerated applications, sound, networking and suspend/resume. Test the actual Steam games you need and their controller/save behavior. Follow Ubuntu's Secure Boot enrollment prompt if required.

If an Electron application renders badly, diagnose that application first. OpenAI currently uses XWayland by default; native Wayland is experimental. Do not globally disable GPU acceleration or change the entire session based on one application's problem.

## Conservative defaults

- Keep Ubuntu's supported kernel, memory management and balanced power profile.
- Keep security updates enabled and check SSD TRIM status; do not blindly change encrypted-volume discard settings.
- Keep database stacks, GPU compute jobs and extra sync services off until requested by a project.
- Reduce GNOME animations and VS Code watchers for dependency/build directories.
- Use `journalctl --disk-usage`, `systemd-analyze critical-chain`, SMART data and thermal readings to locate a demonstrated bottleneck before changing system settings.

No swap/zram hacks, custom kernels, TLP desktop profile, blanket service disabling or global cache deletion is applied.

Reference: [Ubuntu NVIDIA driver guidance](https://ubuntu.com/desktop/docs/en/latest/how-to/graphics/install-nvidia-drivers/).
