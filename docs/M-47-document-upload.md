# The document upload flow — the missing half of the write path

*Built 30 August 2026 in `eBPCO-Mobile-App`. Front-end mobile only; the client
half of an endpoint the contract already declares. Nothing was changed in
`~/ebpco-contract` or `~/ebpco-api`.*

---

## What this closes

Two of M-47's six divergences were **one gap seen from two request bodies**:
the app sent a document's *label and filename* on the submission and on the
payment report, because it had no way to produce the `documentIds` and
`documentId` the contract asks for. `POST /documents` was declared and never
called.

Both are now sent when the files were uploaded. And a third defect, invisible
to a gate that compares bodies, was found on the way and fixed with them.

## The third defect: a required header on nothing

**The contract makes `Idempotency-Key` a required header on every POST an
applicant can make** — register, file, cancel, answer an instruction, register
a business, save a professional, upload, report a payment, register a device.
Measured: `grep -rn Idempotency lib` returned nothing. The app sent it on none
of them.

It is a third class of divergence — not a missing field and not an undeclared
one, but a missing *header*, which the write-body gate structurally cannot see.
It also has the worst failure mode if a server ever stopped enforcing it:
without a key, **a retry after a timeout is a second filing**, and an applicant
tapping again on a rural connection ends up with two applications and two fees.

`ApiClient.post` now takes `idempotencyKey` as a **required** named argument.
Required rather than optional because a parameter nobody can forget is the only
version of this that stays true.

**The honest limit**, stated because it is easy to read this as more than it
is: a key made in the repository is stable across *the client's* retry of one
call, and **not** across an applicant tapping the button twice. The durable
version generates the key where the operation is created — which the offline
queue already does, and which is why the one queued path passes
`operation.idempotencyKey` instead.

## What was built

| File | What it is |
|---|---|
| `lib/core/api/idempotency_key.dart` | RFC 4122 v4 from `Random.secure()`. Sixteen bytes and two bit-masks; the contract asks for `format: uuid`, not for a package |
| `lib/core/api/api_client.dart` | `upload()` — streamed `multipart/form-data`; `post()` — the required header; 413 and 415 classified |
| `lib/core/repositories/document_upload_repository.dart` | The upload, its response, and a mock-build implementation that **refuses** |

### Four decisions worth naming

- **The files go before the filing, and all of them or none.** An application
  filed before its documents reach the office is one the office cannot act on.
  A *partially* uploaded one is worse: a submission listing eleven of
  twenty-four documents reads to an evaluator like an applicant who forgot
  thirteen. On any failure nothing is filed and the applicant still has their
  draft.
- **Sequential, not parallel.** Twenty-four concurrent multipart uploads from a
  phone on a rural connection is how a submission times out. The applicant
  would rather wait than start again.
- **`scanCleared` is carried, not hidden.** `201` does not mean the office can
  open the file: the bytes are unavailable until malware scanning finishes. An
  absent flag is read as *not cleared* — the safe reading of a missing value is
  the one that does not tell an applicant their document is with the office.
- **The mock build refuses.** A fabricated id would be the worst possible mock:
  the submission succeeds, the office holds a reference to nothing, and the
  applicant is told their documents were received. The same rule the sync
  engine already follows for the four operations it cannot send.

### 413 and 415 are the applicant's to act on

Both used to fall through to *"check your details and try again"*, which is
useless advice for a file that is too large and actively misleading for one of
the wrong type — the server inspects **magic bytes**, so renaming the file
achieves nothing. They are now distinct failures with messages that say what to
actually do.

## The fallback that is not a fallback to something that works

When documents were attached and **none** could be uploaded, the app sends the
undeclared `documents` key it always sent, and a conforming server refuses the
whole filing.

That is the intended outcome. The alternative is a submission that succeeds
while silently discarding twenty-four attachments the wizard told the applicant
were sent. The payment report does the same with `proof` versus `documentId`.
The two keys are mutually exclusive — sending both would be refused for the
undeclared one, which is the worst of both — and a test asserts it.

## The privacy manifest moved by itself, as designed

The manifest written this morning said no photo or user-content collection was
declared **because no file bytes left the device**, and its guarding test
carried the trigger: *the day an upload path appears, this fails and names the
two constants to add.*

It fired. `NSPrivacyCollectedDataTypePhotosorVideos` and
`NSPrivacyCollectedDataTypeOtherUserContent` are now declared — separately,
because "photos or videos" does not cover a PDF plan set an architect exported,
and an applicant reading the label should recognise what they attached.

## What guards it

`test/core/repositories/document_upload_test.dart` runs against a fake
`http.Client`, so what is asserted is the actual multipart request that would
go on the wire: the bytes themselves rather than a filename standing in for
them, the bearer token, the `Idempotency-Key`, a reused key on a retry,
`scanCleared`, and each of the failures.

`test/core/providers/upload_before_filing_test.dart` covers the ordering rule,
falsified two ways — filing before uploading, and pressing on past a failed
upload — both caught.

`test/core/api/idempotency_key_test.dart` pins the version and variant bits
against a seeded generator, because a generator producing 36 random hex
characters would pass a length check and fail a server's format validation
roughly fifteen times in sixteen — in production, on a filing, not here.

## What is still not done

- ~~**Nothing retries.**~~ **Closed 30 August 2026, and this line was stale
  after that day.** The offline queue's `documentUpload` kind IS implemented:
  a transient failure enqueues the upload with the same idempotency key and
  rethrows — queuing is not success, and a caller that treated it as success
  would file an application referencing documents the office does not have.
  The bytes survive a restart because picked attachments are copied into the
  app's own directory.

  What was genuinely missing, and is now filed as a task rather than claimed
  as done: **the citizen cannot see the queue.** `SyncProvider` exposes
  `pendingCount` and `hasPendingWork`, and nothing in `lib/features/` reads
  either. An upload waiting to be retried is invisible.
- **The key is per attempt, not per operation.** See the honest limit above.
- ~~**No upload progress.**~~ **Closed 31 August 2026.** `ApiClient.upload`
  takes an `onProgress` callback — a `MultipartRequest` subclass counting the
  stream it hands to the client, since `package:http` has none and the file is
  streamed rather than buffered. `ApplicationsProvider` reports an
  `UploadProgress` per document and `UploadProgressSheet` shows it: how many
  documents, which one by **its own name**, and a bar spanning the whole
  filing rather than resetting to zero twenty-four times.

  Stated honestly in the code: those are bytes handed to the socket, not bytes
  the server acknowledged. The OS buffers, so it can reach the total slightly
  before the office has the file — and "nearly done" that is a little
  optimistic beats four minutes of silence.
- ~~**`form` and `location` are still not sent**~~ — **both closed.**
  `location` on 31 August; `form` on 31 August, once the field-for-field
  audit against Castilla's own forms retired the reason it was blocked on
  M-10. See `docs/M-47-form-payload.md`.
- **The App Store Connect privacy label has not been re-read** since the app
  started transmitting the wizard contents. It is a separate declaration of the
  same facts as the privacy manifest, and only the manifest was updated.
