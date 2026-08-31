# D-11 — the file an operator configures from contradicts the behaviour

From the mobile lane, 31 August 2026. Found while advising the LGU on
`SCHEDULER_ENABLED` for their staging deployment. **Documentation, not code**,
and it points the wrong way for the person most likely to read it.

## The two statements

`.env.example`, which is what an operator copies and edits:

> Off by default. **Exactly one deployment should run the schedulers; several
> replicas each running them multiply every swept notice by the replica count.**

`docs/OPERATIONS.md` §4a:

> **Every replica runs a scheduler; they coordinate through the database.** A
> job is claimed by one UPDATE whose WHERE only matches an unheld lock, so
> exactly one replica runs it — no leader election, no coordinator to be down.

## Which is right

`OPERATIONS.md`. `src/common/scheduling/job-runner.ts` claims a job with

```
update scheduled_jobs … where name = $1 …
```

taking a lease against `instanceId`, and reports `'held-elsewhere'` when
another instance holds it. The coordination is real and it is good — no leader
election, nothing to be down.

## Why it matters more than a stale comment usually would

The wrong statement is in the file an operator **configures from**, and it
leads to a worse architecture than the one that was built. Following it, an LGU
designates one special instance as the scheduler-runner — and when that
instance dies, scheduled work stops **silently**: no job fails, nothing is
retried, `consecutive_failures` never rises because nothing ever attempts. The
design in the code has no such failure mode, and the comment talks an operator
out of it.

## Suggested fix

`.env.example` says something like:

```
# Off by default so a one-off process or a test does not start deleting
# documents as a side effect of booting. Set true on every deployment that
# should run jobs — replicas coordinate through `scheduled_jobs`, so exactly
# one runs each job. See OPERATIONS.md §4a.
```

## Guidance given to the LGU meanwhile

`SCHEDULER_ENABLED=true` on their single staging instance, and **true on every
instance when they scale** — not one designated box.
