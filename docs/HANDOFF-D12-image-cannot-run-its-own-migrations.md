# D-12 — the shipped image cannot run its own migrations

From the mobile lane, 31 August 2026, while writing a deployment runbook for
the LGU's staging instance. **Not a code defect — a gap between what
`OPERATIONS.md` instructs and what the image supports.**

## The instruction

`OPERATIONS.md` §2: *"Migrations run in the pipeline, not on boot."* Correct,
and for the right reason: several instances racing to alter one schema is worse
than an extra deploy step.

## The gap

`npm run migrate` is `ts-node --transpile-only scripts/migrate.ts`, and
**neither Docker stage can run it**, for two independent reasons:

* **`scripts/` is never copied.** The build stage copies `package.json`,
  `package-lock.json`, `tsconfig*.json` and `src`. The runtime stage copies
  `node_modules`, `dist`, `package.json` and `db/migrations`. `scripts/` is in
  neither, so `scripts/migrate.ts` does not exist in the image at all.
* **`ts-node` is pruned.** The build stage ends with
  `npm prune --omit=dev --ignore-scripts`, and `ts-node` arrives transitively
  through `ts-node-dev`, a devDependency. So even with the script present the
  runtime image has no interpreter for it.

`db/migrations` **is** copied — deliberately, because the readiness probe reads
it to compare the schema the build expects against the schema it found. So the
image can *check* the schema it cannot *apply*.

## Why it matters for this deployment specifically

The LGU is standing up a staging instance this week on a Linode box with Docker
and no Node toolchain. Following `OPERATIONS.md` they will run
`npm run migrate`, and there is nothing on the host to run it with. The
workaround below works and is not obvious.

## What the LGU is doing meanwhile

Running migrations from a throwaway container over a checkout, so the host
needs no Node:

```sh
docker run --rm -v "$PWD:/app" -w /app --network ebpco_default \
  --env-file .env node:22-bookworm-slim \
  sh -c "npm ci --ignore-scripts && npm run migrate"
```

## Suggested fixes, in the order I would prefer them

1. **Compile the migrator.** Add `scripts/migrate.ts` to the build's TypeScript
   inputs and ship it in `dist`, so `node dist/migrate.js` works from the
   runtime image with production dependencies only. Then the pipeline step is
   `docker run --rm <image> node dist/migrate.js` and the image is
   self-sufficient.
2. **A `migrate` build stage** that keeps the dev dependencies and copies
   `scripts/`, published alongside the runtime image.
3. **Document the throwaway-container form** in `DEPLOYMENT.md`, if the image
   is meant to stay production-only.

Whichever, `DEPLOYMENT.md` should say how migrations are actually run, because
today it says when and not how.
