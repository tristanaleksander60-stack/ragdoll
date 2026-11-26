# Guard dog: whistle, then tap the exact limb it bites (owner, 26 Nov 2026)
> First: "Tilføj en guard dog, tryk e for whistle … alt er optimeret til mobil igennem hele planen."
> Changed: "Eller nej ændre det til du whistler med e, og så følger den efter dig og så kan du trykke hen på hvor den skal bide en ragdoll, så bider den præcis det lem og ragdollen reagerer og man kan se med xray hvad hunden gør og den skade bliver der."

The owner's picture shows a wooden doghouse with a dark slate roof and a food bowl beside it, on the grass. The prompt reads "Guard Dog / Whistle" (E).

There is no guard-dog code in git, so the doghouse is a place-file model. Keep it and wire it behind `Config.GUARD_DOG = true`.

- Cartoon only: gore is off (`docs/BODY_V2.md`).
- No treats.

## The flow (a 10-year-old on an iPad gets it in 5 seconds)
1. **Whistle.**
   - At the doghouse: "Whistle" (E, tap, or the console button).
   - The dog runs out wagging, barks once and follows you. It stays a few studs behind, off to the side, never in your way.
   - While it follows, a round **dog-head icon** shows on the HUD. Tapping it sends the dog home.
2. **Pick the limb.** While the dog follows, **tap a ragdoll right on the limb you want bitten** (PC: click; console: crosshair on it + button).
   - That limb lights up with a yellow outline and a small paw icon, so you see exactly which one.
   - **Bitable:** each arm, each hand, each leg, each foot, and the bottom (torso back).
   - **Never the head or neck:** a tap there picks the nearest arm.
   - **Phones and iPads:** limb touch areas are 1.5x bigger, and the tap snaps to the nearest limb within a finger's width.
3. **The bite.**
   - The dog sprints to the ragdoll and bites **exactly that limb**: its jaw locks onto that part at the bite point (a weld or a strong spring).
   - It tugs and shakes its head for 2-3 s, then lets go and trots back wagging.
   - A "GOOD BOY!" pop appears.
4. **The ragdoll reacts, by limb:**
   - **Arm or hand:** it yelps (pain face), waves the arm to shake the dog off, then holds it.
   - **Leg or foot:** it hops on the other leg, kicks, falls if the dog pulls hard, then limps.
   - **Bottom:** it jumps up high holding its bottom (cartoon), then runs a few steps.
   - The dog's tug really pulls that limb (active-ragdoll physics), and the body follows.
5. **The damage stays.**
   - Each bite raises that limb's injury stage by 1 (`docs/BODY_V2.md` 4b).
   - Two arcs of cartoon tooth marks (small purple dents) stay on the limb where the jaw was, until it heals or gets a bandage.
   - Enough bites in total knock the ragdoll out, and that counts as a KO for you.
6. **X-ray shows it** (`XRAY_V2`):
   - while it bites, the dog's jaws and teeth are seen clamped round that limb's bone;
   - afterwards the bone keeps cartoon tooth marks;
   - at stage 3, a thin cartoon zig-zag crack line shows on the bone.

   Never a broken or missing bone, and nothing poking out. The marks stay until the limb heals or gets a bandage.
7. **Rhythm:**
   - one bite at a time; the next tap queues;
   - 1.5 s between bites;
   - the dog goes home by itself after 3 minutes with no bite.

## Simple and mobile-first
- **Nothing to learn:** whistle, then tap the limb.
- **Big touch targets:** the doghouse prompt and the dog icon are at least 60 px.
- **First time only:** one tiny hint, "Tap a ragdoll's arm or leg!", with a pointing hand.
- **Performance:**
  - the dog is one animated model (Creator Store, malware pass), not physics-heavy;
  - pathfinding runs every 0.5 s;
  - phones are the same.
- **Server:**
  - it decides who has the dog and the bites;
  - the bite remote (ragdoll + limb name) goes through Net with a rate limit (1 per 1.5 s);
  - the target must be a ragdoll within 40 studs, and the limb must be a bitable one.
- **Funnel steps:** "Dog whistled", "Bite ordered", "Dog KO".

## Check
- One quick Play on the phone emulator and on PC:
  - whistle; the dog follows;
  - tap an arm, a leg and the bottom on different ragdolls;
  - each bite lands on the tapped limb, and the reaction fits it;
  - the tooth marks and injury stay;
  - X-ray shows the jaws, and later the marks on the bone.
- **Test selv** (Danish) in the run's one list.
