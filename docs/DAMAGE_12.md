# DAMAGE 12/10: real bone breaking, a different shot per weapon, purple splash and drips (owner, 26 Nov 2026 late)
> "Gør så man faktisk kan knække knoglerne afhængig af hvor mange gange man skyder og hvad man slår/skyder med og hvor hårdt man slår. Det er vigtigt vi minimum er på samme niveau hvis ikke udkonkurrere ALLE konkurrenter på physics nu hvor vi ikke kan lave "gore" som folk godt kan lide at spille, så alt skal være 12/10 ... Sørg for skuddene er forskellige ud fra hvad våben der skyder - gør så der er splash hver gang man rammer en ragdoll med purple blod og hullet drypper lidt, maks 2-3 huller ad gangen kan drypper, de nyeste."

**Why this matters:** we cannot use gore, so the FEEL of hitting a body must beat every ragdoll game on Roblox:
- the push;
- the bones cracking and breaking;
- the purple splash;
- the reaction.

This doc makes the damage model concrete. It replaces the loose rules of `BODY_V2.md` 1b and adds to 2b and 3. Build it ONCE, here.

**First, check the real path in the code** (by reading, not by test runs): every hit (gun, melee, explosion, impact, machine, bite) must reach ONE function, `Bones.hit(model, part, hitPoint, info)`. Today breaks seem to need "injury stage 3", so in practice they rarely happen. Find every hit path that skips it and route it through.

