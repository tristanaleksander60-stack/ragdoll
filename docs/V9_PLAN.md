# V9: everything you can use a ragdoll with looks and moves top class (owner, 21 Nov 2026)

## The owner's words (verbatim)
> Lig en plan for at gøre alle modellerne man kan benytte ragdolls med bedre, altså hajen, edderkoppen osv, alle de ting som man kan købe med robux også. Fx. hvalen som skal være under vandet og fed animation når den spiser en ragdoll og bedre akvarium og sårn. Sammel alt i 1 plan så jeg bare kan skrive klar til claude code. Imens så opretter jeg alle produkterne

## How it runs
- One `/klar` runs all of V9 in order: V9-0a, V9-0, V9-0f, V9-0g, V9-0h, V9-0i, V9-0j, V9-0k, V9-0l, V9-0m, V9-0n, V9-0o, V9-0p, V9-0q, V9-0r, V9-0b, V9-0c, V9-0d, V9-0e, V9-1, V9-2, V9-2b, V9-2c, then V9-3, V9-3b, V9-3c, V9-4, V9-4b, V9-5, V9-5b, V9-6, then `docs/RELEASE.md` (it publishes by itself).
- **Then** go back to V8 at its State line.
- Between steps, report in Danish and go straight on. Do not wait for the owner.
- **Ids:** the owner is creating the products and passes while this runs. If ids arrive in chat, paste them in (V9-0, F5) and carry on.

## Rules for every step
- **The look:**
  - Real Creator Store models with the malware pass, rigged where they move, in one style (bright, readable, slightly cartoon, kid-safe).
  - Nothing code-built from blocks or balls, no clipping, nothing floating, and the right scale against a 5-stud dummy.
- **Motion:**
  - Every creature and machine has idle, notice, act (eat, launch, spin), react and reset motion.
  - Animate on the rig's bones or Motor6Ds, client-side, from one server start event (as `Client/CreatureAnim` does), so the server stays cheap and every screen is in sync.
  - Asset uploads need an approved folder that is not set, so use procedural / tweened animation, not uploaded AnimationIds.
  - Easing with anticipation and overshoot; squash and stretch where it fits.
- **The "eat" beat** (every creature that takes a ragdoll):
  1. It notices the ragdoll (head turns, eyes widen).
  2. A wind-up.
  3. A snap.
  4. The body is hidden (`MachineHidden`) in a cartoon way: no gore, no blood.
  5. Chewing or a wobble for 1-2 s, with sound.
  6. A spit or launch with a trail. The ragdoll flies out whole and lands on the lab side (`toLab`).
  7. A happy beat.

  The camera may punch a little (FeelBus BigHit), with no shake for the reduced-motion setting.
- **Sound:** each thing gets idle, act and react sounds (Pro Sound Effects / Roblox-licensed), played through SoundMix, at most 2 at once per lab.
- **Server decides:**
  - who is taken, the cooldowns (`MachineCool`), the throw;
  - the physics of the ragdoll stays the same;
  - works on dummies and players (V8-2.7), cartoon-style.
- **Phone budget:**
  - triangles and parts per creature in Config;
  - LOD: past 120 studs only idle at 10 Hz, past 250 hidden;
  - low tier keeps the frame time.
- **Each step:**
  - before/after captures (still + a short act sequence of 4 frames) from fixed spots;
  - one blind reviewer per step (pass bar 8.5);
  - the tests;
  - commit and push;
  - a State line here;
  - a short Danish report (Lavet / Test selv / Brug for fra dig).

## V9-0 First: the open fix plan
Run all of `docs/FIX_PATHS_SHOP.md`:
- F1 real bushes;
- F2 no grey strips through paths;
- F3 no dead-end paths;
- F4 captures;
- F5 purchase pictures and id paste-in.

## V9-0a Hitting a ragdoll never opens Talk (owner, 21 Nov; do it first, it is quick)
> "Fiks så at når man forsøger at slå en ragdoll at man ikke åbner talk menuen hele tiden."

**Cause to confirm.** The Talk prompt (`NpcCommand` addPrompt: a ProximityPrompt on the Head, Default style, `HoldDuration` 0, reach 9) is clickable/tappable by default (`ClickablePrompt`). A click or tap meant as a hit on a close dummy lands on the prompt, and `Client/NpcTalk` opens the panel. E (the key) may also clash with tools.

**Fix:**
- Set `prompt.ClickablePrompt = false`, so a mouse click never opens Talk.
- On PC and pad, Talk only through its key: E, or L3 on a pad.
- **Hide the Talk prompts on this screen** (`NpcTalk.setPrompt`) during any attack and for 2 s after any attack: fire held, a swing, a shot (`AmmoClient.onSpent` / `FeelBus` Shot), or a grab. Also hide them while Grab holds a body.
- **Touch** (no key there): never let a tap meant as a hit open Talk.
  - The prompt shows only when the player stands still near a living dummy with no attack in the last 3 s.
  - Talk needs a short hold (`HoldDuration` about 0.4 s on touch).
  - Or move Talk to a small TALK chip beside the HUD that appears near a dummy, never on the dummy's body.
- **NpcTalk:** never opens the panel if an attack happened in the last 0.5 s, even if the prompt fires.

**Test:** T158_HitNotTalk.
- 30 quick clicks/taps on a dummy at 3-8 studs open the Talk panel 0 times.
- E (or a hold on touch) next to a calm dummy still opens it.

## V9-0f GOD MODE lives in the SHOP like every other pass (owner, 21 Nov; quick, do it next)
> "Fiks så at god menuen ikke er synlig for alle men bare er i shop som de andre passes."

**Now (0.30.0):** GOD MODE has its own HudV3 square between Shop and Lab off phones, and a MENU entry on phones. Every player sees it.

**Change:**
- **No GOD MODE square or MENU entry for players without the pass.** HudV3Layout.LEFT goes back to Shop, Lab. The God window (`Client/GodMode`) is not reachable from the HUD for them.
- **In the SHOP:**
  - GOD MODE is a normal pass card among the others, in the same style and order as `Shop.PASSES` / OFFERS: picture `art/icons/god.png`, name, one line ("Spawn dummies anywhere, twice as many, with a golden beam"), price R$199, BUY.
  - It has a **TRY 60 s** button on the card that starts the existing free trial (`DummySpawn.startTrial`, once a visit) and opens the God window for those 60 s.
- **Owners of the pass** (player attribute `God`): the God window opens from a small GOD button. It shows **only for them**, in the HUD square off phones and as a MENU entry on phones. They can also open it from their owned card in SHOP ("OPEN").
- **During a trial:** the same small button shows with a countdown, then it disappears again.
- **Unchanged:** the server rules stay as they are (`godGated` / `mayCreate`, the trial once a visit, the device caps).
- **Gamepad:** reaches the card and the button.
- **Layout:** LayoutCheck shows 0 problems with and without the pass.

**Tests:** update T148_GodMode.
- Without the pass and the trial: no GOD launcher in the HUD or MENU, and the card is in SHOP.
- TRY opens the window and starts the trial.
- With the pass (`OfferService.grantPass`): the launcher shows and the window opens.

## V9-0g Phone notices much smaller: never cover the action (owner, 21 Nov; quick, do it next)
> "Gør også alle nofikationer på telefonen meget mindre, jeg testet det lige og man kunne nærmest ikke se noget når man skød flere ragdolls og unlocked ting osv."

**Problem.** On a phone, during fast play (several KOs, unlocks, missions), the toasts, banners (`Client/Banner`: KNOCKED OUT!, BULLSEYE!...), unlock reveals, KO stamps / "+1", combo pops, the experiment card and the event banner stack up and cover the screen.

**Rules for touch screens** (landscape and portrait; tablets get a middle size):
- **Size:**
  - every unsolicited notice is at most about 40 px tall in landscape (portrait about 48 px);
  - at most about 45 % of the screen width;
  - text 14-16 px, an icon plus one short line;
  - no full-width ribbons on phones.
- **Place:**
  - in one notice lane at the top centre (under the top bar), or in the top-right corner;
  - never in the middle third, never over the crosshair or the thumb zones.
  - The event banner goes straight to its small chip on phones (no big card first).
- **Amount:**
  - **One at a time.** At most 1 notice visible, and never more than 2 lines of the lane.
  - **Merge repeats:** "+1 KO" ×5 becomes one small counter that ticks up ("KO ×5").
  - **Combo pops** are a small number by the crosshair, not a word over it.
  - **KO stamps** stay small and fade in 0.6 s.
- **Unlocks:**
  - a new weapon shows as a small chip "NEW: Rocket" with its icon, sliding into the bar slot;
  - the big reveal plays only when nothing is happening (no shot for 2 s), or when the player taps the chip;
  - never a full-screen reveal in the middle of a fight.
- **Banners** (BULLSEYE!, KNOCKED OUT!, SURPRISE!):
  - on phones a compact pill, about 36-40 px;
  - hold about 1.2 s;
  - when busy, only the most important one shows, and the rest are dropped (not queued).
- **Busy mode:** while the player fired in the last 1.5 s, only critical notices and the merged KO counter show. Everything else waits in `Notify` (V6-1 rules) or is dropped if stale.
- **Settings:** a "Notifications: Normal / Small / Minimal" choice in Settings. Small is the phone default.

**Check:**
- In the phone emulator (iPhone SE landscape, iPhone 17 Pro portrait and landscape, a small Android), play 60 s of rapid shooting with 3 unlocks and a bullseye.
- Captures every 5 s: the centre third is never covered for more than 0.3 s, and there is at most 1 notice at a time.
- LayoutCheck gets a "notice lane" rule.

**Tests:** T162_PhoneNotices.
- 20 KOs in 5 s: one merged counter, no stack.
- An unlock while firing: a small chip, and the reveal waits.
- Sizes are within the limits on the phone screens.
- T100 still passes.

## V9-0h The lab as one big open hub, like the leader (owner, 21 Nov)
> "Analyser dybt dette billede hvad de gør i forhold til map placering og hvor tingene står og hvor stort det er og fiks så vi gør det samme."

The reference capture is `art/store/look_target/leader_hub.webp`. It shows the leader's spawn hub (HRR-style HUD: Shop/Tools/Lab, R Revive · G Spawn · V Scan, Maps/Events, Next pill).

### What the leader does (analysis)
1. **One huge, open, flat floor is the whole play area.**
   - Large light-grey concrete tiles (about 12-16 studs each, thin dark joints), with no paths, no clutter and no fences inside.
   - The player spawns in the middle of empty floor, with about 40+ studs of clear floor round them. Dummies, cars and ragdolls read perfectly on the calm, light floor.
   - The floor is the "path": you walk straight anywhere.
2. **Everything sits on the rim, around the open middle, at about 40-150 studs.** Each attraction is a big, readable silhouette on its own pad:
   - a giant rocket on a lattice launch tower (the tallest landmark, about 60-80 studs, back left);
   - a big ramp or coaster track (left);
   - a raised boxing ring with ropes and steps (back centre), with a brick crash wall behind it;
   - vehicles parked side by side in one row: car, monster truck, tank (back centre-right);
   - a pool (right back);
   - a huge rock (right).
