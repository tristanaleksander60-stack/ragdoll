--!strict
-- Global build info and switches. Read-only at runtime.

local Config = {
	GameName = "Hyper Ragdoll Physics \u{1FA78}", -- (22 Nov 2026: the owner renamed it "Hyper Ragdoll Physics 🩸") -- (the owner renamed the game on Roblox, 22 Nov 2026; was "Ragdoll Havoc")
	-- Bumped with every change that goes live (round 5): SessionStats keeps it per visit, so the
	-- numbers of one build can be told from another's.
	Version = "0.78.0", -- (0.78.0, 26 Nov 2026: the owner's map, phase M1 (ground, walkways, plaza, railway, hills); 0.77.0, 26 Nov 2026: machine demos with real ragdolls, once each; 0.76.0, 26 Nov 2026: compact chip row with X-RAY, no hint strip; 0.75.0, 26 Nov 2026: one round a tap for non-automatic guns, no white blob on hits; 0.74.0, 26 Nov 2026: bullets show in the bones in X-ray; 0.73.0, 26 Nov 2026: hit reactions by where the hit lands; 0.72.0, 26 Nov 2026: a cleaner phone screen and the PC left dock; 0.71.0, 26 Nov 2026: no black screen when you are knocked; ragdolls talk about what they see; 0.70.0, 26 Nov 2026: a smoke trail behind flying ragdolls; 0.69.0, 26 Nov 2026: a quiet "come back tomorrow" line after 8 minutes; 0.68.0, 26 Nov 2026: a lab surprise about every 2 minutes with a 10 s warning; 0.67.0, 26 Nov 2026: a guard dog: whistle it at the doghouse, tap a ragdoll's arm or leg and it bites; 0.66.0, 26 Nov 2026: a failed CPR may end in a burial and a revenge attack; 0.65.0, 26 Nov 2026: wooden crates you can shoot to planks; 0.64.0, 26 Nov 2026: dust and bits by surface when a body hits the ground; 0.63.0, 26 Nov 2026: an X-RAY button: see the skeletons of the nearest ragdolls; no two bullet holes alike; buttons placed for phones; 0.62.0, 26 Nov 2026: a hit's turn and push grow with the weapon's force; 0.61.0, 26 Nov 2026: ragdolls are not afraid of weapons, 2 chat and 1 comes up to you, they come fast; 0.60.0, 26 Nov 2026: TRY at the machine, a ragdoll runs to you, the grab lesson once, +25 BOLTS a machine; 0.59.0, 26 Nov 2026: always 3 living ragdolls near you, Multiplayer as a HUD icon; 0.58.0, 26 Nov 2026: gore off: no limbs off, no bones or meat, no red, mild words; 0.57.0, 26 Nov 2026: the gift clock back on phones, gifts at 1-20 min, 150 BOLTS for trying 6 machines; 0.56.0, 26 Nov 2026: the park look: grass plots, concrete tiles, a raised plaza with 4 boards, a railway, a steel tower, soft daylight; 0.55.0, 26 Nov 2026: machines show off by themselves, a TRY! ring on the next machine, coloured zones, dummies on the test floor; 0.54.0, 26 Nov 2026: the crash-test lab (zones round a test floor, a walled compound, a sunny afternoon), a flatter MORE and a bigger hotbar on phones; 0.53.0, 26 Nov 2026: phone first (clean HUD, aim help, goal line, quiet phone), WEAPONS without BUY/TRY, the first angry dummy, minute moments, tutorial grab and maps steps, bodies never fall through; 0.52.3, 24 Nov 2026: the touch crosshair outside first person too; 0.52.2, 24 Nov 2026: on touch only the button fires; 0.52.1, 24 Nov 2026: no "another player is moving this" notice; 0.52.0, 24 Nov 2026: a ragdoll stretching machine where the ramp stood; 0.51.3, 24 Nov 2026: range piers clear of the wall and roof; 0.51.2, 24 Nov 2026: range ragdolls under the roof, desks to the walls, no holes where a burst head was; 0.51.1, 24 Nov 2026: the weapon range finished: real ragdolls, entrance, sign, lamps; 0.51.0, 24 Nov 2026: an indoor weapon range behind the creature yard; 0.50.3, 24 Nov 2026: fewer CPU spikes; 0.50.2, 24 Nov 2026: a small REVIVE button on phones; 0.50.1, 24 Nov 2026: the shot count off the weapon name, . closes the body card; 0.50.0, 24 Nov 2026: a new HUD layout: nav dock, square hotbar, one top row, phone corners; 0.49.1, 24 Nov 2026: RELOAD and AIM stacked at the edge, the body card clear of them, a small arrow when hidden; 0.49.0, 24 Nov 2026: one premium look for the HUD, bar, buttons, crosshair, top bar; 0.48.4, 24 Nov 2026: the gift opens Rewards, the egg over it; 0.48.3, 24 Nov 2026: no wooden posts for now; 0.48.2, 24 Nov 2026: scaffolds gone, a few wooden posts; 0.48.1, 24 Nov 2026: scaffolds break piece by piece; 0.48.0, 24 Nov 2026: wooden scaffolds to knock over; 0.47.99, 24 Nov 2026: no free event button; 0.47.98, 24 Nov 2026: realistic CPR; 0.47.97, 24 Nov 2026: Q closes the talk card; 0.47.96, 24 Nov 2026: no full-egg-slots notice on joining; 0.47.95, 24 Nov 2026: the arms meet at the elbow; 0.47.94, 24 Nov 2026: one head shot with a big gun bursts it; 0.47.93, 24 Nov 2026: a burst head flies in real pieces, no blob; 0.47.92, 24 Nov 2026: the head off at 2 rounds, burst at 3; 0.47.91, 24 Nov 2026: a real pistol sound always; 0.47.90, 24 Nov 2026: the same on consoles; 0.47.89, 24 Nov 2026: less sound memory on phones; 0.47.88, 24 Nov 2026: the Ford is free; 0.47.87, 24 Nov 2026: a little slower with big weapons; 0.47.86, 24 Nov 2026: aim with every gun in first person; 0.47.85, 24 Nov 2026: V works with the arms on; 0.47.84, 24 Nov 2026: the hit card shows health rightly; 0.47.83, 24 Nov 2026: only lost blood kills a ragdoll; 0.47.82, 24 Nov 2026: newspaper in the hand, no egg notice on joining, an angry ragdoll is not afraid; 0.47.81, 24 Nov 2026: a shot ragdoll may get mad, the more the nearer to dying; 0.47.80, 24 Nov 2026: untouched ragdolls help and take the newspaper too; 0.47.79, 24 Nov 2026: the owner gives VIP and ULTRA in the admin menu; 0.47.78, 24 Nov 2026: no E on the map board; 0.47.77, 24 Nov 2026: a ragdoll with a newspaper; 0.47.76, 24 Nov 2026: a map is only picked near the board; 0.47.75, 24 Nov 2026: new dashboard funnels (Funnels); 0.47.74, 24 Nov 2026: a newcomer sees the next untried slot breathe; 0.47.73, 24 Nov 2026: the face follows a head pulled by the arms; 0.47.72, 24 Nov 2026: the mech arms stay over the ground; 0.47.71, 24 Nov 2026: no 3D in the shop, ULTRA shows a nuke; 0.47.70, 24 Nov 2026: shop: ULTRA in POPULAR, GOD MODE is called Spawn Ragdolls; 0.47.69, 24 Nov 2026: the arms hint says Take off machine; 0.47.68, 24 Nov 2026: no red ball when tearing; 0.47.67, 24 Nov 2026: no first person with the arms on; 0.47.66, 24 Nov 2026: the x-ray shows 3 s after every three hits; 0.47.65, 24 Nov 2026: ragdolls help the hurt ones (FirstAid), talk by what they do; 0.47.64, 24 Nov 2026: no FEED ME signs, stars, NEW tags or lava sign in the world; 0.47.63, 24 Nov 2026: a limb is seen pulled slowly out of its joint by the arms; 0.47.62, 24 Nov 2026: a shorter pull tears a piece off with the arms; 0.47.61, 24 Nov 2026: a bigger, clearer x-ray bone on phones; 0.47.60, 24 Nov 2026: far cars drawn lighter on every device, bodies far off lighter; 0.47.59, 24 Nov 2026: cars throw their shadow with four pieces, far cars drawn lighter on phones, tablets, consoles; 0.47.58, 24 Nov 2026: the cars cost Robux again (not the bike), the phone sound fixes on every device; 0.47.57, 23 Nov 2026: phone sounds always find a loaded recording, mesh detail by distance, lighter far bodies on phones; 0.47.56, 23 Nov 2026: the x-ray bone is shot away bit by bit; 0.47.55, 23 Nov 2026: a real-looking x-ray bone, no bandage over it; 0.47.54, 23 Nov 2026: the portal gun is hard to unlock, Talk is not forced onto the bar; 0.47.53, 23 Nov 2026: takedowns are saved as what each visit added, before every teleport and more often; 0.47.52, 23 Nov 2026: x-ray through a limb shot three times; 0.47.51, 23 Nov 2026: two purples by how much a piece bleeds; 0.47.50, 23 Nov 2026: parked cars rest, less drawn on phones, no missions; 0.47.49, 23 Nov 2026: the body card opens at its size the first time too; 0.47.48, 23 Nov 2026: the body card can be hidden; 0.47.47, 23 Nov 2026: the upper body and the legs turn together; 0.47.46, 23 Nov 2026: the dead are not green, the purple stays until they wake; 0.47.45, 23 Nov 2026: only the struck piece of a limb turns purple; 0.47.44, 23 Nov 2026: smaller holes, the bike keeps to the grass and round everyone, hands on the bar; 0.47.43, 23 Nov 2026: real bullet holes, heads burst, no stars, full-speed reverse, seats on the bike; 0.47.42, 23 Nov 2026: a ragdoll rides a bike round the lab; 0.47.41, 23 Nov 2026: bones and stumps sit on the body you see; 0.47.40, 23 Nov 2026: blows hurt where they land, no hands up, lower bubbles, glossier ragdolls; 0.47.39, 23 Nov 2026: hold to hit harder; 0.47.38, 23 Nov 2026: the owner's ragdoll shape, no pinch out of first person while walking; 0.47.37, 23 Nov 2026: glossy grey ragdolls with the owner's face, purple hurt limbs and bandages; 0.47.36, 23 Nov 2026: a pale overcast day instead of sunshine; 0.47.35, 23 Nov 2026: the next weapon comes about three times sooner, a small unlock notice; 0.47.34, 23 Nov 2026: first person crosshair in the middle on phones; 0.47.33, 23 Nov 2026: bats, axes, swords and the like are held upright in first person; 0.47.32, 23 Nov 2026: picking a weapon and the first strike go to first person, no bone journal; 0.47.31, 23 Nov 2026: on a phone the picked weapon pressed again leaves the hand; 0.47.30, 23 Nov 2026: the mech arms stay on on phones; 0.47.29, 23 Nov 2026: a small first-person eye on phones; 0.47.28, 23 Nov 2026: one big action button for every tool and a RELOAD button on phones; 0.47.27, 23 Nov 2026: phones load in faster and draw less, no LAB VIEW or RAGDOLL button on phones; 0.47.26, 23 Nov 2026: the client boot no longer stops half way (gamepad, likes, catalog start again); 0.47.25, 23 Nov 2026: the hit card only for bodies you gave a creature yourself; 0.47.24, 23 Nov 2026: the multiplayer place is on; 0.47.23, 23 Nov 2026: ready for Play straight into singleplayer, multiplayer in a place of its own; 0.47.21, 23 Nov 2026: one green tiled floor over the whole lab; 0.47.20, 23 Nov 2026: every own shot is heard on phones and consoles; 0.47.19, 23 Nov 2026: three ragdolls always walk about on the spawn circle; 0.47.18, 23 Nov 2026: no TAP A DUMMY on phones; 0.47.17, 23 Nov 2026: benches the lab ragdolls sit down on; 0.47.16, 23 Nov 2026: lab ragdolls spread round the whole lab; 0.47.15, 23 Nov 2026: the ones that do not run stay put and face the gun; 0.47.14, 23 Nov 2026: only half the ragdolls run from a gun; 0.47.13, 23 Nov 2026: casings are heard when they land; 0.47.12, 23 Nov 2026: on a phone a tap on a ragdoll grabs it; 0.47.11, 23 Nov 2026: the shark swims under water with its fin up, the whole rocket flies; 0.47.10, 23 Nov 2026: CPR and punches are seen; 0.47.9, 23 Nov 2026: shots stay until dead and alive again, CPR really works 33%, else mostly attacks, new CPR moves; 0.47.8, 23 Nov 2026: zombies gone, every 3rd failed CPR attacks, one look through the join; 0.47.7, 23 Nov 2026: softer, matte ragdolls; 0.47.6, 23 Nov 2026: every shot stays on a body and on its card; 0.47.5, 23 Nov 2026: a killed zombie loses its ZOMBIE text at once and wakes up normal; 0.47.4, 23 Nov 2026: the mouse works in every window in first person (weapons, maps, multiplayer), and they stay open; 0.47.3, 23 Nov 2026: the compressor at its original size, back in the lab, in machined steel; no Reloading notice; 0.47.2, 23 Nov 2026: one loading screen on the way to your own server at a join, the first player of a server is sent on too, 3 slots and only the next locked weapon, the owner watches people in singleplayer; 0.47.1, 23 Nov 2026: the mech arms fold back after Q (their rest pose kept on each joint, not in a weak table); 0.47.0, 23 Nov 2026: someone passing through a multiplayer server on the way to their own gets no lab built there (no lag for the players who stay); a failed teleport gives them one after all; 0.46.9, 23 Nov 2026, multiplayer bug hunt: arrivals go straight into the shared lab (no own lab built and torn down), the cover lifts for guests at once (no 12 s wait), a guest's events and place are the shared lab, not the plaza, guests use the sandbox buttons and GOD MODE in it; 0.46.8, 23 Nov 2026: multiplayer never takes over someone else's own lab; a friend who follows someone in a shared lab joins it; 0.46.7, 23 Nov 2026: the mech arms hint under the Next pill, X takes the arms off (no revive-all while you wear them); 0.46.6, 23 Nov 2026: the mech arms fold onto your back at rest, reaching forward only while you hold Q; 0.46.5, 23 Nov 2026: the shark no longer jitters back and forth over the water; 0.46.4, 23 Nov 2026: singleplayer by default: joining through Play takes you to a server of your own; public servers are the multiplayer servers (in through the portal); on your own server only the MULTIPLAYER portal (the server list), on a multiplayer server also SINGLEPLAYER back to your own; 0.46.3, 23 Nov 2026: the SINGLEPLAYER portal is back (out of the shared lab), the MULTIPLAYER portal opens the server list again with PLAY WITH EVERYONE HERE on top; 0.46.2, 23 Nov 2026: when the host of a shared lab leaves, a guest takes it over as it is: no reset, nobody moved; 0.46.1, 23 Nov 2026: no start menu, you join in your own lab; one MULTIPLAYER portal: in = the shared lab with the others on this server (no teleport unless you are alone), again = back to your own lab; 0.46.0, 23 Nov 2026, phase D: the chicken pecks, sits, lays an egg that hatches; the washer door, a ragdoll spinning behind the glass in red water; the plant's jaws snap, chew and spit bones; the mole drags bodies under and bursts up elsewhere; the slingshot trees bend and whip; the shark patrols its tank and the water foams; a warning before every event; cannon smoke and recoil; 0.45.8, 23 Nov 2026, phase D: the frog turns to its catch, puffs its throat, a sticky tongue reels the body in, a lump kicks in its belly, then it burps slime and bones; 0.45.7, 23 Nov 2026: the mech arms rise over the shoulders and curl forward, the lower pair stands like legs; steel tubes with pistons, joint housings, jointed claws; 0.45.6, 23 Nov 2026: SINGLEPLAYER on a public server takes you to a server of your own, so it never holds a place the multiplayer players could use; 0.45.5, 23 Nov 2026: MULTIPLAYER with no shared lab on the server puts you in another player's lab (the one here longest) instead of leaving you alone; 0.45.4, 23 Nov 2026: players sharing a lab may grab and throw each other in it, like the top ragdoll games; 0.45.3, 23 Nov 2026: in a shared lab the body goes to whoever hits it (simulated on their own machine, no round trip through the host), back to the lab's player when they leave; 0.45.2, 23 Nov 2026: HOTFIX the server boot no longer stalls ~16 s waiting for the Remotes folder (PurchaseChat, MechArms), labs come at once; 0.45.1, 23 Nov 2026: a cover from the very first frame (ReplicatedFirst FirstCover, place file), no Roblox plate before the start menu; 0.45.0, 23 Nov 2026: MULTIPLAYER goes to the server with the biggest shared lab (else the fullest; none fuller: here), and everyone who arrives through multiplayer joins that server's one shared lab; 0.44.9, 23 Nov 2026: MULTIPLAYER from two servers ends in the same lab: with no shared lab on your server you go to the one shared-lab server everyone else picking MULTIPLAYER goes to; 0.44.8, 23 Nov 2026: faster in after the start menu: the world streams in while it is up, it lifts once the lab and 3 ragdolls are in, the lab fills after 2 s at most; 0.44.7, 23 Nov 2026: no green outline on a ragdoll you point at, the view bobs as you walk and run in first person, both hands on the weapon (first person and on the run), the multiplayer portal only changes server; 0.44.6, 23 Nov 2026: hold Q and pull to rip again (no clicks), the stand turns its arms to you, no Roblox plate after the start menu, MULTIPLAYER puts everyone in one shared lab on the server, the two portals on the spawn circle's rim; 0.44.5, 23 Nov 2026: WEAPONS on the hotbar from the first second, the start menu waits until the whole world is in, MULTIPLAYER opens a hub: one lab together, friends to join, every server, your own server; 0.44.4, 23 Nov 2026: the mech arms rest behind you, Q grabs a limb (the body holds still), clicks rip it with blood and a widening wound, strands of flesh as it comes off, seen in first person; no [T] under WEAPONS; the start menu stays until the lab is in; 0.44.3, 23 Nov 2026: the mech arms move (joints by C0), hold Q on a limb and pull to rip it off (a strain bar), no flicker on the stand, the view turns freely by it; 0.44.2, 23 Nov 2026: the mech arms work (their remote was made before the Remotes folder; the same fix for the purchase chat and WASTED), their stand beside the LIKE GOAL post; 0.44.1, 23 Nov 2026: the start menu buttons in the middle, hopping, SINGLEPLAYER left, a pick always shows (a squish and a line); 0.44.0, 23 Nov 2026: one ragdoll comes running in shock and gives CPR, the dead lie 20-30 s, MECH ARMS on a stand by the spawn: E to wear them, Q to tear ragdolls apart; 0.43.1, 23 Nov 2026: no "See their pulse" notice, animals only come for you when you shoot them from close by, 2 head shots take the head off (spine sticking up, blood spurting), the WEAPONS key chip shows, casings fall out, land and clink, the start menu over our thumbnail; 0.43.0, 23 Nov 2026, V11 phase D 1: a light flash on every shot and blast by weapon; ragdolls are shocked by the dead, kneel and mourn them, try CPR (it sometimes works); 0.42.0, 23 Nov 2026, V11 phase C: a 3D start menu (SINGLEPLAYER or MULTIPLAYER), MULTIPLAYER takes you to a server where everyone shares one lab, SINGLEPLAYER brings you back; 0.41.0, 22 Nov 2026, V11 phase B: a new portal gun (white with a green glass core) and green swirling portals that players walk through too, unlocked at 4 takedowns; Robux purchases in chat on every server; 0.40.0, 22 Nov 2026, V11 phase A: no pop-ups (red counters on the gift and WEAPONS, a "!" on the gift for an egg: tap it to open), no takedown message, the picked slot key again empties the hand and leaves first person, only the rocket flies; 0.39.6, 22 Nov 2026: dead ragdolls say nothing; 0.39.5, 22 Nov 2026: a big CLOSE button on the free egg window; 0.39.4, 22 Nov 2026: 3 rounds in the hips cut a ragdoll in half at the waist, blood spurting from both ends, bones showing; 0.39.3, 22 Nov 2026: ragdolls shine less (no reflection), zombies never flee, WASTED when a zombie kills you; 0.39.2, 22 Nov 2026: no round thigh tops sticking out at the hips: the hips reach down over the joint instead; 0.39.1, 22 Nov 2026: a key chip on the WEAPONS button; 0.39.0, 22 Nov 2026: every 3rd lab dummy killed rises as a green zombie (red outline, ZOMBIE tag) that hunts and hits its lab's player; killed again it wakes up normal; 0.38.9, 22 Nov 2026: a soft overcast light like the biggest ragdoll game (no harsh sun), glossy ragdolls (smooth plastic, a little reflection, head and body alike); 0.38.8, 22 Nov 2026: the thighs reach up into the hips; 0.38.7, 22 Nov 2026: ragdolls flee at half the speed, skins no longer overlap at the joints, bullet holes sized by the weapon (a pistol small); 0.38.6, 22 Nov 2026: Shop/More/Lab keys open their windows (one toggle), no crash-test logo, the like sign's posts beside its text, bullet holes on the true skin surface, skins the head's plastic; 0.38.5, 22 Nov 2026, V10 phase 4: a MAPS board at the plaza, the lab board beside the red button, the button's event in every lab on the server, a wooden LIKE GOAL post; 0.38.4, 22 Nov 2026, V10 phase 3: shoot an animal and it eats you (WASTED, back in your lab), every creature tears and bleeds, melee swings in first person, the crash-test marks on the body behind the holes; 0.38.3, 22 Nov 2026: key chips show the key, WEAPONS always shows its key, no holes on edge grazes, EQUIP in first person puts it in your hand, press yourself flat, cars explode and come back; 0.38.2, 22 Nov 2026, V10 phase 2: the name Hyper Ragdoll Physics, cars free, a wiggling gift, key chips on Shop/More/Lab, matte ragdolls, flat bullet holes, no pictograms, the talk wand pointing ahead, a solid shark, takedowns from the press, the creatures and the rocket; 0.38.1, 22 Nov 2026: phones play in landscape (LandscapeSensor) and keep the next 3 weapons on their own row; 0.38.0, 22 Nov 2026, V10 phase 1: fewer lab ragdolls on phones (9) and tablets (13), a load cover until the lab and its ragdolls are in, the next 3 weapons from the first second (upright phones too), the phone crosshair only where you shoot, no Replay on phones, a "loaded" funnel step; 0.37.20, 22 Nov 2026: the weapons menu works in first person (stays open, the mouse is free while a window is up); 0.37.19, 22 Nov 2026: the crash-test marks hide with the body in the press; 0.37.18, 22 Nov 2026: the giant fan out of the portals' way, E at the rocket straps a ragdoll on and it flies and bursts; 0.37.17, 22 Nov 2026: the compressor posts run from the footing up into the top beam, with foot plates and side braces; 0.37.16, 22 Nov 2026: the compressor 3x instead of 10x, just behind the lab; 0.37.15, 22 Nov 2026: the compressor 10x bigger, standing behind the lab past the portals; 0.37.14, 22 Nov 2026: the portals and the MAPS board where the white target blocks stood, behind the spider; no stone path under them; the spider further forward; 0.37.13, 22 Nov 2026: the Silvia and the Ford turned the right way, the boxing ring in the west garden by the frog, the portals and the MAPS board between the launch and the danger areas; 0.37.12, 22 Nov 2026: three new vehicles (Silvia drift car, Ford truck, Panzer tank) behind game passes, the old cars gone; the spider wraps a still copy in the web while circling it; 0.37.11, 22 Nov 2026: fixed the empty lab (a comment broke Playground), a slide you cannot climb that carries you down, the spider bites, wraps and drains its catch, the shark drags it under, the water goes red and it spits bones with meat; 0.37.10, 22 Nov 2026: no castle, a giant trampoline under the tower that throws higher, no flicker on the tower top, the slide starts from an open platform; 0.37.9, 22 Nov 2026: a sky bridge between the towers, a slide down from it, a sky deck and six jump steps up to it; 0.37.8, 22 Nov 2026: no spinning mace, the shark tank in its place, no paths in the lab (only the plaza and the platforms); 0.37.7, 22 Nov 2026: harder cannon, cannon and wrecking ball tear pieces off, no walk across the launch area, no "Wobbly", no stars over the pancake; 0.37.6, 22 Nov 2026: the press: a ragdoll-shaped pancake with its face, a slow squeeze, a wet splat, blood dripping off the bed; the face hides with the body; 0.37.5, 22 Nov 2026: one walk per area from the plaza to its ground, no bench or flower beds on the plaza, lamps between the walks; 0.37.4, 22 Nov 2026: the game is called Hyper Ragdoll Physics; 0.37.3, 22 Nov 2026: no shot count by the crosshair (the reload ring stays), narrower walks with round ends, a stone floor under the boxing ring, the spider in front of the spawn instead of the black mat; 0.37.2, 22 Nov 2026: the travel corner on a stone platform, the launch pads all on their area, the boxing ring behind the spawn, the spawn faces the cannon and the wrecking ball; 0.37.1, 22 Nov 2026: lab spread 1.2, four themed areas (launch, cars, danger, height) with their own ground, cars and stations moved into their areas, props fill the gaps, lamps and benches on the plaza; 0.37.0, 22 Nov 2026: a much bigger lab (LAB_SPREAD 1.6): machines further out, a lawn with a stone plaza at the spawn and paved walks to every machine; 0.36.9, 22 Nov 2026: a cut-off limb leaves a real stump (flesh, bone, drops), not a disc; 0.36.8, 22 Nov 2026: arms, forearms, hands, legs, shins and feet come off after enough rounds; the card shows the name, the shots and missing pieces; 0.36.7, 22 Nov 2026: ragdolls say a line for where they are hit, small text, one at a time; 0.36.6, 22 Nov 2026: bullet holes sit in the ragdoll, the monitor card shows only Blood and Awake with the bones; 0.36.5, 22 Nov 2026: Talk works in first person (the mouse is freed while its card is up); 0.36.4, 22 Nov 2026: 2X, Next and gift centred over the hotbar; 0.36.3, 22 Nov 2026: 2X and the gift match: dark circles, same size, same gap round the Next pill; 0.36.2, 22 Nov 2026: 2X is a round icon like the gift, the three sit a little lower; 0.36.1, 22 Nov 2026: the 2X chip, the Next pill and the gift side by side in the top bar; 0.36.0, 22 Nov 2026: Shop, More, Lab on the left; no God or Maps squares; 0.35.9, 22 Nov 2026: the next-weapon pill on the gift's line, centred, 1.2x; 0.35.8, 22 Nov 2026: a bigger next-weapon pill under the top bar; 0.35.7, 22 Nov 2026: ragdolls go into the cannon and fly out of its muzzle; 0.35.6, 22 Nov 2026: a much nicer Talk wand; 0.35.5, 22 Nov 2026: no E talk prompt at the ragdolls; 0.35.4, 22 Nov 2026: smaller hit card, an attacker turns and walks 2.5 s first, ATTACK WHO lists 8 from the whole lab, steady marking; 0.35.3, 22 Nov 2026: an NPC with a gun shoots from 30 studs; 0.35.2, 22 Nov 2026: ATTACK fights until the other one is dead, the wand is "Talk" with a drawn icon, green and red outlines in the talk card; 0.35.1, 22 Nov 2026: the wand in your hand with its own icon, its talk card stays open, the sign posts stop under the board; 0.35.0, 22 Nov 2026: the Magic Wand (talk) on the start bar, funny NPC names, the monitor when you point at a ragdoll close by, carry ragdolls into the press; 0.34.13, 22 Nov 2026: the next-weapon pill in the middle of the top bar, right click no longer throws a held ragdoll, the grab passes through the press frame; 0.34.12, 22 Nov 2026: the free event button is a small stand with a sign, every 5 minutes; 0.34.11, 22 Nov 2026: small dressing parts cast no shadows (less lag); 0.34.10, 22 Nov 2026: a ragdoll carried into the press is not pressed or blown away until you let go; 0.34.9, 22 Nov 2026: recoil in first person, the press ram follows the plate, pressed ragdolls go flat as pancakes; 0.34.8, 22 Nov 2026: shots go exactly through the crosshair, no steering wheel over cars, the kart's own seat is off; 0.34.7, 22 Nov 2026: windows close by themselves in first person, the eye chip is first person (V); 0.34.6, 22 Nov 2026: white ragdolls, a slow rot on death that fades before they wake, no Dizzy text; 0.34.5, 22 Nov 2026: no first person on the first shot; 0.34.4, 22 Nov 2026: the crosshair follows the recoil, one crosshair on phones, lab dummies fear guns; 0.34.3, 22 Nov 2026: no mission card; 0.34.2, 22 Nov 2026: 18 lab dummies and no other ragdolls, the car starts in the chase camera; 0.34.1, 22 Nov 2026: guns fire again, lab dummies roam the whole lab from the start; 0.34.0, 21 Nov 2026: a supercar, a jeep and a go-kart in every lab, smoother steering; 0.33.7, 21 Nov 2026: no feed computers or feed buttons, you throw the ragdoll in; 0.33.6, 21 Nov 2026: terminals and the Map Board: the view turns freely, presses work close up, left click only; 0.33.5, 21 Nov 2026: the view turns freely near a terminal; 0.33.4, 21 Nov 2026: skip or hide missions, keys for everything (E use, - skip, = hide, 7 GOD, 8 LAB, 9 MORE); 0.33.3, 21 Nov 2026: weapons sit in the hand on every avatar, running dummies over is a KO; 0.33.2, 21 Nov 2026, V9-NOW 24: no hold E, press the thing itself; 0.33.1, 21 Nov 2026, hotfix: the bow shot one arrow but looked and sounded like two, a feed terminal stood in the wrecking ball's arc; 0.33.0, 21 Nov 2026, V9-NOW 17-21: no bullseye, no neon glow, the crash wall badge out of the wall, a travel corner (MAPS board + portals), KOs from every event you start; 0.32.0, 21 Nov 2026, V9-NOW 11-16: target blocks that topple, the 2X KO + BOLTS event, What's New closes itself, the monitor in the corner, cars with a cockpit and sounds; 0.31.1, 21 Nov 2026, V9-NOW hotfix: bullet holes on every dummy, a reaction by where it is hit, one map place (the board); 0.31.0, 21 Nov 2026, V9 milestone 1: GOD MODE free in the beta with aimed patterns, the time dial (Z), grey matte ragdolls, the first shot in first person, bigger unlock gaps, the 3D shop, codes, the town square, padded hub floor, always a ragdoll to shoot; 0.30.0, 21 Nov 2026: wide paths (twice as wide, no stub at the bullseye), GOD MODE: create life with a free 60 s try; 0.29.0, 21 Nov 2026: connected path network with a plaza, grass verges with bushes, a real lava pit, icons instead of words, a full 6-weapon start bar, toss buttons at the cannon, lava and trampoline, fewer pop-ups; 0.28.0, 21 Nov 2026: every weapon its own sound, a 4-tool start bar with Launch at 3 and the Rocket among the hardest, SURPRISE-style banners, nicer lab paths, a FEED button, sign and drop ring at every creature and station; 0.27.1 UI audit before the ads, 21 Nov 2026: one WEAPONS button, a quiet start, signs in the world, knockable barrels/crates/cones, the weapon in your hand in 3D; 0.27.0 V8-1..6: CRASH score and the long cannon arc, missions, readable hits, fair chase, spawn dummies, streak freeze, admins, 21 Nov 2026; 0.26.0 V8-0: the first hit lands, a full bar from the start, a calm first minutes, the cannon in view, 21 Nov 2026; 0.25.0 v7: paths, crash-test dummies, event banner card, console layout, 20 Nov 2026; 0.24.0 v6: notifications, admin and director menus, bigger lab with garden, creature yard, birds, map shop, 20 Nov 2026; 0.18.0 phase 0; 0.19.0 phases 1-3; 0.20.0 the release; 0.21.0 v3 look, cars, animals; 0.22.0 open-air maps, launchers, disasters, train, throw tower, 19 Nov 2026; 0.23.0 v4: talk to NPCs, real gorilla and bulls, 11 surprises, cars, slow-mo, lab zones, 20 Nov 2026; SessionStats also keeps game.PlaceVersion)
	Phase = 3,
	-- Heavy weapons and close blasts can cut a limb off (round 2, N2). Roblox lists severed body
	-- parts as Restricted (18+, ID-checked players only): switching this off keeps the game at a
	-- lower maturity label (purple blood counts as unrealistic) without touching anything else.
	-- PHASE 0 (19 Nov 2026) CHANGED THE DEFAULT, owner decision recorded in CLAUDE.md: was true. Set
	-- it back to true to allow severing again (Restricted risk).
	SEVERING = false, -- (BODY_V2 0, owner 26 Nov 2026: gore off for the maturity questionnaire; was true since 0.36.8: limbs come off after enough rounds)
	GORE = false, -- BODY_V2 0 (owner, 26 Nov 2026): no bones, meat, red, rips, splats or bone shot away; mild words (KO, knocked out, OUT COLD, Energy). true = the old gore look
	ALWAYS_THREE = true, -- ALWAYS3 (owner, 26 Nov 2026): always 3 living ragdolls within 35 studs; far ones run in, near ones walk in and say a line (Lab)
	FEAR_WEAPONS = false, -- ALWAYS3 update (owner, 26 Nov 2026): not afraid of weapons as such (GunThreat, Lab heard); they react only to real hits
	XRAY_V2 = true, -- BODY_V2 1: an X-RAY button (touch) and the B key show the nearest bodies in X-ray, whole skeleton (Client/XRayToggle, DummySkins.setXray)
	HOLE_VARIETY = true, -- (owner, 26 Nov 2026: no two bullet holes alike, even from one pistol): size, oval by angle, tint, picture, stress ring, edge chip (BulletHoles)
	IMPACT_FX = true, -- IMPACT_FX 1 (owner, 26 Nov 2026): a body hitting the ground throws up dust and bits of that ground, scaled by speed, a shock ring at 70+ (Client/ImpactDust)
	BREAKABLES = true, -- DESTRUCTION 2 (owner, 26 Nov 2026): wooden crate stacks: shot holes, 4 rounds or a blast or a flying body break them into planks, back after 20 s (Systems/Breakables)
	BURIAL = true, -- BODY_V2 4 (owner, 26 Nov 2026): a failed CPR may end in a burial (shovel, dig, grave with R.I.P.) and a revenge attack with one cringe line (Mourning)
	GUARD_DOG = true, -- GUARD_DOG (owner, 26 Nov 2026): a doghouse, Whistle (E), the dog follows; tap a ragdoll's limb and it bites exactly that limb (Systems/GuardDog, Client/GuardDogClient)
	WHEELCHAIRS = false, -- (parked: needs a wheelchair model and its own run; docs/WHEELCHAIRS.md)
	COME_BACK_AT = 480, -- STAY_LONGER 8: s of play before the quiet "Come back tomorrow: day N gift!" line (once a visit; LabShowcase). nil = off
	FLIGHT_TRAIL = true, -- IMPACT_FX smoke trail: a thin grey trail behind a ragdoll flying faster than 60 studs/s (Client/FlightTrail; 3 at once on phones, 6 else)
	CANNON_MUZZLE_LOAD = true, -- F7: no launch plate; a ragdoll let go at the glowing spot under the muzzle slides in and is fired (false = the old pad)
	NO_BLACK_SCREEN = true, -- F3: while your own body is loose the camera stays out in third person on the head (Client/NoBlackScreen); WASTED never darkens
	TALK_CONTEXT = true, -- F8: ragdolls talk about what is in front of them: a machine, your weapon, the dog, a grave (Shared/TalkLines; one line every 4 s)
	PHONE_CLEAN = true, -- F6: on a touch screen no key chips or slot numbers, no body-card arrow or first-person button, RELOAD only when the clip is low (Client/PhoneClean, TouchShoot)
	HIT_REACT_V2 = true, -- F2: hit reactions by the exact spot and direction, 3 variants each, scaled by force; arms only rise for head or upper-chest hits (Ragdoll/Poses.hitReact)
	XRAY_SLUGS = true, -- F4: every round shows as a small slug in the bone in X-ray at its exact spot (max 15 a limb); heavy rounds leave a crack line there, very heavy a snap (DummySkins.xrayBone)
	NO_WHITE_HIT = true, -- F14: no white puff or white body flash round shots (FxController): grey dust, chips and the purple splat only
	CPR_FACE = true, -- F15: the CPR helper kneels level with the chest, turned to it, and re-aims before each round of compressions (Mourning)
	REVIVE_CHIP = true, -- F13: the bottom-left time chip becomes REVIVE ALL (heart, its ReviveAll key, click works too) (HudV3)
	HINT_STRIP = false, -- F17/F20: no input-hint strip under the hotbar on any device (PokeController)
	XRAY_CHIP = true, -- F21: an X-RAY chip (key I, Keybinds XRay) in the bottom-left chip row, lit while X-ray is on; D-pad left on a pad
	DEMO_REAL = true, -- F19: every 45-60 s a REAL lab ragdoll is thrown by one machine, each machine once a visit, never where you stand or during TRY (Systems/MachineDemos)
	SPAWN_FEW = true, -- F18: only 3 lab ragdolls walk about near the spawn (the test floor); the other 15 roam out by the machines (Lab.PLAZA_SLOTS)
	LAB_OWNERMAP = true, -- GO NOW: the owner's map from the screenshots, 10x the area (Systems/LabOwnerMap, built phase by phase; plots 1100 apart). false = the LAB10 park lab
	MECH_ARMS = false, -- map round 2 (owner): the 4 mech arms are gone (MechArms off, the stand hidden by LabOwnerMap)
	BOARD_TOP20 = true, -- map round 2 (owner): the 4 leaderboards show the top 20 in a scrolling list, 5 rows in view (LeaderboardService)
	SPAWN_UPRIGHT = true, -- OVERVIEW 0.5: ragdolls on the raised spawn plaza are set on top of it, upright, once the map stands (LabOwnerMap)
	MACHINE_WATCHERS = true, -- OVERVIEW 0.7: a real ragdoll watching at the 4 machines nearest you (Systems/Watchers), light stand-ins at the rest (Client/WatcherStandIns); spots: Shared/WatchSpots
	NEVER_ZERO = true, -- OVERVIEW 0.8: no living ragdoll within 35 studs for 1 s: the nearest free one comes running (Systems/Watchers)
	LOOK_AT_TALK = true, -- OVERVIEW 0.9: a talking ragdoll turns its head (and waist) to you; chatters look at each other (Client/DummyLife)
	NO_OVERLAP = true, -- OVERVIEW 0.95: walkers keep 2.6 studs of personal space and step off harder (Ragdoll/ActiveRagdoll avoidDummies); bodies already collide
	SPAWN_11 = true, -- OVERVIEW 0.97: the spawn plaza set (welcome arch, rose, fountains, flags, signpost, statues, board frames, gold #1 statues: LabOwnerMap spawnSet) and the moving parts (Client/GateMotion)
	ROOM_GATES = true, -- OVERVIEW 0.97: a themed gate with 3D letters and a moving part at every room entrance instead of the flat banner (LabOwnerMap themedGate)
	SPAWN_GLIDE = true, -- OVERVIEW 0.97: a newcomer's first join starts with a 2.5 s camera glide down to the player (any key skips; Client/GateMotion)
	SPAWN_TITLE = "RAGDOLL ANATOMY", -- the welcome arch's 3D title (the game's name since 27 Nov)
	DEMO_WALK = true, -- F31 / OVERVIEW 0.98: a machine demo starts with a ragdoll saying a line and WALKING to the machine, then hopping in (Systems/MachineDemos); only within 80 studs of the player
	MAP_MACHINES_LIVE = true, -- map round 3: the gyro cage catches, tumbles and flings; the shredder hides, confettis and spits out (Systems/MapMachines); the gyro rings turn on the client
	TREES_V2 = true, -- OVERVIEW 1a: trees and bushes from V3Assets/YTrees (textured bark + leaf canopies, mixed species, 5 greens, rare autumn, lean) instead of the flat green meshes (LabOwnerMap yTree)
	ROAD_WALKERS = true, -- OVERVIEW 1c: 3 groups of 2-3 ragdolls walk the outer ring / boulevard side by side, stop to chat every 20-40 s, say "Hi!" (Systems/RoadWalkers)
	BRICK_WALL = true, -- OVERVIEW 1d: the crash wall breaks one brick at a time with gravity (hybrid panels, sleeping debris, cap 50; Systems/BrickWall)
	SOLO_HIDE = true, -- OVERVIEW 2 / F30: in the START place, other players (characters, name tags, sounds, effects) are hidden on this screen if a server ever holds 2+ (Client/SoloHide)
	M10_CANNON = true, -- MACHINES_10 3.1: the cannon's fuse spark + "Cover your ears!", then the landing distance pops ("123 studs!", NEW BEST, 1 in 20 GOLDEN) (Playground cannonWindUp/cannonScore)
	RAGDOLL_NAV = true, -- OVERVIEW 0.95: every walk longer than 8 studs follows a PathfindingService path (radius 2, no-go lava/water/beds/rails), with a stuck guard (Systems/RagdollNav)
	SIGNS_V2 = true, -- F39: every name sign is a framed board on 2 side posts (nothing across the text), in its room's material and colour, with bolts, an outlined chunky text and the room pictogram (LabOwnerMap signV2)
	LAMP_LINT = true, -- F40: no lamp within 2 studs of ANY walkable surface (roads, paths, plazas, Tower Square, station, courtyards) (LabOwnerMap onWalkable)
	PROP_CLEAR = true, -- F44: yard benches, signs and props only go where nothing stands within 3 studs (GetPartBoundsInBox; next spot if blocked) (LabOwnerMap freeSpot)
	NO_WHITE_RINGS = true, -- F41: no pale stress ring and no white rim round the bullet holes (the hole picture tinted darker) (Client/BulletHoles)
	WALK_SETTING = false, -- F38: Settings > Walk speed: NORMAL / FAST 34 / VERY FAST 40 / CALM 20, saved in the profile; sprint is 1.5x it (Client/Settings, Client/Sprint) (F83: off, the owner wants Roblox's standard walk speed)
	UNSTICK = true, -- F32: invisible solid walls along every tree belt (gaps at the entrances, NoGo for paths), and a ragdoll stuck inside anything solid for 1 s is moved to the nearest free spot (Systems/Unstick)
	WATCHER_STANDINS = false, -- F45: the yellow watcher stand-ins are gone; real grey watchers walk to the 5 machines within 90 studs (Watchers)
	NO_DEATH_FREEZE = true, -- F46: a dead or knocked-out body that hangs still in the air for 0.6 s is unanchored and pushed down (Systems/Unstick deathGuard)
	LAG_GUARD = true, -- OVERVIEW 0.1: on each screen no light casts shadows, lights beyond 140 studs are off, every sign/billboard has a view distance (150), phones: no canopy shadows (Client/LagGuard)
	RAGDOLL_DIRECTOR = true, -- OVERVIEW 0.1 B: ragdolls 140+ studs from every player and not in use are Parked (the simulating screen skips their brain and pose); woken within 120 (Systems/RagdollDirector)
	FAST_THREE = true, -- OVERVIEW 0.15: the 3-near check every 0.25 s, recruits sprint (Pace 2.5), one over 110 studs away is set down out of view 30-40 studs behind you first (Lab alwaysThree)
	FOLIAGE_PASS = true, -- F54: trees, bushes and hedges have no collision (players, cars and bodies pass through); the belt walls are group RagdollBlock (ragdolls only)
	TREE_CLEAR = true, -- F53: 4 s after the map stands, every tree/bush with its foot within 4 studs of a building, wall, machine or sign is removed (LabOwnerMap build)
	CAR_STAY = true, -- F56: no automatic eject: a car is only "off" when it fell out of the world or is 700+ studs out (it goes home WITH the driver); OutOfBounds moves the whole car (VehicleService, OutOfBounds)
	PAD_CARS = true, -- F57: the 3 launch pads launch cars (the server takes the car for 0.6 s and sets its speed; small/medium/BIG) and ragdolls; AIR TIME pop + NEW BEST (Systems/LaunchPads)
	PHONE_HIT_CARD = false, -- F66: no hit card ("Chest . Belly ... 0% health . KO") on phones; PC and console keep it (Client/HitInfo)
	LEADERBOARD_EXCLUDE = {} :: { number }, -- F61: userIds kept off every leaderboard (the creator/group owner, Owner.isOwner players and the admins are added by themselves) (LeaderboardService)
	LEADERBOARD_EXCLUDE_NAMES = { "RolingStudios" }, -- F61: the owner's known accounts, looked up by name at start
	NEARBY_CAP = true, -- OVERVIEW 0.158: living ragdolls within 45 studs capped per device (phone 7, tablet 9, PC 12); the extras walk away 90 studs, never removed (RagdollDirector)
	PEN_TO_PLAN = true, -- F55: the T-rex pen is its plan size (100 x 46), gate in the WEST wall, so it no longer stands across the Animal Cove path (LabOwnerMap)
	LEG_JITTER_LOG = true, -- F65: an always-on detector logs any ragdoll whose knee reverses 6+ times a second (state, role, Home changes, feet, fps) (Client/LegJitter)
	SLIDE_V2 = true, -- F58: the tower slide is ONE smooth chute (a curve cut into 4-stud pieces), legs every few pieces, an opening in the roof railing with a SLIDE sign, a soft mat at the run-out (LabOwnerMap hero)
	HOLES_KEEP = 4, -- F60: the newest 4 bullet holes on each ragdoll stay sharp; older ones fade out over 2 s (Client/BulletHoles)
	V_TOGGLE_WINS = true, -- F64: leaving first person with V (or the eye button) is the player's choice: no weapon pick, strike or shot puts them back in until they press V again (Client/FirstPerson)
	TOWER_STAIRS_V2 = true, -- F67: real switchback stairs in the tower (two 8.5-stud lanes, half landings, 18 studs headroom, smooth ramp, rails, lights) + Invisicam inside (LabOwnerMap, Systems/TowerCam)
	XRAY_TORSO = true, -- F59: X-ray torso skeleton (spine, sternum, 6 ribs a side, shoulder blades, collarbones, pelvis); each torso hole puts a slug on the bone it reaches first, cracks by force (Client/DummySkins)
	NEARBY_TWO = true, -- 0.1566 THE 2 NEARBY: 2 more living ragdolls live their own life 35-60 studs from each player; when one of the 3 dies, a close-by one WALKS over first (Systems/NearbyTwo, Lab alwaysThree)
	DRAWN_TO_YOU = true, -- 0.1567 DRAWN TO YOU: a free ragdoll's next roam goal is a path spot 60-120 studs from its nearest player, in the emptiest direction, 4 studs from other goals (Lab roam)
	PHONE_NO_KEYS = true, -- F70: one rule for HUD key letters (ViewMode.showKeys: a keyboard and no touch screen); none on any touch screen, the gift's J included
	NAV_WEAPONS = true, -- F63: the left nav's MORE becomes WEAPONS (toolbox, T); the hotbar toolbox only shows as CANCEL; MORE is a gear in the top bar (9) (HudV3, PokeController)
	BACK_TO_SPAWN = true, -- F80: BACK TO SPAWN as MORE's first row: a fade, the server sets you on a free spot of the spawn plaza facing the boulevard (Net Teleport, 5 s cooldown; Systems/BackToSpawn)
	PHONE_MINI_BAR = true, -- F71: on a phone the hotbar rests at 0.6 size; one tap opens it (0.15 s spring), it shrinks after a pick, 4 s idle, a touch elsewhere or a window (Client/MiniBar)
	STATUE_SKIN = true, -- F77: the #1 statues keep the player's own skin and clothes, stand with their feet on the plinth (scaled to 7 x 5), on a gold-trimmed plinth BESIDE the board (LabOwnerMap)
	SMOOTH_MOTION = true, -- S1: ragdolls walk and run with Roblox's real R15 clips (KeyframeSequenceProvider, blended by ground speed, phase tied to distance: no sliding), eased in (Client/ClipGait, DummyLife gaitPose)
	IDLE_WEIGHT_SHIFT = true, -- S1: standing ragdolls shift their weight from leg to leg (slow, eased; Client/DummyLife updateIdle)
	GESTURE_LAYERS = true, -- S1: strolling ragdolls do an upper-body gesture over the walk clip every 8-16 s (phone, brow, scratch, watch, shoulder roll); standing feet tilt to the ground within 40 studs (foot IK) (Client/DummyLife layers)
	CAVE_V2 = true, -- F79: the bear cave is a Terrain rock hill with a carved arched opening, a tunnel, a dark chamber with blinking eyes, a Ground yard with half-buried rocks, a log and a stump (LabOwnerMap caveV2); no ball parts, no black slab
	ENTRANCE_ROW = true, -- F76: the herringbone vehicle row north of the CrossN walkway by the spawn (LabLayout10.ENTRANCE_ROW, LabOwnerMap entranceRow): Silvia, Ford and Panzer moved there; plaques with FREE, the price, or SOON; the Ford uses its pass when it is for sale
	VIEW_REPORT = true, -- 0.158: every screen reports its camera twice a second (Net CameraView, unreliable, validated, 4/s); RagdollDirector.inView(point) sends extras away out of view first
	PATH_WALKERS = true, -- 0.1568: client-only walkers that look like our ragdolls walk every walkway (phone 14, tablet 20, PC 30; anchored, BulkMoveTo, banded rates, fade within 26 studs of the camera; Client/PathWalkers)
	WATCHER_REACT = true, -- 0.7: a watcher cheers with a line for 3 s when a body is in its machine within 24 studs (at most every 6 s; Systems/Watchers)
	STRETCH_LONG = true, -- F74: the STRETCHER stands on the plan spot and stretches limbs long with the claws (up to 3.2x, joints kept, mass kept; Shared/Ragdoll/Stretch), never tears; full length 30 s after the release, then shrinks back over 10 s; the skins grow with the limb (Client/DummySkins)
	CAR_WALL = true, -- F48: a car crashing into the brick wall knocks a car-sized hole (by speed x weight class, measured on the server from the car's own movement; the tank ploughs through); the wall rebuilds 12 s after the last hit (Systems/BrickWall)
	TRY_AUTO = true, -- F81: TRY at a machine = its watcher or the nearest free ragdoll runs there (Pace 2.2), hops in and the machine throws it; no machine near = the old call (MachineDemos.tryAt, SessionStats)
	EVENTS_V2 = true, -- 1.0 rule 1: an event happens round the player it is for (their own spot; a covered, seated or high spot moves it to the nearest open plaza or walkway crossing within 90 studs; EventService eventSpot)
	PICK_OUT = true, -- F47: a ragdoll that wakes after being dead or out with bullet holes gets them picked out one by one by a helper that comes over (or by itself), with lines (Systems/PickOut, VitalsService.pickOneOut)
	DEATH_HEAL = true, -- F47: waking from DEATH heals every injury (bones, bruises, limp, face, drips, plasters) but the bullet holes, which stay (closed) for the pick-out scene (VitalsService)
	BUOYANCY_V2 = true, -- row 5: in the part-water tanks each limb floats by how much of its volume is under (a VectorForce per limb, 1.4x its weight fully under, plus drag), not a velocity write that fought the simulating screen (SwimService)
	PUDDLE_GLOSS = true, -- row 6: the purple pools are glossy (sheen + a light highlight) with 2-4 star splats on the edge, growing and fading with the pool (Client/BloodFx)
	INJURY_V2 = true, -- row 6: 3 hurt stages per piece by its hits (1-2 light lavender, 3-4 violet, 5+ deep violet); gauze bandages with offset ridges, a taped loose end and a seep spot at stage 3; a head wrap after 2 head hits (Client/DummySkins)
	CRATE_BURST = true, -- row 7: a body flung through a crate at 40+ studs/s smashes it (planks fly, a crack, wood dust; the body flies on through); it is back whole with the others (Knockables)
	BIKE_PEDAL = true, -- F76: a bicycle rider's legs pedal with the speed (Client/BikePedal) and the horn button rings a bell (VehicleService)
	SWIM_POSE = true, -- F78: an awake ragdoll in the water splashes in panic for a second, then front-crawls and kicks while it moves, treads water while still (Client/DummyLife swimLayer)
	POLITE_DISTANCE = true, -- 0.1567 rest: the ALWAYS3 comer stops at 5.5 studs, 45 degrees to one side of the player's view; the chatters never stand in the 35 degrees in front of the camera (Lab assignRoles)
	TIE_SHOE = true, -- row 11 rest: a new idle gesture: it bends down and ties its shoe (4-5 s, right foot forward, hands fiddling) (Client/DummyLife)
	FILM_PHONE = true, -- P1 rest: half the curious ragdolls that come to look get their phone out and film it (a lit phone held up at face height) (Personas + Client/DummyLife filmLayer)
	AUTO_QUALITY = true, -- 8: an FPS governor on each screen: start level by device (PC 3, phone/tablet 2), under 45 FPS for 10 s one step down, over 58 for 30 s one up: particles halved and far walkers slower, then no shadows and nearer lights, then fewer walkers and real hands (Client/QualityGovernor)
	IDLE_LIFE = true, -- 11: standing ragdolls do small human actions 8-20 s apart, never the same twice in a row: + hands on hips, neck roll, rub eyes, look at nails, sneeze, wave, crack knuckles (Client/DummyLife gestures)
	HIT_BONE_NAME = true, -- row 4: a round to the trunk names the bone on the hit card (Sternum, Rib, Spine, Shoulder blade, Pelvis, Lower spine), as the X-ray shows (VitalsService)
	IMPACT_SCUFF = true, -- row 7: a hard slam (dust tier 2-3) leaves a scuff on the ground that fades over 10 s; at most 12 at once, none on water (Client/ImpactDust)
	NO_SPEED = true, -- F83: no extra walk or run speed: StarterPlayer.CharacterWalkSpeed 16 (Roblox's standard), no RUN button, no Shift or stick sprint, no run FOV; the Walk speed setting is off (WALK_SETTING false, saved choices ignored)
	NAME_SIGNS = false, -- F84: no attraction name boards, signposts or IN HERE boards anywhere (LabOwnerMap nameSign); leaderboards, vehicle plaques and machine panels stay
	NO_HEAD_WHIP = true, -- F85: the fleeing glance back eases at most 230 deg/s (never a 0/55 snap); a noise look never looks behind (over 100 deg) and never while running (Client/DummyLife)
	MOOD_LEGS = true, -- F86: a kneeling mood (CPR, mourning, checking, wrapping) lowers the lift to kneeling height over 0.5 s (up again over 0.6 s), the ground measured fresh; the client runs no walk cycle on the legs during it (ActiveRagdoll, DummyLife)
	AQUA_PARTS = true, -- F87: the aquarium's water is built from parts exactly inside the glass (no terrain voxels bulging through): blue-teal 0.55, a lighter surface with scrolling textures, light shafts, bubbles; the swim volume is the same box (LabOwnerMap realWater, Client/GateMotion scroll)
	BONES_V2 = true, -- D12 part 1: every bone has integrity 100; each wound takes base (round 20, blow 14, blast 60) x power x bone factor off it, adding up; HAIRLINE <70, CRACKED <40, BROKEN 0 (a limb breaks for real via BreakReq, guns too), SHATTERED on one huge hit; the card names the stage; a heal resets (Systems/Bones)
	DRIPS_V2 = true, -- D12 part 3: only the 2-3 newest bullet holes drip (phones 2, within 40 studs), a drop every 0.6-1.2 s each, for 8 s, then stop (Client/BloodFx, BulletHoles.dripHoles)
	SHOVE_SERIES = true, -- F26: the angry dummy shoves a random 1-3 times, a line before each ("Hey!", "Stop that!", "How do YOU like it?"), a short wind-up, following if you back off; knocked over ends it; then it flees (Mourning attack)
	XRAY_TRACER = true, -- F28: with X-ray on, your round leaves a short bright line through the glass body for 1 s, along the shot (FxController.predictHit)
	HARD_PHYS = true, -- row 5: the physics watchdog (a NaN or runaway body is stopped and put back at its last good place) and no tunnelling (a body over 70 studs/s that crossed a wall or floor in one step is put back short of it, its speed into it taken off) (ActiveRagdoll hardChecks)
	FACE_TEARS = true, -- row 6: a crying face while mourning or in despair: the hurt face with two light-blue tears running down, drawn in code (DummyLife setFace)
	OWN_SLAM = true, -- row 7: a body you hit or threw in the last 2.5 s slamming down at 70+ studs/s gives you a small camera shake and a 40 ms hit-stop (FxController Land)
	BOWLING = true, -- F88 part 1: the ragdoll bowling lane on the plan's RagdollBowling spot (parts: maple lane, 10 giant physics pins, roof, bulb scoreboard, red lever); the lever rolls the nearest ragdoll down it; STRIKE/SPARE/SPLIT/GUTTER, frames of 2, TODAY'S BEST; the chicken moved to its coop (Systems/Bowling, LabLayout10)
	SPLASH_FLOAT = true, -- F78 part 3: a splash of drops where a body goes into water, and code buoyancy in the aquarium (its water is parts now): a body below the surface is lifted and slowed so it floats (SwimService)
	PERSONAS = true, -- P1 part 1: every ragdoll a Persona (Curious 35, Scared 30, Hero 15, Chill 20): at a shot, hit or crash nearby the curious walk over and watch, the scared scream and run, a hero runs to the hurt body, the chill shrug (Systems/Personas)
	SPREAD_LIFE = true, -- P1 part 2: only 8 bodies a lab are drawn to the player; the rest roam to the fronts of the plan's attractions, weighted to the emptiest and far ones, never where 5 are within 25 studs (Lab spreadSpot)
	DOG_PET = true, -- row 13 part 2: the guard dog barks (coming out, biting) and its owner can Pet it (F): a happy bark and pink hearts (GuardDog)
	FTUE_10 = true, -- T1 part 1: the bowling lane is the ONE machine shown (the goal line "Bowl a STRIKE!", the guide line, TRY bowls); a new player's first roll is always a STRIKE; after it free play: nothing is pointed at, TRY shows at any machine you walk up to (Client/FirstTwo, Bowling)
	MP_PHONE = true, -- row 15: on a phone the Multiplayer window fits the screen (lower, the body scrolls) instead of shrinking (PortalUI)
	WATCH_GROUPS = true, -- 0.7 part 3: a third of the watch spots get a PAIR of watchers side by side; up to 4 watched spots near you (Watchers)
	IDLE_LIFE2 = true, -- 11 part 2: idle gestures FootTap and Pebble (a kick at a pebble); a body with wounds or cracked bones often holds its side instead (DummyLife)
	BOWLING_FX = true, -- F88 part 2: a strike or spare plays a pin crash with confetti over the pins; a gutter plays a sad trombone (Bowling)
	GOLDEN_RUN = true, -- T1 part 3: once a session at about 2:00 a free ragdoll nearby turns GOLDEN and runs; knock it down within 10 s for +10 KOs; a countdown on the goal line (GoldenRun, FirstTwo)
	FTUE_LATER = true, -- T1 part 4: at 8 min "Play with friends: tap MULTIPLAYER", at 12 min "Come back tomorrow: DAY 2 chest!", once each on the goal line (FirstTwo)
	EVENT_CROWD = true, -- 1.0 rule 3: before an event up to 12 free ragdolls within 160 studs run into a ring round its middle and look ("What's that?!"), let go 25 s later (EventService crowdIn)
	PERSONA_CPR = true, -- P1 part 3: when a ragdoll dies, a HERO nearby comes first and always runs in to give CPR; a SCARED one never does (Mourning)
	CANNON_TARGETS = true, -- 3.1 part 2: 3 targets on the cannon's landing field (a hay ring +25, a paint circle +40, a splash pool +50); landing in one pops its name and adds the bonus (Playground)
	DROP_SCORE = true, -- 3.2 part 1: a body landing hard by the tower shows its fall height ("64 stud DROP!", from the landing speed) and a NEW BEST for the lab's owner (DropScore)
	BOUNCE_SCORE = true, -- 3.5 part 1: landings on the trampoline less than 3 s apart chain: "BOUNCE x3!" and a NEW BEST chain for the lab's owner (DropScore)
	HOME_CLEAR = true, -- F75: once the map stands every vehicle home is checked with the vehicle's box and moved to the nearest clear spot when something solid is inside it ([Vehicles] homes moved: n)
	BIKE_ROUTE = true, -- F69: on the compact map the motorbike rider follows the walkway loop's centre line point to point (a point not reached in 14 s is skipped)
	REAL_HANDS = true, -- S2 plan B: real hands from rounded parts (palm, 4 fingers of 3 segments, a thumb of 2), posed by state, on this screen only; the hook hand skin is shrunk away (Client/RealHands)
	SMOOTH_BODY = true, -- S2: the Blender-made skinned mannequin (ReplicatedStorage.SmoothBody, one connected body, real fingers) on the nearest ragdolls; bones follow the physics parts; block skins hidden (Client/SmoothBody)
	SMOOTH_BODY_V2 = true, -- F89: the slim body (arms down, no bodybuilder shoulders, always grey) from ReplicatedStorage.SmoothBodyV2, driven forward-kinematically (Client/SmoothBody)
	HAND_POSES = true, -- S2 rest: the smooth body's hands grip (right hand: the paper, the tweezers, CPR) and point (a fist with the index straight, Mood Point), eased (Client/SmoothBody)
	FACES_V2 = true, -- row 6: 7 new v2 faces (worried, pain, angry, sad, relieved, scared, X eyes when dead; art/faces/v2/make_faces.py) chosen by state and mood (DummyLife expressionFor)
	GYRO_10 = true, -- 3.3 gyro: leather straps, HOLD to spin faster (the prompt ring is the dial), a rising motor whir, flung out along the spin, RPM + G-force pop with NEW BEST (GyroBest), 1 in 20 golden rainbow trail +5 KOs (MapMachines)
	FAN_10 = true, -- 3.4 giant fan: a 3-speed dial (prompt OFF>1>2>3), the blade spins, a rising roar and a dust cone, nudge / lift / blown tumbling by speed, "BLOWN 74 studs!" + NEW BEST (FanBest), players pushed at 3 (Systems/FanMachine)
	WRECK_10 = true, -- 3.6 wrecking ball: hangs still; a lever (HOLD = pull back farther, ratchet clicks) and release swings it with a whoosh; force by ball speed ("SMASH! FORCE 87%"), distance + NEW BEST (WreckBest), a crate stack in its path that restacks (Playground)
	PRESS_10 = true, -- 3.7 press: a soft hydraulic hiss before the slam (only with a body on the bed), "FLAT x2!" / "FLAT x3!" when pressed again while still flat, NEW BEST (FlatBest) (Compressor)
	WASHER_10 = true, -- 3.8 washer: a program prompt (DELICATE / NORMAL / TURBO), light purple suds, TURBO walks the machine across its pad, "142 SPINS!" + NEW BEST (WashBest), out with bubbles rising off it (LabCreatures)
	ROCKET_10 = true, -- 3.9 rocket: a 3-2-1 / LIFT OFF! board, fireworks at the top, the body drifts down under a parachute to a random lab spot, "375 studs HIGH!" + NEW BEST (RocketBest), 1 in 20 "TO THE MOON!" gold stars +5 KOs (RocketRide)
	WALL_10 = true, -- 3.10 brick wall: a ragdoll slamming in leaves a purple cartoon SPLAT (fades in 8 s) and pops "SPLAT! 140 studs/s" + NEW BEST (WallBest) (BrickWall)
	DOG_10 = true, -- 3.11 guard dog: petted it rolls over with a GOOD BOY! pop, a deep growl-woof as it crouches to bite, tooth marks (grey dents, 10 s) on the bitten limb (GuardDog)
	SHARK_10 = true, -- 3.12 shark: a cartoon death roll (two full turns), a random time in the jaws as the score ("CHOMP! 2.1 s in the jaws" + NEW BEST: SharkBest), the body comes up soaked with bubbles (LabCreatures)
	SPIDER_10 = true, -- 3.13 spider: the dropped cocoon stays 10 s and can be shot (or blasted) open: a white silk burst, the body comes out with web strands for 8 s, "FREED!" (LabCreatures)
	FROG_10 = true, -- 3.14 frog: the tongue length pops ("TONGUE 14 studs!" + NEW BEST: FrogBest), the body comes out dripping green slime 5 s (LabCreatures)
	PLANT_10 = true, -- 3.15 plant: yellow cartoon stars spin out of its jaws while it chews, "MUNCH!" (LabCreatures)
	CHICKEN_10 = true, -- 3.16 chicken: when the egg hatches a little yellow chick follows the lab owner for 60 s, hopping behind them (LabCreatures)
	CAR_10 = true, -- 3.17 cars: a car hitting a ragdoll pops "BONK! 48 studs/s" with a NEW BEST for the driver (CarBest) (VehicleService)
	TESLA_10 = true, -- 3.20 tesla coil: a ZAP button; 1 s charge (rising electric growl, faster sparks), a lightning arc to the nearest ragdoll (blue-white flash, soot-black 3 s, smoke puff, a jump), chaining to 2 more; "ZAP! x3 CHAIN" (MapMachines)
	SWEEP_10 = true, -- 3.22 sweeper: a speed button on the post (SLOW / FAST / CRAZY), ragdolls on the pad are swept off over the edge, players jumping the beam score "JUMPED x5!" + NEW BEST (SweepBest), caught on the ground = knocked off (MapMachines + LabOwnerMap)
	LAVA_10 = true, -- 3.23 lava strip: glows and bubbles; a ragdoll in it hops a hot-foot dance, goes soot-black and smoking, jumps out over the kerb after 1.6 s, "HOT FOOT! 1.6 s" + NEW BEST (LavaBest) (MapMachines)
	MOLE_10 = true, -- 3.24 mole: whack-a-mole: between catches it peeks out of a random hill for 1.2 s; shoot it while up: "WHACK! x3" streak + NEW BEST (MoleBest) (LabCreatures)
	ANIMALS_10 = true, -- 3.27-3.29 the Animal Cove comes alive: the bear (poke or come close: ROAR, SWAT or BEAR HUG, Zzz), the crocodiles (swim in, SNAP, death roll, toss onto the bank), the T-rex (a lever opens its gate: 30 s of stomping, CHOMP and toss, ROAR shock rings) (Systems/AnimalCove)
	STRETCH_10 = true, -- 3.19 stretcher: on release the stretch percentage pops ("SPROING! 180%") + NEW BEST for whoever cranked it (StretchBest) (StretchMachine)
	SHRED_10 = true, -- 3.21 shredder: spat out with "FOLDED x4!" + NEW BEST for whoever pressed (ShredBest) (MapMachines)
	SLING_10 = true, -- 3.25 slingshot: aims at the archery target (ballistic, a little spread) and scores the ring: BULLSEYE 50 / 30 / 20 / 10 / MISS + NEW BEST (SlingBest) (LabCreatures)
	EVENT_STATS = true, -- 3.30 red-button events: an end line with stats for the starter (every player for an all-labs event): "TORNADO over: 37 ragdolls flung!" (EventService)
	REVIVE_WAVE = true, -- 3.34 REVIVE ALL: a sparkling green ring sweeps out from you across the lab and every body it brings back bursts with sparkles (SandboxService)
	RIDE_AIR = true, -- 3.32 rides: any driven bike, wheelchair or car that leaves the ground 0.6 s+ pops "AIR TIME 1.4 s" + NEW BEST (AirBest); pad launches keep their own (VehicleService, LaunchPads)
	TURN_EVEN = true, -- F73: the heading rotates at a capped even rate (220 deg/s walking, 360 fleeing), never a lerp whip or 180 degree snap; turning on the spot steps the feet (ActiveRagdoll, DummyLife)
	TURN_STEP = true, -- F73 part 2: a turn pose with stepping feet, cycle hysteresis (in 0.6 / out 0.3), walks round corners in an arc, curved arrivals home, low foot friction upright, the TURN TWIST detector (ActiveRagdoll, DummyLife, LegJitter)
	NAV_SNAP = true, -- F72 rest: every Home goes through NavTarget.snap (moved to the nearest free spot when inside or against a solid part or the lava; cached), and a walker pressed against something (under 30 % of its speed for 0.4 s) takes the open side at once (ActiveRagdoll, Shared/Ragdoll/NavTarget)
	NAV_BLOCKCAST = true, -- F72: obstacles are seen with a body-sized Blockcast whose look-ahead grows with speed (2.5-7 studs), and the detour takes the more open side (ActiveRagdoll blocked/clearAhead)
	NAV_BUMP_LOG = true, -- F72: ActiveRagdoll counts detours, other-side tries and waits for a car, printed once a minute ([NavBump]); a moving car in the way is waited for, not walked round
	NAV_ALWAYS = true, -- F72: RagdollNav puts its waypoint in NavHome (followed before Home) and never overwrites Home, so every walk gets a path, moving goals too (re-planned when the goal moved 4 studs, max 1/s)
	M4_CLEAN = true, -- M4 part 1: no tree belts, belt walls, bush rows, hedges, flower beds or room gates; trees only in a 50-stud edge band, at most 70 (LabOwnerMap m4Clean, Unstick)
	REF_LOOK = true, -- M4 THE LOOK: the lab's light like the references (ClockTime 14, Brightness 2, grey ambient 70/128, Atmosphere 0.35 / 0.25 / (199,199,199), haze 1, no glow or tint) (Client/ZoneLighting)
	REAL_WATER = true, -- F78 part 1: real Terrain water in the aquarium, both pools (raised basins) and the croc pond (mud bank); ragdolls in it cry out, float and climb out after 8 s (LabOwnerMap realWater, Systems/SwimService)
	TRY_GUIDE_LINE = false, -- map round 2 (owner: "a yellow rope line across the grass"): no guide line to the next TRY machine (FirstTwo); the TRY button and the goal line stay
	MP_ICON = true, -- (owner, 26 Nov 2026) the Multiplayer window from a square under Lab (HudV3)
	MP_PORTAL = false, -- the multiplayer portal in the world hidden (PortalService); the SINGLEPLAYER portal stays
	FIRST_TWO = true, -- FIRST_2_MIN (owner, 26 Nov 2026): TRY button at an untried machine, a ragdoll runs to you, the grab lesson once, "Put it in!", a faint guide line to the next machine (Client/FirstTwo)
	LAB_SPREAD = 1.2, -- (0.37.1: 1.6 left too much empty grass) -- (0.37.0, owner 22 Nov 2026: "a much bigger lab"): every machine, the floor, the garden and the yard this many times further from the spawn; machines keep their size
	COUNTERS_ONLY = true, -- (V11 A1/A2, owner 22 Nov 2026: "no pop-ups, only (1),(2) on the icons; only events tell you"): Notify sends only critical lines; nothing opens by itself; Client/IconCount
	START_MENU = false, -- (23 Nov 2026, owner: "remove the start menu: you join singleplayer by default, multiplayer is a portal") (V11 C8, owner: "choose single or multiplayer before loading in"): Client/StartMenu
	LAB_GRASS = true, -- (0.37.0: the lab floor is lawn with a stone plaza at the spawn and paved walks to every machine; Lab.dressPlot)
	GREEN_TILES = table.freeze({ texture = nil :: string?, studs = 8, color = Color3.fromRGB(92, 118, 60), material = Enum.Material.Grass }), -- (0.47.38, owner: short, slightly dark, realistic grass; the tiles were texture rbxassetid://129845169187120, SmoothPlastic, 58, 178, 48) -- -- (0.47.21, owner: smooth green floor with a thin grid, tiles of 4 studs, over the whole lab; false = the lawn and the area platforms)
	START_PLACE = 126037745825106,
	MULTI_PLACE = 81638873302354, -- (0.47.23: the multiplayer place's id; then the start place's server size must be 1 on the dashboard. PortalService)
	LAB_NO_PATHS = true, -- (0.37.8, owner: "remove all paths, just platforms"): no walks, no path network and no garden walks in the labs; the plaza and the area platforms stay
	HEIGHTS = true, -- (0.37.9, owner: "build bridges and platforms"): sky bridge, slide, sky deck and jump steps in the height area (Server/Systems/Heights)
	THROW_TOWER = false, -- (0.37.10, owner: "remove the castle": no stone throw tower in the labs)
	MACE = false, -- (0.37.8, owner: the spinning spike ball is gone; the shark tank stands there, LabCreatures)
	-- Phase 0 (19 Nov 2026): nothing that interrupts in a new visit's first QUIET_START s: no view
	-- card, no egg window, at most one hint at a time; tips and gift notes wait until after it. On a
	-- phone LAB VIEW and RUN wait too (HudSlots.PHONE_LATER).
	-- (20 Nov 2026, Session_v1: the median visit on 0.24 left at about 120 s, before the HUD's 90 s
	-- reveal, the 110 s wow and the 120 s mission had come. The hooks now land inside the first two
	-- minutes, one about every 30-40 s: HUD 35, mission 40, wow 45, next weapons 45, surprise 80+,
	-- chase 100, play gift 120.)
	QUIET_START = 35,
	-- The "Walk, or view from above?" card (74 % never answered it): off; everyone starts in the
	-- player view and LAB VIEW stays a button (MENU's on a phone after the quiet start).
	VIEW_CARD = false,
	-- The three locked "next weapon" cards on the bar (0.15) wait until a player has this many
	-- takedowns AND this many seconds of the visit have passed (BarRules.nextUnlocksShown).
	NEXT_UNLOCKS_MIN_TAKEDOWNS = 0, -- (V10 phase 1, owner: players left thinking there was nothing more: shown from the start; was 5)
	NEXT_UNLOCKS_AFTER = 0, -- (V10 phase 1: from the first second; was 45)
	-- Mild content (phase 0; the owner's earlier choices stay one switch away):
	--   BLOOD "off": hits show cartoon stars, sparks and dust (HitFxConfig "Stylised"), and the
	--   Settings row is hidden; "purple": the owner's purple cartoon blood, players may turn it off.
	-- V9-NOW 6 (owner, 21 Nov 2026: "purple blood on"; a move away from the all-ages "mild" setting, the owner's call):
	BLOOD = "purple" :: "off" | "purple",
	--   TOY_NAMES: toy-style names for the real-gun nicknames (G17 -> Popper ...; Toys.TOY_NAMES).
	--   Internal ids stay, so saves, products and sounds are untouched. false = the old names.
	TOY_NAMES = true,
	--   MILD_TEXT: the hit line names a body region ("Body", "Left arm") and "health", not organs and
	--   blood; doctor mode (opt-in) keeps its monitor.
	MILD_TEXT = true,
	-- Phase 1 (first 60 s hook):
	--   EXPERIMENTS: one-line goal cards with a timer and stars (Shared\Experiments, ExperimentService)
	--   XRAY_REPLAY: the replay shows see-through bodies with their bones, a score pop ("CRACK! +140"),
	--   CLIP IT and a SHARE CODE (Shared\ShareCode)
	--   PHONE_HUD_MAX7: a phone shows the experiment card in the big WEAPONS button's place (the bar
	--   keeps its own WEAPONS slab): fire, stick, bar, experiment, SHOP, MENU, RAGDOLL
	EXPERIMENTS = false, -- (22 Nov 2026, owner: the mission card must never fill the screen; true brings it back)
	EXPERIMENT_FIRST_AT = 40, -- (20 Nov: just after the 35 s reveal; was 120, then 30) -- s into a visit (the first-minute bar must be free too)
	DEAD_GREEN = false, -- (23 Nov 2026, owner)
	REPLAY = false, -- (23 Nov 2026, owner: no replays anywhere)
	XRAY_REPLAY = true,
	PHONE_HUD_MAX7 = true,
	-- Phase 2 (reasons to stay): BOLTS, the BONE JOURNAL, Daily Experiments, rationed eggs, the
	-- retuned ladder and like-milestone codes (Shared\Economy, EconomyService).
	ECONOMY = true,
	BOLTS_PER_STAR = 10,
	DAILY_BONUS = 30, -- extra bolts for each of today's Daily Experiments
	DAILY_COUNT = 3,
	BONE_JOURNAL = false, -- (23 Nov 2026, owner: gone, with its notices)
	JOURNAL_BOLTS = 25,
	PLAYTIME_BOLTS = 40,
	EGG_RATION = true, -- playtime gifts give BOLTS, not eggs (eggs: the daily egg and milestones)
	BOLTS_PER_TAKEDOWN = 1.5, -- a weapon costs its ladder takedowns x this in bolts...
	BOLTS_MIN_PRICE = 20, -- ...and never less
	-- The ladder (LADDER_V2): up to LADDER_KEEP takedowns as it was; above, squeezed so the top
	-- (Golden Popper, 1,600) is ~600 and a one-hour goal is in reach. Ids and order unchanged.
	LADDER_V2 = true,
	LADDER_KEEP = 30,
	LADDER_V2_SCALE = 0.363,
	-- V9-3b (owner, 21 Nov 2026: "bigger gaps between unlocking new weapons"): rungs up to LADDER_V9_KEEP stay (the
	-- first presents); above, one smooth curve: the first gap LADDER_V9_FIRST_GAP, each next gap
	-- LADDER_V9_GROWTH times the one before (58 rungs above the kept ones: the top 1,609, 2.7x the old 600; never past
	-- LADDER_V9_TOP). Players keep what they had reached (ladder 6); every weapon keeps its price.
	LADDER_V9 = true,
	LADDER_V9_KEEP = 5, -- (0.47.35, owner: easier to unlock the next weapon; was 15, gap 5, growth 1.05: the top was 1,529)
	LADDER_V9_FIRST_GAP = 2.5,
	LADDER_V9_GROWTH = 1.035,
	LADDER_V9_TOP = 1800,
	-- Codes the owner turns on by hand when the like count reaches a milestone (never a reward for
	-- liking: Roblox forbids it; anyone may type a live code). Set `code` and `live = true`.
	LIKE_CODES = table.freeze({
		table.freeze({ likes = 100, code = "", bolts = 100, live = false }),
		table.freeze({ likes = 500, code = "", bolts = 200, live = false }),
		table.freeze({ likes = 1000, code = "", bolts = 400, live = false }),
	}),
	-- Phase 3 (social, Christmas, rhythm):
	--   PRANK_PARTY: 2..PARTY_MAX players in one lab share an experiment card (PartyService).
	--   SERVER_SIZE: what the owner sets as the place's max players on the Creator Dashboard (it is not
	--   settable from code; PortalService's own servers and the tests read it). The plan: try 6.
	PRANK_PARTY = true,
	PARTY_MAX = 6,
	SERVER_SIZE = 6,
	-- Release 0.20 (throw your friend): PARTY_THROWS lets the members of a running Prank Party grab
	-- and throw each other inside that lab (PlayerGrab; everywhere else it stays plaza only, and
	-- nobody is ever hurt). A player thrown by a friend who lands in the cannon, on the bullseye, on
	-- a station or in a trap within THROW_COMBO_WINDOW s is a TOSS COMBO: a pop on both screens, a
	-- "Toss" for the thrower's cards (the party's TOSS card, the journal). Combos less than
	-- THROW_COMBO_CHAIN s apart count up (x2, x3...). false = the plaza-only grab of 0.19.
	PARTY_THROWS = true,
	-- Release 0.20.0 (Shop.OFFERS passes, OfferService): EVENTS PASS starts a server event free at
	-- most once per EVENTS_PASS_GAP s; VIP LAB adds VIP_LAB_VISITORS roaming ragdolls in your lab.
	EVENTS_PASS_GAP = 120,
	VIP_LAB_VISITORS = 0, -- (22 Nov 2026, owner: only the 18 lab dummies; was 2)
	-- (22 Nov 2026, owner: "no ragdolls but the 18"): no visitors, chase pack, horde or greeter.
	ONLY_LAB_DUMMIES = true,
	THROW_COMBO_WINDOW = 4,
	THROW_COMBO_CHAIN = 20,
	--   CHRISTMAS_FROM_DEC1: the season starts 1 December (it was on since 7 November 2026; Santa hats
	--   in mid-November read as stale). CHRISTMAS_LAB: the chimney launcher, the present trap and the
	--   sleigh ramp in every lab while the season is on; ADVENT: a daily advent experiment 1-24 Dec.
	CHRISTMAS_FROM_DEC1 = true,
	CHRISTMAS_LAB = true,
	ADVENT = true,
	-- Update rhythm: what the title shows in an update week, and the days updates go out. The newest
	-- entry of Shop.WHATS_NEW must carry Config.Version (T66 checks it).
	UPDATE_TITLE = "[UPD] Hyper Ragdoll Physics \u{1F4A5}",
	UPDATE_DAYS = table.freeze({ "Thursday", "Saturday" }),
	-- UI v2 (19 Nov 2026, branch ui-polish): one premium, phone-first look for every screen. The
	-- LihFolk kit's tokens (LihFolkUITheme: navy canvas, havoc-orange accent, Fredoka One titles,
	-- rounder corners, press squish 0.92, 14 px text floor), drawn icons on the HUD's text buttons
	-- (KitStyle.icon), press + click on every button (KitStyle.press), count-up numbers, rarity
	-- colours and readable stat bars on the weapon cards (Shared\UiRarity), a clearer hit / kill
	-- mark. false = the round 5 dark-glass look, unchanged.
	UI_V2 = true,
	UI_PREMIUM = true, -- 24 Nov 2026 (owner): one premium HUD look (graphite glass, hairline edges, havoc orange). false = the look before
	-- Extra ragdolls a device simulates for its own lab (Shared\DeviceTier: phone low, tablet and
	-- console mid, computer high).
	DEVICE_CAPS = table.freeze({
		low = table.freeze({ visitors = 1, chasers = 4 }),
		mid = table.freeze({ visitors = 2, chasers = 7 }),
		high = table.freeze({ visitors = 3, chasers = 10 }),
	}),
	-- World/Feel v2 (19 Nov 2026, branch world-polish; nothing of it play-tested in Studio yet):
	--   WORLD_V2: every lab and the plaza get a code-built dressing on top of what was there (a
	--   backdrop wall, a gantry over the test zone, signposts to the cannon and the hazards, a dashed
	--   flight line from the cannon to the bullseye, light towers, crates, barrels, tyres, cables,
	--   framed station boards, warning signs; a nicer chimney, present and sleigh), and the dummies a
	--   test-suit colour and a chest number. Pictures only: not one new part collides, is hit by a ray
	--   or listens for a touch, so play is the same with it off (WorldDress). false = the 0.20 look.
	--   FEEL_V2: hit feel on this screen (a trauma shake from one strength value, a hit-stop on big
	--   moments, star/dust/spark bursts, flop sounds by landing speed, speed trails on launched and
	--   thrown bodies, a slow-mo beat on big combos, muzzle flash, casings and recoil per gun) and the
	--   ragdoll guard (limbs never fly off the body: ActiveRagdoll). false = the 0.20 feel.
	WORLD_V2 = false, -- (LOOK_V3, 19 Nov: off. Its neon boards, suits and floating bits read as clutter)
	FEEL_V2 = true,
	-- What one device draws at most (Shared\FeelTuning reads it; DeviceTier picks the tier):
	--   lights: world lamps lit at once (the nearest; WorldLights), flashes: muzzle-flash lights at
	--   once, particles: particles one burst may emit, trails: speed trails at once, casings: shell
	--   casings in the air at once, ragdolls: bodies this device simulates for its own lab (the 6 lab
	--   dummies + visitors, VIP LAB's extra ones included, + chasers; T80 checks DEVICE_CAPS fits under it).
	FX_CAPS = table.freeze({
		low = table.freeze({ lights = 4, flashes = 1, particles = 10, trails = 3, casings = 6, ragdolls = 14 }),
		mid = table.freeze({ lights = 8, flashes = 2, particles = 18, trails = 6, casings = 12, ragdolls = 18 }),
		high = table.freeze({ lights = 14, flashes = 4, particles = 30, trails = 10, casings = 24, ragdolls = 22 }),
	}),
	-- LOOK_V3 (19 Nov 2026, the owner: "copy everything graphic from the big ragdoll games"; plan:
	-- docs/V3_PLAN.md). Calm overcast daylight with soft shadows and no grey wash on the play area
	-- (ZoneLighting), plain white dummies with no glow, no crash marks and no suits (DummyFactory,
	-- NpcGlow), short lines in a black box over a dummy's head when a gun points at it, when it gets
	-- up from a fall, and idle chatter (DummyLife + Shared\DummyLines), no shouting signs in the world
	-- (Playground billboards), and the clean HUD (HudV3). false = the 0.20 look.
	LOOK_V3 = true,
	MAP_ACTIVITIES = true, -- v3 phase C: launchers on the open-air maps (Server/Systems/MapActivities)
	NPC_COMMANDS = true, -- v4 B4: talk to NPCs (E): follow, stay, attack with your weapons (Server/Systems/NpcCommand, Client/NpcTalk)
	SLOWMO_V2 = true, -- v4 C5: smooth client slow motion (Client/SlowMotion): bodies keep SLOWMO_SCALE of each speed change, grade/blur/vignette/pitch/trails
	SLOWMO_SCALE = 0.25, -- time in a slow-mo bubble runs at this speed
	SLOWMO_AUTO_GAP = 8, -- s between automatic slow moments on big hits
	LAB_SURPRISES = true, -- (STAY_LONGER 3, 26 Nov 2026: back on, about every 2 min, a 10 s warning on the goal line; the minis add no dummies, so "only the 18 lab dummies" (22 Nov) still holds) -- v4 C4: a short surprise (Surprises.MINI) by itself now and then in your own lab
	LAB_SURPRISE_GAP = Vector2.new(110, 130), -- (STAY_LONGER 3: about every 2 minutes; was 150-240) -- s between them (random in the range)
	LAB_SURPRISE_FIRST = Vector2.new(80, 110), -- s into a visit for the first one (20 Nov: was 150-240, after most visits ended)
	FIRST_WOW_AT = 45, -- s into a visit: FIRST_WOW_EVENT over your own lab once (V9-0u: was a UFO) (20 Nov: was 110, after most visits ended; first 50)
	FIRST_VISIT = true, -- audit area 1: the first-visit flow (Client/FirstVisit): a bare screen and one objective line, the HUD slides in at QUIET_START
	NEWCOMER_SECONDS = 300, -- played in all under this = a newcomer (the first-visit flow)
	-- V6-1 notification centre (Client/Notify, Shared/NotifyRules): one big pop-up at a time, gaps by
	-- kind, dedupe, quiet after windows; false = every message straight to Toast as before.
	ADMIN_V2 = true, -- V6-2: the owner's tabbed admin menu (Client/AdminPanel, Server/Systems/AdminTools)
	DIRECTOR = true, -- V6-3: the owner's F8 director mode for filming (Client/Director; AdminTools Shot/LaunchDummy/DirectorSave)
	LAB_V6 = true, -- V6-4: wider plots (Zones.PLOT_SPACING 250) with a garden on both sides (Server/Systems/LabGarden)
	LAB_CREATURES = true, -- V6-5: the creature yard in front of each lab (Server/Systems/LabCreatures): spider, plant, frog, shark tank (slot id "Whale"), chicken, washer, slingshot, mole, vacuum/compressor
	BIRDS = false, -- V6-6: client-side flocks (Client/Birds) round the lab and the open-air maps (20 Nov 2026, the owner: "remove the birds"; true brings them back)
	MAP_SHOP = true, -- V6-7: showcase booths on the maps selling Shop.OFFERS map items (Server/Systems/MapShopService); id 0 = no booth live
	PATHS = true, -- V7-2: earthen paths to everything in the lab, and repainted terrain paths on the plaza and open-air maps (Shared/PathPlan, Server/Systems/PathBuilder)
	PATHS_V3 = true, -- 21 Nov 2026 (the owner: "make the paths round the lab much nicer"): a gravel shoulder, lamp posts that glow and flower tufts along every lab path (PathBuilder.dressLine)
	BIRDS_MAX = table.freeze({ pc = 24, tablet = 14, phone = 8 }), -- birds out at once per device
	NOTIFY = true,
	BANNER_V7 = true, -- V7-5: the event banner as a picture card that shrinks into a chip
	BANNER_CHIP_AFTER = 3, -- seconds the full banner shows before it becomes a chip
	NOTIFY_BIG_AFTER_REVEAL = 20, -- s after a newcomer's HUD reveal before the first big pop-up
	NOTIFY_REVEAL_KEEP = 2, -- rewards that waited through a newcomer's quiet: only the newest this many show
	EXPERIENCE_NOTIFY = false, -- (V8-0.7: off until the sender is live, V8-3.5: the once-per-30-days opt-in was spent for nothing)
	NOTIFY_OPTIN_AFTER = 480, -- s of play before that ask (never on join)
	LAB_ZONES = true, -- v4 C1: lab zones, today's machine, NEW tags (Server/Systems/LabZones)
	ZONE_FLOOR = false, -- V7-1: the painted zone boxes on the lab floor (tints, edges, names, parking lines); off by the owner's wish
	TODAY_LIGHT = false, -- V7-1: the yellow light column over today's machine; off by the owner's wish (the small sign stays)
	UI_CLEAN = true, -- v4 D2: calm hand-made look (leaderboards as wall panels, no neon frames/crowns/glow; see LeaderboardService.STYLE)
	ARENA_V2 = true, -- v4 D1: the Game Arena as a sports hall (track floor, lanes, concrete, padding) instead of the pink room
	SPIKE_BLOCKS = false, -- owner 20 Nov 2026: no red spike plates in the labs (true brings them back)
	WRECKING_V2 = true, -- owner 20 Nov 2026: the wrecking ball as a steel ball on a chain under a yellow A-frame gantry (Playground)
	NEW_SINCE = "2026-11-20", -- UTC date of the update whose things get a NEW tag
	NEW_DAYS = 7,
	-- (session v850, owner: "fjern det ret du har tilføjet oven på bilerne"): the NEW tag was floating
	-- over every vehicle; a cluttered look. The cars are no longer the one newest feature — kept the
	-- tag on the BigButton and PortalMulti only.
	NEW_IN_LAB = table.freeze({ "BigButton", "PortalMulti" }), -- names in the lab's folder
	-- v4 A5 (owner): bodies die from enough hits, not only headshots. Every hit adds damage =
	-- weapon power x DAMAGE_PER_POWER x the region (head, limbs) x DAMAGE_BLUNT for blows; BODY_HP of it
	-- kills (about 6 Popper rounds to the body, about 10 punches). Headshots stay instant.
	-- v4 A3: the sound mix (Client/SoundMix): each group's volume under the player's Effects setting.
	SOUND_MIX = table.freeze({ Weapons = 0.95, Impacts = 0.8, Blasts = 1, World = 0.7, UI = 0.45, Ambient = 0.5 }),
	BLOOD_KILLS = true, -- 24 Nov 2026 (owner): only the blood left kills (VitalsService), no hit points
	BODY_HP = 100,
	DAMAGE_DECAY = 2, -- damage points a body heals per second (100 in 50 s)
	DAMAGE_PER_POWER = 17,
	DAMAGE_HEAD = 1.5,
	DAMAGE_LIMB = 0.6,
	DAMAGE_BLUNT = 0.83,
	LOOK_V3_LIGHT = table.freeze({
		ClockTime = 13,
		Brightness = 2.2,
		Ambient = Color3.fromRGB(70, 72, 78),
		OutdoorAmbient = Color3.fromRGB(120, 124, 130),
		ExposureCompensation = 0,
		EnvironmentDiffuseScale = 1,
		EnvironmentSpecularScale = 0.6,
		ShadowSoftness = 0.35,
		airDensity = 0.3,
		airOffset = 0.1,
		airHaze = 0.4,
		airGlare = 0,
		airColor = Color3.fromRGB(199, 205, 214),
		airDecay = Color3.fromRGB(106, 112, 125),
		bloom = 0.1,
		bloomThreshold = 2,
		contrast = 0.05,
		saturation = -0.05,
	}),
	-- V9-0b (owner, 21 Nov 2026: "make the game feel like the thumbnails ... now it looks dark and the sky
	-- looks dead"; art/store/look_target): a bright, sunny afternoon. A cartoon-blue sky with Roblox's
	-- own cloud skybox and dynamic white clouds, a big sun behind the spawn camera's left shoulder (faces
	-- and the cannon lit), warm sunlight with blue-grey (never black) shadows, richer colour, a soft
	-- glow on only the brightest things. Client/ZoneLighting reads it. false = the LOOK_V3 light.
	LOOK_THUMB = false, -- (0.47.36, 23 Nov 2026, owner: no sunshine, a pale overcast day: ZoneLighting overcast; was true)
	LOOK_THUMB_LIGHT = table.freeze({
		ClockTime = 14.5,
		GeographicLatitude = 50, -- (with ClockTime: the sun at about (-0.54, 0.71, 0.45))
		Brightness = 3.3,
		Ambient = Color3.fromRGB(104, 116, 140),
		OutdoorAmbient = Color3.fromRGB(150, 168, 200),
		ColorShift_Top = Color3.fromRGB(255, 232, 200),
		ExposureCompensation = 0.1,
		EnvironmentDiffuseScale = 0.8,
		EnvironmentSpecularScale = 0.8,
		ShadowSoftness = 0.3,
		airDensity = 0.22,
		airOffset = 0.25,
		airHaze = 0.4,
		airGlare = 0.6,
		airColor = Color3.fromRGB(190, 220, 255),
		airDecay = Color3.fromRGB(110, 160, 230),
		bloom = 0.4,
		bloomThreshold = 1.4,
		bloomSize = 24,
		contrast = 0.08,
		saturation = 0.22,
		tint = Color3.fromRGB(255, 251, 242),
		sunRays = 0.1,
		sunRaysSpread = 0.5,
		sunSize = 18,
		cloudCover = 0.58,
		cloudDensity = 0.75,
	}),
	LOOK_V3_DUMMY = Color3.fromRGB(240, 240, 238), -- the plain white of a test mannequin
	LOOK_V3_DUMMY_LOW = Color3.fromRGB(232, 232, 230), -- forearms and shins, a hair darker
	LOOK_V3_DUMMY_ENDS = Color3.fromRGB(222, 222, 220), -- hands and feet
	-- V9-0o (owner, 21 Nov 2026: "make the ragdolls greyer so they are easier to see, and more matte, the sun
	-- shines a lot now"): a mid-light neutral grey that the bright light never blows out to white, darker
	-- than the hub floor pads (216, 206, 190) and the sky, far from the dead green; matte (Plastic,
	-- Reflectance 0) on the body and the client skins. The crash-test details keep their colours; the
	-- crowd in clothes is not touched. false = the white of LOOK_V3.
	DUMMY_TONE = {
		shell = Color3.fromRGB(92, 95, 102), -- (NOW 1.3, 26 Nov 2026: a shade darker so they stand out on the light hub floor and the white sky; was 112, 114, 118) -- (23 Nov 2026, owner: they shone far too much: 245 blew out in the light; 22 Nov 2026, owner: white, so they stand out from the lab floor; was 138, 140, 145)
		low = Color3.fromRGB(92, 95, 102), -- forearms and shins, a shade darker
		ends = Color3.fromRGB(92, 95, 102), -- hands and feet
		material = Enum.Material.SmoothPlastic, -- (0.47.37: glossy again, in the overcast light) -- (23 Nov 2026: matte again; head and body alike; was SmoothPlastic)
		reflectance = 0.17, -- (V10, owner: "they shine a little too much, it hurts to look at"; was 0.06)
	} :: any,
	-- v3 Phase C: cars in every lab (VehicleService builds them, VehicleClient drives them on the
	-- driver's screen). Speeds in studs/s; a hit over HitMath.MACHINE_MIN_SPEED knocks a dummy.
	VEHICLES = table.freeze({
		enabled = true,
		-- (session v846, owner: "bakker sygt langsomt, alle leaver": reverse was ~30% of forward which felt broken.
		-- Raised to ~55% and accel +15% so getting out of a wall/off a dummy is snappy. Retention fix.)
		Car = table.freeze({ speed = 72, reverse = 72, accel = 3.0, turn = 1.9 }), -- (the supercar: the fastest)
		Truck = table.freeze({ speed = 52, reverse = 52, accel = 2.1, turn = 1.5 }),
		Kart = table.freeze({ speed = 58, reverse = 58, accel = 3.0, turn = 2.1 }), -- (V9-NOW 26: the go-kart, quick and twitchy)
		Jeep = table.freeze({ speed = 56, reverse = 56, accel = 2.3, turn = 1.7 }), -- (owner 21 Nov 2026: the jeep on its own pad)
		Bike = table.freeze({ speed = 44, reverse = 44, accel = 2.8, turn = 2.2 }), -- (BikeService)
		Bicycle = table.freeze({ speed = 26, reverse = 12, accel = 2.4, turn = 2.4 }), -- (F76: the free pedal bicycle, slower than the motorbike)
		Wheelchair = table.freeze({ speed = 18, reverse = 8, accel = 2, turn = 2.6 }), -- (row 14: the 3 free wheelchairs)
		Wheelchair2 = table.freeze({ speed = 18, reverse = 8, accel = 2, turn = 2.6 }),
		Wheelchair3 = table.freeze({ speed = 18, reverse = 8, accel = 2, turn = 2.6 }),
		MuscleCar = table.freeze({ speed = 68, reverse = 68, accel = 2.8, turn = 1.8 }), -- (session v842: a 70s muscle car, fast and heavy, slightly less nimble than the supercar)
		flippedReset = 4, -- s an empty flipped or fallen car waits before it goes home
		idleReset = 30, -- s an empty car left away from its pad waits before it goes home
		-- v4 C2: sounds (free Creator Store audio): engine loop (Roblox Resources), horn, crash.
		engineSound = 80317022777602,
		hornSound = 127513531122725,
		crashSound = 70951531892215,
		-- V9-NOW 16 (owner, 21 Nov 2026): the cockpit (Client/Cockpit): the driver's-seat camera from the moment you sit
		-- (V / Select / the VIEW button: the chase camera), a turning wheel and a speedometer, and these sounds
		-- (free Creator Store audio): engine start (zKevin), tyre screech (diman's group), wind (Great British Air).
		cockpit = true,
		startSound = 5830481291,
		screechSound = 73429750798250,
		windSound = 5813077875,
		feel = true, -- spinning/steering wheels, body roll, lights, engine pitch, dust (Client/VehicleFeel)
	}),
	STRETCH_MACHINE = true, -- 24 Nov 2026 (owner): the stretching machine in the ramp's place (StretchMachine)
	SHOOTING_RANGE = true, -- 24 Nov 2026 (owner): the indoor weapon range (ShootingRange)
	SCAFFOLDS = false, -- 24 Nov 2026 (owner): wooden scaffolds to knock over in the labs
	BIG_BUTTON = false, -- 24 Nov 2026 (owner): no free event button and sign in the lab
	BIG_BUTTON_GAP = 300, -- (22 Nov 2026, owner: a free random event every 5 minutes; was 75) -- s between two presses of a lab's BIG RED BUTTON (a random free event)
	LAB_CONTROLS_GAP = 8, -- s: the same with the Lab Controls pass (its owner, in their own lab)
	-- All UI 3D and interactive (19 Nov 2026, the owner): turning weapon models on the cards and the
	-- bar, tilt and depth on the HUD buttons, windows that swing in (Client\Ui3D). Live (turning)
	-- viewports at once per device tier; the rest are drawn once and left still.
	UI_3D = true,
	UI_3D_LIVE = table.freeze({ low = 2, mid = 4, high = 6 }),
	WORLD_V2_LAB_PARTS = 320, -- parts one lab's WORLD_V2 dressing may add (T81)
	WORLD_V2_LAB_LIGHTS = 12, -- lights one lab's dressing may hold (only FX_CAPS[tier].lights are lit)
	COMBO_SLOWMO = 5, -- a combo of this many (and every this-many after) gets the slow-mo beat
	-- V8-0.8: adult test accounts that join the live game as a brand-new player every visit (TestAccount;
	-- never the owner's own). 3037725863 is the second account seen on the owner's phone: the owner
	-- confirms or replaces it in Sitting 1.
	TEST_ACCOUNTS = table.freeze({ 3037725863 }),
	-- V8-0.2 (the first hit lands): a newcomer's first FIRST_HITS hits with any tool knock the dummy
	-- flat with a big flop; gun hits get a dry impact puff with BLOOD off; the client stamps KO at
	-- once; nobody flees in a newcomer's first CALM_FIRST s, then only the nearest coward runs, for
	-- FLEE_SHORT s, at most FLEE_MAX at once in a lab; aim help on the torso, for pads too.
	V8_FIRST_HIT = true,
	FIRST_HITS = 3,
	FIRST_HIT_PUSH = 20, -- studs/s the first hits throw the body back, at the least
	CALM_FIRST = 60,
	FLEE_SHORT = 1.2,
	FLEE_MAX = 2,
	-- V8-0.3 (a full bar that stays yours): the start bar is Popper, Grab, Bat, Grenade, Launch
	-- (Toys.DEFAULT_LOADOUT; Rocket the first unlock at 3; Poke/Slap/Shove/Heal moved up the ladder);
	-- older saved bars move over once (LoadoutStore, profile flag); new tools keep to the hand rules
	-- (PokeController.slotFor: the weakest slot, only for a stronger tool; never a gun, a bang, Grab,
	-- the G17 or the Bat; a prize always lands; never picked while firing).
	V8_START_BAR = true,
	-- Start bar v9 (21 Nov 2026, the owner: "the best start weapons, the Rocket one of the hard ones";
	-- the big games start small: BRP 3 slots on PC, RDP 1 tool and 3 empty slots): 4 tools at the
	-- first join (Popper, Grab, Bat, Grenade) and 2 empty slots that the first unlocks fill; Launch is
	-- the first present at 3 KOs; the Rocket is among the hardest (Toys.HARD_RUNGS). Ladder 5 keeps
	-- what older players had. false = the V8 bar of 5 with the Rocket at 3.
	START_BAR_V9 = true,
	-- WEAPONS window (owner, 26 Nov 2026): no BUY on the weapon cards (the weapons stay for sale in
	-- SHOP), no TRY FREE anywhere (TrialService refuses), and only the next weapon to earn shows its
	-- KOs; every later locked one reads "Locked".
	WEAPONS_NO_BUY = true,
	WEAPONS_NO_TRY = true,
	-- Phone first (NOW item 1, owner 26 Nov 2026: most players are on a phone in landscape).
	HIDE_OWN_TAGS = true, -- your own FOUNDER/VIP tags are hidden from you (others see them, smaller)
	PHONE_SHOULDER_CAM = true, -- a phone holding a gun looks over the right shoulder (GrabController)
	PHONE_AIM_ASSIST = true, -- a wider touch aim pull (PokeController.ASSIST_PHONE) and a buzz on every hit
	PHONE_CLEAR_AIR = true, -- half the fog and a little more colour on phones (ZoneLighting)
	TARGET_ARROW = true, -- a bobbing arrow over the nearest dummy for a new player, first 2 min (Client/TargetArrow)
	GOAL_LINE = true, -- the top pill reads "Next: Bow  3 KOs" (HudV3.drawNext)
	PHONE_QUIET = true, -- phones and tablets: no gift button, no red badges, no pop-ups about gifts/eggs/codes/sales/events, no auto What's New (Client/PhoneQuiet)
	PHONE_MENUS = true, -- phones: near full-screen windows, 2-3 big weapon cards a row without descriptions, FEATURED never shows what you own
	GROUND_RESCUE = true, -- NOW 2: a body with nothing under it is put back on top; a sunk head or chest is lifted (GroundGuard)
	LAZY_SHELVES = true, -- NOW 3: WEAPONS builds a shelf's cards the first time it is shown (was 8,700 UI objects at the start)
	MINUTE_MOMENTS = true, -- NOW 4: a newcomer's goal pill says "Try the cannon!" (2 min), "Feed a creature!" (3), "New place: Island!" (4) with a white outline (Client/MinuteMoments)
	ANGRY_FIRST = true, -- NOW 6: the first dummy a newcomer hits twice gets angry, runs at them, then runs off (Mourning.provoke)
	ANGRY_SHOVE = true, -- NOW 6: that angry dummy gives one harmless funny shove; false = it only scolds (owner to choose)
	SHOP_CHEAP_FIRST = true, -- NOW 8: the shop opens on the R$ 49 Starter Crate and cheaper picks (ShopV9 hero, ShopArt.FEATURED)
	PHONE_MORE_FLAT = true, -- NOW 1.6: MORE on a phone starts with MAPS, LAB, REWARDS, SETTINGS (HudMenu)
	PHONE_BIG_HOTBAR = true, -- NOW 1.8: a landscape phone's hotbar slots 62 x 56 (was 54 x 48) (PokeController.plan)
	-- LAB 10/10 (owner, 26 Nov 2026: "Hele labbet skal tages fra 2/10 til 10/10"; docs/LAB10.md): the crash-test lab:
	-- everything in zones round a test floor (Shared/LabLayout10), the compound frame (Systems/LabV10), a sunny
	-- afternoon (Client/ZoneLighting). false = today's lab (LAYOUT_V3) and the overcast light.
	LAB_V10 = true,
	LAB_PARK = true, -- LAB TARGET (owner, 26 Nov 2026; docs/LAB_TARGET.md): the realistic park look (grass plots, concrete tiles, raised plaza with 4 boards, railway, steel tower, soft daylight) over LAB_V10's spots. false = the LAB10 cartoon look.
	ATTRACT_MODE = false, -- (F19, 26 Nov 2026: off; DEMO_REAL shows machines with real ragdolls) LAB10 R2: every machine shows off with a demo dummy (Client/LabShowcase, this client only)
	TRY_ME = false, -- (FIRST_2_MIN, owner 26 Nov 2026: the floating sign is gone, it flickered and jumped; Client/FirstTwo instead) LAB10 R2: a pulsing ring and TRY! on the nearest untried machine, "Next: try the X!" (Client/LabShowcase)
	PHONE_GIFT_TIMER = true, -- STAY_LONGER 1 (owner said yes, 26 Nov 2026): the gift and its countdown back on phones (no red !, no pop-ups); gifts at 1, 3, 5, 8, 12, 16, 20 min (PlaytimeGifts)
	TRY_REWARD = table.freeze({ count = 6, bolts = 150, each = 25 }), -- STAY_LONGER 2: "Try: CANNON! 2/6" on the goal line, BOLTS when 6 machines are tried (ExperimentService). nil = off
	-- The lab guide (21 Nov 2026, the owner: "a 9-year-old must understand everything in the lab"): a
	-- sign, a glowing drop ring and a FEED button at every creature and station (Server/Systems/LabGuide,
	-- Client/LabGuideClient). false = none.
	LAB_GUIDE = true,
	-- The lava pit v2 (21 Nov 2026, the owner: "make the lava much nicer"): a rounded glowing pool, a rim
	-- of volcanic rocks, embers, heat haze, a bubbling sound and a warning picture (Server/Systems/LavaPit,
	-- Client/LavaClient). false = the flat box with hazard tape.
	LAVA_V2 = true,
	-- (session v848, owner: "udskift lavaen med boxing ring"): the lab's hazard pit is dressed as a
	-- BOXING RING instead of a lava pool (Server/Systems/BoxingPit, V3Assets.BoxingRing). The pool
	-- part stays the trigger and still throws the ragdoll up — only the picture changed. true = the
	-- ring; false = the lava pit (LAVA_V2 / LavaPit).
	BOXING_RING = true,
	-- Icon signs (21 Nov 2026, the owner: "remove distracting text, make it nice signs and icons a child
	-- understands"): the lab's word signs become drawn pictograms (Playground.iconBadge, the signposts,
	-- today's machine, the HUD's key chips and help line). false = the words.
	ICON_SIGNS = true,
	-- The lab re-laid out (21 Nov 2026, the owner: "place everything psychologically best; paths must all
	-- hang together"): the lava moves west with the tower (out of the spawn's first view), the mace back,
	-- the paths a network of loops (PathPlan), the garden walks join the yard road. false = the old lab.
	LAYOUT_V2 = true,
	-- V9-0h (owner, 21 Nov 2026: "analyse deeply what they do with map placement, where things stand and
	-- how big it is, and do the same"; art/store/look_target/leader_hub.webp): the lab core is one big
	-- open floor of large light tiles (LAYOUT_V3_FLOOR, a texture: no parts to flicker), no paths,
	-- verges or lamps inside it, a 40-stud clear circle round the spawn and every attraction on the
	-- rim: the dummy row moves behind the bullseye as a test ring, the BIG RED BUTTON and the ramp
	-- step out to 40+ studs, the lab boards grow. Paths stay outside the floor (yard, gardens).
	-- false = LAYOUT_V2.
	LAYOUT_V3 = true,
	-- V9-0d (owner, 21 Nov 2026: "upgrade the plaza so people want to meet there"): the plaza as a town square
	-- (Server/Systems/TownSquare, Client/PlazaClient): the fountain in the middle, seating groups under
	-- shade trees, benches facing each other, string lights, a toss pit, a meet stage and a photo spot.
	PLAZA_V9 = true,
	-- V9-0s (owner, 21 Nov 2026: "remove the game arena for now"): hidden, not deleted. false: it is not in
	-- Places (so not on the Map Board, the portal, the Maps window or MENU), not built, no arena games,
	-- invites or daily arena goals, and no trip goes there. true brings it all back.
	ARENA_ENABLED = false,
	-- V9-0t: the game is in beta (the BETA code works while true; V9-0l's free GOD MODE reads it too).
	BETA = true,
	-- V9-0u (owner, 21 Nov 2026: "remove the UFO"): hidden, the code stays. false: the UfoBeam event is in no
	-- list (shop, Events window, button, roulette, surprises, admin), nothing starts it, and the first wow
	-- at FIRST_WOW_AT is FIRST_WOW_EVENT instead. Set its developer product to "not for sale".
	UFO_ENABLED = false,
	FIRST_WOW_EVENT = "RocketRain", -- (STAY_LONGER 3: no balloon of new dummies: only the 18 lab dummies; was "BalloonDrop") -- (V9-0u: a balloon drifts over your lab and drops new dummies in)
	-- V9-0i (owner, 21 Nov 2026: "make the whole shop 3D, interactive and beautiful"): the SHOP as a store
	-- (Client/ShopV9): tabs, 3D cards with their own pictures, a detail view, a purchase celebration.
	-- false = the old shop list, untouched.
	SHOP_V9 = true,
	-- V9-0j (owner, 21 Nov 2026: "always a ragdoll to shoot"): bodies standing in your own lab at least, by
	-- device tier (VisitorService.keepTargets: walkers come in from the rim; all under FX_CAPS.ragdolls).
	-- (session v850, owner: "der skal ikke spawne random ragdolls rundt om en, men at dem der står på den
	-- sorte plade nu og står stille bare spawner der og så begår at gå rundt i hele ens map"): the VisitorService
	-- walk-in system (bodies that puff in from the rim into the player's view) is turned off. The ten
	-- lab dummies (Lab.DUMMY_COUNT, see below) stand on the test row and then wander the whole lab on
	-- their own (DummyLife + RowRoam). 0 for every tier means VisitorService.keepTargets never walks
	-- a new body in.
	LAB_MIN_TARGETS = table.freeze({ low = 0, mid = 0, high = 0 }),
	-- V9-0k (owner, 21 Nov 2026: "the floor looks like white tiles, it should look like 3D cushions"): the hub floor
	-- wears a PBR MaterialVariant of soft padded pads (MaterialService "HubPads", place file; 2 x 2 pads a
	-- 28-stud tile = 14-stud pads), still one flat floor part. nil = the V9-0h tile texture.
	HUB_FLOOR_PADS = table.freeze({ variant = "HubPads", material = Enum.Material.Rubber, color = Color3.fromRGB(198, 182, 156) }), -- (NOW 1.3: warmer and a step darker, was 216, 206, 190) (a light warm grey: the white dummies still read brighter)
	-- V9-0l (owner, 21 Nov 2026: "give everyone GOD MODE free because we are still in beta"): everyone gets GOD MODE at
	-- a moment that fits (DummySpawn.grantBeta: attribute GodBeta); the SHOP shows it FREE · BETA; who bought it
	-- is a FOUNDER (gold tag and beam) and keeps it. false = the trial + BUY again (pass owners keep it).
	GOD_FREE_BETA = true,
	-- V9-0w (owner, 21 Nov 2026: "when you shoot for the first time, send them into first person so they
	-- find out they can"): the first shot ever glides into first person once (Client/FirstShotFP; keyboard
	-- and pad, where V / Select bring you back). Settings can turn it off.
	FIRST_SHOT_FP = false, -- (22 Nov 2026, owner: the first shot put you in first person and you could not get out; V still toggles it)
	-- V9-2c (owner, 21 Nov 2026: "Z opens a small menu where you turn time faster or slower in a bubble round
	-- yourself"): Z opens the time dial (Client/TimeDial): 0.1x-3x in a bubble that follows you, in your own lab
	-- (SandboxService.setTime, Client/SlowMotion). false = Z is the old slow-mo spell over the lab.
	TIME_DIAL = true,
	-- V9-P (owner, 21 Nov 2026: "make the BEST physics on all of Roblox"): the ragdolls' physics tuning, all here
	-- (docs/PHYSICS.md, the bench T183). MASS: each part's mass, a real body's spread (pelvis 14 %, thighs
	-- 10 %, upper arms 2.7 %...) over the same total as before (6.4), so the ActiveRagdoll forces stay right;
	-- only dummies (a player's avatar walks as Roblox makes it).
	-- V9-0ac (owner, 21 Nov 2026: "ragdolls should not fall so fast, so you get to shoot them several times; they
	-- should not fall from being shot, they should fall when they die"): a round never knocks a living dummy
	-- down (ActiveRagdoll.gunReaction: a flinch, a stagger, a limp), it drops when the damage kills it
	-- (VitalsService: about 6 Popper rounds, 4 Deagle, 10 SMG, 1-2 shotgun; a headshot at once; a body round
	-- of SHOT_ONE_KILL_POWER or more (Sniper, Railgun, Golden Deagle) at once). A newcomer's rounds do NEWCOMER_DAMAGE times
	-- the damage until FIRST_HITS takedowns (the first KO within 2-3 shots), instead of knocking flat.
	-- Big forces (blasts, the cannon, cars, heavy blows, throws) still ragdoll at once.
	-- V9-0ab (owner, 21 Nov 2026: "if you fall out of your map you spawn back in your lab"): Server/Systems/OutOfBounds.
	OUT_OF_BOUNDS = true,
	-- V9-0e / Phase M (owner, 21 Nov 2026: "much nicer portals and a sign with the maps where you choose"): the Map Board
	-- and the gold PLACES ring portal in every lab's spawn view, a copy at every map's arrival, Solo/Multi in
	-- the same ring family (Server/Systems/MapBoard, Client/MapBoardClient).
	MAP_BOARD = true,
	-- V9-NOW (owner, 21 Nov 2026: "remove one of the two map places"): the gold PLACES ring portal is gone; the Map Board
	-- (tiles with GO) is the one place to pick a map, in the lab and at every map. true = the portal again.
	MAP_PORTAL = false,
	-- V9-NOW 10 (owner, 21 Nov 2026): the small vitals monitor shows the body your round just hit, for HospitalCharts.HOLD
	-- (3) s; a new hit restarts it, another body switches it; no hover. false = the old dead-body hover (Settings).
	MONITOR_ON_HIT = true,
	-- V9-NOW 7 (owner, 21 Nov 2026: "real launch pads instead of neon"): every launch pad is a steel plate with a
	-- rubber mat, bolts, painted colour and pictogram (Playground.realPad); no glowing rings on them (LabGuide).
	REAL_PADS = true,
	-- V9-NOW 14 (owner, 21 Nov 2026): seconds the What's New window stays before it closes by itself (EventShop).
	WHATS_NEW_AUTO_CLOSE = 3,
	-- V9-NOW 11 (owner, 21 Nov 2026): the crash wall behind the row is three big target blocks that topple when shot
	-- (Lab.targetBlocks, Knockables "Block"). false = the old one-piece CrashWall mesh.
	TARGET_BLOCKS = true,
	-- V9-NOW 17 / V9-0ae (owner, 21 Nov 2026: "remove the bullseye"): no bullseye part, rings, sign, machine of the day, cards,
	-- mission (Chain4 is the lava), journal pages or tip; the cannon lands on the open floor. true = it comes back.
	BULLSEYE = false,
	-- V9-NOW 18 (owner, 21 Nov 2026: "no neon glow, it looks like AI slop"): every Neon part over 0.5 stud in the world
	-- goes matte and world screens are no brighter than 1 (Shared/NoNeon, server and each screen); short effects,
	-- tiny LEDs, the lava, characters and tools keep theirs.
	NO_NEON = true,
	-- V9-NOW 20 (owner, 21 Nov 2026: "the Map Board next to the portals"): SINGLEPLAYER and MULTIPLAYER stand either side of
	-- the MAPS board in the spawn's view (MapBoard.travelSpot); the west walk to their old spot is not laid (PathPlan).
	TRAVEL_CORNER = true,
	-- V9-NOW 23 (owner, 21 Nov 2026: "a bow on the start bar"): the Bow takes Launch's slot (Launch: the first present at 3);
	-- hold to draw, let go to shoot, a real arc (Shared/BowMath, Client/BowClient, HitService caps the draw).
	BOW = true,
	-- V9-NOW 24 (owner, 21 Nov 2026: "no hold E anywhere; press the computer itself"): Client/PromptGate: never a hold; mouse and
	-- touch press the thing itself (no E panel), pads one press of the shown prompt; Drive and Talk keep one E press.
	NO_HOLD_E = true,
	-- V9-NOW 12 (owner, 21 Nov 2026): 2X KOs (toward unlocks) and 2X BOLTS (not codes or bought bolts; stacks with the
	-- 2x BOLTS pass) from `from` to `to`, UTC seconds (Shared/DoubleEvent). Starts with this publish, 48 hours.
	DOUBLE_EVENT = { from = 1795270200, to = 1795270200 + 48 * 3600 }, -- (21 Nov 2026 14:10 UTC to 23 Nov 14:10 UTC)
	-- V9-NOW 9 (owner, 21 Nov 2026: "recoil on every gun"): your own shot kicks the camera up by `up` degrees and to a
	-- random side by `side`, `shake` adds a little trauma (the minigun's steady shake); it settles back smoothly
	-- (FeelTuning.KICK_RETURN). Settings "Recoil" FULL/HALF/OFF scales it, Motion LESS halves it. A gun not here
	-- uses FeelTuning.GUN_FX kick.
	RECOIL = {
		Blaster = { up = 1.0, side = 0.3, shake = 0 }, -- (the Popper: small)
		Deagle = { up = 2.6, side = 0.7, shake = 0.04 },
		GoldenDeagle = { up = 2.6, side = 0.7, shake = 0.04 },
		Revolver = { up = 2.3, side = 0.6, shake = 0.03 },
		SMG = { up = 0.55, side = 0.35, shake = 0 },
		TommyGun = { up = 0.6, side = 0.4, shake = 0 },
		AK = { up = 0.9, side = 0.45, shake = 0.01 },
		M4 = { up = 0.75, side = 0.35, shake = 0.01 },
		LMG = { up = 0.7, side = 0.45, shake = 0.02 },
		Minigun = { up = 0.25, side = 0.2, shake = 0.05 }, -- (a steady shake, not a climb)
		Sniper = { up = 4.2, side = 0.9, shake = 0.08 },
		DMR = { up = 2.2, side = 0.5, shake = 0.04 },
		Shotgun = { up = 3.8, side = 1.0, shake = 0.1 },
		AutoShotgun = { up = 2.6, side = 0.8, shake = 0.06 },
		DoubleBarrel = { up = 4.8, side = 1.2, shake = 0.14 },
		FlareGun = { up = 1.8, side = 0.5, shake = 0.02 },
		LaserRifle = { up = 0.3, side = 0.15, shake = 0 },
		Railgun = { up = 5.0, side = 0.8, shake = 0.16 },
		Crossbow = { up = 1.2, side = 0.3, shake = 0 },
		Bow = { up = 0.5, side = 0.15, shake = 0 }, -- (V9-NOW 23: a soft kick on let-go)
		NailGun = { up = 0.3, side = 0.2, shake = 0 },
	},
	-- V9-2b / Phase T (owner, 21 Nov 2026: "a little computer terminal you walk up to and press FEED, spam allowed"): a
	-- terminal by every creature and machine instead of the floating prompt (LabGuide, Client/TerminalClient).
	FEED_TERMINAL = false, -- (owner, 21 Nov 2026: "remove the computers completely, people know to throw the ragdoll there")
	GUIDE_PROMPTS = false, -- (and no feed button in their place: the ring and the sign show where; you throw it in)
	COMPRESSOR = true, -- (owner, 21 Nov 2026: the hydraulic press on the robot vacuum's spot; a ragdoll thrown on the bed is pressed: Compressor)
	-- V9-P fix round 2: the plaster strips on a broken limb are not drawn (on the sculpted skins they read as
	-- stray geometry); they still mark the break (DummyLife's limp), and the vitals monitor shows it.
	PLASTER_VISIBLE = false,
	SHOT_FLINCH = true,
	SHOT_ONE_KILL_POWER = 2.4,
	NEWCOMER_DAMAGE = 2.5,
	PHYSICS_V9 = true,
	PHYSICS = table.freeze({
		MASS = table.freeze({
			Head = 0.546, UpperTorso = 2.047, LowerTorso = 0.955,
			LeftUpperArm = 0.184, RightUpperArm = 0.184, LeftLowerArm = 0.109, RightLowerArm = 0.109, LeftHand = 0.041, RightHand = 0.041,
			LeftUpperLeg = 0.682, RightUpperLeg = 0.682, LeftLowerLeg = 0.314, RightLowerLeg = 0.314, LeftFoot = 0.096, RightFoot = 0.096,
		}),
		-- A limp body on the ground slower than SETTLE_SPEED studs/s loses SETTLE_DAMP of its speed per second
		-- (a soft body: no long rolling after a big fall). ActiveRagdoll.settle.
		SETTLE_SPEED = 6, -- (fix round 2: was 10: a landing rolls and skids out before the assist takes over; reviewer: "velcro")
		SETTLE_DAMP = 2.2,
		-- Joint friction (x Roblox's own), by the part the socket sits in: the neck and the spine swing with weight.
		JOINT_FRICTION = table.freeze({ Head = 2, UpperTorso = 1.5 }),
		-- A living body falling (faster than BRACE_FALL studs/s down) braces BRACE_TTI s before it lands (the
		-- ground looked for BRACE_PROBE studs down): arms straight out, chin tucked (Poses.catch); the arms keep
		-- their tone CATCH_TIME s into the landing. Higher up it windmills.
		BRACE_TTI = 0.35,
		BRACE_PROBE = 30,
		BRACE_FALL = 8,
		CATCH_TIME = 0.25,
		-- The settle assist (fix round 1): only on a flat (normal Y >= SETTLE_FLAT), not bouncy floor found
		-- SETTLE_PROBE studs under the pelvis, braked against that floor's speed; never under SETTLE_MIN_GRAVITY
		-- (Zero-G), in a time bubble or just after a push.
		SETTLE_FLAT = 0.9,
		SETTLE_PROBE = 4,
		SETTLE_MIN_GRAVITY = 150,
		-- A part slower than SETTLE_REST (studs/s and rad/s) is left alone, so the body can fall asleep.
		SETTLE_REST = 0.15,
		-- Only while this machine simulates at most SETTLE_MAX_BODIES limp bodies: a bigger heap is left to the
		-- solver (assisted, a 20-body heap cost a third more solver time; heaped bodies stop each other anyway).
		SETTLE_MAX_BODIES = 8,
		SETTLE_HEAP_RADIUS = 12, -- (fix round 2: the heap is the moving limp bodies within this many studs)
		-- A knocked-down dummy lies at least MIN_DOWN s before it gets up (the assist calms it sooner).
		MIN_DOWN = 3,
	}),
	LAYOUT_V3_FLOOR = table.freeze({ texture = "rbxassetid://91579008413917", tile = 14, color = Color3.fromRGB(222, 222, 216) }),
	-- V9-0 F1 (owner, 21 Nov 2026: "boxy, boring bushes"): real bushes and mesh flowers on the path verges
	-- (V3Assets VergeBushRound/Leafy, VergeFlowers*; tools/ImportV9Foliage.luau). false = the old balls and blocks.
	FOLIAGE_V9 = true,
	-- GOD MODE (21 Nov 2026, the owner: "a pass called God: it gives access to creating life"): spawning
	-- ragdolls is the GOD pass's (Shop.PASSES God), with a free 60 s trial a visit; while the pass id is
	-- 0 live, spawning stays free. Client/GodMode is its window and launcher. false = free for all.
	GOD_PASS = true,
	V8_HAND_RULES = true,
	-- V8-0.4 (one voice on screen): no false toasts (starters "unlocked", "come back tomorrow" on a
	-- first visit, hidden buttons named, a tip for a hazard already done, two unlock lines that
	-- disagree); one toast per 15 s in the first 3 minutes (NotifyRules.EARLY_GAP); no signpost at
	-- the spawn (PathPlan.SPAWN_CLEAR); the spawn turned 40 degrees so the cannon is in view (Lab).
	V8_ONE_VOICE = true,
	-- V8-0.6 (a calm first three minutes): a newcomer gets no NPC chase before CALM_CHASE_AFTER s and
	-- CALM_CHASE_KOS takedowns this visit (both; ChaseService.calmAllows), and no window opens by
	-- itself before CALM_MODALS_AFTER s (Notify.waitBig: egg card, auto egg, What's New, favourite).
	V8_CALM_START = true,
	CALM_CHASE_AFTER = 300,
	CALM_CHASE_KOS = 15,
	CALM_MODALS_AFTER = 180,
	-- V8-0.7 (mild and honest): "KO" for kills on screen; the events sold as products are out of the
	-- BIG RED BUTTON's free pool; EXPERIENCE_NOTIFY off; no share prompt for clips (16+ on Roblox);
	-- a Robux weapon with everything owned pays fixed BOLTS, not eggs (no paid random items).
	MILD_V8 = true,
	-- V8-1.1 (the CRASH score): your own flights from the cannon, a station or a trap are scored
	-- (StuntScore, StuntMath: air, distance, flips, bounces, machines, the bullseye, chains), with a
	-- live count, a landing card with your best and AGAIN. The player's cannon shot is a long arc of
	-- CANNON_AIR s to the same bullseye, with a slow-mo beat at the top (StuntHud).
	STUNT_SCORE = true,
	CANNON_AIR = 2.5, -- (2.2 measured 2.3-2.4 s in the air on the server; 2.5 with the slow-mo beat: about 2.9)
	-- V8-1.2 (hits you can read): a word over the struck body (Dizzy / Wobbly / Knocked out, at most
	-- 2), dizzy stars after a head hit, a 70 ms hit-stop on the body for melee and big hits
	-- (HitWords); the camera shake is undone each frame (no drift); slow-mo slows your own body too,
	-- and gives speed back with no 90 cap (SlowMotion).
	REACTIONS_V8 = true,
	-- V8-1.3 (one mission chain): the first 8 cards are always the same missions in order (KO, BAT,
	-- CANNON, BULLSEYE, GRENADE, WRECKING BALL, 10 KOs, 2,000 CRASH), no timer, SKIP after 60 s, each
	-- paying its stars as BOLTS; the place is kept for every visit (Missions_v1). After the chain a
	-- newcomer never gets a creature or map card.
	MISSION_CHAIN = false, -- (22 Nov 2026, owner: no mission card)
	-- V8-1.4 (unlocks that feel like presents): one "next weapon" for every surface (Shared/NextGoal);
	-- BOLTS buy only weapons BOLTS_BUY_GAP or more KOs away (they bought the rung one KO off); every
	-- unlock gets a 1.5 s reveal that never blocks (ProgressUI.reveal).
	LADDER_V3 = true,
	BOLTS_BUY_GAP = 5,
	-- V8-1.5 (sounds that reward): KOs close together are a combo ("KO! x3", a chime that climbs), and
	-- a short buzz on a pad or phone on a KO, the cannon's launch and a landing (Client/Haptics).
	AUDIO_V8 = true,
	-- V8-1.6 (the chase, fair and later): for everyone, not before 300 s and 15 KOs (both); 2 chasers;
	-- one knocked down is out for good (the counter only counts down); no HP bar: every 3rd punch
	-- throws you; a burst when you clear it.
	CHASE_V8 = true,
	CHASE_V8_COUNT = 2,
	-- V8-2.5 (dummy types and a SPAWN key): H drops a MINI, HEAVY, BOUNCY or FLOPPY dummy where you aim
	-- in your own lab (server-checked, a cap per device, Reset removes them: DummySpawn, SpawnKey).
	DUMMY_TYPES = true,
	-- V8-3.4 (a reason for tomorrow): one missed day a week is forgiven by a streak freeze
	-- (DailyGoals.nextStreak, profile freezeWeek); TOMORROW_AT s into a visit, "TOMORROW: Day N = ...";
	-- Session_v1 keeps streak and dailyClaimed.
	STREAK_V8 = true,
	TOMORROW_AT = 480, -- (21 Nov 2026: 80 -> 480 s, research: early pop-ups drive players away; it comes late in a visit, near the end)
}

-- (GO NOW: THE MAP, 26 Nov 2026: the owner's map is 10x the area: every machine, creature, ragdoll and path spot 3.2 times
-- further out from the spawn; the machines keep their own size. LabLayout10 scales its spots the same way.)
if Config.LAB_OWNERMAP then
	(Config :: any).LAB_SPREAD = Config.LAB_SPREAD * 3.2
end

return table.freeze(Config)