## 1. The bone model
- **Every bone has its own INTEGRITY, 100 when fresh:**
  - the 15 limb bones;
  - the torso split into skull, spine, left ribs, right ribs, sternum and pelvis (F59's torso skeleton).
- **Each hit takes integrity off the bone it hits:**

  `damage = weapon base x force x bone factor`

  - **force:** guns: by range (point blank 1.3, normal 1.0, far 0.6); melee: by the charge (0.4 tap to 1.5 full) times the swing speed; impacts: by speed (18 studs/s = 0, 120+ = 1.5); explosions: by distance (the centre 1.5, the edge 0.2).
  - **bone factor (how easily it breaks):** hands, feet and ribs 1.3; lower arms and legs 1.1; upper arms, thighs and pelvis 0.9; skull 0.8; spine 0.7.
- **Damage ADDS UP:** shot after shot on the same bone, until a heal, a bandage or a full revive. The number of shots matters.
- **The stages, shown in X-ray and in the body:**

| Integrity | Stage | In X-ray | In the body |
|---|---|---|---|
| 100-70 | whole | clean bone | - |
| 70-40 | HAIRLINE | a thin crack line | a wince |
| 40-1 | CRACKED | a zig-zag crack, a little gap | the limb is weaker (tone 0.6); it holds the limb |
| 0 | BROKEN | snapped in 2 pieces, offset (BODY_V2 1b) | a broken leg limps or crawls; a broken arm dangles; broken ribs: it hunches and holds its chest; a cracked skull: dizzy stars, then knocked out |
| one hit that takes 140%+ of what was left | SHATTERED | 3-5 pieces, spread a little inside the glass shell | as BROKEN, plus a bigger crunch |

- **Feedback** (players learn it): each stage has its own sound, getting heavier:
  - a tick for a hairline crack, a crack for cracked, a loud CRUNCH for broken, a glassy CRUNCH plus a rattle for shattered;
  - a white flash on the bone in X-ray;
  - a small pop text only at "CRACK!" (broken) and "SHATTERED!";
  - the hit card (PC) names the bone and its stage ("Left Femur: CRACKED").
- **Never:** bone through skin, splinters flying, anything torn off. Breaks show in X-ray only; outside X-ray only the behaviour shows.

## 2. Every weapon hits differently
The numbers below are the starting values. The Toys list maps every weapon to the nearest class (by its kind and POWER stat). The bone base is the damage on the bone hit at force 1.

| Class | Bone base (shots to break a fresh lower leg) | Push and reaction | The hole | The splash |
|---|---|---|---|---|
| Light pistol | 18 (about 5) | rocks the body; a flinch of that spot | small, clean | small, 6 drops |
| Heavy pistol / revolver | 32 (about 3) | a hard jolt; the limb kicks back | medium | 10 drops |
| SMG / auto | 9 per bullet (about 10) | a stagger chain: each bullet a small push, so the body dances backwards | small, in a line | 4 drops each |
| Rifle | 38 (about 3) | the hit part snaps back hard; 2 in the chest knock it down | medium | 10 drops |
| Shotgun | 8 per pellet x 8 pellets: point blank 1-2 shots break, far away only bruises | knocks it DOWN and back; the pellets spread over 2-4 bones | a cluster of small holes | one big burst, 16 drops |
| Sniper | 95 (1 shot; point blank SHATTERS) | SPINS the body round the hit point; it drops | small, clean | a long streak burst behind |
| Bow / crossbow | 42 (about 3) | pins the limb back; the arrow stays in (X-ray shows the tip) | the arrow | 8 drops |
| Explosive / launcher | 120 at the centre, down to 0 at the edge, on EVERY bone in range | throws the body in an arc with spin (RAGDOLL_FEEL "weight") | burns (soot), not holes | a ring of drops |
| Fist / slap / poke | 4 tap, 14 full charge | a punch turns the head or body; a slap spins the head | none | 3 drops on a full charge only |
| Bat / club | 22 tap, 60 full charge | a home-run swing launches it | none (a bruise) | 6 drops |
| Hammer / heavy | 30 tap, 95 full charge (can shatter) | a downward smash flattens it to the ground | none (a dent bruise) | 8 drops |
| Sword / axe (cartoon, they act blunt: nothing is cut) | 26 tap, 70 full charge | a slash spins it | a long bruise line | 8 drops |
| Thrown (crate, rock, barrel) | by speed and mass | by speed and mass | none | by force |
| Impacts (falls, cars, cannon, walls, machines) | by speed: 120+ studs/s = 100 on the bone that hits first | already in the physics | none | by force |

- **Every hit is an impulse AT the hit point** (`ApplyImpulseAtPosition`, RAGDOLL_FEEL), so a shoulder shot turns the torso and a knee shot buckles the leg.
- **Each class has its own sound, muzzle flash, tracer and casing** (as they are; make sure no two classes share the same one).

## 3. The purple SPLASH on every hit, and the DRIPS
- **The splash:** EVERY hit that touches a ragdoll (bullet, pellet, arrow, melee with force, impact, bite) bursts purple cartoon droplets from the hit point in the direction of the hit; the size is from the table. A few drops land and leave small purple splats on the ground and on walls within 6 studs. The splats fade after 20 s.
- **The holes drip:**
  - only the 2-3 NEWEST holes on a ragdoll drip;
  - an older one stops when a newer one starts;
  - a drop falls every 0.6-1.2 s (a short thin purple trickle runs down from the hole first);
  - each hole drips for about 8 s, then stops;
  - the drops leave tiny dots on the ground that fade.
- **The pools:** a knocked-out body lying still gets a small purple puddle under its newest hole (BODY_V2 2), which grows a little and fades after 30 s.
- **Cost:**
  - everything pooled;
  - phones: splash drops x0.5, splats max 30 on screen, drips only within 40 studs;
  - PC: splats max 80.

## 4. 12/10 against every competitor
The bar is what Hyper Realistic Ragdoll, Bloody Ragdoll Physics, Ragdoll Engine and Fling Things and People do (RAGDOLL_FEEL "How the biggest ragdoll games do it"), plus what none of them have:
- real bones that crack, break and shatter by hits;
- a different shot per weapon;
- the splash and drips.

**Must all be true (built from the code, the owner tests):**
1. The hit lands where it hits (the impulse at the point), with no explosions or flings (the speed clamp and the watchdog).
2. **Weight is felt:** a pistol rocks, a shotgun knocks down, a sniper spins, an explosion throws in an arc, a hammer flattens.
3. Bones crack, break and shatter by the number of hits, the weapon and the force (sections 1-2).
4. A broken body moves broken: the limp, the dangle, the hunch, the crawl.
5. Bodies tumble, slide and roll after landing, settle without jitter, pile up without vibrating, and ride moving things (RAGDOLL_FEEL PERFECT physics).
6. Ownership is smooth, so the hit body reacts on YOUR screen at once.
7. Every hit has the splash, the sound by class, and the hit reaction of that spot.
8. It is the same on phones (pooled effects, the phone caps).

## 5. Order and no double work
This is the first row of the body phase (OVERVIEW PHASE 3, moved up by the owner's priority). It includes `BODY_V2.md` 1b (breaks), 2b (the splash) and the drips in 3. Row 4 (the X-ray look) and row 5 (the physics hard checks) build on it right after.