3. **Everything is visible from spawn in one turn of the camera.** The spawn frame alone shows about 7 attractions. Nothing hides behind another, and heights step up toward the back (ring low, vehicles mid, rocket tall), like a stage.
4. **Big, close social and info pieces frame the spawn:**
   - the leaderboards are a giant wall of tall boards (about 30+ studs), angled toward the spawn, only about 10-20 studs away on the right. They form the right edge of the view;
   - a **Maps billboard** with picture tiles of every map stands about 25 studs from spawn, angled to face it (click to travel);
   - a wooden deck with a fence, a bench and a small house sits at the near left (a cosy corner).
5. **The edge is closed:** green rolling hills with pine trees ring the whole hub (a bowl), with a few grey buildings as backdrop. No void, no visible map end. The grass shows only outside the tiled floor, behind a low kerb.
6. **Scale:** generous. The floor is about 250-300 studs across, and the attractions are real-sized and big against a 5-stud player. Lots of negative space, so the physics chaos has room.
7. **Few, calm world texts:** only the Maps board and the boards. Dummies have one small dark speech label. No signposts.

### What we change (`Config.LAYOUT_V3`; false = today's LAYOUT_V2)
- **Floor:** the lab core becomes one big open tiled floor.
  - Light concrete tiles: a real MaterialVariant or a texture with large tiles and calm joints. Check it does not z-fight or shimmer (V9-0d rules).
  - About 220-260 studs across inside the plot (`PLOT_SPACING` 250+; grow the spacing if needed, with the neighbour labs still hidden).
  - The paths, verges and lamps inside the core go. Paths and greenery stay only on the grass ring outside the floor, to the garden and the creature yard.
- **Spawn:** in the middle of the floor, with a 40-stud clear circle, facing the main attractions.
- **The rim** (one ring at about 50-140 studs, each on its own pad, heights rising toward the back):
  - **left/back left:** the rocket on its launch tower (V9-3c) as the tallest landmark, and the tower/ramp;
  - **back centre:** the cannon with the bullseye in front of the spawn view, the BIG RED BUTTON pad, the boxing/test ring with the dummy row;
  - **back right:** the vehicle row (Car, Truck, Tank, monster truck) parked side by side;
  - **right:** the aquarium/pool (V9-1) and the creature yard entrance;
  - **sides:** the lava pit, wrecking ball, mace, trampoline and stations, spaced so none hides another.
- **Info pieces near the spawn:**
  - **the leaderboard wall:** big, angled, about 15-20 studs to one side, forming that edge of the view;
  - **the Maps board / Places portal** (V9-0e) about 25 studs from the spawn, angled to face it;
  - **a cosy corner:** a wooden deck with a bench and fence at the near side.
- **Edge:**
  - a low kerb, then grass;
  - the garden and the creature yard outside the floor;
  - the hedge and the rolling hills with trees all round (Landscape), so nothing beyond is visible (privacy holds).
- **Keep:** every machine and system works as now (only positions change). Update PathPlan and LabGuide rings, LabZones/today's machine, the Christmas spots, VehicleService spawn and reset points, GreeterService and VisitorService routes, and the tests that hold positions.
- **HUD check against the reference** (only where ours is weaker):
  - the big left squares (Shop, Tools/Weapons, Lab);
  - the key chips bottom-left (R Revive, G Spawn, V…);
  - the Next pill top right;
  - Maps/Events squares top right;
  - an in-game board panel (Here/Friends/Global).

  Ours already has most of this; only align what V9-0g's phone rules allow.

### Done when
- **Captures from the spawn:**
  - the PC frame shows at least 6 attractions without turning, the leaderboard wall and the Maps board;
  - phone landscape shows at least 4;
  - a top-down shot shows the ring layout, and a back shot shows the closed edge.
- **Side by side** with `leader_hub.webp`, the blind reviewer judges that "it reads as one big open hub with everything on the rim" (≥ 8.5).
- **Tests:**
  - T112 (spawn view), T106/T150 (paths), T36, T26, T50, T103 and T153 updated;
  - a new T163_HubLayout: a 40-stud clear spawn circle; every attraction on the rim between 40 and 150 studs; none fully hidden from the spawn camera; no part z-fighting on the floor.
- **Phone budget** held.

## V9-0i A shop people want to spend in: right pictures, 3D and interactive (owner, 21 Nov)
> "Fiks alle ikonerne i shop så de passer til de rigtige og gør hele shoppen 3d interaktiv og super flot fordi folk skal bruge penge derinde."

**What the capture shows** (`art/store/look_target/shop_now.png`):
- **Wrong pictures:** Starter Crate, All Guns and Lab Controls all show the egg icon, because `EventShop.buildOffers` falls back to `OFFER_ICONS[offer.key] or "gift"`, and the new keys have no entry.
- **Buttons:** one card shows "R$ 49" and the others only "BUY".
- **Cards:** flat and alike: a small icon, a name and a short line.

