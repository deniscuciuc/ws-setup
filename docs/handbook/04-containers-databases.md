# 4. Containers and databases

[Index](README.md) · Previous: [Development](03-development.md) · Next: [Desktop/accounts](05-desktop-accounts.md)

## What the container components do

| Component | Job |
|---|---|
| Podman | Build and run Linux containers as your normal user |
| `podman-docker` | Provide a `docker` command backed by Podman |
| Standalone Docker Compose | Read project Compose files and coordinate multiple services through Podman's API |
| Podman user socket | Let compatible development tools talk to the native rootless engine |
| Podman Desktop | Show containers, images, volumes and engine state graphically |
| Skopeo | Inspect/copy container images without running them; installed by `tools` |

On Linux there is no Podman VM in this setup. **Rootless** means the engine runs under your user identity, with subordinate user/group mappings for container IDs. Run development containers as your normal user. `sudo podman` uses separate root-owned state and will not show the same containers.

The `docker` bridge alone does not implement Compose; the external provider is an intentional part of the setup. `DOCKER_HOST` points compatible tools at the user socket. An explicit remote endpoint is preserved.

## A project session

In a project containing the expected default Compose file:

```bash
docker compose config --quiet  # Validate configuration
docker compose up -d           # Start this project's services
docker compose ps              # Check status
docker compose logs --tail 100 # Read recent logs
docker compose stop           # Stop services while retaining containers
docker compose down           # Remove project containers/networks
```

Use the project's `-f` and `--env-file` options when it uses different filenames. Do not commit real `.env` credentials. A published localhost port lets desktop clients connect; a service name such as `postgres` generally resolves inside the Compose network, not in your host browser.

Named volumes preserve data across normal container recreation. `down` normally retains named volumes; **`down -v` removes them**. Avoid that option on data you need. Container/image cleanup and database backups are separate operations.

## Choose a database client

| Database/service | GUI | CLI | What to do |
|---|---|---|---|
| PostgreSQL | DBeaver | `psql` | Connect to the project's published host/port/database; inspect tables and run SQL |
| MySQL/MariaDB | DBeaver | `mysql` | Use the project's credentials and selected database |
| SQLite | DBeaver | `sqlite3` | Open the database file directly; no database server is needed |
| SQL Server | DBeaver | Go-based `sqlcmd` | Connect to the SQL Server instance provided by your project |
| MongoDB | MongoDB Compass | `mongosh` | Connect using the project's MongoDB URI and browse/query documents |
| Redis/Valkey | RedisInsight | `redis-cli` | Inspect keys and cache state; these are not SQL tables |
| MinIO | Project's web console/API | Project-provided client | Manage object-storage buckets/uploads according to project docs |
| Mailpit | Project's web interface | HTTP/API tooling if needed | Inspect emails captured from local development |

DBeaver may need to download a database driver when you create the first connection. Clients do not install or start the corresponding database servers. RedisInsight is installed with the everyday Snap applications; a core-only setup has the cache CLI but no GUI.

Connection profiles need host, port, username, database and authentication/TLS settings. Use values from your local project's configuration. Avoid disabling TLS for a remote server just to dismiss a connection error. Keep passwords out of screenshots, shared exports and committed connection files.

Local examples, once the corresponding service exists:

```bash
psql -h 127.0.0.1 -p 5432 -U app -d app
mysql -h 127.0.0.1 -P 3306 -u app -p
sqlite3 ./development.db
redis-cli -h 127.0.0.1 -p 6379 PING
```

The SQLite command can create a new file if it does not exist. Other commands need the correct project values; ports shown here are examples, not reserved workstation settings.

## Preserve data and troubleshoot

Create logical database exports before migrating Windows, then restore into fresh Linux services. Test the restore by querying real representative records. Uploaded files/object storage need their own consistent export. An image backup does not include volume data, and a raw live database directory is not a reliable logical backup.

If a GUI cannot connect, check service health, port publishing, credentials and whether another stack occupies the port. If tools show different containers, compare user identity and `DOCKER_HOST`; restart the login session after setup.

Use [PODMAN.md](../PODMAN.md) for socket diagnostics, Docker conflicts, subordinate IDs, project compatibility and the known MinIO image-source issue. Advanced Docker/BuildKit features, Testcontainers and Aspire require their own project acceptance tests.
