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
