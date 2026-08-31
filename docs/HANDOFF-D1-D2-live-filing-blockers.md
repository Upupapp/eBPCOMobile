# Handoff — two blockers found by the first live filing

From the mobile lane, 31 August 2026. Both are **cross-lane** and filed rather
than fixed. Evidence and method in `docs/FIRST-LIVE-FILING.md`.

Reproduced against `apps/ebpco-api` at `start:dev`, 31 migrations applied,
`GET /ready` reporting database, object store and scanner all up.

---

## D-1 — the server rejects `serviceDomain`, which the contract requires

```
POST /applications
{"serviceDomain":"Construction Permit","permitType":"Fencing Permit", …}

400  {"pointer":"/","message":"Unrecognized key(s) in object: 'serviceDomain'"}
```

Remove the key and the same body validates.

`ApplicationSubmission` in `openapi/ebpco.openapi.yaml` declares:

```yaml
required: [serviceDomain, permitType, applicationAction]
```

The mobile client was changed on **30 August specifically to start sending it**,
because a conforming server would refuse a filing without it. The server that
exists refuses the filing *with* it.

**Every application this app can file is refused.** The client is following the
contract and should not be the thing that moves. One of two decisions:

* the server adopts `serviceDomain`, or
* the contract drops it — in which case the client's gate
  (`test/contract/application_submission_test.dart`) inverts, and mobile does
  that in one commit.

Please say which, rather than each side assuming the other.

---

## D-2 — nothing can create the applicant profile a filing requires

With `serviceDomain` removed, the body validates and the filing still fails:

```
422  "This account has no applicant profile. Complete your profile before filing."
```

`submission.service.ts:132`. The refusal is right, and
`submission.spec.ts:265` asserts it deliberately: *"refuses an account with no
applicant profile, rather than inventing one."*

**There is no way to create one.**

* the contract has no `/applicants` route;
* `/me` is **GET only** — no POST, no PATCH;
* registration inserts no `applicants` row;
* `businesses.controller.ts:107` hits the same wall for business registration.

So `register → sign in → file` dead-ends at the third step, **through any
client, for every citizen.** This is a hole in the contract rather than a bug
in either implementation, which is why nobody has hit it: the server's own
tests insert the row directly.

Needed: an operation that creates or completes the applicant profile, declared
in the contract, and a decision on what it requires. The mobile side then adds
the step — the wizards already collect everything an `applicants` row is likely
to want.

---

## What the mobile lane is doing meanwhile

Nothing that pre-empts either decision. The client keeps sending
`serviceDomain` because the contract requires it, and there is no profile step
because there is no operation to call. Both land quickly once you have chosen.

The harness that found these is `test/live/first_filing_live.dart` — named
`_live.dart` so the suite does not collect it, since it needs a server and
asserts nothing.