**1. The right picture on every item:**
- **Pictures:** use the finished 512x512 pictures in `art/shop/` (`<key>.png`, `event_<id>.png`, made by `art/tools/build-product-icons.py`), the GOD MODE picture, the weapon-tier pictures, ULTRA and VIP.
- **Upload** them with Studio MCP `upload_image` (the same way as the DrawnIcons: serve `art\` over a localhost HttpListener, batches of 8). Put the ids in `Shared/DrawnIcons` (`shop_<key>`, `shopevent_<id>`).
- **Mapping:** map every OFFERS / PASSES / Events / weapon-tier key to its picture in one table. A test fails if any sold item has no own picture (no fallback egg or gift).

**2. A 3D, interactive shop:**
- **Layout:**
  - tabs **FEATURED · PASSES · ITEMS · EVENTS · BOLTS**;
  - FEATURED opens first, with a big hero banner (GOD MODE or Everything) and a "BEST VALUE" ribbon;
  - cards in a clean grid, the UI v2 tokens and rarity frames by price.
- **Each card:**
  - **Live 3D:** a live 3D model of the item in a ViewportFrame (Ui3D): the pet, the trampoline, the fan, the spider, the gun set fanned out, the crate opening, the rocket, a dummy in the suit or in gold, the event's star model.
  - **Motion:** it turns slowly; on hover or focus the card lifts, tilts toward the mouse (parallax), lights up and speeds the turn. On phones, a tap = focus, and a second tap opens the detail.
  - **Price:** shown the same way on every card, with the Robux mark ("R$ 149"), never a bare "BUY".
  - **States:** OWNED ✓ / EQUIP for owned items, and TRYING for items on trial.
- **Detail view** (click a card):
  - a big turning 3D model you can drag to rotate;
  - what you get, as 2-3 icon bullets;
  - TRY 60 s where it exists (the booth/God trial rules);
  - a big gold BUY.
  - For events, a short looping preview (the event card picture with motion, or a mini 3D scene).
- **Buying:**
  - Roblox's own prompt;
  - on success, the card bursts (confetti, a coin shower), the item flies to the HUD/bar, a "YOURS!" banner (V9-0g sizes on phones) and the purchase sound;
  - on cancel, nothing nags.
- **Feel:** gentle easing; a press squish (KitStyle.press); hover and click sounds; numbers count up; the window opens with a soft scale and a blur of the world behind.
- **Performance:** only visible cards render 3D (Ui3D budget). Off-screen ones are a still picture, and the low tier uses the still pictures. The window opens in under 0.3 s.
- **Phones and pads:**
  - 2 cards per row on phones, 44 px targets, and LayoutCheck 0;
  - pad focus moves card to card with a clear yellow ring, A opens the detail and X buys.
- **Fair and policy-safe:** no fake timers or fake discounts, real prices only, and nothing random sold.

**Tests:** T164_ShopPictures and T165_Shop3D.
- Every sold key has its own uploaded picture.
- Every card shows a price.
- Owned items show OWNED.
- The visible 3D cards stay within the budget.
- The detail view opens and closes.
- The shop fits on 16 LayoutCheck screens.

**Capture:** before/after of FEATURED, PASSES and a detail view, on PC and phone.

## V9-0j There is always a ragdoll to shoot (owner, 21 Nov)
> "Sørg også for at der også går ragdolls rundt omkring i ens lab så der altid er en at skyde."

**Now:**
- the lab's dummy row (6 dummies; dead ones revive after `REVIVE_AFTER` 10 s);
- `VisitorService` (3 roaming visitors per owner, phone tier 1, `ROOM_KEEP` 8; VipLab more);
- the GOD MODE spawns;
- creatures and the feed terminals take dummies out of play for a while.

So a player can stand there with no standing target.

**Rule: never zero standing targets.**
- In the owner's lab there are always at least `LAB_MIN_TARGETS` standing dummies (PC 6, tablet 5, phone 4). At least 2 of them are within about 40 studs of the player and in front of the camera when possible.
- **Kept up live:** checked every 1-2 s, cheap, only while the owner is in their lab (sleep otherwise, V9-5b). When the count drops (KO'd, in a creature, launched, thrown off), a new dummy **walks in** from the rim of the hub (V9-0h): through a small gate/door, or popping out of a spawn tube with a puff.
- **Life:** the roaming ones wander the hub floor on loose routes:
  - they stop at machines (cannon, trampoline, ring), look around and wave;
  - some sit or chat in pairs (DummyLife lines, small);
  - they flee briefly from bangs, but never out of the lab, and never more than V8's coward rule.
  - Visitors and the new walkers share one pool, so the counts never add up past the cap.
- **Caps:**
  - the total bodies per lab stay within the device tier (`DEVICE_CAPS` / FX_CAPS ragdolls);
  - KO'd bodies past the cap are cleaned (the oldest first, after `REVIVE_AFTER`);
  - a body lying still for a long time is recycled.
- **Newcomers:** the first minute still follows V8 (the greeter, calm, first hits knock flat).
- **Party labs:** the same count, shared.

**Tests:** T166_AlwaysTargets.
- KO every dummy in the lab: within 3 s at least the minimum is standing again.
- The body count never passes the tier cap.
- With no owner in the lab, the loop is idle.

**Capture:** after 20 s of nonstop shooting, standing dummies are still in view, on PC and phone.

## V9-0k The hub floor as soft 3D pads, not flat white tiles (owner, 21 Nov)
> "Gulvet ligner lige nu hvide fliser, det skal mere ligne 3d puder agtig."

**Now:** V9-0h laid the hub floor as a light tile texture on a flat part, so it reads as flat white bathroom tiles.

**Target** (as in the leader's hub, `leader_hub.webp`): big square slabs that look **3D and soft, like padded cushions or rounded concrete pads**:
- each slab slightly raised, with a rounded/bevelled edge catching the light;
- a dark groove between slabs;
- a light warm grey, not pure white;
- a tiny colour and roughness variation per slab.

**How** (pick the cheapest that really looks 3D; check it on the low tier):
1. **Real geometry, instanced:** one rounded-slab MeshPart (a Creator Store bevelled tile/pad mesh, or a rounded box) reused for every slab.
   - The same MeshId, so Roblox instances it cheaply.
   - About 12-16 studs per slab, about 0.6-1 stud thick, with a 0.3-0.5 stud groove.
   - Anchored, CanQuery/CanTouch off on the visual slabs. One flat invisible collision floor underneath keeps the physics and the ragdolls exactly as now (no bumps).
   - Only the owner's lab is drawn (PlotPrivacy), so the part count stays low. Use a slab budget per lab in Config.
2. **Or a PBR MaterialVariant with a strong pillow normal map:** a ColorMap + NormalMap + RoughnessMap of rounded pads, `StudsPerTile` = the slab size, uploaded through Studio MCP like the icons. Use it if 1 costs too much on phones.
3. **Possibly both:** real slabs near the spawn, the MaterialVariant further out.

**Rules:**
- **Light:** the light shading comes from the bevel. It must read in the V9-0b bright light and still let white dummies stand out (a greyscale check: dummies brighter than the floor).
- **No z-fighting or shimmer** (V9-0d scan = 0).
- **Ground level:** cars drive smoothly; the trampoline, ring and machines sit flush on it.
- **Christmas:** snow from 1 Dec lies lightly on top.
- **Switch:** `Config.HUB_FLOOR_PADS`.

**Tests:** T163 extended.
- The floor collision is one flat surface.
- The slab count is within the budget.
- No overlap pairs.

**Capture:** spawn view, close-up and top-down, before and after, PC and phone, next to the leader's floor.

## V9-0l GOD MODE free for everyone in the beta, fully 3D, and easy to spawn many where you aim (owner, 21 Nov)
> "Gør så alle får GODMODE efter nogle sekunder hvor det passer ind, og så skal den opgraderes til komplet 3d interaktiv og flot og stå som gratis fordi vi lige er åbnet og stadig er i beta selvfølgelig på engelsk. Gør også godmode meget bedre så det lettere at spawne fx. 10 hurtigt hvor man vil, ikke bare random steder."

**1. Free for everyone during the beta** (`Config.GOD_FREE_BETA` = true):
- **Who:** every player gets GOD MODE free, server-side (the same path as owning the pass: the player attribute `God`, the caps, the gold beam).
- **When "it fits"** (V8 calm rules, V9-0g phone sizes):
  - **a newcomer:** after their first wow (the first 3-5 KOs or the first cannon launch), or at about 90 s at the latest, at a calm moment (no shot for 2 s);
  - **a returning player:** about 10 s after joining.
- **The reveal:** a short golden reveal, "GOD MODE unlocked: FREE during beta!", with the God icon flying into its HUD button and a chime. Small on phones. Once per player: it is remembered on the profile, so later visits only get a tiny "God Mode is still free in beta" chip once a day at most.
- **Shop:**
  - the GOD MODE card shows **"FREE · BETA"** (English) instead of a price, with an OPEN button;
  - it is not sold while free: hide BUY, so nobody pays for what is free;
  - the 60 s trial logic is skipped while it is free.
- **People who already bought the pass** get something extra so they never feel cheated: a "Founder" gold name tag or title and a gold God beam colour no one else has, and they keep GOD MODE for good after the beta.
- **When the beta ends** (the owner flips the switch): pass owners keep it; everyone else goes back to the trial plus BUY. An in-game note comes a few days before (the What's New rhythm), never a surprise.
- **All texts in English.**

**2. The God window, fully 3D and beautiful:**
- **Look:**
  - a sleek panel (UI v2 tokens);
  - each dummy kind (TINY, HEAVY, BOUNCY, FLOPPY plus any V8 types) shown as a **live turning 3D dummy** in a ViewportFrame, tilting on hover, with a rarity glow and its name;
  - a gold header with the God icon and "FREE · BETA".
- **Controls:**
  - **Kind:** pick the dummy kind.
  - **Amount:** a quick picker **1 · 5 · 10 · 25** (within the device cap) and a slider.
  - **Pattern:** **Point · Line · Circle · Grid · Tower · Rain**.
  - **Spacing:** a small slider.
  - **CLEAR MINE:** removes the dummies you spawned.
- **Keyboard:** G toggles the window or the placing mode; the mouse wheel changes the amount; Q/E rotate the pattern; R/F change the spacing.

**3. Spawning where you want, fast:**
- **Placing mode:** a ghost preview of the whole pattern follows the aim point on the floor (raycast; it snaps to surfaces, in your own or a party lab only). It shows how many and where, green when the spot is valid and red when not (inside a wall or a machine, outside the lab).
- **Click / tap / RT** spawns the whole pattern at once, with the gold beam and a satisfying pop per dummy (staggered over about 0.3 s). **Hold and drag** "paints" dummies along the drag (rate-limited).
- **Phones:**
  - tap the floor to place;
  - a big SPAWN button repeats at the last spot;
  - the pattern and amount sit in a compact bar (44 px targets, out of the thumb zone).
- **Pads:** the aim point at the screen centre, RT spawns, and the D-pad changes the amount and pattern.
- **Server:**
  - checks every request: the place is in your lab, the amount is within the tier cap (twice the cap with God);
  - a rate limit;
  - the oldest of your spawned dummies are recycled when the cap is hit (never an error spam).
  - The remote goes through `Net` with a validator and is listed in CLAUDE.md.

**Tests:** T148 updated and a new T167_GodSpawn.
- With `GOD_FREE_BETA`, every player has God after the grant moment, and newcomers not before their first wow or 90 s.
- The shop shows FREE · BETA with no BUY.
- Pass owners get the Founder extra.
- A 10-dummy line spawns where aimed, with all 10 inside the lab.
- A spot outside the lab is refused.
- The cap and the rate limit hold.
- The window fits on 16 LayoutCheck screens.

**Capture:** the reveal, the 3D window, a 10-dummy line and a ring being placed, on PC and phone.

## V9-0m The Compressor: a hydraulic press that flattens ragdolls (owner, 21 Nov)
> "Tilføj en compressor som fladmasser ragdolls."

**The machine:**
- **Model:** a big industrial hydraulic press: a steel frame with pistons, a heavy press plate, warning stripes, a lit "PRESS" lamp and a small conveyor or plate where the body lies. A real model with the malware pass, in the V9 style.
- **Terminal:** a feed/launch computer like V9-2b / V9-3c, with a big **PRESS** button. Spam is allowed within the rate limit.

**One press:**
1. The nearest free dummy is carried onto the plate, or a player drops one there (LabGuide ring "DROP HERE").
2. The lamp blinks and hydraulic hiss plays.
3. The plate slams down with a heavy THUD, a camera punch nearby, dust and a comic "SQUISH!" sticker.
4. **Cartoon flattening:** the dummy becomes a flat pancake. It is done visually on the client: the body's skin is scaled to about 15 % height and widened, with the server marking the state; it is not physics damage, and there is no gore.
5. It lies there as a flat pancake for 2 s. Then the plate lifts, and the pancake **pops back to shape** with a boing and wobbles (squash and stretch), and walks off dizzy (stars round the head).
6. A player may also flatten themselves, in their own lab or a party lab (the same cartoon effect).

**Extras:**
- a "PANCAKE ×N" counter on the terminal screen;
- an experiment card "Flatten 5 dummies" and a journal page;
- the first press of a visit gets the slow-mo beat.

**Rules:**
- server-checked (owner or party, near the terminal);
- a cooldown of about 2.5 s per press, with spam queued up to 3;
- the body physics stays the same after it pops back;
- the phone budget is held.

**Tests:** T168_Compressor.
- A press flattens and restores the dummy.
- No body is stuck under the plate.
- Spam respects the cooldown and queue.
- Strangers are refused.

## V9-0n Every machine and creature placed where it works best (owner, 21 Nov)
> "Alle maskiner og dyr står stadig dårlig, sørg for alt er placeret psykologisk bedst i forhold til mappet osv."

A full placement pass for the lab hub (V9-0h) and every map, done as a designer would, with these rules written into `docs/STYLE_LAB.md` and checked in captures:

- **The spawn view sells the game.** The first frame shows the 3-4 most fun things (cannon + bullseye, the rocket, the spider/aquarium, the compressor) and at least 2 standing dummies. Big landmark silhouettes stand at the back (the rocket), action in the middle, the dummies near.
- **One landmark ("weenie") pulls you in.** The tallest thing (the rocket tower) stands at the far end of the main view line, so players walk across the hub, passing everything else.
- **A loop, not a dead end.** The attractions sit in a clockwise loop round the hub: spawn → cannon/bullseye → compressor → rocket → creatures/aquarium → vehicles → back to spawn. Each one is visible from the one before ("what's next?" pulls the player on).
- **Group by verb.**
  - Launchers together: cannon, rocket, trampoline, stations.
  - Crushers and hazards together: compressor, mace, wrecking ball, lava.
  - Feeders together: creatures, aquarium.
  - Drivers together: the vehicle row with open floor in front to drive into dummies.

  The groups are spaced so their action radii never overlap: a launched body must not land in another machine.
- **Distances by use.**
  - Most-used machines (Session_v1 `used`) within about 20-45 studs of the spawn, rarer ones on the outer ring.
  - The walk between neighbours is at most about 6-8 s.
- **Facing.** Every machine and creature faces the player's approach: the terminal on the near side, the screen toward the path, the creature's face toward the spawn. Nothing shows its back.
- **Landing zones.** Every launcher points its flight into open floor or the bullseye, in view of the camera that launched it; never over the hedge or behind a building.
- **Readable at a glance.** Each attraction has room round it (negative space), its LabGuide ring and one icon sign. No two signs overlap from the spawn view.
- **Social and shop anchors.**
  - The leaderboard wall and the Places portal by the spawn (V9-0h / V9-0e).
  - Seating at the edge of the action, so friends can watch.
  - The map-shop booths on the walk between attractions, seen but never in the way, and never in the spawn's first frame for a newcomer (V8 fair shop).
- **Ground and scale.**
  - Everything stands on the floor (no floating or sinking), at a real scale against a 5-stud player.
  - Big things far, small things near.
  - No machine hides another from the spawn camera.
- **Maps too.** On each open-air map, arrive 15-20 studs in front of its hero activity (V8-2.10), with the other activities in a loop and the portal home in view.

**How:**
- Draw the top-down plan first (a capture with the loop and the radii marked), then move the things (positions in one data table per place, so tests can read them).
- Update PathPlan, LabGuide, VehicleService, the Christmas spots and the tests that hold positions.
- Use the data: after release, compare `used` shares and the walk heatmap (if logged) and adjust.

**Tests:** T163 extended.
- Every attraction lies inside its band.
- No action radius overlaps another attraction.
- Every launcher's landing point is on the open floor.
- Every machine faces within 45° of the spawn or path.
- No sign overlaps another in the spawn view.

**Capture and review:** spawn view (PC and phone), top-down with the loop drawn, and a walk-through of 6 frames. The blind reviewer scores the layout ≥ 8.5. The owner signs off.

## V9-0o Grey, matte ragdolls that read in the bright sun (owner, 21 Nov; quick, do it next)
> "Gør ragdolls mere grå så de er lettere at se og gør dem mere matte fordi solen skinner jo meget nu."

**Problem:** under the bright V9-0b light (LOOK_THUMB), the white dummies blow out (clip to white), shine and blend with the light floor and sky.

**Change** (`Config.DUMMY_TONE`; the old white is one switch away):
- **Colour:** a **mid-light grey**, about RGB 165-180 (a soft neutral or slightly warm grey), not white.
  - The crash-test details stay: the yellow and black target, the dark joint rings, the belt.
  - The dead/KO green still reads clearly against the grey.
  - Gold Dummies and the crash suit keep their own looks.
- **Matte:**
  - SmoothPlastic → **Plastic or a matte MaterialVariant** (roughness about 0.85-0.95, no specular hot spots);
  - `Reflectance` 0 on every skin part;
  - check `DummySkins` (the client skin from ReplicatedStorage.DummySkin) and `DummyFactory` (the server body colours) both follow it.
- **Contrast check:**
  - In the bright light, from the spawn and at 60 studs, on PC and phone (quality 1 and max), the dummies must stand out from:
    - the hub floor pads (V9-0k);
    - the grass;
    - the sky.
  - The floor stays a bit lighter or warmer than the dummies, or add a soft contact shadow so they pop.
  - A greyscale capture shows clear separation.
- **All dummies:** the lab dummies, walkers and visitors, GOD MODE spawns, event dummies, the greeter, the compressor pancakes. The crowd NPCs in clothes are not touched.
- **Settings:** if a player picked a dummy skin later (paid skins), that skin wins.

**Tests:** T36/T91 updated.
- Skin colour within the grey range.
- Reflectance 0.
- A matte material.
- The KO green still differs.

**Capture:** before/after in the sun at the spawn and close up, PC and phone, plus the greyscale check.

## V9-0p Guide signs and rings move with their creature (owner, 21 Nov; quick)
> "Fiks så at teksten ikke følger bag ved robotstøvsugeren men følger ordentligt efter."

**Problem** (the owner's capture): the vacuum robot roams, but its "FEED ME!" sign (with "3 / 10") and its cyan dashed drop ring stay behind at its home spot, or trail behind it. The sign floats over empty grass while the robot is elsewhere.

**Cause to confirm:**
- `LabGuide` builds the sign and the ring (`GuideRingSeg`) at a fixed position, or welds them to a part the vacuum does not move with.
- The vacuum's motion is server-stepped at 15 Hz (V6-5 review), so anything updated separately lags.

**Fix:**
- **Sign:** a BillboardGui with its **Adornee** set to an Attachment on the creature's own root/PrimaryPart (the part that actually moves), with `StudsOffsetWorldSpace` above its top. Then it follows exactly, every frame, on every screen, with no extra network.
- **Ring:** for a moving creature, the ring is drawn **client-side** around the creature's current position. It is a cheap ring of pieces re-placed on RenderStepped from the creature's pivot, or one decal disc welded to the root, kept flat on the floor by a ground raycast. Rings of creatures that do not move stay where they are.
- **Smooth motion:** the vacuum's motion is smoothed on the client (interpolate between the server's 15 Hz steps), so the robot and its sign glide instead of stepping.
- **The same check for every moving thing** with a sign, ring, hunger meter or name: the spider on its thread, the frog's tongue target, the mole, the chicken, the robot dog/parrot pets, the creature events. Their labels follow the thing.

**Test:** T169_GuideFollows. Move the vacuum 30 studs: within 1 frame, its sign and ring are within 1 stud of its position, over 5 s of roaming.

**Capture:** the vacuum moving with its sign and ring, 3 frames.

## V9-0q No sign hidden inside trees or models (owner, 21 Nov; quick)
> "Man kan ikke se hvad der står ved slingshot."

**Problem** (`art/store/look_target/slingshot_sign_now.webp`): the slingshot's "LOAD ME! 3/10" sign sits inside the tree's leaves, so the text is unreadable. The slingshot itself is half hidden under the canopy too.

**Fix for every world sign** (LabGuide signs, hunger counters, today's machine star, NEW tags, booth signs, terminals' screens, board and portal labels):
- **Placement:**
  - put the sign **above the top of everything around its thing**: compute the bounds of the creature or machine **and** any foliage or prop within a few studs (like LabZones `topOf`, but including trees and MeshParts), then add a margin;
  - or put it **in front of the thing, toward the player's approach side** (the path or spawn), whichever is closer to eye height and not blocked.
- **Occlusion fallback:**
  - Each client checks (cheaply, about 4 Hz, only for signs within 40 studs) whether the line from the camera to the sign is blocked by leaves or a model.
  - If it is blocked, the sign switches to `AlwaysOnTop` with a soft backing card, and fades back to normal when the line is clear.
  - Far signs (past about 40 studs) stay normal, so the whole lab does not show through walls.
- **Readable:**
  - a minimum size in pixels at 10-30 studs;
  - a dark card behind white text, or the V9 icon style;
  - the counter ("3 / 10") inside the card, not floating loose.
- **The slingshot tree itself:**
  - trim or lift the canopy so the slingshot, its band and its load pad are clearly visible from the approach;
  - or use a slingshot-tree model whose fork is the readable shape.
- **Prompts:** the default "Slingshot / Load" ProximityPrompt is replaced by the V9-2b terminal / V9-4b card style when those steps land. Until then, the prompt sits in front of the leaves.
- **Audit:** walk every creature, machine, booth and board in the lab and on the maps, and fix any sign that is hidden, clipped or overlapping. Record it in a short table in `docs/AUDIT.md`.

**Test:** T170_SignsVisible. For every guide sign, a ray from the main approach point at eye height reaches the sign unblocked, or the sign has the occlusion fallback; no sign's centre is inside another part's bounds.

**Capture:** the slingshot from the owner's angle, before and after, and 3 other creatures.

## V9-0r Hero scale: everything big and magnificent, each with its own animation and sound (owner, 21 Nov)
> "Gør alt vi har 10X større, kanonkugle, kanon, slingshot, raket, edderkop og sådan noget så det ser magnificent ud, og de skal have en custom animation alle sammen så det ikke bare er det samme, og de skal lave lyde."

**Scale rule.** Literally 10x would make the 14-stud cannon 140 studs long and the rocket taller than the hub is wide (250 studs), so nothing would fit or be playable. Make each one as big as it can be while the hub still frames it and it still works: **"hero scale"**, about 2.5-5x today, with the landmarks biggest.
- Tune per thing in Config (`HERO_SCALE.<name>`), judged from the spawn camera on PC and phone.
- Grow the hub or plot (`PLOT_SPACING`) if needed, keeping privacy.

| Thing | Target size (about) | Its own signature motion | Its own sound |
|---|---|---|---|
| **Cannon** | barrel 35-45 studs, wheels taller than a player | barrel tilts up and aims, breech loads with a clunk, the whole cannon recoils back on its wheels, smoke ring | deep BOOM with a long echo, metal clank on the reload |
| **Cannonball** | 6-10 studs (a dummy fits on it) | rolls into the breech, flies with a smoke trail, bounces and rolls when it lands | whistle in flight, heavy thud and rumble on landing |
| **Rocket** (V9-3c) | 80-120 studs on its tower, the tallest landmark | gantry arms swing away, steam vents, a slow heavy lift-off that speeds up, slight wobble | countdown beeps, rising roar, crackle of the flame |
| **Slingshot (tree)** | 30-40 studs tall | the band stretches back with a creak while the tree bends, snaps forward, leaves shower, the tree sways back | creak, twang, rustle |
| **Spider** | 25-35 studs across, its web spanning a corner | scuttles down its thread, spins the body in silk, chews with its jaws, "burrito" spit | skitter, silk zip, munch, cartoon spit |
| **Whale / shark** (V9-1) | whale 40-60 studs, shark 20-25 | whale breaches and blows, the shark circles with its fin and snaps | whale call, splash, blowhole spray; shark bite snap |
| **Plant, frog, chicken, mole, washer, vacuum** | 2.5-4x each | each their own (V9-2 list): plant chomp and bob, frog tongue reel, chicken egg lay, mole pop, washer spin, vacuum suck | each their own: chomp, ribbit and slurp, cluck and plop, dirt burst, spin and slosh, vacuum whine |
| **Compressor** (V9-0m) | 20-30 studs tall | pistons pump, plate slams, lifts with steam | hydraulic hiss, THUD, boing |
| **Wrecking ball, mace, trampoline, tower, button** | 2-3x | ball swings on real chain links, mace spins with wobble, trampoline mat stretches deep, button cover flips and presses | chain rattle, whoosh, boing, a big clunk click |

**Rules:**
- **Gameplay follows the size:** trigger volumes, launch powers, flight arcs and landing zones (V9-0n), LabGuide rings, terminals and signs are all re-tuned to the new sizes. Every launch still lands on the open floor or the bullseye.
- **No two things share an animation.** Each has its own idle (so it looks alive while waiting), its own act and its own rest. Animated on the client from one server start event (V9 rules), with anticipation, follow-through and squash and stretch.
- **Every one makes sound:**
  - its own idle loop (quiet, falls off with distance);
  - its act sound;
  - its reaction sound;
  - all through SoundMix, at most 2 big sounds at once per lab, with the volume falling off over distance.
- **Performance:**
  - bigger models keep their triangle budget (real LOD meshes);
  - idle animations stop past 120 studs;
  - the low tier stays smooth (V9-5b).
- **Placement:** re-check V9-0n after the scale-up (spawn view, loop, no hiding).

**Tests:**
- T163 and T168 updated for the new sizes;
- T171_HeroScale: every hero thing is inside its size band, every trigger contains its drop point, every launch lands on the floor, every thing has its own animation set and sound ids (none shared).

**Capture:** the spawn view and a close-up of each hero thing in action, before and after.

## V9-0b The thumbnail look: bright, sunny, alive (owner, 21 Nov)
> "Lig en plan for at få spillet til at føle som thumbnailsne ... lige nu ser det mørkt ud og himlen ser død ud i forhold til thumbnailsne."

**Target.** `art/store/look_target/thumb_cannon.webp` and `thumb_gorilla.webp`.

**The look of the target:**
- a deep saturated blue sky with big white fluffy clouds and a visible warm sun with a soft flare;
- bright warm sunlight from one side with soft, blue-tinted shadows (not black);
- high colour: lush green rolling hills with round trees, warm sandstone, red and yellow accents;
- clean white dummies that pop against the background;
- light dust and smoke puffs.

Do this step first, so every later capture in V9 uses the final light.

**Where the look comes from:** Lighting, the post effects and the sky, set per place through ZoneLighting (LOOK_V3 `finishV3`) and AdminWorld (time/weather). This ends the "realistic grey" grade.

**Light:**
- Daytime about 14:00-15:00 (`ClockTime`), with the sun in front of the spawn camera's side so faces and the cannon get light.
- Brightness about 2.5-3.5. Warm `ColorShift_Top`; `Ambient` and `OutdoorAmbient` raised and tinted light blue, so shadows read blue-grey, never black.
- `EnvironmentDiffuseScale` and `EnvironmentSpecularScale` about 0.6-1.0. ExposureCompensation tuned so white dummies are white but not clipped.
- Keep LightingStyle Realistic + PrioritizeLightingQuality. Check that phones (low quality) still look bright.

**Sky:**
- A bright cartoon-blue sky with big cumulus clouds: a Creator Store skybox of that style, or Roblox `Clouds` (Cover about 0.5-0.6, Density about 0.7, white).
- A visible sun (SunTextureId / SunAngularSize larger) and a soft SunRays.
- The old sky stays in ServerStorage as a backup.

**Atmosphere:**
- low Density (about 0.2-0.3), Haze low, a light blue Color/Decay;
- the far hills read soft blue, not grey fog.

**ColorCorrection:** Saturation about +0.15-0.25, Contrast about +0.05-0.1, a slight warm TintColor. Bloom soft (Intensity about 0.4, Threshold high) so only the sun and white highlights glow. DepthOfField only off or very light in normal play.

**Ground and world:**
- greener, brighter grass (terrain colour `SetMaterialColor` for Grass/LeafyGrass), and warm sandstone paving;
- the lab's dark grey/asphalt areas get a lighter, warmer surface where it fits;
- round, lush trees (real models) on the hills;
- red/yellow accents on barriers and barrels.

**Snow (Christmas from 1 Dec):** a sunny snow day: blue sky and sun stay, the snow is light, and it never turns the scene grey.

**Every place.** Lab, Plaza, Arena, Island, City, Site, Farm and Military each get their own profile in the same bright family. Indoor/arena light gets the same lift. The director (V6-3) and admin time/weather still work on top.

**Phones:** the low tier frame time holds; post effects are cheap or off at low quality, and the scene must still look bright without them.

**Done when:**
- side-by-side captures, the game vs the two thumbnails, from the same kind of angle (the cannon with the bullseye; a wide lab shot with hills), on PC and phone;
- the blind reviewer says it matches the target mood (≥ 8.5);
- the owner signs off;
- T91 is updated if it checks light values.

**Switch:** `Config.LOOK_THUMB` (false = the old light).

## V9-0c Cars that drive straight, and a speedometer (owner, 21 Nov)
> "Når man sætter sig ind i bil så drejer den bare rundt i en cirkel fiks det og lav speedometer."

**Reproduce first** on PC (WASD), on a phone (thumbstick) and with a pad, in the Car and the Truck (`VehicleService`, `Client/VehicleClient`, `VehicleFeel`). Log the throttle and steer input, the heading and the angular speed each frame.

**Likely causes to check:**
- **Steering read from the camera:** the steering is taken from `Humanoid.MoveDirection` or relative to the camera, so the car chases its own camera and circles. The steer must come from the input axis only (A/D, stick X, the phone's steer control).
- **The model's forward axis:** the model's forward axis does not match the drive force. The imported model's front is ±X or the `Yaw` attribute is applied twice, so "forward" pushes sideways and the yaw torque never settles.
- **A stuck steer:** a non-zero steer or AngularVelocity/AlignOrientation target that is never reset to 0 when the input is released.
- **Wheels:** the VehicleFeel wheels on Welds touch the ground unevenly, so one side drags. The visual wheels must be non-colliding; the drive body decides.
- **Network owner:** the driver must own the car. A server/client ownership flip makes it fight itself.

**Fix the root cause.**
- Steering:
  - centred when no input;
  - a smooth steer with a speed-dependent turn rate;
  - no turning on the spot at 0 speed.
- Driving:
  - reverse works;
  - the brake works;
  - the car stays upright (anti-flip) and never gets stuck in a spin.
- **Phones:** phones get clear drive controls: GAS/BRAKE pedals plus steering, or the thumbstick X for steering and pedals for throttle. Pads get RT/LT plus the left stick. They follow the HUD and LayoutCheck rules.

**Speedometer.** A round gauge HUD while seated:
- a needle that sweeps and a number (km/h; 1 stud ≈ 0.28 m, or the scale from Config);
- a small gear/R indicator;
- a red zone at top speed.

It follows the UI v2 tokens, phones included (out of the thumb zone), and hides on exit.

**Tests:** T153_CarDrives.
- With throttle only for 3 s, the heading changes less than 3°.
- Steer left or right turns that way, and releasing it stops the turn within 0.5 s.
- No spin at 0 throttle.
- Both vehicles pass.

**Capture:** the speedometer on PC and phone.

## V9-0d The ground stops flickering, the bench set is fixed, a plaza people want to meet in (owner, 21 Nov)
> "Også fiks bordet bænke sættet her på plazaen og generelt upgrade plazaen så folk for lyst til at mødes. Desuden så bugger jorden når man kigger rundt på grund af alt det grussten tror jeg."

**What the capture shows** (`art/store/look_target/plaza_bench_now.png`):
- a green bench floating on a stack of overlapping stone discs, with a table that is missing or broken;
- layers of round paving pieces on top of each other;
- the booth signs crowding the seating.

**1. The ground flicker (z-fighting and shimmer). Fix it everywhere, not only on the plaza.**
- **Find it.** Write a tool script that lists every pair of overlapping parts whose top faces are within 0.06 studs of each other. These are:
  - path stones on stones;
  - paving discs on discs;
  - paving on the plaza floor or the baseplate;
  - verge pieces on grass parts.

  Run it in the lab, the plaza and every map. The list must reach 0.
- **Fix the cause:**
  - one surface layer per area: merge the overlapping round paving pieces into single clean slabs or shapes, or use terrain paint where the ground is terrain;
  - where layers must stack, at least 0.1 stud apart and never the same material on the same height;
  - remove hidden duplicates (older path versions under newer ones).
- **Shimmer at a distance** (the busy "gravel" texture): use a calmer paving material or MaterialVariant with a larger `StudsPerTile` and less high-frequency detail. Keep the stone look up close.
- **Check:** slow 360° camera turns at the spawn, the plaza and 2 maps, on PC and phone. No flicker seen.
- **Test:** T156_NoZFight (the overlap scan returns 0 in the lab and on the plaza).

**2. The bench and table set.**
- Replace it with a real picnic set: a table with two benches as one model, or matching table plus benches, at the right height, standing on the ground (not on discs).
- Every seat works: Seat parts at the right height, facing the table, and a player sits correctly.
- Check every other bench and table in the game the same way.

**3. A plaza people want to meet in.** Design it as a town square, with:
- **A centre piece:** a fountain or a landmark statue (a giant crash-test dummy).
- **Seating:**
  - picnic sets and benches facing each other in small groups, under shade trees;
  - string lights between lamp posts, warm at dusk.
- **Things to do together:**
  - a photo spot (a frame with the game's logo and a step);
  - the plaza grab and throw area clearly marked by its shape, not by paint;
  - a high-five or emote spot;
  - the leaderboards together in one place;
  - the portals.
- **A market row:** the map-shop booths as a proper market row along one side (V9-4b spacing). They never stand among the seats.
- **Life:**
  - a few calm crowd NPCs sitting, chatting and walking (existing CrowdService);
  - pigeons (Birds);
  - ambient town sound, with no music (owner rule).
- **Layout:** clear walking lanes from the arrival to everything, open space in the middle, flowers and planters at the edges, and no clutter.
- **Light:** the bright thumbnail light from V9-0b.

**Done when:**
- before/after captures from the arrival, the seating, the centre and from above;
- the blind reviewer passes it (≥ 8.5);
- the walking and crowd tests pass;
- T156 passes.

## V9-0e A beautiful Places portal you see at once (owner, 21 Nov)
> "Lav en portal til places som er flot og ses hurtigt af spilleren så de udforsker."

**Today.** Travel to the maps is a HUD button (Maps), plus the lab's two server portals (PortalSolo / PortalMulti, `PortalService`). Players rarely leave the lab (V8 data: maps are seldom used).

**The new portal:**
- **One big, beautiful "PLACES" portal in every lab**, placed in the spawn view (inside the V8 spawn cone, at about 25-40 studs from spawn, on a path, not blocking the cannon/dummies view).
  - **Look:** a round stone or metal ring gate (a real model) with a swirling animated surface (a slowly turning texture plus particles), a soft glow and a hum.
  - **Pictures:** small live picture panels of the 5 maps round it (the map card pictures), turning slowly.
  - **Look and sound:** in the V9-0b bright look, plus a low hum.
- **Walk in (or press E / tap):** a picture carousel of the places opens (Plaza, Arena, Island, City, Site, Farm, Military, with only the maps that are live). It shows:
  - each place's picture, name and one line ("Feed the shark", "Drive the tank");
  - who is there now;
  - a NEW tag.

  Pick one, then the V8-2.10 travel: stream ahead, a short whoosh transition through the portal swirl, and you arrive in front of that map's hero thing.
- **Ways home:** the same portal stands at every map's arrival ("Back to my lab" plus the other places), so the maps feel connected.
- **Hints, never spam:**
  - after the first 3 minutes, and only once a visit, a subtle beam or sparkles call from the portal;
  - one Notify tip the first time ("Explore other places →");
  - an experiment card "Visit 2 places".
- **The existing PortalSolo / PortalMulti** become part of the same gate family (one style). They must not be confused with PLACES: they get different colours and clear icons.

**Done when:**
- a capture from spawn on PC and phone (the portal is visible in the first frame);
- the carousel on 16 LayoutCheck screens;
- a trip to each place and back works;
- Session_v1 logs `used.portalPlaces` so its effect can be read.

**Tests:** T159_PlacesPortal.
- The portal is in the spawn view at 1920x1080 and 414x896.
- Each place travels and returns.
- Travel is refused while seated or grabbing.

**Owner addition (21 Nov): much nicer portals and a map board.**
> "Gør portalerne langt flottere og tilføj et sted hvor man kan se et skilt med forskellige maps og så kan man vælge der hvilket map man vil skifte til."

- **Every portal, beautiful:** the Places portal, PortalSolo and PortalMulti in the lab, and the portal at every map's arrival.
  - **Frame:** a real ornate ring or arch model (carved stone with glowing runes, or polished metal with lights), at a proper size, about 14-18 studs tall.
  - **Surface:** a **living swirl**: a layered, slowly turning texture with depth, soft refraction, sparkles drifting in, and a glow that lights the ground in front (a PointLight within FX_CAPS).
  - **Sound and motion:** a calm hum that rises as you come near; a small pull of particles toward you within 15 studs.
  - **Colour per kind:** gold = Places, blue = Solo, green = Multiplayer, each with its own icon on top.
  - **Entering:** a whoosh, a quick swirl filling the screen, then the arrival (with streaming ahead).
- **The Map Board:** a big world billboard (like the leader's "Maps" board) about 20-25 studs from the spawn, angled toward it (V9-0h / V9-0n), on a sturdy frame with lights.
  - **Tiles:** a tile per place with its real picture (the map card pictures), its name and how many players are there now, plus a NEW tag. The tiles glow on hover.
  - **Use:** click or tap a tile, or walk up and press E for the focused tile (pads: the left stick picks a tile). That opens the same travel confirm as the portal carousel: the picture, one line, GO. GO uses the V8-2.10 travel.
  - **Build:** the board is a SurfaceGui on a real frame model, readable at 30 studs, and works on PC, phone and pad.
  - **On every map** there is a smaller copy of the board by the arrival, with "My lab" first.

**Tests (T159 extended):**
- every tile travels to its place;
- the board is visible from the spawn at 1920x1080 and 414x896;
- the portal colours match their kind;
- travel is refused while seated or grabbing.

## V9-1 The water: a real aquarium, the whale under water, a shark
- **The aquarium.** Replace the flat glass "WhalePool" with a real aquarium/lagoon in the creature yard:
  - glass walls with frames and rivets, deep enough to see into (about 14-18 studs deep, partly sunk into the ground, with a viewing side facing the path);
  - Roblox **terrain water**, or a water mesh with a moving surface (gentle waves, caustic light on the floor);
  - sand floor, rocks, seaweed that sways, coral, bubbles rising, a few small fish (client-side, cheap);
  - a ladder/ramp and a feeding platform with a sign icon (LabGuide).
- **The whale** lives **under water**:
  - It swims slow loops with a tail beat, blinks, and breaches now and then (a splash and a spray).
  - **Eat:** it rises under the dropped ragdoll, opens wide, gulps it with a big splash, swims a happy loop with the cheeks puffed, then blows it out of the blowhole as a geyser. The ragdoll flies to the lab side. Water ripples, spray particles, a deep whale call and a splash sound.
- **The shark** (the owner's "hajen"): add a shark in the same aquarium, or its own tank, if there is room in the yard (one water body is cheaper).
  - It circles with its fin above the surface.
  - It snaps at a ragdoll that drops in: a fast bite, a shake, then spits it out over the glass, cartoon style.
  - It is a real rigged shark model, with a friendly cartoon face (kid-safe).
- **Swimming:** players and ragdolls float and swim in the water. Nothing gets stuck under the glass. A body under water for more than 6 s pops back up.
- **Tests:** T151_Aquarium.
  - The whale and the shark take a ragdoll and throw it to the lab side.
  - Nothing is left inside the glass.
  - Budget held.

## V9-2 Every creature in the yard
Go through each one in `Server/Systems/LabCreatures` and its model in V3Assets (M prefix). Replace any model that looks cheap with a better rigged one, and give it the full beat set from the rules:
- **Spider:**
  - a big rigged cartoon spider in a real web (strands that sway and stick);
  - it scuttles down on a thread, wraps the ragdoll in silk while spinning it, hangs the cocoon, and munches with a wobble;
  - the "burrito" spit;
  - the hunger meter as a small icon in the world;
  - napping with Zzz.
- **Plant:** a carnivorous plant with leaf jaws that sway and track the nearest body, chomp, chew (the stem bulges) and spit.
- **Frog:** it sits on a lily pad or rock, its throat puffs, the tongue shoots out in an arc (a stretchy beam), reels the body in, gulps, then a burp-hop launch.
- **Chicken:** a giant chicken that pecks, clucks and sits; then a big egg pops out and cracks, and the ragdoll tumbles out.
- **Washer:** a real washing-machine model. The door opens, it spins with a wobble and suds, then the door flies open and throws the body out.
- **Slingshot tree:** a real tree with a rubber band. It stretches back with a creak and snaps forward with leaves falling.
- **Mole:** a dirt mound with real dirt particles. The mole peeks and dives, the ground cracks, and it pops up under a ragdoll.
- **Vacuum robot:** a real robot vacuum. It roams with blinking lights, sucks the body in (with suction lines) and shoots it out.
- **Yard layout:**
  - each creature on its own small "habitat", reached by the paths (F3);
  - a clear drop ring (LabGuide) and a sign icon;
  - spaced so their acts never overlap.
- **Tests:** T103 updated, plus a T152_CreatureBeats check (each creature: notice → act → release within its time, the body is released, it is not stuck).


**Much juicier eating (owner, 21 Nov: "Gør animationerne meget federe på dyrene ... når de flækker ragdolls").** On top of the beat in the rules, every creature's act must feel like a cartoon highlight:
- big anticipation (a long wind-up, eyes popping);
- a hard snap with squash and stretch;
- impact frames: a white flash, a quick hit-stop of about 80 ms through HitFeel, and a small camera punch;
- a comic word pop in the world ("CHOMP!", "GULP!", "SPLAT!", "BOING!") as a drawn sticker, not plain text;
- particles that fit: stars, feathers, splash, silk strands, dust, suds;
- layered sound (whoosh → snap → crunch-free chew → spit);
- the ragdoll launched with spin and a trail;
- a happy victory wiggle;
- a short slow-mo beat for the first feed of a visit.

All of it stays kid-safe (no gore) and within the phone budget.

## V9-2b A feed terminal at every creature, spam allowed (owner, 21 Nov)
> "Gør så at det er en lille computer terminal man kommer hen til og så kan trykke feed ved og spam hvis man ville."

**The terminal.** Replace the floating "Feed" ProximityPrompt (`LabGuide`) with a small computer terminal model beside each creature (and the cannon/lava/trampoline machines that have one):
- a real model: a console on a post, a screen, and a big glowing FEED button;
- the screen is a SurfaceGui showing the creature's picture, its hunger bar and "FEED!";
- it beeps and lights when used.

**Use:**
- Walk up and press FEED:
  - click or tap the button on the screen (SurfaceGui button);
  - or E / ButtonX through a prompt for keyboard and pad.
- **Spam is allowed and fun:** every press sends the next dummy flying in an arc into the creature. Rapid presses chain:
  - a combo count on the screen ("x5!");
  - the creature gets more excited;
  - the feeding speeds up a little.

**Server rules:**
- every press is checked: owner or party member, near the terminal;
- a rate limit of about 4 presses per second;
- a queue of at most 6;
- the feed uses free lab dummies first. When none are free, it drops a spare dummy from a little chute on the terminal, within the device-tier body cap, and the spare is cleaned up after;
- no remote without `Net` validation and a rate limit, listed in CLAUDE.md.

**Tests:** T154_FeedTerminal.
- One press = one feed.
- 20 fast presses respect the rate limit and the queue.
- A press from far away or by a stranger is refused.
- The body cap is held.

## V9-2c Z opens a time dial: faster or slower in a bubble round you (owner, 21 Nov)
> "Gør så at Z ikke bare stopper tiden i ens lab et lille sted, men åbner en lille menu hvor man kan skrue tiden hurtigere eller langsommere i en bobbel rundt om en selv."

**Now:** Z = `SandboxService` "SlowMo", a fixed slow-motion bubble over the lab's middle (ToyService Slowmo), with a gap of 8 s.

**New: Z opens a small time menu** (it closes with Z again or Esc):
- a round dial or slider with steps **0.1x · 0.25x · 0.5x · 1x · 2x · 3x**, the current speed shown big;
- a size control for the bubble (small / medium / big, for example 12 / 20 / 30 studs radius);
- ON/OFF.

The UI v2 tokens; drag or click on PC; tap on phones (the button sits under More/sandbox and is phone-sized); LB/RB or the D-pad on a pad.

**The bubble:**
- It is centred on the player and follows them (only in their own lab, or a party lab).
- **Look:** a clear, slightly refractive sphere with a soft rim glow. Blue for slow, orange for fast, with ripples where things cross the edge, a clock-tick sound slowed or sped up, and the sky/colour inside the bubble faintly tinted.
- **Inside, time really runs at the chosen speed** for dummies and props (the server decides; Roblox has no per-region time scale, so it is simulated):
  - **gravity:** a VectorForce per body in the bubble counters gravity to `g·s²`;
  - **speed:** velocities are scaled by `s` on entering and by `1/s` on leaving;
  - **launches and throws:** launch impulses inside are scaled;
  - **creatures, machines and animations:** they run at `s` (their tweens, the AnimationTrack/procedural speed and the cooldowns);
  - **effects:** particles get `TimeScale = s`, and sounds get `PlaybackSpeed` × `s` (limits 0.5-2);
  - **at 3x:** dummies fall and fly fast and machines cycle fast, with caps so nothing explodes or tunnels through walls.
- **Players** keep their own walking speed (so they can enjoy the effect). The camera gets the C5 slow-mo look only when the bubble is slow.

**Rules:**
- **Server checks:**
  - owner or party only;
  - inside their lab;
  - the speed from the list only;
  - one bubble per player;
  - a rate limit on changes.
- **Remote:** goes through `Net` with a validator; it is listed in CLAUDE.md (extend the Sandbox remote, do not add a new one if it can be helped).
- **Performance:** at most N bodies affected per bubble per device tier. On the low tier the visual is simpler.
- The old one-tap behaviour stays reachable: the dial opens on 0.25x by default, so Z then Enter is the old slow-mo.

**Tests:** T157_TimeBubble.
- A dummy dropped inside at 0.25x falls about 4x slower than outside (±15 %).
- At 2x it falls faster.
- Leaving the bubble returns it to normal.
- Bad speeds and a stranger's lab are refused.
- The menu fits on 16 LayoutCheck screens.

**Capture:** the menu and the bubble at 0.1x and 3x, on PC and phone.

## V9-3 The lab machines
Give the same pass to everything in the lab that takes or throws a ragdoll:
- the **cannon** (barrel recoil, smoke ring, breech, a turn/aim motion);
- the **bullseye** (score rings that light up where the body lands, a wobble on hit);
- the **trampoline** (springs and a stretchy mat that dips);
- the **launch stations** (a real launcher model with a lever pull and a clank);
- the **wrecking ball** (real chain links, swing with weight);
- the **spinning mace**;
- the **lava pit** (it already has LAVA_V2; only the throw-out beat);
- the **tower**;
- the **BIG RED BUTTON** (a press-down with a click and a cover that flips up);
- the **knockables** (V8 Knockables: barrels, crates, cones).

For each one:
- a real model at the right scale;
- a readable "ready" state;
- a satisfying act;
- a return to rest.

Keep the gameplay numbers the same unless the act needs a small timing change (note it in State).

## V9-3b Bigger gaps between weapon unlocks (owner, 21 Nov)
> "Lav større mellemrum på når man unlocker nye våben."

**Now:** takedown rungs come from `Toys` (the base rungs → `squeeze` under `LADDER_V2` with `LADDER_KEEP` / `LADDER_V2_SCALE` → `V8_RUNGS` / `START_BAR_V9` / `HARD_RUNGS`).

**Change:**
- **Widen the gaps** between unlocks, so each new weapon feels earned and the ladder lasts longer.
- **Keep the first-minutes hook** (V8's evidence: players who get early takedowns and a first present stay longer):
  - the start bar stays as it is;
  - the first present (Launch at 3) stays;
  - the next 2 unlocks stay within the first ~10 minutes.
- **From there on**, the gaps grow:
  - make it a smooth curve, for example each gap about 1.35-1.5x the one before, set as Config numbers (`LADDER_V9_GROWTH`, `LADDER_V9_KEEP`);
  - the top end stays reachable, about 2-3x today's top;
  - keep `HARD_RUNGS` items (the Rocket at 470) in proportion.
- **Show the progress well,** so the wait never feels empty: the NEXT pill / NextUnlocks bar shows "x / y KOs" and fills smoothly, there is a small reward sound at 50 % and 90 %, and the unlock moment is a big satisfying reveal.
- **Never take anything away:** a profile keeps every weapon it already owns (grandfather, like Ladder 5). The Robux weapon tiers and Bolts prices are re-checked so nothing looks like a pay wall (V8-5 fair shop).
- **Switch:** `Config.LADDER_V9` (false = today's ladder).

**Tests:**
- T35, T64 and T110 updated;
- a new pure test checks that the gaps grow monotonically after the kept early rungs, that no owned weapon is lost, and that the top is at most `LADDER_V9_TOP`.

**Watch after release:** Session_v1 takedowns-per-visit and leaves just before an unlock. If early leaves rise, shrink the growth.

## V9-3c The big rocket in the lab: strap a ragdoll on and launch it from a computer (owner, 21 Nov)
> "Gør så man kan bruge den store raket i ens lab så man trykker ved en computer og strap en ragdoll på."

**Now:** a big Rocket model stands in the lab only as decoration (LabDress role `Rocket` at x -72, z 12, height 26).

**New: a working launch pad.**
- **Pad:** the rocket stands on a launch pad with a gantry and arms. Beside it is a launch **computer terminal**, the same family as V9-2b: screen, big red LAUNCH button and a countdown display. Pick it up: a real rocket model, a launch tower and a terminal, from the Creator Store with the malware pass.
- **Press LAUNCH** (click/tap on the screen, or E / ButtonX):
  1. The lab's nearest free dummy is carried in an arc to the rocket (or a spare one drops from the gantry). It is strapped on with belts, standing at the nose, and given a little helmet.
  2. The gantry arms swing away.
  3. A 3-2-1 countdown on the screen and above the rocket, with steam venting and a rumble.
  4. Lift-off: a big flame and smoke trail, a camera shake nearby and a roar. The rocket climbs, wobbles a little and arcs over the lab.
  5. At the top, the straps pop: the ragdoll flies free, spinning, with a trail. It lands toward the bullseye or the crash zone (with BULLSEYE scoring), or uses a small cartoon parachute some of the time for fun variety.
  6. The rocket bursts into a cartoon firework (kid-safe, no debris that hurts).
  7. A fresh rocket rises back onto the pad from below, ready again.
- **"Ride it yourself"** (optional second button on the terminal): the player straps themselves on, with the same flight. Your own lab, or a party lab, only.
- **Server rules:**
  - owner or party only;
  - near the terminal;
  - cooldown about 10 s (one flight at a time);
  - a press during a flight queues at most 1;
  - the flight is server-driven for the body (network owner stays the lab's player for the fall);
  - the ragdoll physics stays the same;
  - LabGuide gives it a ring and a sign icon.
- **The same V9 rules apply:** juicy beats, sound, a phone budget, and the first launch of a visit gets the slow-mo beat. An experiment card "Launch a dummy to space" and a journal page.

**Tests:** T161_RocketPad.
- One press = one dummy strapped, launched and landed whole on the lab side.
- Spam respects the cooldown and queue.
- Strangers are refused.
- The rocket resets.
- No body is left stuck on the rocket.

**Capture:** a 4-frame launch sequence and the terminal.

## V9-4 Everything sold for Robux, perfect
These are the `map = true` OFFERS and the passes that put a thing in the world. Each must look and move as good as its price (the turning booth model **and** the thing in use):
- **Spider Deluxe:** a golden version of the V9-2 spider with sparkle, a bigger spit and its own sound.
- **Mega Trampoline:** a big premium trampoline with a padded frame and a deeper bounce dip.
- **Giant Fan:** an industrial fan whose blades spin up, with a visible wind (streaks, leaves) and a roar.
- **Robot Dog:** a rigged robot dog with a walk cycle, a tail wag, a sit when you stop, a head tilt and a little bark. It never clips through you.
- **Parrot:** it sits on your shoulder, flaps when you jump or ragdoll, and flies a loop now and then.
- **Gold Dummies:** real gold with a reflection (MaterialVariant), still reading as a dummy, and the dead green still shows.
- **Crash-Test Suit:** a proper suit with clean seams, the target marks and a helmet. It fits R6/R15 and stays on in ragdoll.
- **Rainbow Trail / Fire Trail:** smooth trails with no gaps at speed. The fire has embers and is never blinding.
- **Bolt Crate / Starter Crate:** a crate that opens with a pop and bolts spilling, in the booth and on purchase.
- **Booths (V6-7):** each booth's turning item is the same improved model. Lit well, with the price readable at 20 studs.
- **TRY:** TRY shows the real thing working for 60 s.
- **Tests:** T105 updated (every booth model present and script-free; every item works after purchase and after TRY; delivered once).

## V9-4b Buying and trying must look premium (owner, 21 Nov)
> "Lig også en plan for man undgår det ser så grimt ud når man skal købe eller try."

**What the owner's capture shows now** (`art/store/look_target/booth_now.png`):
- **Prompts:** two default Roblox ProximityPrompts stacked ("Gold Dummies / Try 60 s free", "Gold Dummies / Buy").
- **Overlap:** they overlap the neighbouring booth's sign ("FIRE TRAIL"), so the names do not match what you look at.
- **Pole:** a pole runs through the gold dummy.
- **Spacing:** the booths stand so close that their signs and prompts collide.

**One card per booth, our own style:**
- Hide the default prompts: `ProximityPrompt.Style = Custom`, drawn in `ProximityPromptService.PromptShown`.
- Show one clean card for the nearest booth only, in the UI v2 tokens:
  - the item's picture or icon (`art/shop`);
  - the name;
  - the one-line pitch;
  - the price with the Robux mark;
  - two real buttons: **TRY 60 s** (secondary) and **BUY** (primary, gold).
- The buttons work by click or tap, and through the E/T keys and pad glyphs. Pads can select them.
- The card pops in softly and leaves when you walk away. Only one card shows at a time.
- The world sign above the booth fades while its card is open.
- **States:** the card shows OWNED ✓ / EQUIP when owned, TRYING 0:42 during a trial, and TRY USED when today's try is spent.
- **Phones:** the card sits above the thumb zone, has 44 px targets and passes LayoutCheck. No text is cut off.

**The booths themselves:**
- No pole or light post through any item. Move the spotlight to the booth's frame, or use a hidden light.
- Spacing: at least about 14-16 studs between booths, so signs and prompts never overlap. A prompt's reach (`MaxActivationDistance`) stays inside its own booth, and `RequiresLineOfSight` is on.
- The sign belongs to its own booth: the same name and price as the prompt, readable at 20 studs and never overlapping its neighbour.
- Each item on a clean pedestal, lit, turning slowly, at the right scale.

**Buying feels good:**
- **On BUY:** Roblox's own purchase prompt.
- **On success:**
  - a short celebration: confetti, the item flies to the player or equips at once, and a "YOURS!" banner through `Client/Banner`;
  - a purchase sound;
  - the booth switches to OWNED.
- **On cancel:** nothing nags.

**Trying feels good, with no pressure:**
- **TRY** equips the real thing at once.
- A small HUD chip shows "Trying <item> 0:42" with the item icon and a small BUY button.
- When the try ends, there is one gentle line through Notify ("Liked it? It's at the booth"). No pop-up window, no repeat (Roblox policy, and V8's calm rules).

**Tests:** T155_BoothCard.
- One card at a time.
- The card's item always matches the nearest booth.
- No prompt reach overlaps a neighbour.
- No booth part intersects its item.
- The card fits on 16 LayoutCheck screens.
- The OWNED / TRYING states are right.

**Capture:** the same angle as the owner's screenshot, before and after, on PC and phone.

## V9-5 Event creatures and big models
- **Bring every event model up to the same bar:** Gorilla, Bull, UFO, Train, Balloon, Giant Dummy, Tornado, Meteor, Bowling balls, Magnet, Rocket rain and so on.
- **Each needs:** a real model, an entrance, an act on the ragdolls, an exit and sound.
- **Match V8-2.9:** only the events that stay get the work. The rest stay hidden and are not sold.

## V9-5b A clean server and no lag, without losing quality (owner, 21 Nov)
> "Sørg for serveren kører så clean som overhovedet muligt med så lidt lag som overhovedet muligt, uden at ødelægge eller svække noget kvalitet mæssigt."

**Measure first, with numbers.** Use a full lab session with 6 players (4 test clients if MCP multi-client allows, else 2 plus bots), all creatures, machines and events used, and 10 minutes on a map. Record:
- **server:** heartbeat Hz, physics step time, script activity per script (the Script Performance view), memory per category, instance count, Data send/receive KB/s per player, remote calls/s per remote;
- **clients:** FPS p50/p5, frame time, draw calls, triangles, memory (MicroProfiler dumps), on PC and the low-tier phone emulator.

Write the baseline into `docs/PERF.md`.

**Fix the heaviest first:**
- **Loops:** every `while true` / Heartbeat loop on the server.
  - Event-driven where possible, at the lowest rate that still looks the same (for example 10-15 Hz for AI, 0 when no player is near).
  - No per-frame `GetDescendants`, `FindFirstChild` chains or new tables.
  - Sleep the whole lab's AI, creatures and machines when its owner is away or not in the lab.
- **Physics:**
  - set the network owner of every ragdoll and prop correctly (the lab's player);
  - anchor or sleep idle props;
  - limit the bodies per lab by device tier (already there: check it holds);
  - CanQuery/CanTouch off on all decoration;
  - collision groups so decoration never collides;
  - CollisionFidelity Box/Hull for props;
  - Touched handlers only where needed.
- **Network:**
  - no per-frame attribute writes;
  - batch updates;
  - UnreliableRemoteEvent for cosmetic streams;
  - send only to players in that lab or place;
  - check every remote's rate limit;
  - nothing replicated that only one client needs (creatures' animation stays client-side, V9 rules).
- **Memory and leaks:**
  - disconnect every connection on cleanup (players leaving, bodies removed, events ending);
  - destroy temp parts;
  - pool effects;
  - run a 30-minute soak and check that server memory and instance count stay flat.
- **Streaming:**
  - StreamingEnabled with sensible radii;
  - models atomic or persistent only where needed;
  - far maps never loaded until visited.
- **Rendering:**
  - CastShadow off on small parts;
  - LOD (RenderFidelity Automatic, `ModelStreamingMode`);
  - lights within FX_CAPS;
  - particles pooled and capped per tier;
  - textures sized sensibly.
- **Start time:** time to the first playable frame; preload only what the first minute needs.

**Rule:** nothing may look or feel worse. Every fix needs a before/after capture where it could change the look. A change that lowers quality is reverted.

**Done when** `docs/PERF.md` shows, against the baseline:
- the server heartbeat stays at 60 with 6 players in full chaos;
- server script time and memory are flat over 30 minutes;
- network per player goes down;
- the low-tier phone holds 30+ FPS p5 in the lab;
- no errors and no warnings in the output.

**Tests:** T160_PerfBudget (instance count, loop count and remote rate per lab under its budget; leak check after a lab reset).

## V9-6 Final check and release
- **Full self-test suite** and LayoutCheck.
- **10-minute play:** on PC and in the phone emulator, feeding every creature and using every machine and every bought item at least once, with no errors.
- **Low tier frame time** held with the whole yard active.
- **A capture sheet** for the owner: every creature, machine and Robux item, before and after.
- Then `docs/RELEASE.md` (it publishes by itself), then back to V8.

## State
- 21 Nov 2026: plan written (cloud). Nothing done.
- 21 Nov 2026, V9-0a DONE (PC): `Shared/TalkRules` (pure). The server's TalkPrompt is `ClickablePrompt = false`. `Client/NpcTalk` hides every Talk prompt for 2 s after a click, R2 or own shot (3 s on touch; on touch only while standing still, with a 0.4 s hold) and while Grab holds a body, and ignores an "Open" within 0.5 s of an attack. T158_HitNotTalk passes (18 live prompts not clickable). Live in Studio: 30 quick clicks with the Popper on a dummy 5-9 studs away opened Talk 0 times (the prompt hid at once and came back after 2 s); E next to a calm dummy still opens it (capture).
- 21 Nov 2026, V9-0 DONE (PC) for the lab (details in FIX_PATHS_SHOP State): real foliage (FOLIAGE_V9), no grey strips (kerb runs, warm kerbs), nothing on the paving, every path end at its thing; T150 passes, T106/T112/T147/T50/T103 pass. Captures: spawn, yard, garden after. The plaza's and maps' old stone-disc paths move to V9-0d. Place saved v683 (new V3Assets roles).
- 21 Nov 2026, V9-0b DONE (PC), owner to sign off: `Config.LOOK_THUMB` + `LOOK_THUMB_LIGHT`. `Client/ZoneLighting` (thumbSky) works on this screen only; the server and the place keep the realistic sky.
  - Sky: Roblox's classic cloud skybox ("ThumbSky"), a big sun (SunAngularSize 18) behind the spawn camera's left shoulder (ClockTime 14.5 and GeographicLatitude 50 put the sun at about (-0.54, 0.71, 0.45)), plus dynamic Clouds (cover 0.58).
  - Light: Brightness 3.3, blue ambient (shadows read blue-grey), a warm ColorShift_Top, light-blue air (density 0.22, glare 0.6), saturation +0.22, contrast +0.08, a warm tint, bloom 0.4 at threshold 1.4, sun rays 0.1, no depth of field.
  - Terrain grass (96,158,62).
  - Captures: the cannon and the spawn, before and after. Phones keep the bright base light when the post effects drop at low quality.
- 21 Nov 2026, V9-0f DONE (PC):
  - `Shared/GodRules` (pure) decides who sees the GOD launcher: an owner of the pass, or during the free trial with a countdown on the square; everyone while creating is free (id 0).
  - Everyone else: no HudV3 square (`HudV3.godShown`, the left column respects it) and no phone MENU entry (`godOnly`).
  - SHOP: the GOD MODE pass card has TRY 60 s beside BUY. TRY sends Spawn "Try", the server runs `DummySpawn.tryFor` (once a visit), and the window opens. An owner sees OPEN.
  - T148 is updated and passes. Live: the square is hidden for a player without the pass. LayoutCheck shows 0 problems.
- 21 Nov 2026, V9-0a + V9-0 blind review: V9-0a scored 8.3, V9-0 scored 6.5 (fail). Fix round 1:
  - **Kerbs:** one kerb pass for the lab's Paths and Garden (`PathBuilder.finishKerbs(into, together)`, own bends included; LabGarden leaves its kerbs to it under LAYOUT_V2). Bushes and lamps avoid the garden's real curving walks (`pendingLines`).
  - **Paving check:** `overPaving` samples at most 2 studs apart and tall props only by their foot, with the paving cached per lab. Bush footprints are measured from the models.
  - **Garden:** no tree under the shed, no bed under the fountain; the rug is clearly under the yard road.
  - **Paths:** `PathBuilder.lab` has its own pcall.
  - **Talk:** every tool use (`PokeController.onUsedAlso`) and R2 count as attacks for Talk.
  - **Tests:** T150 also checks that no kerb lies across paving; T158 requires live prompts; T128 doubles the cap while the creator's GOD MODE shows. T150/T158/T148/T128/T103/T106/T147 pass.
- 21 Nov 2026, V9-0 review round 2: V9-0a 8.7 (pass), V9-0f 8.6 (pass), V9-0 8.3 (the rug only). The rug now lies on the yard grass (top 0.28) and shrinks until it reaches no path (`PathBuilder.overPaving`), so it is never level with or over the yard road.
- 21 Nov 2026, V9-0c DONE (PC):
  - **Cause:** reproduced in Studio. Seated, `AvatarMoves.ownAim` treated the driver as "standing" (no MoveDirection) and turned the body to the mouse / screen centre. The body is welded to the seat, so the car followed the camera and drove in circles: with AimTestPoint 90 degrees to the side the heading went 47 -> -33 in 2 s with no input.
  - **Fix:** a seated body never turns (ownAim and AvatarMoves.play) and has no aim pose (it sits upright). After the fix, the same check turns 0 degrees.
  - **Drive:** `Shared/CarDrive` (pure), used by VehicleClient: eased steer (back to 0 within 0.25 s), a speed-scaled turn (none on the spot, flipped in reverse), stronger braking against the roll, reverse, and a self-righting nudge when tipped.
  - **Speedometer:** `Client/Speedometer`, a round gauge with a sweeping needle, km/h, a D/R/N chip and a red zone at top speed. It pops in when seated and sits just above the tool bar on every screen.
  - **Tests:** T153_CarDrives passes for Car and Truck (0.0 degrees in 3 s on throttle, left/right, stops turning, brake + reverse, gauge); T52 still passes.
  - **Not done:** separate GAS/BRAKE pedals on phones. The thumbstick drives (X steer, Y throttle), and the circle on phones came from the same body turn (screen-centre aim).
- 21 Nov 2026, V9-0g DONE (PC):
  - **Rules and state:** `Shared/NoticeRules` (pure) and `Client/NoticeState` (who fired when: PokeController.onUsedAlso and own shots; the phone test; the setting).
  - **Toast:** on a phone (Settings "Notices" AUTO = small) a notice is one pill at most 45 % wide and 40 px tall (48 upright) with 15 px text, shows for 1.4-3 s, and only one waits.
  - **Banners:** BULLSEYE!, KNOCKED OUT! and the rest become that small pill; in a fight only priority-4 ones show, the rest are dropped.
  - **Notify:** in a fight (a shot in the last 1.5 s) only critical notices show.
  - **KO counter:** "+1 TAKEDOWN" repeats merge into one small "KO xN" counter just under the crosshair.
  - **Unlocks:** an unlock's big reveal waits for 2 s without a shot (or is skipped after 20 s); the "NEW: X" line shows at once.
  - **Settings:** "Notices" AUTO / NORMAL / SMALL / MINIMAL, saved in the profile (ProgressService SETTING_CHOICES).
  - **Checks:** T162_PhoneNotices passes; T100/T147/T45 pass; LayoutCheck shows 0 problems. In the phone simulator (iPhone 17 Pro landscape, 750x381) the BULLSEYE line is a small top pill and 5 KOs read "KO x5".
  - **Left:** a LayoutCheck "notice lane" rule; the event card's chip-first on phones; the egg offer card (it opens only when calm) is unchanged.
- 21 Nov 2026, V9-0h DONE (PC), the core of it (`Config.LAYOUT_V3`):
  - **Floor:** the lab core is one open floor of big light tiles. A texture (`LAYOUT_V3_FLOOR`, art/icons/floor_tile.png, 14-stud tiles, a light grey tint) draws the tiles, so no parts lie on the floor.
  - **Paths:** no paths, verges, lamps, plaza or signposts on the floor. PathPlan V3 keeps only the yard road (from the floor's back edge) and the garden round.
  - **Spawn circle:** 40 studs (`PathPlan.HUB_CLEAR`) are kept clear.
  - **The rim:** the dummies' test row and mat sit behind the bullseye (`PathPlan.ROW_Z` -60, a 40-degree arc at r 58). The BIG RED BUTTON (`PathPlan.BUTTON_AT` (-34, 24)) and the car ramp (`RAMP_AT` (34, 34)) are out on the rim. The lab boards are the bigger wall (20x26).
  - **Tests:** T163_HubLayout passes (16 attractions on the rim at 42-82 studs). T150 accepts a path end on the floor's edge. T112/T106/T36/T50/T103/T45/T147 pass.
  - **Captures:** spawn and top-down.
  - **Left for V9-0e and later:** the Maps board near the spawn (V9-0e), a cosy deck corner, angling the board wall at the spawn, the 6+ attractions-in-one-frame check on a phone.
- 21 Nov 2026, blind review of V9-0b/0c/0g/0h: 0b 8.6 (pass), 0c 7.9, 0g 7.4, 0h 6.8. Fix round 1:
  - **0h:**
    - The Christmas sleigh moved off the moved test row to (62,-62), and the XmasSleigh obstacle with it. The Ramp and TestMat obstacles follow V3. The ramp is at (36,38), its nearest corner 42 out.
    - The lab view focuses on the row (focusOf). T112 checks the row's 3 slots in view (the spawn faces 50 degrees right). T31 allows the row's 58 studs.
    - T163 checks the nearest corner of everything that blocks and that no Christmas spot is on the row. T150 really checks YardIn against the floor's back edge (`PathPlan.FLOOR_BACK_Z`).
  - **0c:**
    - No melee lunge while seated.
    - Self-righting only when tipped past about 45 degrees, at a set rate.
    - T153's steer-release check can fail now, and T153 runs the cause live (seated, AimTestPoint 90 degrees to the side: 0.0 degrees turned).
  - **0g:**
    - A compact pill holds two lines (less padding, 50 % wide).
    - The KO counter counts always in compact mode, through the shared `NoticeRules.mergeKo`, which T162 tests.
    - In MINIMAL only priority-4 banners show. Only the newest waiting unlock reveal plays. The Notices row has its own order.
  - **0b:** a sky that replicates late is taken out too; the comment is fixed.
- 21 Nov 2026, V9-0d DONE (PC), the ground part:
  - **Scan:** `Shared/ZFight` finds overlapping flat ground layers with top faces within 0.06. At first it found 597 pairs in the lab and 800+ on the plaza.
  - **Fixes:**
    - The plaza's and maps' paths are clean walkways (thinned to bends / 12 studs) instead of rows of overlapping round stones, stop 6 studs short of their booth, and lie clear of the plaza square. On the paved plaza itself there are no path slabs at all.
    - Path joints sit 0.1 under the slabs, and every other joint and slab is 0.07 apart. Lines are 0.1 apart.
    - The verge is one grass layer; under V3 the yard road has none (the yard grass is there).
    - The test mat is 0.1 over the floor; lava beds, scorch, guide rings and bullseye rings are 0.07 apart. The garden walks are lifted, and the yard road ends just touching the garden walk.
    - The frog's pond is moved off the west garden walk (x -81 under V3).
  - **Result:** T156_NoZFight passes (4 tiny path pairs left at the yard junctions, outside the floor).
  - **Bench set:** the plaza's benches are real picnic sets: V3Assets "PicnicSet", Creator Store 79924543529998, 6 seats. It carried the known Runtime/ScreenBuilder malware, removed; a second pick (138266223570881) had it too and was dropped.
  - **Tests:** T36 (plaza budget 280, picnic sets count as seats), T106 (the plaza is paved), T42 (judges without the creator's passes). Place saved v698.
  - **Left for V9-4b:** the booths into a market row clear of the paths (T156 leaves booth parts to it).
  - **Left (time):** the town-square extras (string lights, photo spot, statue, seating groups under shade trees, pigeons, ambient town sound).
