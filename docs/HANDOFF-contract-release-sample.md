# Handoff — the contract's release sample names another LGU's city hall

Found 31 August 2026 while working M-11. **Cross-line: the contract repo is
read-only from the mobile front-end lane, so this is filed rather than fixed.**

## What

`reconciliation/response-samples.json`, the `release` block of the application
detail sample:

```json
"claimLocation": "Office of the Building Official, 2/F Cabuyao City Hall",
"officeHours":   "Monday to Friday, 8:00am - 5:00pm",
"bringWithYou":  ["One valid government ID.", "The Official Receipt."]
```

**Cabuyao is a city in Laguna.** This product serves the Municipality of
Castilla, Province of Sorsogon — a different region, about 500 km away.

## Why it matters more than a placeholder usually would

1. **It contradicts the contract's own decision, three files apart.**
   `reconciliation/RECONCILIATION.md`, note R-13, says the claim logistics
   "are LGU-specific (M-11 / decision E-15) and **are omitted rather than
   guessed**". The sample guesses them.

2. **A response sample is what an implementer copies.** It is the most likely
   thing to be pasted into a fixture, a mock server or a demo seed. The mobile
   app has already shipped one set of fabricated LGU details that arrived
   exactly this way: `support@ebpco.gov.ph`, a Metro Manila landline and "City
   Hall Building, Quezon City" — Quezon City being the structural reference the
   requirements were modelled on. Its address survived into shipping copy. See
   `docs/M-16-office-contact-found.md`.

3. **This one is harder to catch than that one was.** "Cabuyao City Hall"
   reads as a real, specific, plausible answer. Nothing about it looks like a
   placeholder, so nobody deletes it.

## Suggested fix, for the lane that owns the contract

Either drop the three keys from the sample, matching R-13, or set them to
obviously-unreal values. If a sample value is wanted, `null` says what the
contract means.

## What the mobile side did instead

Nothing that depends on the contract changing. The digital permit screen now
falls back to what Castilla has actually published — the office and
municipality from its own checklist letterhead, and the checklist's step-3
fact that ancillary permits are claimed with the building permit — and names
the address and hours as unpublished rather than filling them.

If a backend does send these fields, it still wins; the fallback is only for
the gap. So the sample being corrected changes nothing on the client, and the
client is safe if it is not.
