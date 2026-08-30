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

## What is left

Nine of the ten permits whose bundled form is flagged as Castilla's own while
their requirements are recorded as built from a national baseline. Each is one
render and one read.
