# 3. Development workflow

[Index](README.md) · Previous: [Terminal](02-terminal.md) · Next: [Containers/databases](04-containers-databases.md)

## Start an existing project

1. Restore or clone it into a Linux filesystem directory such as `~/Development/my-project`.
2. Read its README, inspect `git status`, and identify its runtime/lock files.
3. Restore private environment settings from your encrypted backup or project secret store.
4. Install dependencies with the project's package manager and pinned version.
5. Start its required services using its Compose instructions, then run its build/tests.

Do not reuse Windows `node_modules`, virtual environments or internal container storage. Recreating them on Ubuntu avoids platform-specific binaries and path problems.

## Git tools

| Tool | Why it exists | First use |
|---|---|---|
| Git | Version history, branches, commits and remote synchronization | `git status`, `git diff` |
| Git LFS | Stores large tracked assets using LFS pointers | In a project using LFS, follow its setup and fetch instructions |
| GitHub CLI (`gh`) | GitHub authentication, repository and pull-request operations | `gh auth login`, then `gh auth status` |
| GitLab CLI (`glab`) | Equivalent GitLab workflows | `glab auth login`, then `glab auth status` |
| delta | Readable Git diffs in the terminal | Used automatically by `git diff` |
| lazygit | Interactive terminal Git interface | `lazygit` in a repository |
| GitKraken | Graphical Git history, staging and branch workflows | Open the app and select a local repository |

Managed Git defaults use `main` for new repositories, rebase on pull, prune stale remote-tracking references during fetch, and keep Linux line endings on checkout. Review your work before pulling. Override identity or project-specific behavior locally rather than editing another project's configuration globally. `~/.gitconfig.local` is included for private machine overrides. GitHub HTTPS credentials use `gh`; SSH authentication is a separate path explained in [chapter 5](05-desktop-accounts.md).

## Runtime selection

pnpm uses a shared package store and prefers cached packages. Keep worktrees on the store's filesystem and use `ws-storage pnpm . --probe` to verify linking. See [storage/maintenance](../MAINTENANCE.md) for package sharing, backup exclusions and why generated build outputs can still consume space.

| Component | Role | What determines a project's version? |
|---|---|---|
| .NET SDK | Compile, test and run .NET applications | Project targets and `global.json`; setup installs .NET 10 from Ubuntu |
| mise | Install/select Node runtimes | Project `mise.toml` or `.node-version`; the managed baseline is Node 24 |
| Corepack | Dispatch the project's package-manager version | `packageManager` in `package.json` |
| pnpm | Install Node dependencies and run scripts | Project lockfile and package-manager version |
| uv | Manage Python versions, virtual environments and dependencies | `.python-version`, `pyproject.toml`, `uv.lock` and project instructions |
| System Python | Support Ubuntu and provisioning | Ubuntu packages; keep it separate from project environments |

Useful checks:

```bash
dotnet --list-sdks
node --version
pnpm --version
uv --version
```

Typical project commands, after reading its instructions:

```bash
dotnet restore
dotnet build
dotnet test

pnpm install --frozen-lockfile
pnpm run build

uv sync --locked
uv run python --version
```

These examples apply to their respective project types, not as a sequence required in every repository. If a Node/Python lockfile does not exist or a script is named differently, follow that project. Do not globally change pnpm to fix one project. Trust mise project configuration only after reviewing its contents.

For a simple Python project without uv metadata, `uv venv` creates `.venv`; use the project's dependency instructions afterward. Avoid `sudo pip` and modifying Ubuntu's Python environment. Additional .NET SDKs use the documented route in [customization](../CUSTOMIZATION.md); do not mix conflicting .NET package feeds.

## VS Code and its extensions

VS Code is the graphical development editor; the full Windows Visual Studio IDE is not installed. Check Windows-only workloads before migration.

| Extension | Purpose |
|---|---|
| C# Dev Kit | C#/.NET project editing and debugging |
| Python + Pylance | Python editing, environment selection and language analysis |
| Ruff | Python formatting and linting |
| ESLint | JavaScript/TypeScript lint feedback using project configuration |
| Prettier | Formatting for configured JS/TS/JSON files |
| YAML | YAML editing, schema support and formatting |
| Container Tools | Inspect/build/manage containers from the editor |
| Dev Containers | Open a project in its development-container environment |
| Remote SSH | Work on a remote machine through SSH |
| Claude Code + OpenAI | Integrate the requested AI coding tools |

Settings enable format-on-save, disable autosave/minimap, add final newlines, trim trailing spaces, and exclude common build/dependency directories from watchers. VS Code's terminal is login Bash. Dev Containers is configured to use Podman and the standalone Compose provider; test each project's compatibility.

## Makefiles

GNU Make is installed explicitly by the base module, including the core profile. In a project containing `Makefile`, run `make` for its default target or `make TARGET` for a named target, for example `make build` or `make test` if that project defines them. Read the Makefile or project README for available targets and required tools. Make executes the recipes in that file; it does not replace the project's SDKs, dependencies or container engine. `just` is an additional task runner, and does not replace `make`.

## AI tools

Claude Code (`claude`) and Codex (`codex`) are standalone CLIs, independent of your project's Node version. Start them in the intended repository and complete their own sign-in flows. Claude Desktop and OpenAI's ChatGPT desktop with Codex are separate desktop applications and may require separate authentication.

Review their proposed file changes and command approvals like any other development work. Credentials stay outside Git. Linux desktop feature limitations and current launch-test results are in [the catalog](../APPLICATIONS.md) and [testing](../TESTING.md). This handbook does not imply an account subscription or enable paid services.

## API and DevOps work

**Bruno** organizes GUI API requests; **HTTPie** provides quick terminal HTTP requests, for example `http GET http://localhost:3000/health` when your project exposes that endpoint. Keep API tokens in private environments, not committed collections.

**just** runs named tasks from a project's `justfile`; `just --list` shows available tasks. **yq** queries YAML, while **jq** queries JSON. **OpenTofu** manages declared infrastructure; inspect `tofu plan` before any apply. **cloudflared** supports Cloudflare tunnels/Access; provisioning does not create a tunnel. **Wrangler** belongs in each Workers project's dependencies, not the global workstation.

Optional **SOPS** encrypts structured secret files, **age** supplies encryption keys/recipients, **Ansible** automates machines using project inventories, and **Trivy** scans project/image contents. Installing them creates no credentials, infrastructure or background jobs. Follow the examples and opt-in commands in [TOOLS.md](../TOOLS.md).
