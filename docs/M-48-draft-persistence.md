# M-48 — draft persistence: all nineteen wizards

*Built 30 August 2026 in `eBPCO-Mobile-App`, in two passes on the same day.
Front-end only. Follows `docs/SCOPING-M-48-draft-persistence.md`, which measured
the four options and recommended this one.*

---

## What an applicant used to lose

Nineteen wizards offered **Save as Draft**. The Applications tab listed drafts
with a "Last saved" time. **Nothing reached disk.** Every draft lived in a
`ChangeNotifier` and died with the process — up to nine steps of typing and, on
a Building Permit, twenty-four attachments. The copy had already been narrowed
to say so; that was honesty, not a fix.

**All nineteen wizards now survive a restart.** The mechanism was proven on
the Building Permit and Fencing first; the remaining seventeen followed once
the gate was in place to catch what repetition drops.

## The boundary moved, later the same day

**Attachments are kept now.** The section below is the reasoning that dropped
them, and it was sound when it was written — a `DocumentModel` carried a path
into the picker's own temporary container, and persisting such a reference
gives a draft that claims to hold a document it cannot open.

Two things changed it:

1. **Picked attachments are copied into the app's own storage** the moment they
   are chosen. That was done for a different reason — a picker path can die
   *within* a session, which was a live defect — and it removed the premise
   above as a side effect.
2. **What is stored is the file's NAME, not its path.** On iOS the app's
   container is `/var/mobile/Containers/Data/Application/<UUID>/…` and that
   UUID changes on an app update: **the file survives and the path does not.**
   A draft that stored a path would have kept every attachment right up until
   the first update and then lost all of them at once, which is worse than
   never keeping them.

So a file in the app's own storage is kept, by name, resolved against the
current documents directory at read time. Anything else — a picker path, a
fabricated attachment with no bytes, a file the applicant has since cleared —
is dropped and **named**, exactly as before.

The two losses are tracked separately and both reach the applicant:
`detachedDocuments` is what could not be *kept* at save time;
`unresolvedDocuments` is what could not be *given back* now. Neither subsumes
the other, and the second is the one a capture-time list gets wrong.

The applicant-facing sentence changed with it:

> Your attached files are kept too — if any are missing when you return, the
> draft will say which.

`honest_assurances_test` gates both halves. The second is what keeps it honest.

---

## The boundary as it was first drawn

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
| `lib/core/drafts/*_draft_codec.dart` | **Nineteen codecs**, one per wizard: 2,122 declared paths, of which 592 are attachment slots |

**Persistence is optional.** A provider built without a store behaves exactly as
it did before M-48 — in memory, dying with the process. That is what leaves
every existing widget test in the suite unaffected, and it is asserted rather
than assumed.

### Five decisions worth naming

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
- **Collections restore by key, never by position.** Six fields hold repeated
  records — two accessibility/fire-code maps, the demolition utilities, two
  fixture inventories and the applicant's own list of extra documents. A list
  index is not an identity: an enum reordered, or a row removed, would shift
  every value onto the wrong record.

### The seventeen were written mechanically, then gated

The codecs read uniformly because they were generated from each model's own
field declarations and then reviewed. That is the honest description: a
generator without a gate is how 2,122 fields become 2,122 chances to drop one
silently. The generator's own field parser was cross-checked against the gate's
until the two agreed on all nineteen wizards, path for path — they disagreed
twice before that, and each disagreement was a real parsing bug.

## Three gates, each catching what the others cannot

**1. `test/architecture/draft_snapshot_completeness_test.dart` — source.**
Every field a draft declares is captured **and** read back, or exempted with a
reason of at least 40 characters. It walks the object graph rather than
matching leaf names, so the applicant's `street` and the site's `street` are
two different paths.

Exemptions are **per wizard**, and that is not tidiness: a flat map would have
let `scopeOfWork` — genuinely fixed on the Addition/Extension draft — silently
exempt the scope of every other wizard, including the two where it is the
applicant's own answer.

