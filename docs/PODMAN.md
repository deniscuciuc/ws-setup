# Local development with Podman

Ubuntu runs **native rootless Podman**, without a Podman VM. `podman-docker` provides the `docker` command; `docker compose` delegates to the explicitly pinned upstream Compose executable. Databases start only when you run the project's commands.

## Verify the environment

After a fresh login:

```bash
systemctl --user status podman.socket
podman info --format '{{.Host.Security.Rootless}}'
printf '%s\n' "$DOCKER_HOST"
docker compose version
bash scripts/smoke-containers.sh
```

The endpoint should be `unix:///run/user/<your-uid>/podman/podman.sock`, and rootless should print `true`. Podman Desktop must display the same containers as the CLI. `~/.config/environment.d/99-workstation.conf` supplies the endpoint and tool paths to user services/desktop apps, after Ubuntu's `/etc/environment`; `.profile` supplies them to login shells. Restart the session to apply both. An explicit existing `DOCKER_HOST` takes precedence.

The smoke test uses a unique project name, temporary build context and localhost-only randomly allocated port. It creates and removes only its own containers, image and named volume. It tests image building, PostgreSQL health, Valkey, network DNS and persistence across container recreation.

## Existing projects

Use each project's existing commands, for example:

```bash
docker compose --env-file .env.example -f compose.local.yml config --quiet
docker compose --env-file .env -f compose.local.yml up -d
```

Validate in an isolated Ubuntu test environment before migrating real data. The audited Peerbridge stack includes PostgreSQL 17, Valkey 8, MinIO and Mailpit; the detector stack uses PostgreSQL 16 and Valkey 8. Keep their image versions and ports project-owned. Choose a distinct Compose project name for tests, and avoid starting a second stack on ports already in use.

Export logical database dumps on Windows and restore them into newly created Linux volumes. For uploads/object storage, use the service's export/sync mechanism or a stopped, consistent volume backup. Do not copy Docker Desktop's internal storage directories into Podman.

**Audit finding, 15 September 2026:** Peerbridge's `minio/minio` tag was denied by Docker Hub with both engines. The same MinIO/MC releases are available from the vendor's [Quay distribution](https://min.io/docs/minio/container/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html). Both projects passed their service checks when Peerbridge used the digest-pinned test override in `tests/peerbridge-minio-quay.yaml`. Resolve the project's image source before migration; review long-term MinIO maintenance separately. The workstation installer does not rewrite project Compose files. Reproduction commands are in [TESTING.md](TESTING.md).

## Common problems

| Symptom | Check |
|---|---|
| Cannot connect to Docker | Start a new login session; verify the Podman socket and `DOCKER_HOST`. Do not expose the API over an unauthenticated TCP port. |
| Rootless range errors | Inspect `/etc/subuid` and `/etc/subgid`. Setup preserves existing mappings and allocates non-overlapping 65,536-ID ranges only if missing. Stop containers and follow Podman's migration instructions before changing an existing mapping. |
| Host files have incorrect ownership | Keep repositories on ext4; inspect the image's UID expectations and Podman user namespaces. Do not recursively chown your whole home or container storage. |
| Compose provider missing | Run `./setup.sh --only containers`; inspect `~/.config/containers/containers.conf` and `~/.local/bin/docker-compose`. |
| VS Code sees another engine | Restart VS Code from the new session; check its Dev Containers paths and inherited endpoint. |
| Remote Docker stopped working | Set `DOCKER_HOST` explicitly in that project/session or a private local override. |
| A Docker feature is unsupported | Verify that feature against Podman. `buildx`, advanced BuildKit features, privileged networking and socket-dependent integrations are not guaranteed drop-in replacements. |

Testcontainers and .NET Aspire require their own project-level tests. Do not globally disable cleanup/resource reapers or enable privileged containers to make an untested integration pass.

## Existing Docker installation

Setup stops before installing conflicting packages. First export and verify data. Review installed Docker packages and repository configuration, then remove only the engine/CLI packages you intend to replace. Never run a blanket prune or delete volumes as part of this transition. Rerun setup afterwards.

No linger or always-on database service is enabled by the installer. If you later need containers running after logout, configure a deliberate user service/Quadlet and document that requirement separately.

References: [Podman API socket](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html), [Compose provider](https://docs.podman.io/en/latest/markdown/podman-compose.1.html), [Desktop on Linux](https://podman-desktop.io/docs/installation/linux-install).
