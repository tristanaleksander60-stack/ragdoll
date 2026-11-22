# V11 plan (22 Nov 2026)

Owner's list, in the order it pays while the ads run: first what interrupts or confuses a new player, then
what makes the start more fun, then the big single/multiplayer change. As few credits as possible; the owner
tests everything; Claude compile-checks every changed script in Studio before saying "ready" and never puts a
comment inside an expression.

**State:** plan sent to the owner, waiting for a yes.

## Phase A: quiet screen (small, do first)
1. **No egg pop-up.** The EggReady window never opens by itself (ProgressUI offer, AutoEgg). Instead a red "!"
   badge sits on the gift; a tap on the gift opens Rewards where the egg is claimed.
2. **No pop-ups, only counters.** Every self-opening window and notice (Notify kinds tip / info / reward,
   What's New, Like, launch gift, tomorrow, mission cards) goes quiet; the icon it belongs to gets a red round
   counter (1), (2) ... that clears when opened. Only events still show their banner.
3. **No takedown message** when a ragdoll dies ("+1 TAKEDOWN" pop, the knocked-out banner line).
4. **Press the picked slot again** (e.g. "1" while 1 is picked): nothing in the hand, and out of first person.
5. **Rocket ride:** only the rocket itself flies; its launch stand and base stay (split the model's parts by
   height and size; the stand is anchored and left home).

## Phase B: the start more fun (medium)
6. **Portal gun, much better** (inspired by the green swirl portal look, our own art): two swirling green
   portals with a glowing rim, spark particles and a whoosh, a proper gun model, and it unlocks early (rung ~3-5).
7. **Robux purchases in chat, every server:** "Name bought X for R$N" as a system line in chat on all servers
   (MessagingService topic, TextChatService system message, rate-limited; names only, nothing else).

## Phase C: singleplayer by default, multiplayer by portal (big)
8. **A start menu before you load in:** a light 3D scene (one camera, a few animated ragdolls, no heavy
   models) with SINGLEPLAYER and MULTIPLAYER; it hides the world loading behind it and costs nothing on phones.
9. **Singleplayer** = what the game is now: your own lab, nobody else's visible.
10. **Multiplayer** = a portal (and the menu button) that teleports you to a multiplayer server where all
    players share ONE lab (the first player's lab, everyone a guest with the same rights); a portal there
    takes you back to singleplayer. Built on PortalService's reserved servers and the party rules
    (PartyService) that already let guests use a lab.

## Phase D: realism (biggest; one machine / creature / event at a time, the most used first)
11. **Events more realistic** (gorilla, bulls, meteor, tornado, train, UFO, bowling, rocket rain ...): real
    models where we have them, sounds, debris, ragdolls thrown by real forces, a short warning before.
12. **Machines and creatures much more realistic, in look and kills** (the plan for them):
    - **Spider:** a real spider model with legs that move, it walks down the web, bites, wraps (done), drags
      the cocoon up into the web and leaves it hanging; the web shakes.
    - **Shark:** a real shark model that circles in the tank, a fin above the water, splash and foam on the
      grab, the water turns red (done), pieces and bones float up (done).
    - **Giant plant:** a jaw that snaps shut over the ragdoll, chewing, juice drips, it spits the bones.
    - **Frog:** a long sticky tongue (done), swallow bulge going down its throat, a burp of bones.
    - **Chicken:** pecks the ragdoll, lays an egg that hatches a small ragdoll.
    - **Washer:** door opens, the ragdoll spins visibly behind the glass, water turns red, it comes out limp.
    - **Mole:** pulls the ragdoll under the ground (hole, dirt flying), spits it up somewhere else.
    - **Slingshot tree:** the branches bend back with the ragdoll in the band, a creak, release, a long flight.
    - **Compressor, cannon, wrecking ball, rocket:** hydraulic hiss and steam, cannon smoke and recoil, a
      chain that swings with real weight, rocket exhaust and a real launch tower.
    Each: one owner test before the next.

## What the owner tests after each phase
- A: no pop-ups at all in 5 minutes except events; counters on icons; the gift "!"; slot key twice; rocket.
- B: the portal gun early and pretty; a Robux buy shows in chat on another server.
- C: the menu on a phone and a PC; singleplayer; multiplayer with 2 players; back to singleplayer.
- D: each machine/creature/event as it is done.
