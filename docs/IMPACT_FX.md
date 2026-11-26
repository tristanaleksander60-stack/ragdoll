# Smoke, dust and real impacts + grab and smash (owner, 26 Nov 2026)
> "Lav røg effekt når de rammer jorden eller noget som gør det realistisk når de rammer ting så man kan grab dem og smadre dem ind i ting"

**What exists:**
- impact particles by surface in `Shared/FeelTuning` (soft = earth dust, etc.);
- impacts counted in `Shared/Ragdoll/ActiveRagdoll` (`IMPACT_MIN_SPEED` 18, `IMPACT_GAP` 0.4);
- grab and throw (`PlayerGrab`).

Today it is too small to notice. Build it big, clear and phone-cheap, behind `Config.IMPACT_FX_V2 = true`.

## 1. Impact effects (every ragdoll body part hitting the ground or a thing)
**Scale by speed:**
- **18-35 studs/s:** a small puff.
- **35-70:** a dust cloud plus debris.
- **70+:** a big burst plus a shock ring plus a hit-stop.

**By surface:**
- **Grass/earth:** a brown-grey dust cloud that rolls out low and slow (2-3 s fade), grass and dirt bits flying.
- **Concrete/stone:** a light grey dust cloud plus small stone chips bouncing, and a dark scuff decal on the floor that fades over 6 s.
- **Wood:** splinters plus light dust.
- **Metal** (tower, machines, cars): sparks plus a clang, a short metal ring sound.
- **Brick wall:** red-brown brick dust plus chips.
- **Water:** a splash and ripples (no dust).
- **Sand:** a big sand spray.

**On every big impact (70+):**
- a ground shock ring (a flat expanding ring of dust);
- a camera shake for nearby players, small and only for your own throw or shot;
- a 40 ms hit-stop (only for the player who caused it);
- a heavy layered thud sound (pitch by speed).

**Smoke trail:** a thin smoke trail behind a ragdoll flying faster than about 60 studs/s (launched, thrown, cannon), ending in the impact burst.

**Props react:**
- barrels, crates and cones get knocked and roll (Knockables);
- a fast body through a wooden crate breaks it into planks (reset after 20 s);
- cars rock on their springs and get a dent sound.

**The blood rule stays:** `BLOOD = "purple"`, only a small purple splat on very hard hits, never red, never gore beyond the owner's maturity choice.

## 2. Grab and smash
**Hold and swing**
- Hold GRAB on a ragdoll (phone: tap and hold; PC: click and hold; console: the trigger).
- The body hangs from your hand and swings with real momentum when you turn or move. Physics-driven, network owner = you, so it feels instant.

**SLAM**
- While holding, press SLAM: phone has a big SLAM button that only shows while holding; PC uses the right click or F; console uses a button.
- You swing the body down hard into the ground in front of you: a big impact with full effects.
- Swinging it into a wall, a car or a machine while walking also counts as a smash.

**THROW** (as now), but the throw speed feeds the impact effects.

**SMASH COMBO**
- Smashes within 2 s count up: "SMASH x2, x3…" with a pop and a rising sound.
- Each smash counts toward KOs when the body goes down (as hits do now).

**Damage**
- Impact speed hurts the ragdoll as now (ActiveRagdoll), so a few hard smashes knock it out.

## 3. Performance (phones are most players)
- **Effects are client-side:**
  - pooled emitters (no new instances per hit);
  - at most 6 dust bursts per second per client;
  - only within 90 studs.
- **Phones:** half the particles, no scuff decals beyond 4 at once, no smoke trails on low tier.
- **Decals and debris are removed after their fade;** a hard cap per lab.

## 4. Check
- One quick Play: throw, smash into grass, concrete, the brick wall, a car and water. Each must look and sound different and clearly "real".
- Check the effect count stays under the cap on the phone emulator.
- **Test selv (Danish), in the run's one list:**
  - grab a dummy, swing it and SLAM it into the ground and into the brick wall;
  - throw one from the tower onto concrete;
  - on phone and PC.
