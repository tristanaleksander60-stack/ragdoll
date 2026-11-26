---
description: Build the WHOLE plan in docs/OVERVIEW.md without stopping; the owner tests only at the end
argument-hint: "[optional: what the owner wants first]"
---
Read `CLAUDE.md`, then `docs/OVERVIEW.md` (the one-page map of the whole plan: ORDER, docs, done, left). Then read the doc of the item you are working on (and `docs/NOW.md` only for details). If the owner wrote something after /klar, do that first.

## THE OWNER'S ORDER (26 Nov 2026): "Gør så den laver alt nu uden at stoppe så jeg bare skal teste alt til sidst"
**Build EVERYTHING in OVERVIEW's ORDER, top to bottom, in ONE run. Do not end your turn early.**
- **Never end the turn after one item, one phase or a short while.** When an item is done:
  1. one quick Play;
  2. commit and push;
  3. update OVERVIEW (State and LEFT);
  4. go straight on to the next item.
- **The only reasons to stop:**
  - (a) every item in the ORDER is done or parked;
  - (b) Studio or the MCP is gone and cannot be reached after 3 tries.
- A long run is expected and wanted. When the context fills up, it is summarised automatically; keep going from OVERVIEW.
- **Never ask the owner anything mid-run.** For every open question, pick the default below (or the safe default behind a Config switch), write it in NOW.md's "Questions for the owner", and go on.
- **Never stop for a blocked item.** Park it in OVERVIEW with the reason and go on.
- **Do not ask the owner to test anything until the very end.**

## Standing answers (use them; do not ask again)
- **Script Sync not landing:** do not wait for it and do not ask about it. Put every changed script into Studio through the MCP and check it by length or checksum, as before. Note it once in the final message.
- **The dog is one stiff mesh:**
  - look in the Creator Store yourself for a RIGGED German Shepherd (bones or Motor6D joints: legs, neck, tail, jaw) with a clean license; malware pass; keep only the model;
  - if none is good, use the best rigged realistic dog, recolour it tan and black, and animate its joints in code;
  - never wait for the owner to send one.
- **REVIVE ALL on X:** yes, keep X.
- **X-RAY on I:** yes.
- **Missing models** (wheelchair, trees, mountains, animals): get them from the Creator Store yourself (malware pass, one matching style).
- **Publishing:**
  - the owner said publish only when the map meets its DEFINITION OF DONE;
  - until then, save the place after every item;
  - at the end, tell the owner exactly how to publish BOTH places (start + multiplayer; see OVERVIEW's two-places warning).

## Every item
- Phone and iPad first; simple enough for a 10-year-old.
- Gore off (purple cartoon; X-ray bones may break).
- A Config switch for it.
- No test suites or reviewers; one quick Play.
- Do not read `docs/V9_PLAN.md` or `docs/V8_PLAN.md` whole; grep them.

## The ONE final message (Danish, short, only when you really stop)
1. **Step 0 reminder** (only if it is not done): "Husk punkt 0: tryk Alt+P i Studio for at udgive gore-off, og send aldersspørgeskemaet med svarene i docs/MATURITY.md."
2. **What was built,** item by item, one line each, and what is parked and why.
3. **How to publish both places**, if the map is done.
4. **ONE combined "Test selv" list:** phone first, then PC, max about 20 lines.
5. **The "Questions for the owner" list:** each with the default you chose.

**Keep `docs/OVERVIEW.md` true:** update an item's State and LEFT whenever you finish or start it.

The owner's wish for this session: $ARGUMENTS
