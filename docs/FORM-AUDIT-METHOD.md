# Auditing a wizard against its official form

*Written 31 August 2026. Front-end mobile lane.*

---

## The register was wrong about who can do this

`docs/M-10-forms-already-bundled.md` said auditing the wizards against the
bundled forms was *"work this lane cannot do — reading a scanned form is not a
source scan"*, and needed someone who could open a PDF.

**That was wrong, and it was wrong because I did not try.** Every Mac ships
`qlmanage`, which renders a PDF page to PNG; the PNG can then be read directly.
`tool/render-form.sh` is the two lines it takes.

## The limit, which is real

`qlmanage` renders **page one only**, and this machine has neither Homebrew nor
poppler, so there is no `pdftoppm` to render the rest. For most of these forms
page one carries Boxes 1–5 — applicant, location of construction, scope of
work, the design professional, the supervisor and the consent block — which is
where nearly all applicant-entered fields live. The later boxes (specifications,
and the office-only processing sections) are on page two and remain unread.

Say which pages an audit covered. A wizard "audited against the form" on the
strength of page one is a different claim from one audited against all of it.

## The method

1. `tool/render-form.sh <Form-Name>` and read the PNG.
2. Walk the form box by box. For each printed field, find the model field that
   holds it.
3. Record three things separately: fields **on the form and missing from the
   wizard**; fields **in the wizard and not on the form**; and anything the
   form says that the app's comments contradict.

That third one is where the first audit found its defect.

## First audit: the Fencing Permit

**The form is genuine.** `NBC FORM NO. B–03`, headed *Republic of the
Philippines / MUNICIPALITY OF CASTILLA / Province of Sorsogon / OFFICE OF THE
BUILDING OFFICIAL / FENCING PERMIT*. That settles `isOfficialCastillaForm` for
this one by reading rather than by trust — the earlier audit could corroborate
only two of fourteen flags and said so; this is a third method, and a better
one.

**One field was missing.** Box 1's address row is
`ADDRESS NO. · STREET · BARANGAY · CITY/MUNICIPALITY · ZIP CODE · TELEPHONE NO.`
The wizard collected every part of it except the telephone number — and the
model carried a comment saying the form *"has no contact number or province
field (unlike other ancillary permits')"*.

Half of that is right: there is no province field. The other half is not, and
it was load-bearing. **Fencing was the only one of the nineteen wizards without
a contact number**; the other eighteen collect one. The comment is why nobody
questioned it. Both are fixed.

**Everything else on page one matches**, box for box: the six Scope of Work
options are exactly the app's six; Boxes 2 and 3 are the same professional
shape twice, which is how the model has it; Box 4's applicant and lot-owner
consent pair matches; Box 5's notarial fields are a subset of what the model
carries.

**One oddity in the LGU's own form, recorded rather than acted on.** Box 5's
notarial block is pre-printed `REPUBLIC OF THE PHILIPPINES ) S.S. / CITY OF
LEGAZPI` — Legazpi is in Albay, not Sorsogon. That is the municipality's form
to correct, not the app's; the app leaves the notarial venue blank, which is
the right behaviour either way.

## A spot check that came back clean

The Electrical Permit form's `SUMMARY OF ELECTRICAL LOADS/CAPACITIES APPLIED
FOR` asks for Total Connected Load, Total Transformer Capacity and Total
Generator/UPS Capacity, all in kVA. The model has
`totalConnectedLoadKva`, `totalTransformerCapacityKva` and
`generatorCapacityKva`, with a conditional document requirement when the
generator capacity is above zero. No gap.

## The rest of the audit, 31 August 2026

All nine remaining forms rendered and read. **Every one carries the Castilla
letterhead**, so the ten `isOfficialCastillaForm: true` flags among them are now
verified by reading rather than pinned on trust — the earlier audit could
corroborate two of fourteen by machine and said so.

| Permit | Form | Page-one verdict |
|---|---|---|
| New Construction · Renovation · Addition/Extension | Unified Application Form for Building Permit | **four findings** |
| Civil / Structural | NBC A-02 | exact — 12 scope options, 15 natures of work |
| Electrical | NBC A-03 | exact — 8 scope options, all three supervisor types |
| Mechanical | NBC A-04 | exact — 12 scope options, 2 supervisor types; the app's 29 equipment kinds are a superset of the form's 19 grouped ones |
| Sanitary | NBC A-05 | exact — 12 scope, 4 water supplies, 8 disposal systems. Title wrong |
| Plumbing | NBC A-06 | exact — 12 scope, 4 systems; the app offers one fixture more than page one prints (swimming pool) |
| Electronics | NBC A-07 | exact — 3 scope options, 14 systems |
| Excavation | NBC B-02 | exact — 6 scope options. Title wrong |
| Fencing | NBC B-03 | audited first; the telephone number was missing |

**That settles the 14-against-4 disagreement.** The forms are Castilla's and the
wizards were built from them — nine of the ten match box for box. The
requirements catalogue's `verified: false` is the stale party for these
permits, not the form flag.

### Fixed

- **`LEGALIZATION OF EXISTING BUILDING`** was missing from the building
  permit's Scope of Work. The form prints twelve options and the app had
  eleven, so an applicant regularising an unpermitted structure had to choose
  *Others* and type it — on the one permit where the office most needs to know,
  since legalisation follows a different assessment path under PD 1096.
- **Two form titles named the permit rather than the document**, against
  `PermitForm.title`'s own rule. NBC B-02 is headed *Excavation and Ground
  Preparation Permit*; NBC A-05 is headed *Sanitary Permit*, not "Sanitary /
  Plumbing".

### Filed, not fixed

Three more findings on the Unified Application Form, all bigger than an enum
value and all on the app's most-filed permit:

- **`NUMBER OF STOREY` is not collected.** The form asks for it beside Number
  of Units, Total Floor Area and Lot Area, which the app does collect.
- **The estimated-cost breakdown is collapsed to one figure.** The form asks
  for TOTAL ESTIMATED COST split across *Building · Electrical · Mechanical ·
  Electronics · Plumbing*, plus *Cost of Equipment Installed*. Building permit
  fees are assessed from those components, so a single number is not the same
  information.
- **Boxes 3 and 4 ask for a `Gov't Issued ID No.`; the app asks for a CTC
  Number.** The ancillary forms do ask for C.T.C. No., so the app is right
  elsewhere and wrong here.

### One oddity in the LGU's own paperwork

The Excavation form is headed **Office of the Municipal Engineer**, not Office
of the Building Official. The app shows the OBO for it. In many municipalities
these are the same officer and `FormIssuingOffice.obo` documents both, so this
is recorded rather than changed — but an applicant reads the app's label and
then the paper's.

## What guards the audit

`test/architecture/form_field_parity_test.dart` pins every count read off the
paper — twelve scope options here, eight there, fifteen natures of work, three
electrical supervisor types. A count that lives only in a document is a count
nobody checks; an option quietly added or dropped now fails a test and has to
be justified against the form.
