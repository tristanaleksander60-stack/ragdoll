# V10 plan: Hyper Ragdoll Physics 🩸 (22 Nov 2026)

The owner's list, put in order of what matters most while live ads run: first what makes new players
(mostly on phones) leave in the first seconds, then bugs everyone sees, then fun, then big new features.
Rule for every step: as few credits as possible. The owner tests in Studio; Claude does not play-test,
compile-checks every changed script in Studio before saying "ready", and never puts a comment inside an
expression (twice that emptied the lab).

**State:** phases 1-3 and phase 4 items 21-23, 25 built (0.38.5, not play-tested); item 24 (more realistic events) not started; phase 1 (0.38.0); data read 22 Nov: phones 2/3 of new players, fps p5 ~11, all held upright.

## Phase 1: why new players leave (do first)
1. **Read the data.** `tools/SessionReport.luau` over Session_v1 (device, seconds played, funnel step, first
   shot, takedowns). Find what phone players see in their first 10 s before they leave. Report in 5 lines.
2. **Next 3 weapons from the first second.** NEXT_UNLOCKS_MIN_TAKEDOWNS 25 / NEXT_UNLOCKS_AFTER 180 → 0, and the
   phone layout shows them too (today phones get none). The owner's own data: players leave thinking there is
   nothing more.
3. **No half-loaded map or ragdolls.** A short loading cover until the player's lab is built and its ragdolls are
   dressed (DummySkins done); preload the lab's models and the start bar's sounds behind it.
4. **Phone crosshair** only where the shot goes (no fixed one in the middle); **no Replay button on phones.**
5. **Funnel for every new player from now:** SessionStats steps join → loaded → first shot → first takedown →
   first machine → first weapon unlock → 3 / 5 / 10 min, with device; a one-table read script.

## Phase 2: quick fixes everyone sees
6. Name "Hyper Ragdoll Physics 🩸" in Config.GameName and every player text.
7. All three cars free for now (PASSES back to 0; the ids stay in a comment).
8. Gift button wiggles every 20-30 s until opened.
9. Keys: Shop, More, Lab (picked so they clash with nothing; shown on the squares).
10. Matte ragdolls: no shine in the sun (skin material/specular off), wounds easier to read.
11. Bullet holes and blood that still stand out as bubbles: flatter, smaller, sunk further in.
12. Remove every pictogram (sign icons, FEED ME labels, ring icons, help-line icons).
13. Talk wand held the right way round.
14. The shark is solid (you cannot walk through it).
15. Takedowns from the compressor, the shark and every creature kill.

## Phase 3: feel and fights
16. First person: melee swings show (the weapon swings into the body, not a hammer pointing ahead).
17. First person: picking a weapon in WEAPONS puts it in your hand at once.
18. Animals fight back: hit or shoot one and it comes for you, eats you, **WASTED** on screen (our own look,
    not GTA's), you respawn in your lab. Every creature at least as violent as the shark.
19. Compress yourself: stand on the press, you go flat too, then pop back.
20. Cars can be destroyed: shots or a bomb add damage, at the limit the car explodes and comes back on its pad.

## Phase 4: places and events
21. A MAPS board at the plaza (a way out of it again).
22. The MAPS board next to the red event button in the lab.
23. The red button starts the event in every lab on the server, not only yours.
24. Every event more realistic (one by one, the most used first).
25. Wooden info post: "50 likes = Area 51". **Check first:** Roblox forbids rewarding likes. A shared update goal
    with no reward for the one who likes is the safe form; the post must not promise anything per player.

## Phase 5: big new things (most credits; after the data says the start works)
26. Spider-Man hands: a weapon with 8 mechanical arms that grab ragdolls and pull them apart.
27. Spectate lag: check whether it is the spectate camera (replication focus far away, so bodies update
    slowly on the spectator's screen) or real lag; fix the camera side first.

## What the owner tests after each phase
Phase 1: a phone (Device Simulator) join: loading cover, next-3 cards, crosshair, no Replay; read the report.
Phase 2: each item by sight in one Play.
Phase 3: first person melee and weapon pick; hit each animal; stand in the press; blow up a car.
Phase 4: plaza board, button with two players in Studio (Test → 2 players), each event once.
