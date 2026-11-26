# The first 2 minutes: TRY at the machine, a ragdoll comes, grab it, put it in (owner, 26 Nov 2026)
> "Man skal bare kunne trykke TRY når man er derhenne og så kommer der en ragdoll første gang, og så skal man grab den og putte den i maskinen, og så skal man prøve næste maskine og så ved man godt selv hvordan man grabber den, ved ikke om noget allerede er til sidst i planen med de første 2 minutter"

**What the game already has for the first minutes** (built in 0.53-0.57):
- FirstVisit steps "GRAB a dummy and THROW it!" and "Walk to the MAPS board";
- minute moments at 2/3/4 min in the goal pill (`MINUTE_MOMENTS`);
- the angry dummy on the 2nd hit (`ANGRY_FIRST`);
- the newcomer target arrow (`TARGET_ARROW`);
- the goal line;
- the floating TRY! ring and sign (`TRY_ME`, buggy);
- the "tried 2/6" reward (150 BOLTS).

They run separately and overlap. **This doc merges them into ONE calm sequence**, behind `Config.FIRST_TWO = true`, and replaces the floating TRY! sign.

## The new TRY (every machine)
- **No floating sign or ring any more** (`TRY_ME` sign off). That also ends the jumping/flipping bug.
- **When you walk up to a machine you have not tried** (within about 12 studs):
  - a big round **TRY button** appears on screen: phone, right side above SHOOT, at least 70 px, orange, with the word TRY; PC, the E prompt "TRY"; console, a button;
  - the machine gets a soft orange outline (Highlight) while you are near.
- **Press TRY:** a ragdoll comes running to you (very fast, `docs/ALWAYS3.md`) and stops right next to you, in front of the machine. With `ALWAYS3`, one of your 3 near ragdolls is used, so no extra spawn is needed.

**First machine only (the lesson):**
1. A pointing hand on the ragdoll plus one short line: "Hold to GRAB" (phone: "Hold"; PC: "Hold click").
2. Once you hold it, the machine's load spot glows (the cannon's mouth, the gyro cage's middle, the press bed, the washer door, the fan's front, the rocket seat, the slide top…), with a pointing hand and "Put it in!".
3. You carry it there and let go inside the glow: it snaps into the machine and the machine runs at once. The full show, with the effects.
4. Then a big pop: "+25 BOLTS · 1/6".

**Every next machine:** press TRY, and a ragdoll comes. No hand, no text: you know how to grab it now. The pop shows the count "2/6".

- **Machines without a load spot** (the trampoline, the slide, the tower plank, the lava, the crash wall): TRY makes the ragdoll walk to the start itself (the slide top, the plank end), and you give it the push or the throw.
- **Being tried:** a machine counts as tried when a ragdoll you put or pushed in makes it run.

## The first 2 minutes as one sequence (new players)

| Time | What happens | Goal line |
|---|---|---|
| 0-15 s | You spawn; the 3 near ragdolls are right there, and you hit them with your weapon (the target arrow stays for the first KO) | "Hit a dummy!" |
| about 15-20 s (after the first 1-2 KOs) | — | "Try the CANNON" (the first machine is always the one nearest the spawn with the biggest show, chosen once in `LabLayout10`); a faint walkway arrow line (a Beam along the path, not a floating sign) leads there |
| at the first machine | TRY + the lesson above | — |
| after it | the faint line leads to the next nearest untried machine | "Next: GYRO CAGE" |
| about 1 min | the angry dummy may happen (only when no TRY sequence is running) | — |
| about 2 min | the red button lights up for the free mini event (only when no TRY sequence is running) | "Press me!" |
| at 6 machines | the 150 BOLTS reward (exists) | — |
| later | the 3 and 4 min moments as now (a creature, the MAPS board) | — |

**Never two at once:** one goal line and one hint at a time. Moments wait while a TRY sequence runs. No pop-ups.

**Remove the separate FirstVisit "GRAB a dummy and THROW it!" step.** The grab lesson now happens at the first machine. Keep "Walk to the MAPS board" as the 4 min moment.

## Funnel steps
"TRY pressed", "Ragdoll grabbed", "Put in machine", "Machines 1/2/3/6", by device, so we see where new players stop.

## Check
- **A fresh player (newcomer state) on the phone emulator and on PC:**
  - spawn; hit the dummies; the cannon is pointed out;
  - press TRY; a ragdoll comes; the hold hint shows; grab it; the load glow shows; put it in; the machine runs; the pop shows 1/6;
  - the next machine is pointed out; TRY brings a ragdoll with no hints.
- No moment fires during a TRY sequence.
- **Test selv** (Danish) in the run's one list.
