# Lasso + smashable walls and crates (owner's screenshots, 26 Nov 2026)
The owner sent 2 pictures without text, from the old build of their own lab. Build what they show, in the same run, after the impact effects (`docs/IMPACT_FX.md`).

**Picture 1:**
- The player holds a yellow-brown **rope (a lasso)** tied to a ragdoll's arm and has yanked it through a grey **concrete wall**.
- The wall has broken into big angular chunks scattered on the grass and the walkway, with a ragged hole where the body went through.
- The ragdoll says "I said put me down!" (a talk bubble with an emoji).
- A small purple puddle and a grave (mound + headstone) are nearby.

**Picture 2:**
- Stacks of **wooden crates and plank fences** near the press ("DANGER" sign), with **bullet holes** in the wood.
- Some crates are half broken: missing planks, open frames.
- A grey post with holes.

## 1. LASSO (`Config.LASSO = true`): a tool in the weapon unlocks (early, about 6-10 KOs; the old HUD showed "Unlock: Lasso")
- **Throw:** tap or click a ragdoll within about 35 studs. The rope flies out and ties to the limb you aimed at (snaps to the nearest limb on phones).
- **The rope:** a RopeConstraint (yellow-brown, about 0.3 thick, a rope texture) from your hand to that limb. Max length 30.
- **Pull:** hold to reel in or run away. The ragdoll is dragged by that limb with full physics (the body follows, bumps along the ground).
- **Swing:** turn fast to swing it round you in an arc.
- **Let go:** release, and it flies with its momentum.
- **Smashing:** dragged or swung into walls, crates, cars or machines, it smashes into them with impact effects (`docs/IMPACT_FX.md`) and breaks breakables (section 2).
- **The ragdoll talks while lassoed** (one line, max every 4 s):
  - "I said put me down!"
  - "This is NOT in my contract."
  - "Weeeee— no."
  - "Okay this is kind of fun."
  - "My arm doesn't bend that way!"
- **Phone:**
  - tap a ragdoll to rope it;
  - a big REEL button (hold) and a LET GO button appear only while roped;
  - the move stick swings.
- **Server:** the rope target must be a ragdoll within range (Net validator + rate limit); one rope per player.

## 2. Smashable walls and wooden crates (`Config.BREAKABLES = true`)
**Concrete walls** (a few free-standing walls in the lab, like picture 1, plus the brick crash wall):
- A wall is pre-cut into about 12-20 angular chunks (hidden seams), all anchored.
- **What breaks it:**
  - a body or a car hitting it faster than about 45 studs/s;
  - a lassoed or SLAMmed ragdoll swung into it;
  - an explosion near it.
- **When it breaks,** only the chunks near the hit come loose:
  - they become physics pieces with grey dust (`docs/IMPACT_FX.md` concrete);
  - the hole matches where it was hit;
  - a hard hit (force > 0.85, the same force scale as bones in `docs/BODY_V2.md` 1b) breaks it wider.
- **Reset:** chunks stay 20 s, then fade, and the wall rebuilds (a quick rise-up animation).
- **The brick crash wall** works the same way: bricks fly out, with red brick dust.

### 2b. Brick by brick, with gravity, lag-free (owner, 26 Nov 2026: "Gør så man kan smadre muren en block ad gangen, altså en mursten ad gangen, gør det lagfri på alle enheder. Så hele væggen ikke falder ned på en gang, men følger gravity.")
This replaces the "chunks" idea for the BRICK crash wall. The concrete walls get the same system with bigger blocks.

**Hits remove bricks one at a time, at the point that was hit:**
- **A bullet:** cracks the brick it hits (a crack decal). A second bullet on it knocks it out.
- **Big guns** (sniper, shotgun pellets close up): knock it out at once.
- **Melee:** knocks out 1 brick, or 2-3 with a charged hit.
- **A body or car impact:** knocks out bricks round the impact point, the number by force (2-10). A SLAMmed or lassoed ragdoll through the wall makes a body-shaped hole.
- **An explosion:** a round hole by radius.

**Gravity, brick by brick:**
- A brick stays up only if it is SUPPORTED: a brick or the ground directly under it, or held by its mortar from both side neighbours (a short bridge, max 2 bricks wide over a gap).
- After each removal, check the bricks above the gap: unsupported ones come loose and fall, a few per frame. Bricks fall one after another in a natural cascade, never the whole wall at once.
- A wall with a big hole low down slowly sags and drops its upper bricks in a trickle.

**Loose bricks:**
- real physics: they tumble, bounce a little and clatter;
- brick dust puffs (pooled); a clatter sound per brick (pooled, max 8 a second);
- they can hit and knock ragdolls.