**2. `test/features/drafts/all_wizards_round_trip_test.dart` — runtime.**
Capture a blank draft, read the codec source to learn which accessor each path
uses, mutate every scalar and date, encode through JSON, apply to a fresh
draft, capture again, compare. It covers what a source scan structurally
cannot. Demonstrated rather than claimed: **swapping two restore assignments so
each reads the other's key leaves the source gate green and fails this one.**

**3. `test/features/drafts/draft_collections_test.dart` — by hand.**
The six collection fields, which both generic gates treat as leaves. They are
also the only places an attachment is held inside a repeated record rather than
a named slot — the case a re-attach list is most likely to lose.

Plus `draft_persistence_test.dart`, which now checks the **wiring**: that every
wizard exposing a draft persists it, that `lib/app.dart` builds each with a
store, hands each to the tree by `.value` rather than a `create` callback that
would construct a second provider over the same keychain key, and starts a
restore for every one it builds.

### Falsified before believed

Nine deliberate breakages across the three gates, every one caught:

| Breakage | Caught by |
|---|---|
| A captured field deleted | *every field is captured* |
| A field captured but never restored | *every field is read back* |
| An attachment dropped from the re-attach list | *every field is captured* |
| A typo in a path | *the codec invents no path the draft does not declare* |
| A document path read back | *no document is restored* |
| A restore reading the wrong key | source gate **and** runtime |
| Two restore assignments swapped | runtime only — source gate stays green |
| A provider left out of `restoreFromStore` | *the app starts a restore for every wizard* |
| A provider handed to the tree by `create` | *every wizard is wired to the store* |

Two of the gates' own blind spots were found this way and fixed rather than
worked around:

- **`_classBody` bounded a class at the next `class` keyword.** Several models
  declare top-level helper functions *between* two classes, so a
  `final parsed = int.tryParse(...)` local read as a declared field. Now
  brace-matched.
- **The accessor regex required `input.` with no space.** dart format breaks a
  long assignment after the receiver — `= input\n    .boolean('a.long.path')`
  — so the strict form stopped seeing those calls and reported eleven
  correctly-restored fields across four wizards as lost.

A third was found in a *neighbouring* test: `draft_registry_test` matched
`class X extends ChangeNotifier implements DraftSource` on one line, and the
new `with PersistentDraft<...>` wraps that onto three. It had silently stopped
seeing the converted providers.

## The copy an applicant reads

Narrowed on 29 August to *"only while the app stays open"*, because that was
then true of all nineteen. Widened on 30 August, because it is now true of
none:

> You can save your progress as a draft and come back to it later, even after
> closing the app. Attached files are not kept — you will be asked to attach
> them again.

`honest_assurances_test` gates it **both ways**: the promise may not come back
without the caveat that makes it true, and the stale caveat may not survive.
That test joins adjacent string literals before matching, because dart format
breaks the sentence across source lines and a raw `contains` would have passed
while the copy said something else.

## What is NOT done

- ~~No re-attach prompt inside the wizard.~~ **Added 31 August 2026.** All
  nineteen wizards now show a `ReattachNotice` above the step: what was not
  kept, by name, dismissible, driven off the same `documentsToReattach` the
  Drafts row uses. The Drafts row is where the applicant *chose* the draft, not
  where they fill it in — an empty slot on a step they remember finishing needs
  its explanation there.

  It is **bounded**, for the reason `WizardProgressHeader` already records: it
  sits in the same Column above an `Expanded(PageView)`, and twenty-four
  document names at 200% text scale overflowed by **2,741 pixels**, which would
  have left the applicant unable to reach the fields. Measured, not guessed —
  the widget test that found it was written before the notice shipped. The
  names are capped and ellipsised; the count is not, so an applicant always
  learns whether they are missing one file or twenty, and the Drafts row, which
  scrolls, carries the full list.
- **Enum values are not covered by the runtime gate.** A blank draft cannot say
  what other values an enum has. They are covered by the source gate and by the
  concrete per-wizard tests.
- **Nothing is written until the applicant taps Save as Draft.** There is no
  autosave; a wizard closed without saving still loses its typing.

## Scope

Front-end mobile only, per the standing rule. Nothing here reaches a server: a
draft is not an application until the wizard files it, and the filing path is
unchanged.
