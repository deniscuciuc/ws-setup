# Development and system tools

The workstation profile includes the `tools` module. Core remains smaller. Add tools later with `./setup.sh --only tools`. Package names live in `packages/*.txt`; pinned standalone downloads live in `config/assets.lock.json`.

## Cloudflare and infrastructure

| Tool | Use | Setup |
|---|---|---|
| cloudflared | Cloudflare Tunnel and Access connections | Default workstation; official signed APT repository. No tunnel or service is created. |
| Wrangler | Workers development and deployment | Project-local dependency, following [Cloudflare guidance](https://developers.cloudflare.com/workers/wrangler/install-and-update/). |
| OpenTofu (`tofu`) | Declarative infrastructure, including Cloudflare resources | Default; checksum-locked official release `.deb`. |
| Mike Farah `yq` | Query/edit YAML and JSON | Default; upstream binary, not the unrelated Python package. |
| `just` | Named project tasks in a justfile | Default; upstream binary. |
| Skopeo | Inspect/copy container images without starting them | Default; Ubuntu package. |

Inside an existing Workers project:

```bash
pnpm add -D wrangler
pnpm exec wrangler login
pnpm exec wrangler dev
```

Commit the dependency and lockfile; keep tokens in private environment variables or the service's credential store. Deployment remains a deliberate project command. For infrastructure, use `tofu init`, `tofu fmt`, `tofu validate` and `tofu plan`; inspect the plan before applying it. Keep state and secrets out of Git.

Optional tools:

```bash
./setup.sh --only devops       # SOPS, age, Ansible, Trivy
./setup.sh --only diagnostics  # Wireshark and TShark
./setup.sh doctor --only tools,devops,diagnostics
```

Ansible comes from Ubuntu; projects requiring another release can isolate it with uv. SOPS/age need project recipients and a separately backed-up private key. Trivy downloads its vulnerability database on first scan; setup does not launch scans. These modules create no inventories, credentials or background services.

The opt-in diagnostics installer enables Ubuntu’s non-root capture configuration and adds your account to the `wireshark` group. Log out fully and back in after installation, then run the GUI as your normal user. Rerunning `./setup.sh --only diagnostics` also repairs older installations that disabled capture. `./setup.sh doctor --only diagnostics` checks group membership and dumpcap capabilities.

## Which system tool to use

| Question | Command or application |
|---|---|
| Which program is using CPU/RAM? | `btop` |
| Which process owns a listening port? | `sudo ss -lntup`, `sudo lsof -i :3000` |
| Which process uses bandwidth? | `sudo nethogs` (exit with q) |
| What routes and addresses are active? | `ip -brief address`, `ip route`, `nmcli device status` |
| Why is DNS failing? | `resolvectl status`, `dig example.com` |
| Where does connectivity slow down? | `mtr example.com` |
| Which services are exposed on my machine? | `nmap localhost` |
| How fast is my LAN? | On a test peer: `iperf3 -s`; locally: `iperf3 -c PEER_IP`; stop the server afterward. Setup disables new daemon autostart. |
| Where is disk space going? | `duf`, `ncdu "$HOME"`, Disk Usage Analyzer (`baobab`) |
| Is a disk healthy? | GNOME Disks (`gnome-disks`); `sudo smartctl --scan` then `sudo smartctl -a DEVICE` |
| Which service failed? | `systemctl --failed`, `journalctl -b -p warning` |
| What delayed startup? | `systemd-analyze`, `systemd-analyze blame` |

Cockpit remains an optional server-management recommendation, outside provisioning. Follow its [Ubuntu instructions](https://cockpit-project.org/running.html) if a browser-based system console becomes useful. WARP is also optional: it changes device connectivity, whereas cloudflared connects tunnels and Access applications. Follow [Cloudflare's client documentation](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/warp/) if needed.

## Office and everyday applications

GitKraken and Discord use checksum-locked official `.deb` downloads. Run `gitkraken` and `discord`, then sign in. Their Linux launch, audio and screen-sharing acceptance checks remain part of the Desktop VM/physical-PC checklist.

Discord's package bootstraps additional client components at first launch; the reviewed `.deb` checksum does not pin those vendor-managed components. In container testing its downloaded client reported a sandbox-helper error. GitKraken's window smoke test also timed out. See [validation results](TESTING.md); verify both in the Desktop VM before migration, without disabling browser sandboxing as a workaround.

ONLYOFFICE uses its [official signed repository](https://helpcenter.onlyoffice.com/desktop/installation/desktop-install-ubuntu.aspx); `squeeze` is the vendor's documented cross-distribution suite. Run `desktopeditors`, open a representative document and test saving a copy. ONLYOFFICE replaces LibreOffice in the setup inventory. If Ubuntu preinstalled LibreOffice, remove its applications after that check:

```bash
sudo apt remove libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-math libreoffice-base
```

Review APT's removal summary; do not use purge or autoremove as part of this migration. User documents and configuration are retained. Choose ONLYOFFICE in Files → Open With for document types you use.

## Maintaining pins

Use `python3 scripts/lock-assets.py --only gitkraken,discord,tofu,yq,just,sops,trivy --write` in Linux, inspect the lock diff, then test before distributing it. The resolver records the vendor's final redirect (currently versioned for both GitKraken and Discord). If upstream replaces the bytes, the checksum refuses the download. Refresh the reviewed lock instead of bypassing verification. `setup.sh update` uses the reviewed lock and does not resolve latest versions itself. An unqualified update includes all previously managed modules, including opt-ins; `--only` restricts it.

Sources: [GitKraken installation](https://support.gitkraken.com/gitkraken-client/how-to-install/), [Discord downloads](https://discord.com/download), [Cloudflare packages](https://pkg.cloudflare.com/), [OpenTofu releases](https://github.com/opentofu/opentofu/releases), [yq](https://github.com/mikefarah/yq), [just](https://just.systems/man/en/), [SOPS](https://github.com/getsops/sops), [Trivy](https://github.com/aquasecurity/trivy).

### DBeaver startup on Ubuntu 26.04

DBeaver 26.2.0 can report a fatal Java error while its native GTK splash screen crashes in `gtk_widget_realize`. The bundled Java itself runs. The database-gui installer writes a user desktop entry and `~/.local/bin/dbeaver` wrapper using `-nosplash`; it preserves the existing workspace and credentials. Immediate workaround: `dbeaver -nosplash`. See [upstream issue #41998](https://github.com/dbeaver/dbeaver/issues/41998), which also reports the problem with Snap; switching to the App Center package is not a confirmed fix.