**Lag-free on every device:**
- **The wall is mostly anchored.** It is built from brick-sized MeshParts that all share ONE mesh and ONE material (so the engine instances them), CollisionFidelity Box, CastShadow off except on the outer row.
- **Hybrid wall:** far from any damage, rows of bricks are merged into wall panels (a few parts with a brick texture). Only the panel that is hit is swapped for its individual bricks, in place, invisibly. A fresh wall is therefore a few dozen parts, not hundreds.
- **Loose bricks sleep:**
  - a brick that has rested for 2 s is anchored again where it lies (no more physics cost);
  - network ownership of moving bricks goes to the nearest player, so they move smoothly.
- **Caps:**
  - max loose (moving) bricks at once: PC 80, tablet 50, phone 30;
  - over the cap, the oldest resting debris fades away first;
  - fallen bricks fade after 30 s.
- **The server decides** which bricks break and fall (gameplay); the changes go out in one batched update per tick.
- **Measure:** frame time on the phone emulator while 10 shots and a car crash hit the wall. There must be no hitch over 30 ms.

**Rebuild:** (changed by F48: 10-15 s after the last brick has fallen) the wall rebuilds brick by brick from the bottom up (each brick slides into place with a small "clack"). Holes heal over about 6 s.

**Check:** shoot single bricks out (one at a time, see the bricks above drop in a trickle), drive a car into it (a hole round the impact, the bricks above cascading), SLAM a ragdoll through it, then wait for the rebuild. Do it on PC and the phone emulator, with no lag.

### 2c. Concrete walls: block by block, the same system (owner, 26 Nov 2026: "Lig det også ind for betonvæggene og trækasserne")
- The free-standing concrete walls (and the speaker wall's concrete back) are made of **concrete blocks** (about 4 x 2 x 2 studs, cast-concrete grey with a slight tone variation, chipped edges).
- **The same rules as the brick wall (2b):**
  - hits remove one block at a time at the hit point; bullets crack first; heavy hits and impacts take several;
  - support and gravity: blocks above a gap trickle down, never the whole wall at once;
  - hybrid panels far from damage; resting blocks anchored after 2 s;
  - the same caps (PC 80, tablet 50, phone 30, shared with the bricks);
  - rebuilt block by block 10-15 s after the last block has fallen (F48).
- **Concrete feel:**
  - grey dust and small gravel chips;
  - a heavier, duller crunch than the bricks;
  - blocks take 2-3 bullets (tougher than bricks).
  - Exposed rebar stubs show in a big hole (cartoon, thin rods) for fun.

### 2d. Wooden crates: plank by plank, with gravity (replaces "breaks into planks at once")
- **Each crate is built from planks:** 4 side faces of 3 planks each, a top and a bottom, and corner posts. They share one wood mesh and material, instanced, and the crate is a single panel set until hit (the hybrid idea).
- **Hits knock out PLANKS one at a time:**
  - a bullet splits the plank it hits (a split decal, splinters); a second bullet knocks it out;
  - melee or a body knocks out 1-3 planks;
  - an explosion blows the crate apart.
- **Gravity:**
  - with enough side planks gone, the top sags and drops in;
  - when the lowest crate of a stack loses its strength, the crates above tip and fall as whole crates (real physics) and break further on landing by impact speed;
  - stacks topple naturally, never all at once.
- **The look:** wood splinters and wood dust (pooled), a wood crack and clatter sound; loose planks bounce and can knock ragdolls.
- **Lag-free:**
  - resting planks are anchored after 2 s;
  - they count toward the same caps as the bricks;
  - they fade after 30 s.
- **Rebuild:** after 45 s with no hits, the crates rebuild plank by plank (slide-in), and the stacks restack.
- **Check:** shoot planks out one by one, see the top sag, then knock the bottom crate so the stack topples. PC and phone emulator, no lag.

**Wooden crates and plank fences** (stacks near the machines, like picture 2):
- **Bullet holes:** guns leave small dark holes in the wood (decals). Max 10 per crate; they fade after 30 s.
- **Breaking:** enough damage (shots or melee, by force), or a body or car through it, breaks a crate or fence into planks and splinters, with wood dust.
- **Reset:** planks stay 20 s, fade, and the crate comes back.

**Limits:** a cap on loose pieces per lab (about 80; phones about 40); the oldest fade first. Pieces are client-simulated where safe; the wall's state is decided on the server.

## Check
- **One quick Play:**
  - lasso a ragdoll, drag it, swing it, and yank it through a concrete wall: a hole, chunks, dust; it rebuilds after 20 s;
  - shoot a crate: holes, then it breaks into planks.
- **Phone emulator:** the piece cap holds.
- **Test selv** (Danish) in the run's one list.
