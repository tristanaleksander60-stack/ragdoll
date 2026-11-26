# Guard dog: whistle, treats, creative cartoon take-downs (owner, 26 Nov 2026)
> "Tilføj en guard dog, tryk e for whistle, så kommer den frem og følger efter dig og så får man 3 godbidder man kan kaste på en ragdoll og så ser man ragdollen samle den op og så er der forskellige måder hunden dræber, når ragdollen har taget godbidden, vær kreativ. Sørg for det simpelt nok til ipad børn på 10 forstår det og alt er optimeret til mobil igennem hele planen."

The owner's picture: a wooden doghouse with a dark slate roof and a food bowl beside it, on the grass. The prompt reads "Guard Dog: Whistle" (E). There is no guard-dog code in git, so the doghouse is a place-file model. Keep it, and wire it behind `Config.GUARD_DOG = true`. Cartoon only (gore is off, `docs/BODY_V2.md`).

## The flow (a 10-year-old on an iPad gets it in 5 seconds)
1. **Whistle.**
   - At the doghouse, a big prompt with a whistle icon: "Whistle" (E / tap / console button).
   - A whistle sound; the dog runs out wagging, barks once, and follows you (a few studs behind, off to the side, never in your way).
2. **3 treats.**
   - A big round **TREAT button** appears on the HUD (phone: right side above SHOOT; PC: key T or click; console: a button).
   - It shows a bone-biscuit icon and a big number "3". No text needed.
3. **Throw.**
   - **Tap the TREAT button:** the treat flies to the nearest ragdoll in front of you. A soft yellow ring shows on that ragdoll before you tap.
   - Or **tap a ragdoll** while the treat button is selected.
   - The treat arcs through the air and lands at the ragdoll's feet.
4. **The ragdoll picks it up.**
   - It bends down, picks it up, looks at it with a happy face, and says one line:
     - "Ooh, a snack!"
     - "For me?"
     - "Is this… gluten free?"
     - "Finders keepers!"
   - Then it nibbles.
5. **The dog goes.** The dog's ears go up, it barks, and it sprints at the ragdoll holding the treat. A random take-down from the list below plays.
6. **Back to you.**
   - The dog trots back wagging and sits by you.
   - A "GOOD BOY!" pop and a heart.
   - The KO counts for you, as with weapons.
7. **Treats back:** +1 treat every 30 s (max 3), or all 3 at once by tapping the doghouse bowl.
8. **Send it home:** whistle again at the doghouse, or it goes home by itself after 3 minutes without a treat.

## Take-downs (cartoon, no gore; pick at random; each 2-4 s)
1. **TACKLE:** a full-speed leap. The ragdoll flies backwards with a dust burst and rolls.
2. **CHEW TOY:** the dog grabs the ragdoll by the foot and shakes it side to side like a toy, then tosses it over its shoulder.
3. **TUG OF WAR:** it grabs the sleeve and pulls the ragdoll round in big circles, faster and faster, then lets go and flings it.
4. **ZOOMIES:** it runs rings round the ragdoll until the ragdoll gets dizzy (spiral eyes) and topples over. The dog stops, proud.
5. **SKY POUNCE:** a giant cartoon jump from far away. It lands on the ragdoll's chest; the ragdoll goes flat, and the dog sits on it wagging.
6. **BUTT BOOP:** the dog wiggles its rear end, then headbutts. The ragdoll launches high into the air (nice near the trampoline or the lava edge).
7. **FETCH:** a tackle, then the dog drags the knocked-out ragdoll back and drops it at your feet, tail wagging.
8. **BIG BARK** (rare, 1 in 10): one huge cartoon bark with a shock ring. The ragdoll is blown off its feet together with every ragdoll within 8 studs.

Each take-down has a dust puff, a sound and a bark. The camera does a small shake only for you.

## Simple and mobile-first
- **One button** (TREAT), **one icon**, **one number**.
- **The dog finds the target itself:** no aiming needed.
- **Big touch targets:** the prompt at the doghouse and the TREAT button are at least 60 px.
- **First time only:** a tiny hint "Tap to throw a treat!" with a pointing hand, once, then never again.
- **Performance:**
  - the dog is one animated model (a Creator Store dog, malware pass), not physics-heavy;
  - pathfinding only every 0.5 s;
  - phones: the same.
- **Server:**
  - the server decides who has the dog, the treat count and the take-down;
  - the treat-throw remote goes through Net with a rate limit (max 1 per 0.8 s, max 3 held);
  - the target must be a ragdoll within 40 studs.
- **Funnel steps:** "Dog whistled", "Treat thrown", "Dog KO".

## Check
- One quick Play on the phone emulator and on PC: whistle, the dog follows, throw 3 treats; each ragdoll picks one up and the dog takes it down. See at least 4 different take-downs.
- **Test selv** (Danish) in the run's one list.
