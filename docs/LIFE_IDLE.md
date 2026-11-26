# Ragdolls behave like people when idle, and a cyclist rides round the lab (owner, 26 Nov 2026)
> "Sørg for de nogle gange bevæger deres fingre, strækker sig, ting som normale mennesker gør. Tilføj en der cykler rundt"

## 1. Human idle behaviour (`Config.IDLE_LIFE = true`)
Every living ragdoll that is standing, waiting or watching does a small human action now and then:
- **Timing:** each ragdoll every 8-20 s at random, never the same action twice in a row, and never two neighbours at the same moment.
- **The actions:**
  - wiggles or drums its fingers (uses the finger bones, `docs/BODY_V2.md` 4c);
  - cracks its knuckles;
  - stretches both arms over its head with a big yawn;
  - rolls its neck and shoulders;
  - shifts its weight from foot to foot;
  - scratches its head;
  - rubs its eyes;
  - looks at its wrist as if checking a watch;
  - looks at its fingernails;
  - crosses its arms;
  - puts its hands on its hips;
  - taps a foot;
  - kicks a pebble;
  - bends down to tie a shoe;
  - sneezes (a small head jerk plus a sound);
  - waves at the player;
  - turns its head to look at a sound, an explosion or a machine running.
- **Hurt ragdolls** (`docs/BODY_V2.md` 4b) use hurt versions instead: rubbing the sore limb, a limp shift, checking the bandage.
- **How it is built:** short layered animations on the upper body only (the legs keep standing), blended in and out (0.2 s), on the existing active-ragdoll pose system. A hit interrupts any idle at once.
- **Phones:** only ragdolls within about 40 studs do idles; far ones and stand-ins stay simple (`docs/PERF_MOBILE.md`).

## 2. A cyclist (`Config.CYCLIST = true`)
- **The existing BikeService** has a lab ragdoll riding the **Bike vehicle** (speed 44, the motorbike) round the lab. Keep that.
- **Add a separate pedal BICYCLE** (a realistic bicycle model from the Creator Store, malware pass) ridden by a lab ragdoll round the walkway loop of the big lab, at a calm 14-16 studs/s.
- **The rider:**
  - feet on the pedals, pedalling in time with the speed (the crank turns, the legs follow);
  - hands on the handlebars;
  - leaning into turns;
  - now and then it rings a bell, waves, or rides with no hands for a moment.
- **It stops for things:** it slows for and steers round the player and other ragdolls. It stops at the spawn plaza for a few seconds and rides on.
- **Knocked off:** any hit, a shot, a grab, the lasso, the dog or a car knocks the rider off with full ragdoll physics. The bicycle tips over and skids.
- **It gets back on:** when the rider gets up, it limps back to the bike, lifts it up and rides on (after about 10 s). If the rider is knocked out, another ragdoll comes for the bike after 30 s.
- **The player can ride it** when it is free: press E at the bicycle. The same calm speed, and pedalling uses the same animation.
- **Phones:** one bicycle per lab; simple collision.
- **Check:** one quick Play. Watch it ride the loop, knock the rider off, see it get back on, and ride it yourself.

## 3. Ragdolls walking the roads out there and chatting (owner, 26 Nov 2026: "der skal gå ragdolls rundt på vejene derude og snakke med hinanden")
- **The walkers:**
  - about 10-14 lab ragdolls walk the roads in 2s and 3s: the outer avenues, the cross roads, the boulevard, the road to the station, and the paths by the racetrack and the grandstands;
  - they walk at a calm pace, keep to the walkway (never on the grass edge or in the middle of a junction), and step aside for the player, cars and the cyclist.
- **They talk:**
  - every 20-40 s a group stops (at a bench, a junction, a lamp or a view) and chats for 6-12 s;
  - bubble lines in turn, with gestures (nodding, pointing at things nearby, laughing, shrugging);
  - lines fit where they are, using `Shared/TalkLines`, plus small talk:
    - "Nice day for it."
    - "Did you see the T-rex?"
    - "I'm going to the race later."
    - "My cousin went in the washer once."
    - "Is that the new tower?"
  - then they walk on;
  - sometimes one waves at the player or says "Hi!" as you pass.
- **Hits:** knock one over and the others react (shocked, help it up, or CPR when it is knocked out). They do not run away from weapons.
- **Phones and far away:**
  - walkers more than about 60 studs away are light stand-ins (animated, no physics, no talk); they become full ragdolls when you come close (`docs/ALWAYS3.md`);
  - talk bubbles only within about 40 studs;
  - this keeps the phone caps.
