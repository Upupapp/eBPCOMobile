# Standing up the LGU staging instance

For Castilla's IT, on the existing shared 2 GB Linode. **Testing period only** —
fabricated data, upgrade around 30 September 2026. Written by the mobile lane
from the backend's own docs; the backend lane owns the service.

Everything here assumes `EBPCO_ENVIRONMENT=staging`, which is what makes the
object store and malware scanner deferrable. Production refuses to boot on
either stand-in, correctly.

---

## 1. On the instance

Ubuntu LTS with Docker and the compose plugin. Nothing else — no Node, no
Postgres on the host.

```sh
git clone <the ebpco-api repo> ~/ebpco-api
cd ~/ebpco-api/apps/ebpco-api
```

## 2. The secrets — four, all different

```sh
openssl rand -base64 48    # once per key
```

`JWT_SIGNING_KEY`, `PASSWORD_PEPPER`, `TOTP_ENCRYPTION_KEY`,
`PUSH_TOKEN_ENCRYPTION_KEY`, each ≥32 characters. Staging requires all four —
only `development` is exempt.

**The pepper is not like the others.** It is mixed into every password before
hashing and held outside the database. Lose it and **no stored password can
ever be verified again** — every citizen and every officer is locked out with
no reset path. Put it somewhere a second person can reach, today, before it
protects anything.

## 3. `.env`

Copy `.env.example` and set:

```
EBPCO_ENVIRONMENT=staging
DATABASE_URL=postgres://ebpco:<db-password>@db:5432/ebpco
OBJECT_STORE_DRIVER=filesystem      # staging only; production refuses this
MALWARE_SCANNER_DRIVER=local        # staging only; production refuses this
SCHEDULER_ENABLED=true              # see §7
PORT=3000
```

Leave `DOCUMENT_RETENTION_DAYS` **unset**. Unset means nothing is ever deleted,
and the retention period is the LGU's decision to make deliberately.

## 4. `docker-compose.yml`

```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ebpco
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ebpco
    volumes: [pgdata:/var/lib/postgresql/data]
    restart: unless-stopped
    # No `ports:` — the database is reachable only on the compose network.

  api:
    build:
      context: .                     # this directory, NOT the repo root
      dockerfile: Dockerfile
    env_file: .env
    ports: ["127.0.0.1:3000:3000"]   # loopback only; TLS terminates in front
    depends_on: [db]
    restart: unless-stopped

volumes:
  pgdata:
```

**The build context is `apps/ebpco-api`, not the repository root.** The
Dockerfile says so in its own header: since the monorepo move, building from
the root resolves `COPY package.json` to a different service's file, and the
build then succeeds against the wrong tree.

**No published port on the database.** A Postgres on a Linode's public IP is
found by scanners within hours.

## 5. Migrations — the step that is not obvious

`npm run migrate` cannot run inside the image. `scripts/` is not copied into
either stage, and `ts-node` is pruned with the dev dependencies. Filed as D-12.

Until that changes, run it from a throwaway container so the host needs no
Node:

```sh
docker compose up -d db
docker run --rm -v "$PWD:/app" -w /app --network ebpco-api_default \
  --env-file .env node:22-bookworm-slim \
  sh -c "npm ci --ignore-scripts && npm run migrate"
```

Check the network name with `docker network ls` — compose derives it from the
directory.

## 6. Start, and check

```sh
docker compose up -d api
curl -s localhost:3000/ready | jq
```

Expect `status: ready` with database, objectStore and malwareScanner all `up`.
On staging the last two are the stand-ins, and that is correct.

`/health` is liveness and touches nothing. Point any monitor at `/ready`, not
`/health` — `/ready` is the one that reports draining.

## 7. The scheduler

`SCHEDULER_ENABLED=true`. Replicas coordinate through the `scheduled_jobs`
table, so it is safe on every instance — `.env.example` says otherwise and is
wrong (D-11).

Did it run?

```sql
select name, last_finished_at, last_outcome, consecutive_failures
  from scheduled_jobs;
```

`consecutive_failures` is the number to watch: one is noise, nine is an outage
nobody noticed.

## 8. TLS

Put Caddy or nginx in front of `127.0.0.1:3000` and let it get a Let's Encrypt
certificate. Then, from the mobile repo:

```sh
./tool/check-ats.sh <your-host>
```

Four checks — certificate, TLS 1.2+, forward secrecy, cipher family. The mobile
app declares no App Transport Security exceptions, so a host failing any of
them is refused by iOS **at runtime**, in a citizen's hands, not at build time.

---

## Tell the testers two things before they start

* **No notifications will arrive.** `notification-dispatch` queues and sends
  nothing — no push, email or SMS provider has been chosen, and every run logs
  `NOT SENT`. It is the predictable false bug report.
* **Uploaded documents vanish on redeploy.** The filesystem object store keeps
  them on the container's disk. Correct for staging, and exactly why production
  refuses to boot on it.
