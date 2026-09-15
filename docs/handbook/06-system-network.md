# 6. System and network tools

[Index](README.md) · Previous: [Desktop/accounts](05-desktop-accounts.md) · Next: [Maintenance](07-maintenance.md)

Start by observing the problem. These tools help distinguish CPU load, memory pressure, storage exhaustion, network faults and application errors. Installing Ubuntu alone does not prove that a performance problem is solved.

## System and storage

| Tool | What it tells you | Example |
|---|---|---|
| `btop` | Live CPU, memory and process activity | `btop` |
| procps tools | Process and memory snapshots | `ps aux`, `free -h` |
| `sysstat` | CPU/I/O statistics tools | `iostat -xz 1` |
| `ncdu` | Which directories consume space, in a terminal | `ncdu "$HOME"` |
| `duf` | Filesystem capacity in a readable table | `duf` |
| Disk Usage Analyzer | Graphical directory sizes | Open the app or run `baobab` |
| GNOME Disks | Disk models, mounts and health UI | `gnome-disks` |
| `smartmontools` | Device health information | `sudo smartctl --scan`, then `sudo smartctl -a DEVICE` |
| `lm-sensors` | Available temperature/fan readings | `sensors` |
| `util-linux` tools | Block devices and mounted filesystems | `lsblk -f`, `findmnt` |
| systemd tools | Failed services and boot dependencies | `systemctl --failed`, `systemd-analyze critical-chain` |
| Journal | Logs for the current boot | `journalctl -b -p warning` |

`DEVICE` must be replaced with an identified device path. Merely inspecting a disk is different from formatting or changing its partitions. GNOME Disks and ncdu include destructive actions; review what is selected before using them. Provisioning never formats a drive.

For a slow build, compare CPU use, available RAM, I/O wait and free disk space while the same build is running. For a slow login, inspect the boot chain and journal. `scripts/measure.sh` records useful baseline measurements; compare the same project commit and workload. See [PERFORMANCE.md](../PERFORMANCE.md).

## Network questions

| Question | Tool/example | How to interpret it |
|---|---|---|
| Do I have an address and route? | `ip -brief address`, `ip route` | Check the expected interface and default route |
| What does NetworkManager see? | `nmcli device status` | Distinguish a disconnected interface from an application failure |
| Which DNS servers are configured? | `resolvectl status` | Check the connection's resolver settings |
| Does DNS resolve this name? | `dig example.com` | Inspect the returned address and response status |
| What is listening locally? | `sudo ss -lntup` | Find ports, bind addresses and owning processes |
| Who owns a particular port? | `sudo lsof -i :3000` | Identify the process before stopping it |
| Which process is using bandwidth? | `sudo nethogs` | Observe per-process traffic; quit with q |
| Where is a route slow/unreliable? | `mtr example.com` | Compare end-to-end behavior; intermediate devices may limit replies |
| Which local services are reachable? | `nmap localhost` | Inspect your own machine's exposed ports |
| What throughput does my LAN achieve? | `iperf3 -c PEER_IP` | Needs a deliberate `iperf3 -s` on a test peer; stop that server afterward |
| What HTTP response does an app return? | `http GET http://localhost:3000/health` | Use the actual endpoint provided by your app |

Ubuntu provides the stock `ip`, `ss`, NetworkManager, resolver and systemd tools. ws-setup adds DNS utilities, lsof, mtr and the selected extra diagnostics. iperf3 is installed with new server-daemon autostart disabled. Cloudflared creates no tunnel automatically.

For a service that works inside a container but not on the host, check its published ports and bind address. For a hostname that fails while an IP works, inspect DNS. For an occupied port, identify the owning project before changing anything.

## Packet capture, only when needed

Opt into `./setup.sh --only diagnostics` for **Wireshark** (GUI) and **TShark** (CLI). They decode packet captures to inspect protocol behavior. Open a known capture file before configuring live capture. The installer does not grant capture privileges to your account; [TOOLS.md](../TOOLS.md) explains the distribution-supported opt-in.

Captures can contain traffic and credentials from applications. Keep them out of shared repositories unless reviewed and sanitized. Use the normal-user GUI rather than launching the entire desktop application as root.

## NVIDIA and graphics

`ubuntu-drivers-common` selects Ubuntu's supported driver; `pciutils` supplies `lspci` for hardware identification. `vulkan-tools` supplies `vulkaninfo`, and `mesa-utils` provides graphics diagnostic commands. NVIDIA's installed driver provides `nvidia-smi`. Matching 32-bit graphics dependencies support Steam.

After reboot, check `nvidia-smi` and `vulkaninfo --summary`, then test displays, sound, networking, suspend/resume and actual games. CUDA is not installed by default. Keep normal Ubuntu memory/power defaults until measurements identify a reason to change them.
