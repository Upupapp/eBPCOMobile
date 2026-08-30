# A dropped connection no longer costs the applicant their photographs

*Built 30 August 2026 in `eBPCO-Mobile-App`. Front-end mobile only.*

---

## The gap

The offline queue has had a `documentUpload` kind since it was written, and
`SyncProvider._send` threw for it — deliberately, rather than pretending. Two
things were missing:

1. **Somewhere to send bytes.** `POST /documents` had no client until earlier
   the same day.
2. **Bytes that were still there to send.** This is the one nobody had looked
   at.

## The second one was a live defect, not just a blocker

A wizard attachment picked from the camera, the gallery or the file picker
pointed at **the picker's own temporary path**. `image_picker` and the system
document picker both hand back a path in a container the OS may reclaim —
**within a session, not only across a restart.**

So an applicant who photographed a land title at step 3 of a nine-step wizard
and filed at step 9 could lose it in between, and the failure would surface as
*"the file to upload could not be read"* with nothing to point at. The My
Documents flow had always copied picked files into the app's own directory; the
wizard attachments had not.

They do now. That fixes the live risk **and** is the precondition for queuing:
bytes that may vanish cannot honestly be retried later.

## What queues, and what does not

`QueueingDocumentUploadRepository` wraps the real upload:

| Failure | What happens |
|---|---|
| No signal, timeout, 5xx — **transient** | The file is queued, and the failure is **still thrown** |
| Too large, unsupported type, rejected, unauthorised — **permanent** | Nothing is queued |

A permanent failure replays identically forever while showing the applicant a
pending item that can never complete. That is worse than the error they already
saw.

**Queuing is not success, and the failure is rethrown either way.** A caller
that treated a queued upload as a completed one would file an application
referencing documents the office does not have — which is exactly the outcome
the all-or-nothing upload rule exists to prevent.

An attachment with no file behind it — the fabricated `DocumentModel` the
prototype creates when there is no real picker — is not queued either. Queuing
a reference to nothing shows a pending item that can never complete.

## What it promises, and what it does not

**It queues the file, not the filing.** An applicant whose connection drops
mid-submission still has to submit again. When they do, the bytes are already
at the office and the retry is fast; their typing survived separately, because
M-48 persists the draft.

The queue's `applicationSubmission` kind is still unimplemented. That is the
piece that would make the whole filing automatic, and it needs the wizard's
draft to be replayable from the queue rather than from the provider.

## The key is the queue's own

`QueuedOperation` has always carried an `idempotencyKey` created once at
enqueue. The replay sends **that** key, not a fresh one — so an upload
interrupted after the server committed but before the response arrived returns
the original document rather than storing the file twice.

Until earlier the same day the app sent no `Idempotency-Key` at all, on any
request. The queue was the only place that had ever modelled one properly.

## What guards it

`test/core/sync/queued_upload_test.dart`, sixteen tests. The replay half drives
`SyncProvider.flush()` against a fake `http.Client`, so what is asserted is the
request that would go on the wire: the bytes, the label, the queue's key, and
that a sent item leaves the queue.

Falsified three ways, each caught:

| Breakage | Caught by |
|---|---|
| Queue every failure, transient or not | *a permanent failure queues nothing* — three cases |
| Swallow the failure after queuing | *queues the file and still fails the caller* |
| Send a fresh key on replay | *the bytes, the label and the queue's own key are sent* |

## What is still not done

- **The submission itself does not queue.** See above.
- **Nothing shows the applicant which file is waiting.** `SyncProvider` reports
  a pending *count*; there is no screen listing the items.
- **No connectivity trigger.** The queue drains on app resume, which is the one
  signal available without `connectivity_plus` — an applicant can regain signal
  without ever backgrounding the app. Still the owner's call.
