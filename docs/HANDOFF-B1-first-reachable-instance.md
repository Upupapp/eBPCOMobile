# Handoff to the backend lane — one reachable instance

From the iOS/mobile lane, 31 August 2026. **A request, not a specification** —
you own this service and know its constraints better than I do. Correct
anything below that is wrong.

## What I am asking for

One instance of `apps/ebpco-api` that the mobile app can reach. **Localhost is
enough.** Not staging, not production, not a deployment decision — just a
process I can point a `--dart-define` at.

## Why it is worth your afternoon

**The mobile app has never spoken to a server.** Not once. Every green test it
has is a claim about its own source, and this week that gap produced six
defects that all lived in the same place — between the wizard and the wire:

* `serviceDomain` was never sent. A conforming server would have refused every
  filing the app has ever made.
* `businessId` went as `''` where the contract types a uuid or null.
* `Idempotency-Key` was never sent, on eight operations that require it.
* `location` was never sent, so an office learned the permit type and the
  citizen and not the site.
* `form` was never sent — **up to 239 fields per filing, collected, validated,
  reviewed on screen, and dropped at the wire.**
* `GET /applications/{id}` was never called, because the method existed on the
  repository and the interface did not declare it. Every screen ran on the list
  payload.

All six are fixed and all six are now asserted over a real socket against a
stub. **A stub only proves the app is self-consistent with the contract.** It
cannot tell me whether your server agrees. One real filing would.

## What it appears to need

From your own `.env.example`, which is clear that development degrades safely:

* `DATABASE_URL` — Postgres. `npm run migrate` (31 migrations).
* The token signing key. No default, deliberately.
* `OBJECT_STORE_DRIVER=filesystem` and `MALWARE_SCANNER_DRIVER=local` — both
  fine for development, both refused at boot in production.
* `npm run start:dev`.

So no MinIO and no ClamAV for this. If that reading is wrong, say so.

Then, on my side, one flag:

```
flutter run --dart-define=EBPCO_API_BASE_URL=http://localhost:3000
```

## Two things that will block it the moment we try

**1. A route the app calls that does not exist.**

```
POST /applications/{applicationId}/documents/{documentId}/resubmit
```

`http_applications_repository.dart:139`. Undeclared in the contract and
unimplemented. It is a different operation from
`/instructions/{letterId}/resubmit`, which does exist — a document can be
rejected with remarks when there is no Letter of Instruction at all, which is
why the per-document loop was built. A grep for "resubmit" matches the other
one and reads as closure. `~/ebpco-contract/tools/verify.sh` has been saying so
throughout.

**2. Account deletion — worth doing in the same pass.**

Apple **Guideline 5.1.1(v)** requires any app offering account creation to
offer in-app account deletion. This app creates accounts and has none, and the
contract declares **no DELETE operation anywhere**, so it cannot be built
client-side. It is a certain App Store rejection, and it is cheaper to add
beside the route above than on its own later.

## What I will do with it

Point the app at it and file one application through a wizard, watching every
hop: the request bodies, the required headers, the response parsing, and the
list-versus-detail reads. Then write up what actually happened — including
whatever the client got wrong, which is the point of asking.

## What this is not

Not a hosting decision, not staging, not production, and nothing to do with
who operates the service (E-1/E-2). Production still refuses to boot on the
filesystem store and the local scanner, still needs real object storage — and
the Linode adapter has **no Philippine region**, which is a data-residency fact
the NPC filing has to state. None of that is in scope here.

Also still open on your side and not part of this request: **M-32** —
`devices.push_token_encrypted` and `accounts.totp_secret_encrypted` store their
bytes unchanged.
