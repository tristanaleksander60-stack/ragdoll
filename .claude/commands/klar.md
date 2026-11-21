---
description: Run the Ragdoll Havoc master plan (docs/MASTER_PROMPT.md) on the newest unfinished plan (docs/V9_PLAN.md, then V8), fully automatic, publishing by itself
argument-hint: "[optional: what the owner wants first]"
---
Read `docs/MASTER_PROMPT.md` and follow its section "The prompt" exactly, as the lead developer and art director on this PC with Studio and the Roblox Studio MCP. Start with "Every session starts like this": find the real state (git status and the place itself) before trusting any doc.

Then work on the **newest plan with unfinished steps**. **First `docs/V9_PLAN.md`** (it includes `docs/FIX_PATHS_SHOP.md` as V9-0). Follow its "How it runs" order exactly: the phases P, A, B, C, D, E.

**Run everything automatically, start to finish** (owner order, 21 Nov 2026):
- **Never stop to ask, never wait for the owner between steps.** After each step, write a short Danish report (Lavet / Test selv / Brug for fra dig) and go straight on to the next.
- **When something only the owner can do blocks a step** (ids, a dashboard setting, saving the place): park it in State with one Danish line and continue with the next step.
- **Publish by yourself through `docs/RELEASE.md`:**
  - at every milestone in V9's order (after Phase A, after Phase C, and at the end after V9-6);
  - each time: gate, backup, publish, check. **Never restart or shut down old servers** (owner order, 21 Nov).
  - If a gate fails, do not publish; fix it, or carry it to the next milestone.
- **When V9 is done and published,** continue with `docs/V8_PLAN.md` (evidence in `docs/V8_EVIDENCE.md`). Follow its "Order" and "Rules for every step". Run its phases one after another; when a phase's gate needs live numbers or a playtest round that is not there yet, say so in one Danish line, mark it in State, and go on with the next work that does not need it.
- **Publish V8 phases through `docs/RELEASE.md` too,** at the end of each phase.

Keep `CLAUDE.md` and each plan's State current after every step, commit and push `release`, so a new session continues exactly where this one stopped. Use as few credits as possible without lowering quality. Talk to the owner in Danish, short and plain.

The owner's wish for this session (do it first, if any): $ARGUMENTS
