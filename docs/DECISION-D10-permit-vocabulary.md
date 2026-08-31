# Decision brief — D-10, which permit vocabulary is canonical

For whoever can rule on what the Office of the Building Official calls its own
permits. Prepared by the mobile lane, 31 August 2026, from a mechanical
comparison rather than a reading.

**One sentence:** the server issues 17 permit types, the app and the admin
portal offer 19, and **only one name matches exactly** — so a citizen filing
anything but a Certificate of Occupancy is refused with *"The LGU does not
issue a …"*.

---

## It is not one problem. It is three, and only the last is hard.

Classified mechanically by normalising case, punctuation and the word "Permit":

| | Count | Example |
|---|---|---|
| **Exact match** | 1 | `Certificate of Occupancy` |
| **Suffix only** — the server name plus the word "Permit" | 10 | `Fencing` → `Fencing Permit` |
| **Spacing only** | 1 | `Civil/Structural` → `Civil / Structural Permit` |
| **Absent from the server entirely** | 7 | `Zoning / Locational Clearance` |

The server also has 5 names the app does not file under: `New Construction`,
`Renovation`, `Addition/Extension`, `Sanitary/Plumbing`, `Business Permit`.

### 1 & 2 — the eleven that are the same permit spelled two ways

A ruling, not a design problem. **The office's own paper answers it.** The
forms bundled in this app, under the municipal seal, are titled:

> Fencing Permit Application · Electrical Permit Application ·
> Architectural Permit Application · Sign Permit Application ·
> Demolition Permit Application · Interior Design Permit Application ·
> Civil / Structural Permit Application

**The word "Permit" is part of the name on the office's own documents**, and
the admin portal matches the paper. The server's short forms match neither.

*Honest caveat:* the paper is not a perfect match for the admin's list either —
the sanitary form is titled `Sanitary Permit` where the admin says
`Sanitary Permit` and the server says `Sanitary/Plumbing`, and the excavation
form is `Excavation and Ground Preparation Permit` where both lists say
`Excavation Permit`. The paper settles the *suffix* question. It does not
settle every string.

### 3 — the seven the server does not have at all

This is the part that is **not a naming question**, and it is why this brief
exists rather than a one-line answer.

| Absent from `permit_types` | What it is |
|---|---|
| `Building Permit – New Construction` | the server has `New Construction`; a naming difference |
| `Building Permit – Renovation / Alteration` | as above |
| `Building Permit – Addition / Extension` | as above |
| `Sanitary Permit` | the server has `Sanitary/Plumbing` |
| **`Zoning / Locational Clearance`** | **issued by the MPDC, not the OBO** |
| **`FSEC for Building Permit (BFP)`** | **issued by the Bureau of Fire Protection** |
| **`FSIC for Occupancy Permit (BFP)`** | **issued by the BFP** |

The last three are not spelled differently. **They are not there.** They are
also the three the mobile app built wizards for as gaps G-06, G-07 and G-08 in
the closing certification — a citizen can fill them in and has nowhere to file
them.

The question they raise is scope, not vocabulary: **does eBPCO accept filings
for permits another office issues?** If yes, `permit_types` needs three rows
and the contract's enum three values. If no, the app should stop offering three
wizards, and the certification's G-06/G-07/G-08 closures need re-reading.

---

## What each answer costs

**If the office's 19 are canonical.** The `permit_types` seed and the
contract's `PermitType` enum move. The admin portal does nothing. The mobile
app does nothing. Every client already speaks this vocabulary.

**If the contract's 17 are canonical.** The admin portal moves first — it is
the office's own system and the source this app is generated from — and the
mobile app follows it, as it always has. That is two front ends and a
regenerated fixture, and it means telling the office that its own forms use the
wrong words.

**Recommendation: the office's 19.** Not because mobile prefers them, but
because they are what the office prints on the paper a citizen signs, and
because they cost one seed file and one enum against two front ends and a
conversation with the LGU.

**Whichever is chosen, do not add a cast.** The admin already converts between
the two vocabularies unchecked. A second mapping on the mobile side would make
three spellings, no authority, and a defect that only appears on the surface
nobody tested.

---

## After the ruling

* **Backend:** the `permit_types` seed, the contract's `PermitType` enum, and a
  decision on the three externally-issued clearances.
* **Mobile:** nothing, if the 19 stand. If the 17 do, one commit after the
  admin portal moves — the vocabulary is extracted from it mechanically, not
  typed.
* **Either way:** `test/contract/application_submission_test.dart` currently
  asserts that the contract accepts **1 of the 19** types this app files. That
  number is the measure of this decision, and it should read 19 when it is
  done.
