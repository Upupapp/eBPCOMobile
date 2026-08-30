# Permit conditions — what the app tells an applicant their permit requires

Audited 31 August 2026, against Box 8 (Box 9 on the mechanical form, Box 10 on
the interior design one) of the permit forms bundled in `assets/forms/`.

Twelve models declare `permitConditions`. **Nine wizards render it**, on the
Evaluation & Permit Status step, under a heading that reads as the conditions
the Office of the Building Official attaches to the permit. So a wrong entry is
not a wording problem: an applicant who never hears about the ten-day written
notice to their neighbour does not give it, and finds out when the office stops
the work.

Page two, where these boxes live, went unread until 31 August because
`qlmanage -t` renders only page one and nobody had looked for a second
renderer. `tool/render-form.sh <form> <page>` (JXA + PDFKit) is that renderer.

## What was wrong

| Wizard | Defect | Now |
|---|---|---|
| Fencing | Four real obligations absent — relocation survey, ten-day written notice to the adjoining owner, jobsite logbook, Article 1723 | Stated, with what the notice must show |
| Fencing | **Invented**: "Required signed and sealed professional documents must be authentic." | Removed |
| Plumbing | Notice of Construction softened to "when required" | "Before any plumbing work begins…" |
| Mechanical | Same softening | "Before any mechanical installation…" |
| Electrical | Same softening, and the form names **who** submits it | "you as the owner or permittee must submit…" |
| Electrical | "a PCAB-licensed specialty contractor is required for **qualifying installations**" | "200 amperes and above at 230 volts nominal and above" |
| Interior Design | Article 1723 and the completion documents absent; same invented "must be authentic" | Corrected, and caveated — see below |

Two patterns, each appearing more than once:

* **Softening a "shall" into "when required".** Four forms print the Notice of
  Construction as unconditional. Nobody in this lane had the authority to make
  it conditional, and the applicant is the party who bears the consequence.
* **Generalising away the number.** "Qualifying installations" tells an
  applicant a rule exists and not whether it binds them. 200 amperes at 230
  volts is the entire content of that condition.

And one in the other direction: **an invented condition**, in two wizards. It
is the same defect as an omitted one, and it reads as a rule about the
applicant's honesty standing where the office's obligations belong.

## The interior design form is not Castilla's

Reading page two settled what `isOfficialCastillaForm: false` means in
practice. The interior design form's signature block names **another
municipality's** Municipal Engineer — Engr. Florentino J. Destacamento — and
two of its Processing and Evaluation Division staff. Castilla's own forms
(fencing, plumbing, mechanical, electrical) are signed by **Jesus D. Abitria,
Jr., Municipal Engineer**.

So its Box 10 is that municipality's conditions, not Castilla's, and the three
wizards whose forms are reference templates — **Architectural, Demolition,
Interior Design** — may not print "these conditions will apply once the permit
is issued". They now carry `LguSourceNotice.conditionsFromReferenceForm`
instead, the same rule the form viewer already applies to the document itself.

What those three still state is limited to what is **national law** and holds
whichever LGU issues the permit: Article 1723 of the Civil Code, R.A. 8534,
the National Building Code and its IRR.

## Still to read

Box 8 of **Civil/Structural, Electronics and Sanitary/Plumbing**. All three are
rendered to `${TMPDIR}/ebpco-forms/` already, and all three currently say
"when required" of the Notice of Construction — which four other forms
contradict. That is a strong prior and not a reading, so it stands unchanged
until someone opens the page.

## The gate

`test/features/permit_conditions_test.dart`, 13 tests. It asserts the corrected
text, the absence of both softenings and the invented condition, that the three
reference-form wizards carry the caveat and do not carry the promise, and that
that set of three is **exactly** the set `permit_forms.dart` flags as not
Castilla's — delegated, so if the LGU publishes its own architectural form and
the flag flips, the test fails and the caveat comes off that screen.

It also pins the render count at nine: if a tenth wizard starts showing
conditions, they have not been checked against a form.
