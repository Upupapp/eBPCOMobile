# M-48 — draft persistence: what it would take

*Measured 29 August 2026 in `eBPCO-Mobile-App`. Front-end only. This is a
scoping note for a decision, not a plan I have started.*

---

## The problem, restated

Nineteen wizards offer **Save as Draft**, the Applications tab lists drafts with
a "Last saved" time, and **nothing reaches disk**. Close the app and an
applicant loses everything unsubmitted — up to nine steps and, on a Building
Permit, 22 attached documents. The Before-you-start card has been narrowed to
say so; that is honesty, not a fix.

Proven in `test/features/applications/draft_persistence_test.dart`.

## The size of it, measured

| | Count |
|---|---|
| Draft model files | 19 |
| Classes inside them | **236** |
| Typed fields across those classes | **2,624** |
| — plain scalars (`String`, `bool`, `int`, `DateTime`) | 1,252 (48%) |
| — `DocumentModel` attachment slots | 586 (22%) |
| — enums, lists, nested objects | 786 (30%) |

*Counted over the 19 files that actually declare a `*Draft` class, with one
regex for all three rows so the breakdown sums to the total. An earlier draft of
this note said "~3,225 fields" against a breakdown summing to 2,672 — two
different counting rules, and the inconsistency was only caught by re-verifying
every figure before publishing.*

Two structural facts that shape every option:

- **The draft classes are mutable with field initialisers and no
  all-field constructors** (`String lastName = ''`, and so on). Anything
  generated or deserialised has to assign field by field, not construct.
- **This repo already has a persistence pattern** and it is the right one:
  `SecureQueueStore` keeps records in the platform keychain via
  `flutter_secure_storage`, while document *bytes* stay in the app's private
  directory and are referenced by path. Its own comment explains why —
  "putting megabytes of scanned plans into a keychain designed for secrets
  would be the wrong tool and would fail on size."

**Drafts are personal data**: applicant name, address, TIN, and the filenames of
identity and ownership documents. So the store is the keychain, not
SharedPreferences — the same reasoning as M-01 and M-32.

---

## Four options

### A — Hand-written `toJson`/`fromJson` per class

236 classes × two methods. Complete, and the way every field gets covered.

**Against it:** it is the largest possible version, and every one of 2,624
fields is a chance to silently drop one. That is precisely the defect class this
programme has spent two days finding in parsers — five separate instances. It
would need its own completeness gate to be trustworthy, which is buildable (the
model-versus-serialiser diff already exists for the read path) but doubles the
work.

### B — Code generation (`json_serializable` / `freezed`)

Mechanical, and the 236 classes stop being a per-class cost.

**Against it:** the draft classes would have to be restructured into immutable
constructor-taking shapes, which touches all nineteen wizards and every step
widget that mutates them today. It also adds `build_runner` to a project that
has none. This is the largest blast radius of the four.

### C — Per-wizard snapshot at the section level

Each wizard exposes `Map<String, Object?> toSnapshot()` / `restore(Map)` — 19
pairs rather than 236, written at the section level and deliberately lossy.

**Against it:** still nineteen hand-written pairs, and "deliberately lossy"
needs a rule for what is dropped or it becomes arbitrary.

### D — Persist the resumable core only *(recommended)*

Store, per wizard: **which permit, which step, and the scalar fields**. Do not
persist attachments; on restore, show the applicant which documents they need
to re-attach.

**Why this one:**

- The scalars are **48% of all fields and close to 100% of the typing** — the
  address, the TIN, the lot number, the project description. That is the part
  an applicant would resent re-entering.
- The 586 document slots are the part least safe to persist anyway. A
  `DocumentModel` carries a `filePath` into a picked file, and a path captured
  before a restart is not reliably readable after one. Persisting a reference
  that may not resolve trades one silent loss for a worse one — a draft that
  claims to hold a document it cannot open.
- It is the smallest change that removes the actual harm, and it can be built
  one wizard at a time behind the existing `DraftSource`, rather than as a
  nineteen-wizard cutover.
- Being explicit — *"your details are saved; re-attach your documents"* — is
  honest in a way that a silent partial restore is not.

**Estimate:** the mechanism plus two wizards, roughly a day; the remaining
seventeen are repetitive and gateable. A completeness gate — every scalar field
on a draft class is either snapshotted or exempted with a reason — should be
written *first*, so the seventeen cannot quietly drop fields.

---

## What I recommend deciding

1. **Do drafts persist at all?** If no, the narrowed copy stands and M-48
   closes as a product decision rather than debt.
2. **If yes, is D acceptable** — details restored, documents re-attached — or
   is anything short of a full restore not worth doing?
3. **Keychain confirmed** as the store, consistent with `SecureQueueStore`.

I have not started any of it. The measurement above is the whole deliverable.
