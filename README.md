# dhis2-docker

Local DHIS2 development stack: PostgreSQL + DHIS2 + Glowroot APM + pgAdmin, orchestrated with Docker Compose. Designed for fast iteration on a local machine with a seeded dump of real DHIS2 data.

## What's in the box

| Service | Image | Purpose |
|---|---|---|
| `postgresql` | custom (postgis + wal2json + python3-bcrypt) | DHIS2 database, pre-loaded from `dhis.sql.gz` |
| `glowroot-installer` | `alpine:3.20` | Runs once at stack-up to download the Glowroot APM agent into `home/glowroot/` |
| `dhis2` | `dhis2/core:42` | DHIS2 web app with `-javaagent:/opt/dhis2/glowroot/glowroot.jar` attached |
| `pgadmin4` | `dpage/pgadmin4:latest` | Pre-configured browser-based DB client |
| `analytics-trigger` | `curlimages/curl:latest` | One-shot: hits `/api/resourceTables/analytics` after DHIS2 becomes healthy, polls to completion |

## Prerequisites

- Docker Desktop with **at least 12 GB memory** allocated (16 GB recommended — DHIS2 needs ~5 GB just for the analytics populate phase, and starving the Docker Desktop VM will get the JVM SIGKILL'd mid-populate).
- `make`, `curl`, `bash` on the host (standard on macOS and most Linux distros).
- A DHIS2 database dump at `./dhis.sql.gz` (gzipped `pg_dump` output). The `.sql.gz` file is gitignored; drop your own dump in the project root.

## Quick start

```bash
make run
```

That's it. `make run`:

1. Wipes `home/logs/*` so you start with a clean log directory.
2. `docker compose down -v` — nukes any previous state, including the `pgdata` volume so postgres reinitializes from scratch.
3. `docker compose up` with both `compose.yml` and `compose.pgadmin.yml`.

First startup takes 5–10 minutes: postgres has to import the dump, DHIS2 has to do its schema migrations and app discovery, and `analytics-trigger` has to populate the analytics tables before exiting. Subsequent `make run` invocations are the same length because `-v` wipes the database every time.

When it's done you'll have:

| URL | What |
|---|---|
| http://localhost:8080 | DHIS2 |
| http://localhost:4000 | Glowroot APM |
| http://localhost:5050 | pgAdmin |

## Accessing the services

### DHIS2 → http://localhost:8080

Log in as `admin` / `district`. That said, **any existing username in the dump also works with the password `district`** — `initdb.sh` rewrites every row in the `userinfo` table on a fresh init (see [Password reset](#password-reset--all-dhis2-users-get-the-same-password) below).

If you see a 502 or the page doesn't load immediately, DHIS2 is still booting — Tomcat takes ~30–90 seconds after postgres becomes healthy. Follow `docker compose logs -f dhis2` to watch it come up.

### Glowroot APM → http://localhost:4000

Just open the URL. **No login screen** — `glowroot/admin.json` pre-declares an anonymous Administrator user, so you land directly on the dashboard. Hit a few DHIS2 pages to generate traffic, then look at:

- **Transactions → Web** — per-endpoint response times, sample traces, slow query breakdown
- **Errors** — exceptions with full stacks
- **JVM → Gauges** — heap, GC, threads
- **JVM → MBean tree / Thread dump / Heap dump** — live introspection

Storage is in `home/glowroot/data/` on the host (H2 embedded). Surviving `make run` is fine because `home/glowroot/` is a bind mount, not a Docker volume. If you ever want a blank-slate glowroot, `rm -rf home/glowroot/` and re-run — the `glowroot-installer` sidecar will re-download the agent.

⚠️ **Local dev only.** The anonymous-admin shortcut means anyone who can reach port 4000 has full APM access. Never expose this port on a shared machine or network.

### pgAdmin → http://localhost:5050

Open the URL and click the **DHIS2** server in the left-hand tree (expand `Servers` → `DHIS2`). Everything is pre-configured:

- **No master password** — `PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: "False"` skips the first-launch prompt.
- **Desktop mode** — `PGADMIN_CONFIG_SERVER_MODE: "False"` skips the pgAdmin login.
- **No DB password prompt** — `pgadmin4/pgpass` (chmod 600, format `postgresql:5432:*:dhis:dhis`) is bind-mounted into the container at `/pgpass`, and `pgadmin4/servers.json` points at it via `"PassFile": "/pgpass"`. When you click the DHIS2 connection, pgAdmin reads the pgpass file and connects silently.

If you later want to add more servers, do it in the UI normally — pgAdmin's own internal SQLite state persists inside the container for the lifetime of the pgadmin volume (wiped on `make run`, since it uses `down -v`). For anything permanent, edit `pgadmin4/servers.json` instead so it re-seeds on every startup.

## Make targets

```
make run         clean start: wipe volumes + logs, then start the stack
make force-run   wipe volumes + logs, rebuild images from scratch, and start
make build       build images (no cache bust)
make pull        pull latest images from Docker Hub
make down        stop the stack (keeps volumes)
make help        show this help
```

`make run` reuses cached image layers and is the right default. `make force-run` is needed when you've changed the `Dockerfile` or want a guaranteed-fresh build (`--no-cache`) — it adds several minutes for the `apt-get upgrade` step in the postgres image.

## Password reset — all DHIS2 users get the same password

`initdb.sh` runs once on fresh postgres init and rewrites every row in the `userinfo` table:

```sql
UPDATE userinfo SET password = <bcrypt($DHIS2_PASSWORD)>, disabled = false;
```

This means:

- **Every DHIS2 user** — not just `admin` — can log in with their existing username and the password from `.env`.
- **Every disabled account is re-enabled** (`disabled = false`), which matters because dumps from real deployments often ship with historical users disabled.
- **The password is `$DHIS2_PASSWORD` from `.env`** (default `district`). Change `.env`, then `make run`, and every user's password changes.

The hashing happens inside the postgres container via `python3-bcrypt` (installed in our `Dockerfile`), so `DHIS2_PASSWORD` can be set to anything — no pre-computed hash needed.

This is purely a local-dev convenience and should never be used against a real database.

## Glowroot APM

Glowroot is a Java agent that attaches to the DHIS2 JVM via `-javaagent`. Because it has to be present before the JVM starts, it's **baked into the base compose** rather than offered as an overlay — the `glowroot-installer` service runs first, downloads the agent into `home/glowroot/` (which is bind-mounted into the DHIS2 container as `/opt/dhis2/glowroot/`), and exits. DHIS2 then starts with `JAVA_OPTS=… -javaagent:/opt/dhis2/glowroot/glowroot.jar`.

The installer is idempotent: if `home/glowroot/glowroot.jar` already exists on the host, it skips the download and just refreshes `admin.json` from the seed template (`glowroot/admin.json`), so bumping auth config is fast.

**No login required.** `glowroot/admin.json` declares an `anonymous` user with the `Administrator` role and binds the UI to `0.0.0.0:4000` inside the container. This is explicitly a local-dev shortcut — do not expose port 4000 to anything you don't trust.

## pgAdmin — zero-prompt DB access

`compose.pgadmin.yml` is an overlay that carries the `pgadmin4` service. It's always pulled in by `make run` / `make force-run` / `make build` / `make pull` / `make down` via a `COMPOSE :=` variable in the `Makefile`, so for everyday use it behaves as if it were in the base. The split exists so you can `docker compose up` directly (without `-f compose.pgadmin.yml`) if you ever want a leaner stack.

Two normally-annoying prompts are disabled:

- **No master password on first launch** — `PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED: "False"` plus `PGADMIN_CONFIG_SERVER_MODE: "False"` (desktop mode).
- **No DB password prompt** — `pgadmin4/pgpass` is a `.pgpass`-format file (`postgresql:5432:*:dhis:dhis`) bind-mounted into the container at `/pgpass`, and `pgadmin4/servers.json` references it via `"PassFile": "/pgpass"`. `chmod 600` on the host file is required (libpq rejects looser perms).

Click the `DHIS2` connection and you're in.

## Environment

Configuration lives in `.env` (gitignored). The committed **`.env.example`** is the canonical reference — copy it and edit locally:

```bash
cp .env.example .env
```

Required vars (consumed by image entrypoints and will fail the stack if missing):

- `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` — postgres image init
- `TZ` — container timezone
- `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD` — pgadmin4 image init

Optional (defaulted in `initdb.sh`, only set if you want to override):

- `DHIS2_USER` — default `admin`. Used purely for display/logging; `initdb.sh` resets *every* row in `userinfo`, not just this one.
- `DHIS2_PASSWORD` — default `district`. Bcrypt-hashed at init time and applied to every DHIS2 user. Change this and re-run `make run` to re-seed.

## File layout

```
compose.yml               # base stack: postgres, glowroot-installer, dhis2, analytics-trigger
compose.pgadmin.yml       # pgadmin4 overlay (always included by Makefile targets)
Dockerfile                # postgis/postgis:17-3.4 + wal2json + python3-bcrypt
initdb.sh                 # one-shot init: loads dump, resets passwords, enables accounts
dhis.sql.gz               # your gzipped DHIS2 dump (gitignored)

glowroot/admin.json       # committed seed for glowroot auth config
pgadmin4/servers.json     # pgAdmin pre-registered server entry
pgadmin4/pgpass           # chmod-600 .pgpass for pgAdmin (servers.json → PassFile)

home/                     # bind-mounted into dhis2 container as /opt/dhis2
├── dhis.conf             # DHIS2 config (committed)
├── dhis-google-auth.json # gitignored
├── files/                # DHIS2 runtime files (gitignored)
├── logs/                 # DHIS2 logs (gitignored, wiped by make run)
└── glowroot/             # downloaded by glowroot-installer (gitignored)

Makefile
README.md
.env                      # gitignored
.gitignore
```

## Troubleshooting

**DHIS2 restarts mid-startup, analytics-trigger loops forever.** Docker Desktop VM is out of memory and the host kernel is SIGKILL'ing the JVM during the analytics populate phase. Bump Docker Desktop → Resources → Memory to 16 GB. The JVM's `-Xmx4g` plus analytics workers plus the postgres buffer pool easily blows past 8 GB on real data.

**analytics-trigger keeps printing `Still running...` and never completes.** Check `docker logs dhis2 | grep -i 'added root logger'` — if you see that line *after* analytics started, DHIS2 silently restarted and the task notifications buffer was lost. Same cause as above (memory). The trigger script hardcodes `admin`/`district`, so if you've somehow deleted the `admin` user from the dump, you'll see `401 Unauthorized` instead.

**pgAdmin complains the server is out of date.** `pull_policy: always` on `dpage/pgadmin4:latest` refreshes the image on every `make run`, but Docker Hub's `:latest` tag occasionally lags. Pin to a specific version in `compose.pgadmin.yml` if needed.

**`make force-run` takes forever.** The `--no-cache` flag re-runs `apt-get upgrade` from scratch inside the postgres image build. Use `make run` unless you actually need to bust the layer cache (Dockerfile changes).

## Licensing

Glowroot is Apache 2.0. pgAdmin is PostgreSQL License. DHIS2 is BSD-3-Clause. This repo itself is unlicensed; treat it as an internal dev tool.
