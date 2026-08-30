# M-48 — draft persistence: the mechanism, and two of nineteen wizards

*Built 30 August 2026 in `eBPCO-Mobile-App`. Front-end only. Follows
`docs/SCOPING-M-48-draft-persistence.md`, which measured the four options and
recommended this one.*

---

## What an applicant used to lose

Nineteen wizards offered **Save as Draft**. The Applications tab listed drafts
with a "Last saved" time. **Nothing reached disk.** Every draft lived in a
`ChangeNotifier` and died with the process — up to nine steps of typing and, on
a Building Permit, twenty-four attachments. The copy had already been narrowed
to say so; that was honesty, not a fix.

Two wizards now survive a restart: **Building Permit** and **Fencing**.

## The boundary, and why it is drawn at a reason rather than a size

The scoping note recommended option D — persist "the scalar fields". The
boundary shipped is sharper: **everything a draft holds is persisted except
`DocumentModel` slots.**

That is a superset of D, and it is drawn where it is because of what a
`DocumentModel` *is*. It carries a `filePath` into a file the applicant picked,
and a path captured before a restart is not reliably readable after one — iOS
in particular hands out paths into a container the OS may reclaim. Persisting
such a reference trades one silent loss for a worse one: a draft that claims to
hold a document it cannot open.

So the file is dropped **and the applicant is told, by name**:

> Re-attach 3 documents: PRC ID of the professional in charge, Land Title, Plans

That line renders on the Drafts row — the place an applicant returns to a
draft. A restored draft that silently forgot eleven attachments, on steps the
applicant has already been through and believes are finished, would be a worse
failure than the one M-48 set out to fix.

## Where it is stored

The **keychain**, via `flutter_secure_storage` — not SharedPreferences. A draft
holds the applicant's name, address, TIN and the names of their identity and
ownership documents. That is the same class of content the offline queue holds,
and TAB 11 settled where it belongs; `SecureDraftStore` follows
`SecureQueueStore`'s reasoning deliberately rather than inventing a second
answer. M-01 and M-32 are the same argument applied elsewhere.

Retention is **90 days**, against the queue's 30. An applicant assembling a
building permit waits on a professional, a clearance and a notary, and a draft
untouched for a month is the normal shape of that task rather than neglect —
`DraftSummary.isIdle` already treats a week as merely worth a nudge. It expires
at all because a draft is personal data under RA 10173 and keeping it forever
on a device is not minimisation.

## What was built

| File | What it is |
|---|---|
| `lib/core/drafts/draft_snapshot.dart` | The snapshot value, and the writer/reader that encode a draft into flat dotted paths |
| `lib/core/drafts/draft_store.dart` | `SecureDraftStore`, `InMemoryDraftStore`, `decodeDrafts`, and `DraftPersistence` |
| `lib/core/drafts/persistent_draft.dart` | The mixin a wizard provider takes on. Ordering, races and detachment are decided once |
| `lib/core/drafts/building_permit_draft_codec.dart` | 83 declared paths: 59 values persisted, 24 attachments named |
| `lib/core/drafts/fencing_permit_draft_codec.dart` | 92 declared paths: 67 values persisted, 8 attachments named, 17 exempted as office-only. Two shared shapes captured through one helper each |

**Persistence is optional.** A provider built without a store behaves exactly as
it did before M-48 — in memory, dying with the process. That is what leaves
every existing widget test in the suite unaffected, and it is asserted rather
than assumed.

### Four decisions worth naming

- **Enums are stored by `name`, never by index.** An enum reordered between
  releases would otherwise move every stored value one place along.
- **A restored draft is always a draft.** `status` is captured but deliberately
  never read back: honouring a stored `submitted` would resurrect a filed
  application as editable.
- **Restore refuses to overwrite a draft already being typed into.** A keychain
  read is fast, not instant, and an applicant can reach step 1 before it lands.
  Replacing what they are typing with what they typed last week is the one
  outcome worse than not restoring at all.
- **All drafts share one keychain record, so writes are serialised.** Two
  wizards saving at once would otherwise each write a map built before the
  other's change, and one save would vanish.

## The gate, written before the seventeen

`test/architecture/draft_snapshot_completeness_test.dart`. Every field a
persisted draft declares is captured **and** read back, or exempted with a
reason of at least 40 characters.

It exists before the remaining wizards rather than after, because the rest of
M-48 is hand-writing a capture and a restore for thousands of fields and every
one is a chance to drop one silently. That is not a hypothetical defect class
here — it is the one the read-path gate was built for, after `application_dto`
was found dropping a document's whole review layer, an assessment's payments, a
payment state, a notification's payload and ten of fourteen profile fields. A
dropped field *here* is worse: the applicant retypes it, having been told their
progress was saved.

It walks the draft's **object graph** rather than matching leaf names, so the
applicant's `street` and the construction location's `street` are two different
paths. Matching leaf names would let one stand in for the other — the same
vacuity that made an earlier gate in this repository pass against an empty
slice.

**Falsified before it was believed.** Five deliberate breakages, each caught:

| Breakage | Caught by |
|---|---|
| A captured field deleted | *every field is captured* |
| A field captured but never restored | *every field is read back* |
| An attachment dropped from the re-attach list | *every field is captured* |
| A typo in a path | *the codec invents no path the draft does not declare* |
| A document path read back | *no document is restored* |

The vacuity guard caught an error of my own on its first run: it asserts the
Building Permit declares two fields named `street`, and it was written claiming
three.

## What is NOT done

- **Seventeen wizards.** Zoning, Certificate of Occupancy, FSEC, FSIC,
  Renovation, Addition/Extension, Demolition, Architectural, Civil/Structural,
  Electrical, Mechanical, Sanitary/Plumbing, Plumbing, Electronics, Interior
  Design, Sign, Excavation. Each is one codec plus one line in the gate's
  wizard list; the gate fails the day a wizard is listed and incomplete.
- **The applicant-facing copy stays narrowed.** "Only while the app stays open"
  remains true of seventeen of nineteen, and a promise that holds for two is
  not a promise. A test gates the sentence on the converted count, so it cannot
  be removed early by accident.
- **No re-attach prompt inside the wizard itself.** The Drafts row names the
  documents; the step that lost them does not yet flag it.

## Scope

Front-end mobile only, per the standing rule. Nothing here reaches a server: a
draft is not an application until the wizard files it, and the filing path is
unchanged.
