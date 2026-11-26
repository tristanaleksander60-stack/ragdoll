# Every EVENT fitted to the new big map, so nobody feels scammed (owner, 26 Nov 2026)
> "Sørg for ALLE events er tilpasset til det nye map så ingen føler sig scammet."

**Why this matters:** events are sold for Robux (`Shared/Events.luau`, developer products). They were tuned for the old small lab: centred on the lab origin, sized for about 200 studs, using the old ragdoll spots. In the new 950 x 820 map an event can:
- happen far away from the buyer;
- cover a tiny part of the map;
- hit almost no ragdolls;
- be hidden behind tree belts or the Machine Hall roof.

A player who paid and sees little feels scammed. That means dislikes and refunds.

**The events** (21 in `Events.luau`): DummyRain, MegaBomb, ZeroG, BouncyFloor, FlashFreeze, GorillaRampage, BullRun, Tornado, MeteorShower, TrainRun, UfoBeam (hidden), BowlingAvalanche, RocketRain, MagnetStorm, LightningStorm, Sinkhole, Earthquake, FanBlast, MoonGravity, BalloonDrop, GiantDummy.

## Rules for EVERY event (`EVENTS_V2 = true`)
1. **Where:** it happens AROUND THE PLAYER WHO STARTED IT (the buyer, or the presser of the red button), in view within 1 s.
   - **If the player stands somewhere cramped or covered** (inside the Machine Hall under its roof, in a narrow path between belts, in a car, on the tower top): the event centres on the nearest OPEN area within about 80 studs (the room's courtyard, a plaza, the Tower Square, a lawn).
   - **The player is told:** a short arrow and "EVENT → HERE" on the goal line, and the camera eases toward it for 1 s.
2. **Size:** about 120-200 studs across (event by event), so it fills the screen, not the whole map. Anything that falls or flies starts where the player can see it (in the camera's view cone), never behind the player or far off.
3. **Enough ragdolls:**
   - before the peak, about 10-20 extra ragdolls run in from the sides into the event area (standing spawns, out of view, `ALWAYS3.md` rules) and look up worriedly ("What's that?!");
   - they are part of the show;
   - they leave or fade 20 s after it ends;
   - phones: fewer (within the caps), using stand-ins far away.
4. **A guaranteed payoff:**
   - every paid event must fling, knock or affect at least 12 ragdolls on PC (8 on phones) and give the buyer the KOs (event KOs credited, as V9);
   - the end banner shows the stats ("23 ragdolls flung! +23 KOs").
   - If an event would fall short (too few ragdolls in reach), it brings in more until it reaches the minimum.
5. **Nothing hidden:** no effect behind tree belts, roofs or walls from the buyer's view. The tree belts and the hall roof do not block the event's falling things inside its area (meteors fly over or through them visually; the hits happen in the open area).
6. **Map-aware paths for moving events:**
   - Tornado, BullRun, GorillaRampage, BowlingAvalanche and TrainRun follow paths through the OPEN area round the player: roads, plazas, lawns;
   - they never cross the spawn plaza's leaderboards or the buyer's own spot head-on;
   - TrainRun uses the real railway when the player is near it; otherwise a "ghost train" crosses the nearest road with its horn and barriers (a clear visual).
7. **The map stays intact:** events push and knock things, and they may break the breakable walls and crates (`DESTRUCTION.md`), but they never wreck the map permanently. Sinkhole and Earthquake restore the ground when they end.
8. **What it says = what happens:**
   - for each event, compare its shop name, blurb, icon and price with what really happens on the new map, and fix either side so they MATCH (e.g. "A dozen dummies drop from the sky": at least 12 must drop in view);
   - UfoBeam stays hidden (owner);
   - no event may be sold that cannot run well.
9. **Never lose a purchase:**
   - **Grant in ProcessReceipt only when the event really starts.** If another event is running, QUEUE it ("Your Tornado is next: 0:12"), never drop it.
   - **If it fails to start** (an error, the player leaves), keep it as a saved "event token" the player can start later from the EVENTS menu. Never return PurchaseGranted for an event that did not happen.
10. **Multiplayer:**
    - it happens round the buyer, and the other players nearby see it too;
    - the KOs go to the buyer;
    - the banner shows "<name>'s TORNADO".
11. **Phones and lag:**
    - all effects are pooled;
    - the ragdoll count stays within the caps;
    - the auto quality governor (`PERF_MOBILE.md`) may lower the particles, but never the number of ragdolls affected below the minimum in rule 4.

## Per event (check each, write the result in State)
For each of the 21:
1. start it from 3 places: the spawn plaza, inside a room (Animal Cove), and a cramped spot (the Machine Hall);
2. check rules 1-11;
3. capture one screenshot at its peak;
4. score "worth the Robux" 0-10 (harsh). Fix anything under 9; cut (hide) any event that cannot reach 9.

## State
- (none yet)
