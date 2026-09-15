# Workstation Handbook

This is the user's manual for the workstation defined by these repositories: Ubuntu 26.04 GNOME on x86_64, enhanced Bash, VS Code, local development with Podman, and the selected everyday applications.

**Read this first:** the implementation is a candidate. Package installation and automated checks do not establish that every desktop application or physical device works. See the current [validation results](../TESTING.md) before replacing Windows.

## Reading order

| Chapter | What it answers |
|---|---|
| [1. Understand the setup](01-overview.md) | What owns what? Which modules run? What remains manual? |
| [2. Terminal and navigation](02-terminal.md) | Why these shell tools? How do I navigate, search, edit and manage sessions? |
| [3. Development workflow](03-development.md) | How do Git, editors, runtimes, AI tools and DevOps utilities fit together? |
| [4. Containers and databases](04-containers-databases.md) | Where do services run? Which client should I open? How do I preserve data? |
| [5. Desktop, accounts and SSH](05-desktop-accounts.md) | What is each app for? How do sign-ins, SSH keys and settings work? |
| [6. System and network tools](06-system-network.md) | Which command explains a slow machine, full disk or failed connection? |
| [7. Maintenance and recovery](07-maintenance.md) | How do I update, customize, back up, restore and diagnose setup failures? |
| [8. Configuration and package reference](08-reference.md) | Where is each setting? What are the less visible packages for? |

## Quick routes

- **Before migration:** [Windows backup/install procedure](../MIGRATION.md), then [SSH key migration](../SSH_MIGRATION.md).
- **First login on Ubuntu:** provision using the [repository README](../../README.md), reboot, complete the [checklist](../SETUP_CHECKLIST.md).
- **First project:** chapters [3](03-development.md) and [4](04-containers-databases.md).
- **Something is slow or broken:** chapters [6](06-system-network.md) and [7](07-maintenance.md).
- **Adding or changing a tool:** chapter [8](08-reference.md), then [customization](../CUSTOMIZATION.md).

Examples use placeholder names such as `my-project`, `my-server` and `example.com`. Run project commands inside the corresponding project. Commands that create resources, start services or change files are identified in their surrounding instructions. Never put real tokens, passwords or private keys in a command copied into Git.

## Five commands to remember

```bash
./setup.sh plan          # From the ws-setup repository: preview and prerequisites
./setup.sh doctor        # Read-only installed-state diagnostics
ws-dotfiles diff        # Preview differences in managed user configuration
git status              # Inspect project work before changing or updating it
ws-backup backup        # After configuring and mounting the external backup disk
```

The handbook describes this setup, rather than every feature of every installed application. Use `COMMAND --help` or an application's Help menu for full option lists. The [application catalog](../APPLICATIONS.md) and specialized guides link to upstream documentation.
