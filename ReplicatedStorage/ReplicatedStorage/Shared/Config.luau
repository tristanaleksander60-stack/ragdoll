--!strict
-- Global build info and switches. Read-only at runtime.

local Config = {
	GameName = "Hyper Ragdoll Physics \u{1FA78}", -- (22 Nov 2026: the owner renamed it "Hyper Ragdoll Physics 🩸") -- (the owner renamed the game on Roblox, 22 Nov 2026; was "Ragdoll Havoc")
	-- Bumped with every change that goes live (round 5): SessionStats keeps it per visit, so the
	-- numbers of one build can be told from another's.
	Version = "0.62.0", -- (0.62.0, 26 Nov 2026: a hit's turn and push grow with the weapon's force; 0.61.0, 26 Nov 2026: ragdolls are not afraid of weapons, 2 chat and 1 comes up to you, they come fast; 0.60.0, 26 Nov 2026: TRY at the machine, a ragdoll runs to you, the grab lesson once, +25 BOLTS a machine; 0.59.0, 26 Nov 2026: always 3 living ragdolls near you, Multiplayer as a HUD icon; 0.58.0, 26 Nov 2026: gore off: no limbs off, no bones or meat, no red, mild words; 0.57.0, 26 Nov 2026: the gift clock back on phones, gifts at 1-20 min, 150 BOLTS for trying 6 machines; 0.56.0, 26 Nov 2026: the park look: grass plots, concrete tiles, a raised plaza with 4 boards, a railway, a steel tower, soft daylight; 0.55.0, 26 Nov 2026: machines show off by themselves, a TRY! ring on the next machine, coloured zones, dummies on the test floor; 0.54.0, 26 Nov 2026: the crash-test lab (zones round a test floor, a walled compound, a sunny afternoon), a flatter MORE and a bigger hotbar on phones; 0.53.0, 26 Nov 2026: phone first (clean HUD, aim help, goal line, quiet phone), WEAPONS without BUY/TRY, the first angry dummy, minute moments, tutorial grab and maps steps, bodies never fall through; 0.52.3, 24 Nov 2026: the touch crosshair outside first person too; 0.52.2, 24 Nov 2026: on touch only the button fires; 0.52.1, 24 Nov 2026: no "another player is moving this" notice; 0.52.0, 24 Nov 2026: a ragdoll stretching machine where the ramp stood; 0.51.3, 24 Nov 2026: range piers clear of the wall and roof; 0.51.2, 24 Nov 2026: range ragdolls under the roof, desks to the walls, no holes where a burst head was; 0.51.1, 24 Nov 2026: the weapon range finished: real ragdolls, entrance, sign, lamps; 0.51.0, 24 Nov 2026: an indoor weapon range behind the creature yard; 0.50.3, 24 Nov 2026: fewer CPU spikes; 0.50.2, 24 Nov 2026: a small REVIVE button on phones; 0.50.1, 24 Nov 2026: the shot count off the weapon name, . closes the body card; 0.50.0, 24 Nov 2026: a new HUD layout: nav dock, square hotbar, one top row, phone corners; 0.49.1, 24 Nov 2026: RELOAD and AIM stacked at the edge, the body card clear of them, a small arrow when hidden; 0.49.0, 24 Nov 2026: one premium look for the HUD, bar, buttons, crosshair, top bar; 0.48.4, 24 Nov 2026: the gift opens Rewards, the egg over it; 0.48.3, 24 Nov 2026: no wooden posts for now; 0.48.2, 24 Nov 2026: scaffolds gone, a few wooden posts; 0.48.1, 24 Nov 2026: scaffolds break piece by piece; 0.48.0, 24 Nov 2026: wooden scaffolds to knock over; 0.47.99, 24 Nov 2026: no free event button; 0.47.98, 24 Nov 2026: realistic CPR; 0.47.97, 24 Nov 2026: Q closes the talk card; 0.47.96, 24 Nov 2026: no full-egg-slots notice on joining; 0.47.95, 24 Nov 2026: the arms meet at the elbow; 0.47.94, 24 Nov 2026: one head shot with a big gun bursts it; 0.47.93, 24 Nov 2026: a burst head flies in real pieces, no blob; 0.47.92, 24 Nov 2026: the head off at 2 rounds, burst at 3; 0.47.91, 24 Nov 2026: a real pistol sound always; 0.47.90, 24 Nov 2026: the same on consoles; 0.47.89, 24 Nov 2026: less sound memory on phones; 0.47.88, 24 Nov 2026: the Ford is free; 0.47.87, 24 Nov 2026: a little slower with big weapons; 0.47.86, 24 Nov 2026: aim with every gun in first person; 0.47.85, 24 Nov 2026: V works with the arms on; 0.47.84, 24 Nov 2026: the hit card shows health rightly; 0.47.83, 24 Nov 2026: only lost blood kills a ragdoll; 0.47.82, 24 Nov 2026: newspaper in the hand, no egg notice on joining, an angry ragdoll is not afraid; 0.47.81, 24 Nov 2026: a shot ragdoll may get mad, the more the nearer to dying; 0.47.80, 24 Nov 2026: untouched ragdolls help and take the newspaper too; 0.47.79, 24 Nov 2026: the owner gives VIP and ULTRA in the admin menu; 0.47.78, 24 Nov 2026: no E on the map board; 0.47.77, 24 Nov 2026: a ragdoll with a newspaper; 0.47.76, 24 Nov 2026: a map is only picked near the board; 0.47.75, 24 Nov 2026: new dashboard funnels (Funnels); 0.47.74, 24 Nov 2026: a newcomer sees the next untried slot breathe; 0.47.73, 24 Nov 2026: the face follows a head pulled by the arms; 0.47.72, 24 Nov 2026: the mech arms stay over the ground; 0.47.71, 24 Nov 2026: no 3D in the shop, ULTRA shows a nuke; 0.47.70, 24 Nov 2026: shop: ULTRA in POPULAR, GOD MODE is called Spawn Ragdolls; 0.47.69, 24 Nov 2026: the arms hint says Take off machine; 0.47.68, 24 Nov 2026: no red ball when tearing; 0.47.67, 24 Nov 2026: no first person with the arms on; 0.47.66, 24 Nov 2026: the x-ray shows 3 s after every three hits; 0.47.65, 24 Nov 2026: ragdolls help the hurt ones (FirstAid), talk by what they do; 0.47.64, 24 Nov 2026: no FEED ME signs, stars, NEW tags or lava sign in the world; 0.47.63, 24 Nov 2026: a limb is seen pulled slowly out of its joint by the arms; 0.47.62, 24 Nov 2026: a shorter pull tears a piece off with the arms; 0.47.61, 24 Nov 2026: a bigger, clearer x-ray bone on phones; 0.47.60, 24 Nov 2026: far cars drawn lighter on every device, bodies far off lighter; 0.47.59, 24 Nov 2026: cars throw their shadow with four pieces, far cars drawn lighter on phones, tablets, consoles; 0.47.58, 24 Nov 2026: the cars cost Robux again (not the bike), the phone sound fixes on every device; 0.47.57, 23 Nov 2026: phone sounds always find a loaded recording, mesh detail by distance, lighter far bodies on phones; 0.47.56, 23 Nov 2026: the x-ray bone is shot away bit by bit; 0.47.55, 23 Nov 2026: a real-looking x-ray bone, no bandage over it; 0.47.54, 23 Nov 2026: the portal gun is hard to unlock, Talk is not forced onto the bar; 0.47.53, 23 Nov 2026: takedowns are saved as what each visit added, before every teleport and more often; 0.47.52, 23 Nov 2026: x-ray through a limb shot three times; 0.47.51, 23 Nov 2026: two purples by how much a piece bleeds; 0.47.50, 23 Nov 2026: parked cars rest, less drawn on phones, no missions; 0.47.49, 23 Nov 2026: the body card opens at its size the first time too; 0.47.48, 23 Nov 2026: the body card can be hidden; 0.47.47, 23 Nov 2026: the upper body and the legs turn together; 0.47.46, 23 Nov 2026: the dead are not green, the purple stays until they wake; 0.47.45, 23 Nov 2026: only the struck piece of a limb turns purple; 0.47.44, 23 Nov 2026: smaller holes, the bike keeps to the grass and round everyone, hands on the bar; 0.47.43, 23 Nov 2026: real bullet holes, heads burst, no stars, full-speed reverse, seats on the bike; 0.47.42, 23 Nov 2026: a ragdoll rides a bike round the lab; 0.47.41, 23 Nov 2026: bones and stumps sit on the body you see; 0.47.40, 23 Nov 2026: blows hurt where they land, no hands up, lower bubbles, glossier ragdolls; 0.47.39, 23 Nov 2026: hold to hit harder; 0.47.38, 23 Nov 2026: the owner's ragdoll shape, no pinch out of first person while walking; 0.47.37, 23 Nov 2026: glossy grey ragdolls with the owner's face, purple hurt limbs and bandages; 0.47.36, 23 Nov 2026: a pale overcast day instead of sunshine; 0.47.35, 23 Nov 2026: the next weapon comes about three times sooner, a small unlock notice; 0.47.34, 23 Nov 2026: first person crosshair in the middle on phones; 0.47.33, 23 Nov 2026: bats, axes, swords and the like are held upright in first person; 0.47.32, 23 Nov 2026: picking a weapon and the first strike go to first person, no bone journal; 0.47.31, 23 Nov 2026: on a phone the picked weapon pressed again leaves the hand; 0.47.30, 23 Nov 2026: the mech arms stay on on phones; 0.47.29, 23 Nov 2026: a small first-person eye on phones; 0.47.28, 23 Nov 2026: one big action button for every tool and a RELOAD button on phones; 0.47.27, 23 Nov 2026: phones load in faster and draw less, no LAB VIEW or RAGDOLL button on phones; 0.47.26, 23 Nov 2026: the client boot no longer stops half way (gamepad, likes, catalog start again); 0.47.25, 23 Nov 2026: the hit card only for bodies you gave a creature yourself; 0.47.24, 23 Nov 2026: the multiplayer place is on; 0.47.23, 23 Nov 2026: ready for Play straight into singleplayer, multiplayer in a place of its own; 0.47.21, 23 Nov 2026: one green tiled floor over the whole lab; 0.47.20, 23 Nov 2026: every own shot is heard on phones and consoles; 0.47.19, 23 Nov 2026: three ragdolls always walk about on the spawn circle; 0.47.18, 23 Nov 2026: no TAP A DUMMY on phones; 0.47.17, 23 Nov 2026: benches the lab ragdolls sit down on; 0.47.16, 23 Nov 2026: lab ragdolls spread round the whole lab; 0.47.15, 23 Nov 2026: the ones that do not run stay put and face the gun; 0.47.14, 23 Nov 2026: only half the ragdolls run from a gun; 0.47.13, 23 Nov 2026: casings are heard when they land; 0.47.12, 23 Nov 2026: on a phone a tap on a ragdoll grabs it; 0.47.11, 23 Nov 2026: the shark swims under water with its fin up, the whole rocket flies; 0.47.10, 23 Nov 2026: CPR and punches are seen; 0.47.9, 23 Nov 2026: shots stay until dead and alive again, CPR really works 33%, else mostly attacks, new CPR moves; 0.47.8, 23 Nov 2026: zombies gone, every 3rd failed CPR attacks, one look through the join; 0.47.7, 23 Nov 2026: softer, matte ragdolls; 0.47.6, 23 Nov 2026: every shot stays on a body and on its card; 0.47.5, 23 Nov 2026: a killed zombie loses its ZOMBIE text at once and wakes up normal; 0.47.4, 23 Nov 2026: the mouse works in every window in first person (weapons, maps, multiplayer), and they stay open; 0.47.3, 23 Nov 2026: the compressor at its original size, back in the lab, in machined steel; no Reloading notice; 0.47.2, 23 Nov 2026: one loading screen on the way to your own server at a join, the first player of a server is sent on too, 3 slots and only the next locked weapon, the owner watches people in singleplayer; 0.47.1, 23 Nov 2026: the mech arms fold back after Q (their rest pose kept on each joint, not in a weak table); 0.47.0, 23 Nov 2026: someone passing through a multiplayer server on the way to their own gets no lab built there (no lag for the players who stay); a failed teleport gives them one after all; 0.46.9, 23 Nov 2026, multiplayer bug hunt: arrivals go straight into the shared lab (no own lab built and torn down), the cover lifts for guests at once (no 12 s wait), a guest's events and place are the shared lab, not the plaza, guests use the sandbox buttons and GOD MODE in it; 0.46.8, 23 Nov 2026: multiplayer never takes over someone else's own lab; a friend who follows someone in a shared lab joins it; 0.46.7, 23 Nov 2026: the mech arms hint under the Next pill, X takes the arms off (no revive-all while you wear them); 0.46.6, 23 Nov 2026: the mech arms fold onto your back at rest, reaching forward only while you hold Q; 0.46.5, 23 Nov 2026: the shark no longer jitters back and forth over the water; 0.46.4, 23 Nov 2026: singleplayer by default: joining through Play takes you to a server of your own; public servers are the multiplayer servers (in through the portal); on your own server only the MULTIPLAYER portal (the server list), on a multiplayer server also SINGLEPLAYER back to your own; 0.46.3, 23 Nov 2026: the SINGLEPLAYER portal is back (out of the shared lab), the MULTIPLAYER portal opens the server list again with PLAY WITH EVERYONE HERE on top; 0.46.2, 23 Nov 2026: when the host of a shared lab leaves, a guest takes it over as it is: no reset, nobody moved; 0.46.1, 23 Nov 2026: no start menu, you join in your own lab; one MULTIPLAYER portal: in = the shared lab with the others on this server (no teleport unless you are alone), again = back to your own lab; 0.46.0, 23 Nov 2026, phase D: the chicken pecks, sits, lays an egg that hatches; the washer door, a ragdoll spinning behind the glass in red water; the plant's jaws snap, chew and spit bones; the mole drags bodies under and bursts up elsewhere; the slingshot trees bend and whip; the shark patrols its tank and the water foams; a warning before every event; cannon smoke and recoil; 0.45.8, 23 Nov 2026, phase D: the frog turns to its catch, puffs its throat, a sticky tongue reels the body in, a lump kicks in its belly, then it burps slime and bones; 0.45.7, 23 Nov 2026: the mech arms rise over the shoulders and curl forward, the lower pair stands like legs; steel tubes with pistons, joint housings, jointed claws; 0.45.6, 23 Nov 2026: SINGLEPLAYER on a public server takes you to a server of your own, so it never holds a place the multiplayer players could use; 0.45.5, 23 Nov 2026: MULTIPLAYER with no shared lab on the server puts you in another player's lab (the one here longest) instead of leaving you alone; 0.45.4, 23 Nov 2026: players sharing a lab may grab and throw each other in it, like the top ragdoll games; 0.45.3, 23 Nov 2026: in a shared lab the body goes to whoever hits it (simulated on their own machine, no round trip through the host), back to the lab's player when they leave; 0.45.2, 23 Nov 2026: HOTFIX the server boot no longer stalls ~16 s waiting for the Remotes folder (PurchaseChat, MechArms), labs come at once; 0.45.1, 23 Nov 2026: a cover from the very first frame (ReplicatedFirst FirstCover, place file), no Roblox plate before the start menu; 0.45.0, 23 Nov 2026: MULTIPLAYER goes to the server with the biggest shared lab (else the fullest; none fuller: here), and everyone who arrives through multiplayer joins that server's one shared lab; 0.44.9, 23 Nov 2026: MULTIPLAYER from two servers ends in the same lab: with no shared lab on your server you go to the one shared-lab server everyone else picking MULTIPLAYER goes to; 0.44.8, 23 Nov 2026: faster in after the start menu: the world streams in while it is up, it lifts once the lab and 3 ragdolls are in, the lab fills after 2 s at most; 0.44.7, 23 Nov 2026: no green outline on a ragdoll you point at, the view bobs as you walk and run in first person, both hands on the weapon (first person and on the run), the multiplayer portal only changes server; 0.44.6, 23 Nov 2026: hold Q and pull to rip again (no clicks), the stand turns its arms to you, no Roblox plate after the start menu, MULTIPLAYER puts everyone in one shared lab on the server, the two portals on the spawn circle's rim; 0.44.5, 23 Nov 2026: WEAPONS on the hotbar from the first second, the start menu waits until the whole world is in, MULTIPLAYER opens a hub: one lab together, friends to join, every server, your own server; 0.44.4, 23 Nov 2026: the mech arms rest behind you, Q grabs a limb (the body holds still), clicks rip it with blood and a widening wound, strands of flesh as it comes off, seen in first person; no [T] under WEAPONS; the start menu stays until the lab is in; 0.44.3, 23 Nov 2026: the mech arms move (joints by C0), hold Q on a limb and pull to rip it off (a strain bar), no flicker on the stand, the view turns freely by it; 0.44.2, 23 Nov 2026: the mech arms work (their remote was made before the Remotes folder; the same fix for the purchase chat and WASTED), their stand beside the LIKE GOAL post; 0.44.1, 23 Nov 2026: the start menu buttons in the middle, hopping, SINGLEPLAYER left, a pick always shows (a squish and a line); 0.44.0, 23 Nov 2026: one ragdoll comes running in shock and gives CPR, the dead lie 20-30 s, MECH ARMS on a stand by the spawn: E to wear them, Q to tear ragdolls apart; 0.43.1, 23 Nov 2026: no "See their pulse" notice, animals only come for you when you shoot them from close by, 2 head shots take the head off (spine sticking up, blood spurting), the WEAPONS key chip shows, casings fall out, land and clink, the start menu over our thumbnail; 0.43.0, 23 Nov 2026, V11 phase D 1: a light flash on every shot and blast by weapon; ragdolls are shocked by the dead, kneel and mourn them, try CPR (it sometimes works); 0.42.0, 23 Nov 2026, V11 phase C: a 3D start menu (SINGLEPLAYER or MULTIPLAYER), MULTIPLAYER takes you to a server where everyone shares one lab, SINGLEPLAYER brings you back; 0.41.0, 22 Nov 2026, V11 phase B: a new portal gun (white with a green glass core) and green swirling portals that players walk through too, unlocked at 4 takedowns; Robux purchases in chat on every server; 0.40.0, 22 Nov 2026, V11 phase A: no pop-ups (red counters on the gift and WEAPONS, a "!" on the gift for an egg: tap it to open), no takedown message, the picked slot key again empties the hand and leaves first person, only the rocket flies; 0.39.6, 22 Nov 2026: dead ragdolls say nothing; 0.39.5, 22 Nov 2026: a big CLOSE button on the free egg window; 0.39.4, 22 Nov 2026: 3 rounds in the hips cut a ragdoll in half at the waist, blood spurting from both ends, bones showing; 0.39.3, 22 Nov 2026: ragdolls shine less (no reflection), zombies never flee, WASTED when a zombie kills you; 0.39.2, 22 Nov 2026: no round thigh tops sticking out at the hips: the hips reach down over the joint instead; 0.39.1, 22 Nov 2026: a key chip on the WEAPONS button; 0.39.0, 22 Nov 2026: every 3rd lab dummy killed rises as a green zombie (red outline, ZOMBIE tag) that hunts and hits its lab's player; killed again it wakes up normal; 0.38.9, 22 Nov 2026: a soft overcast light like the biggest ragdoll game (no harsh sun), glossy ragdolls (smooth plastic, a little reflection, head and body alike); 0.38.8, 22 Nov 2026: the thighs reach up into the hips; 0.38.7, 22 Nov 2026: ragdolls flee at half the speed, skins no longer overlap at the joints, bullet holes sized by the weapon (a pistol small); 0.38.6, 22 Nov 2026: Shop/More/Lab keys open their windows (one toggle), no crash-test logo, the like sign's posts beside its text, bullet holes on the true skin surface, skins the head's plastic; 0.38.5, 22 Nov 2026, V10 phase 4: a MAPS board at the plaza, the lab board beside the red button, the button's event in every lab on the server, a wooden LIKE GOAL post; 0.38.4, 22 Nov 2026, V10 phase 3: shoot an animal and it eats you (WASTED, back in your lab), every creature tears and bleeds, melee swings in first person, the crash-test marks on the body behind the holes; 0.38.3, 22 Nov 2026: key chips show the key, WEAPONS always shows its key, no holes on edge grazes, EQUIP in first person puts it in your hand, press yourself flat, cars explode and come back; 0.38.2, 22 Nov 2026, V10 phase 2: the name Hyper Ragdoll Physics, cars free, a wiggling gift, key chips on Shop/More/Lab, matte ragdolls, flat bullet holes, no pictograms, the talk wand pointing ahead, a solid shark, takedowns from the press, the creatures and the rocket; 0.38.1, 22 Nov 2026: phones play in landscape (LandscapeSensor) and keep the next 3 weapons on their own row; 0.38.0, 22 Nov 2026, V10 phase 1: fewer lab ragdolls on phones (9) and tablets (13), a load cover until the lab and its ragdolls are in, the next 3 weapons from the first second (upright phones too), the phone crosshair only where you shoot, no Replay on phones, a "loaded" funnel step; 0.37.20, 22 Nov 2026: the weapons menu works in first person (stays open, the mouse is free while a window is up); 0.37.19, 22 Nov 2026: the crash-test marks hide with the body in the press; 0.37.18, 22 Nov 2026: the giant fan out of the portals' way, E at the rocket straps a ragdoll on and it flies and bursts; 0.37.17, 22 Nov 2026: the compressor posts run from the footing up into the top beam, with foot plates and side braces; 0.37.16, 22 Nov 2026: the compressor 3x instead of 10x, just behind the lab; 0.37.15, 22 Nov 2026: the compressor 10x bigger, standing behind the lab past the portals; 0.37.14, 22 Nov 2026: the portals and the MAPS board where the white target blocks stood, behind the spider; no stone path under them; the spider further forward; 0.37.13, 22 Nov 2026: the Silvia and the Ford turned the right way, the boxing ring in the west garden by the frog, the portals and the MAPS board between the launch and the danger areas; 0.37.12, 22 Nov 2026: three new vehicles (Silvia drift car, Ford truck, Panzer tank) behind game passes, the old cars gone; the spider wraps a still copy in the web while circling it; 0.37.11, 22 Nov 2026: fixed the empty lab (a comment broke Playground), a slide you cannot climb that carries you down, the spider bites, wraps and drains its catch, the shark drags it under, the water goes red and it spits bones with meat; 0.37.10, 22 Nov 2026: no castle, a giant trampoline under the tower that throws higher, no flicker on the tower top, the slide starts from an open platform; 0.37.9, 22 Nov 2026: a sky bridge between the towers, a slide down from it, a sky deck and six jump steps up to it; 0.37.8, 22 Nov 2026: no spinning mace, the shark tank in its place, no paths in the lab (only the plaza and the platforms); 0.37.7, 22 Nov 2026: harder cannon, cannon and wrecking ball tear pieces off, no walk across the launch area, no "Wobbly", no stars over the pancake; 0.37.6, 22 Nov 2026: the press: a ragdoll-shaped pancake with its face, a slow squeeze, a wet splat, blood dripping off the bed; the face hides with the body; 0.37.5, 22 Nov 2026: one walk per area from the plaza to its ground, no bench or flower beds on the plaza, lamps between the walks; 0.37.4, 22 Nov 2026: the game is called Hyper Ragdoll Physics; 0.37.3, 22 Nov 2026: no shot count by the crosshair (the reload ring stays), narrower walks with round ends, a stone floor under the boxing ring, the spider in front of the spawn instead of the black mat; 0.37.2, 22 Nov 2026: the travel corner on a stone platform, the launch pads all on their area, the boxing ring behind the spawn, the spawn faces the cannon and the wrecking ball; 0.37.1, 22 Nov 2026: lab spread 1.2, four themed areas (launch, cars, danger, height) with their own ground, cars and stations moved into their areas, props fill the gaps, lamps and benches on the plaza; 0.37.0, 22 Nov 2026: a much bigger lab (LAB_SPREAD 1.6): machines further out, a lawn with a stone plaza at the spawn and paved walks to every machine; 0.36.9, 22 Nov 2026: a cut-off limb leaves a real stump (flesh, bone, drops), not a disc; 0.36.8, 22 Nov 2026: arms, forearms, hands, legs, shins and feet come off after enough rounds; the card shows the name, the shots and missing pieces; 0.36.7, 22 Nov 2026: ragdolls say a line for where they are hit, small text, one at a time; 0.36.6, 22 Nov 2026: bullet holes sit in the ragdoll, the monitor card shows only Blood and Awake with the bones; 0.36.5, 22 Nov 2026: Talk works in first person (the mouse is freed while its card is up); 0.36.4, 22 Nov 2026: 2X, Next and gift centred over the hotbar; 0.36.3, 22 Nov 2026: 2X and the gift match: dark circles, same size, same gap round the Next pill; 0.36.2, 22 Nov 2026: 2X is a round icon like the gift, the three sit a little lower; 0.36.1, 22 Nov 2026: the 2X chip, the Next pill and the gift side by side in the top bar; 0.36.0, 22 Nov 2026: Shop, More, Lab on the left; no God or Maps squares; 0.35.9, 22 Nov 2026: the next-weapon pill on the gift's line, centred, 1.2x; 0.35.8, 22 Nov 2026: a bigger next-weapon pill under the top bar; 0.35.7, 22 Nov 2026: ragdolls go into the cannon and fly out of its muzzle; 0.35.6, 22 Nov 2026: a much nicer Talk wand; 0.35.5, 22 Nov 2026: no E talk prompt at the ragdolls; 0.35.4, 22 Nov 2026: smaller hit card, an attacker turns and walks 2.5 s first, ATTACK WHO lists 8 from the whole lab, steady marking; 0.35.3, 22 Nov 2026: an NPC with a gun shoots from 30 studs; 0.35.2, 22 Nov 2026: ATTACK fights until the other one is dead, the wand is "Talk" with a drawn icon, green and red outlines in the talk card; 0.35.1, 22 Nov 2026: the wand in your hand with its own icon, its talk card stays open, the sign posts stop under the board; 0.35.0, 22 Nov 2026: the Magic Wand (talk) on the start bar, funny NPC names, the monitor when you point at a ragdoll close by, carry ragdolls into the press; 0.34.13, 22 Nov 2026: the next-weapon pill in the middle of the top bar, right click no longer throws a held ragdoll, the grab passes through the press frame; 0.34.12, 22 Nov 2026: the free event button is a small stand with a sign, every 5 minutes; 0.34.11, 22 Nov 2026: small dressing parts cast no shadows (less lag); 0.34.10, 22 Nov 2026: a ragdoll carried into the press is not pressed or blown away until you let go; 0.34.9, 22 Nov 2026: recoil in first person, the press ram follows the plate, pressed ragdolls go flat as pancakes; 0.34.8, 22 Nov 2026: shots go exactly through the crosshair, no steering wheel over cars, the kart's own seat is off; 0.34.7, 22 Nov 2026: windows close by themselves in first person, the eye chip is first person (V); 0.34.6, 22 Nov 2026: white ragdolls, a slow rot on death that fades before they wake, no Dizzy text; 0.34.5, 22 Nov 2026: no first person on the first shot; 0.34.4, 22 Nov 2026: the crosshair follows the recoil, one crosshair on phones, lab dummies fear guns; 0.34.3, 22 Nov 2026: no mission card; 0.34.2, 22 Nov 2026: 18 lab dummies and no other ragdolls, the car starts in the chase camera; 0.34.1, 22 Nov 2026: guns fire again, lab dummies roam the whole lab from the start; 0.34.0, 21 Nov 2026: a supercar, a jeep and a go-kart in every lab, smoother steering; 0.33.7, 21 Nov 2026: no feed computers or feed buttons, you throw the ragdoll in; 0.33.6, 21 Nov 2026: terminals and the Map Board: the view turns freely, presses work close up, left click only; 0.33.5, 21 Nov 2026: the view turns freely near a terminal; 0.33.4, 21 Nov 2026: skip or hide missions, keys for everything (E use, - skip, = hide, 7 GOD, 8 LAB, 9 MORE); 0.33.3, 21 Nov 2026: weapons sit in the hand on every avatar, running dummies over is a KO; 0.33.2, 21 Nov 2026, V9-NOW 24: no hold E, press the thing itself; 0.33.1, 21 Nov 2026, hotfix: the bow shot one arrow but looked and sounded like two, a feed terminal stood in the wrecking ball's arc; 0.33.0, 21 Nov 2026, V9-NOW 17-21: no bullseye, no neon glow, the crash wall badge out of the wall, a travel corner (MAPS board + portals), KOs from every event you start; 0.32.0, 21 Nov 2026, V9-NOW 11-16: target blocks that topple, the 2X KO + BOLTS event, What's New closes itself, the monitor in the corner, cars with a cockpit and sounds; 0.31.1, 21 Nov 2026, V9-NOW hotfix: bullet holes on every dummy, a reaction by where it is hit, one map place (the board); 0.31.0, 21 Nov 2026, V9 milestone 1: GOD MODE free in the beta with aimed patterns, the time dial (Z), grey matte ragdolls, the first shot in first person, bigger unlock gaps, the 3D shop, codes, the town square, padded hub floor, always a ragdoll to shoot; 0.30.0, 21 Nov 2026: wide paths (twice as wide, no stub at the bullseye), GOD MODE: create life with a free 60 s try; 0.29.0, 21 Nov 2026: connected path network with a plaza, grass verges with bushes, a real lava pit, icons instead of words, a full 6-weapon start bar, toss buttons at the cannon, lava and trampoline, fewer pop-ups; 0.28.0, 21 Nov 2026: every weapon its own sound, a 4-tool start bar with Launch at 3 and the Rocket among the hardest, SURPRISE-style banners, nicer lab paths, a FEED button, sign and drop ring at every creature and station; 0.27.1 UI audit before the ads, 21 Nov 2026: one WEAPONS button, a quiet start, signs in the world, knockable barrels/crates/cones, the weapon in your hand in 3D; 0.27.0 V8-1..6: CRASH score and the long cannon arc, missions, readable hits, fair chase, spawn dummies, streak freeze, admins, 21 Nov 2026; 0.26.0 V8-0: the first hit lands, a full bar from the start, a calm first minutes, the cannon in view, 21 Nov 2026; 0.25.0 v7: paths, crash-test dummies, event banner card, console layout, 20 Nov 2026; 0.24.0 v6: notifications, admin and director menus, bigger lab with garden, creature yard, birds, map shop, 20 Nov 2026; 0.18.0 phase 0; 0.19.0 phases 1-3; 0.20.0 the release; 0.21.0 v3 look, cars, animals; 0.22.0 open-air maps, launchers, disasters, train, throw tower, 19 Nov 2026; 0.23.0 v4: talk to NPCs, real gorilla and bulls, 11 surprises, cars, slow-mo, lab zones, 20 Nov 2026; SessionStats also keeps game.PlaceVersion)
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
	LAB_SURPRISES = false, -- (22 Nov 2026, owner: only the 18 lab dummies; was true) -- v4 C4: a short surprise (Surprises.MINI) by itself now and then in your own lab
	LAB_SURPRISE_GAP = Vector2.new(150, 240), -- s between them (random in the range)
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
	ATTRACT_MODE = true, -- LAB10 R2: every machine shows off with a demo dummy (Client/LabShowcase, this client only)
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
	FIRST_WOW_EVENT = "BalloonDrop", -- (V9-0u: a balloon drifts over your lab and drops new dummies in)
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

return table.freeze(Config)
