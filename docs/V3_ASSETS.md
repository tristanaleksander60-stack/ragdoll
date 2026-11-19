# V3 assets: free Creator Store picks (19 Nov 2026)

Goal: replace the code-built "AI junk" (ball-on-cylinder trees, terrain hills, box cannon, box cars) with free Creator Store models in one semi-realistic, clean, PBR/mesh style close to Hyper Realistic Ragdoll.

How the picks were made: toolbox-service search (category 10, 30 to 40 results per keyword, 2 to 6 keywords per role) + items/details (creator, votes, triangles, MeshPart and script counts) + 420x420 thumbnails, judged by eye on contact sheets. Roblox's own account (creator "Roblox", id 1) was searched separately with `creatorTargetId=1&creatorType=User`, and its 2021 to 2023 PBR packs are the backbone for consistency.

Read the columns this way:
- **Votes**: up-votes / up-vote %. The API gives no favourites count: catalog.roblox.com is blocked here and the details call has no favourites field. Some newer items hide their votes and show 0 / 100%.
- **Verified**: the API returned `isVerifiedCreator = true` for almost every creator, so the flag tells the picks apart very little. **Roblox** = Roblox's official account.
- **S**: number of Script instances in the model. Strip them all on import. Every "S>0" pick also needs the usual malware check (search the model for `require(`, `getfenv`, and Script/ModuleScript names such as "Runtime" or "CoreValidation", like the ones found in round 5).
- **Tris**: total for the whole model or pack. Packs: keep only the pieces you use.

General import rules:
- Anchor every piece.
- Set CanCollide off on decoration.
- Set CollisionFidelity Box or Hull on anything ragdolls hit.
- Scale to the lab: dummy ~5.5 studs, car ~15 studs long.
- Put each model under `ServerStorage.N7Assets.Props.<Role>`. These models live only in the place file, so remind the owner to SAVE.

## Contact sheets (final)
The picks and backups are labelled with the asset id. A yellow "S<n>" means scripts; the white line shows the name, up-votes, up-vote % and k-triangles.
- Lab picks: `/tmp/claude-0/-home-user/8743c2c0-428b-580a-b1a5-a388cd60c08e/scratchpad/assets/sheets/final_lab.png`
- Lab backups and extras: `/tmp/claude-0/-home-user/8743c2c0-428b-580a-b1a5-a388cd60c08e/scratchpad/assets/sheets/final_lab2.png`
- Nature and animals: `/tmp/claude-0/-home-user/8743c2c0-428b-580a-b1a5-a388cd60c08e/scratchpad/assets/sheets/final_nature_animals.png`
- Maps: `/tmp/claude-0/-home-user/8743c2c0-428b-580a-b1a5-a388cd60c08e/scratchpad/assets/sheets/final_maps.png`
- Roblox official packs: `/tmp/claude-0/-home-user/8743c2c0-428b-580a-b1a5-a388cd60c08e/scratchpad/assets/sheets/official.png`
- The per-role search sheets are in the same folder (tree_decid, pine, palm, bush, rock, grass, mountain, fan, rocket2, slide, cannon, cannon2, car, truck, tank, barrel, crate, wall, ring, combo1-5, maps1-2, extra2).
- These are scratch files and can be cleared. Re-run `scratchpad/tools/scout.py` / `sheetids.py` to rebuild them.

## Lab / Test Ground

| Role | Pick id | Name | Creator | Votes | Why | Backup id | Notes |
|---|---|---|---|---|---|---|---|
| Big industrial fan | 104680325645946 | MaxxAir Fan | wei_huan | hidden (0/100%) | Real yellow drum fan, 105 MeshParts, reads instantly as "wind machine" | 290574315 Industrial Floor Fan (BackupSilly10, 8/81%) | S2, 29k tris. Remove the small brand badge on the hub (the "MaxxAir" name). Scale up 3-4x for a wind tunnel. |
| Rocket | 220664616 | Delta IV Rocket | Pulsarnova | 26/89% | Only semi-realistic rocket + launch tower found; clean white/orange | 5380747922 WORKING Rocket Ship (DomiusAngelo, 184/92%) | S0, 32k tris, part-built (no MeshParts). Real launcher type, no logos seen. Weak market overall. |
| Playground / slide tower | 3699248235 | Playground: Citrus | BlueNebula10 | 1700/85% | Best-rated playground, mesh tube slides, clean | 5706899551 Drop water slide (bearwilliam, 29/97%) | S9, 81k tris; bright colours. Tone them down to match the natural palette. No good free water-slide tower exists (the "Tornado" one copies Six Flags, skipped). |
| Cannon | 4558839272 | Old Cannon | StarModelX | hidden | Big flared mesh barrel on a wooden carriage: reads as "human cannon", far better than the current 14278051688 | 18435394013 Parabellum artillery cannon (guypro13, 51/85%) | S2, 11.7k tris, 4 MeshParts. Backup is more realistic but 53k tris, S25. No good circus cannon exists. |
| Sedan car | 6418239833 | Sedan | **Roblox** | 92/92% | Official PBR vehicle kit, matches the other Roblox picks | 6418234850 SUV (**Roblox**, 192/96%) | S70 (A-Chassis); strip it for a static prop, or keep it if VehicleService uses its own drive. 75k tris: one per lab max. Static wreck option: 11875993626 abandon car (3k tris). |
| Monster truck | 1222491712 | Monster Truck Auto Flip | Domukas3123 | 39/78% | Plain white unbranded lifted pickup on big tyres | 6418225759 Pickup Truck (**Roblox**, 186/93%) | S17, 66k tris. Skipped Grave Digger / Urus / Raptor / LA Rams (brands). |
| Tank | 1379706428 | Panzer IV tank | creepercatchanel | 765/85% | Most-voted realistic tank, light at 7k tris, no scripts | 11036026075 Tank AI (jux43, 85/95%) | **Check for WWII insignia (Balkenkreuz) on the hull decals and remove them.** Backup is a modern camo tank (S1). |
| Red oil barrels | 9021582812 | PBR Oil Barrel | Wabbiits | 10/100% | Real PBR rusty red drum, 906 tris, 1 MeshPart | 14452389275 Barrel Metal (JSCHRISP, 10/100%) | S0. Has a small generic flame hazard sign (fine). For "red-white", recolour the band with a SurfaceAppearance tint or a decal. |
| Brick wall section | 1425120075 | Realistic Brick Wall | Owl4110 | 18/92% | Chunky textured wall, 2.7k tris | 104053043839965 Old brick wall, mossy (Guest_62246, 27/91%) | Better still: Parts + the Brick material from **10841357434 Realistic Material Variants - Duvall Drive (Roblox, 950/95%)**, so walls can break per-brick. |
| Boxing ring | 10218162623 | Boxing Ring | WhoosherDoo | 18/93% | MeshPart ring, white canvas, neutral | 1404734428 Boxing Ring (Shiperoni, 10/100%) | S0, 46k tris (50 meshes). |
| Wooden crate | 8458216263 | PBR Crate | Tohb | 69/99% | True PBR crate, 596 tris | 3272950683 Wood Crates (nextlevelgabriel, 384/96%) | S0. |
| Big red push button | 14087568246 | Button | Pixelgamer1989 | 17/89% | Clean mesh dome on a steel base | 15240203293 red_button (Bluemin926, 16/83%) | S0, 620 tris. Scale 4-6x for the BIG RED BUTTON. |
| Park bench | 185280084 | Generic Park Bench | Carollicious | 1820/91% | Classic cast-iron + wood, very popular | 14874085291 Park Bench (Tammy5632) | S0, 5.6k tris. |
| Castle tower | 899477954 | Castle Watch Tower [OLD] | inoobe_xi | 26/89% | Round stone tower with a battlement, natural colours | 101559450428915 Castle Tower (PanBarrier, 57/95%) | S0, 30k tris, part-built. The backup's name says it is from the game "Doors" (IP risk): use only if it carries no Doors marks. |
| Swimming pool | — | **no good option** | | | Free pools are flat part boxes | 7429385071 (kfiros1, 130/65%) | Build it in code: Duvall tile MaterialVariant + Terrain water + Creator Store ladder. |
| Concrete bunker | — | **no good option** | | | Results are doors/part blobs | 931910200 Quonset hut (see Maps) | Build from Concrete parts + Duvall concrete variant. |
| Train locomotive | 302873713 | Pro Series: Pluto Locomotive | NWSpacek | 162/81% | Generic steam loco, no operator logo | 10570360936 Moving train mesh (J3xetor, 89/89%) | Pick: S15, 25k tris. Backup is a nicer 4.9k single-mesh diesel, **but its texture has a real railway emblem on the nose**: only use it re-textured. Strip its "KILLS" script (S3). |
| Rails | 925820578 | Modern train tracks | ItayLevy | 180/90% | Proper sleepers + rails, curves included | 388174618 Train Track (CarlPIandog, 356/89%) | S0, 56k tris for the whole set; use 2-3 straight pieces. |
| Jersey barrier | 8325588430 | PBR road barrier | GREGi_playS | 99/99% | Scanned-look PBR concrete | 2766525411 road barrier (SiameseMouse, 665/95%) | S0, 9.8k tris (backup 368). |
| Traffic cone | 23153487 | Traffic Cone | **Roblox** | 376/94% | Official, 326 tris | 12094920818 [UK] Road Cone (CreativeDevise) | S0. |
| Street lamp | 11146095708 | Street Lamp | BryanROBLOXgamer10 | 88/98% | Modern curved mast fits a test ground | 404475960 Street light (Simoon68, 3640/91%) | S0. Has a big SpotLight cone in the thumbnail: count it against the WorldLights budget. The backup is Victorian style. |
| Fence (chain-link) | 9083814252 | Metal Gated Fence | HotRodGT66 | 445/89% | Mesh chain-link panel, 1.4k tris | 4831942116 Farm Fence, wood (OneMangryGamer, 658/94%) | S0. Also 4715423769 border fence with razor wire (930/93%). |
| Trampoline | 7829441554 | Trampoline | Ashbashthesmash | 26/89% | Real backyard trampoline with safety net | 89910882365911 (dadox034, 10/100%) | S1, 34k tris, part-built. Remove the net for ragdoll launches. |

## Nature

| Role | Pick id | Name | Creator | Votes | Why | Backup id | Notes |
|---|---|---|---|---|---|---|---|
| Deciduous tree | 6432306802 | Forest Pack | **Roblox** | 1940/97% | Official PBR pack: leafy trees, pines, bushes, rocks, logs, all one style | 3755594081 tree (Astrooworlld, 644/92%) | S13 (wind/LOD helpers, strip). 153k tris for the whole pack; one tree is a few k. The backup is a single realistic mesh of 1.7k tris. Stylised-smooth option: 580221169 Tree (SheriffTaco, 6650/95%). |
| Pine tree | 11664016667 | PBR Pine Trees | EnvirobIox | 56/94% | Real PBR pines, 2 variants | Forest Pack pines / 5392132809 Realistic Pine Tree (GabeQZ) | S0, 14k tris for 2 trees. |
| Palm tree | 1567799120 | Coconut Palm Tree Set | DJLCyber | 87/87% | 4 curved palms with coconuts, natural colours | 10562894034 Palm Tree (Realistic) (Natalie_Clabo, 279/93%) | S0, 12.6k for 4. The backup is only 316 tris. |
| Bush | 8647777369 | Bush | Seespotbyte | 1860/93% | Dense realistic leaf cards, 576 tris | 8344171779 Flower Bush (Woof_HDPlay, 285/95%) | S0. Forest Pack bushes also fit. |
| Rocks / boulders | 8421400545 | Rock Pack | RedWood Roleplay (group) | 78/98% | 14 scanned-look mossy rocks | 1192366796 Realistic Rock (woahitsdylx, 940/94%) | S0, ~3.8k tris per rock. |
| Grass clumps | 2846635652 | Light Grass | GrayslandYT | 752/94% | Tall grass card clumps | Terrain Grass with `MaterialService` grass decoration (built in, free) | S0, 25k tris for 5 clumps: use sparingly on phones. Terrain decoration grass is the cheapest good look. |
| Distant mountain | 10606824320 | Super Realistic Mountain | iancrackleche | 76/95% | Textured rock mountain mesh for the horizon | 8761896930 Mountain (s1ix6, 491/82%) | S0, 26k tris (backup 3.9k). Put it far away with no collision. A skybox with mountains (368391268 Mountains Skybox, Crykee, 2820/94%) is the zero-cost option. |

## Maps (whole free maps)

| Role | Pick id | Name | Creator | Votes | Why | Backup id | Notes |
|---|---|---|---|---|---|---|---|
| City street block | 6418277837 + 6432233485 + 6370681139 | City Building / Road / Props Packs | **Roblox** | 637/91%, 846/94%, 576/96% | Official PBR kit, modular, matches the Sedan/SUV/Cone | 13168370735 Modular Building Kit - Modern City (**Roblox**, 475/95%) | Build one block from the packs. Whole community city maps (e.g. 11486778910, 711k tris) are far too heavy for phones. |
| Tropical island | — | **no good whole map** | | | Free islands are blobby part builds | 8143419396 Island (zaragosa126, 73/92%) | Build: Terrain sand + water + 1567799120 palms + 12157426374 tropical foliage pack (PSY0PZ, 58/98%, S0). |
| Construction site | 9527353073 | Industrial and Construction Meshes | sashenka_vrode | 67/97% | 30 PBR meshes: pallets, planks, container, barriers, gas bottles | 2115241906 Construction Site #1 (iBlairBear) | S0, 95k. Add 404337655 tower crane (Melismyx, 279/93%, S0, 13.8k), 8622749017 scaffolding (ethilips, S0), cement mixer truck 12266206679 (bilalels1234, S3, 5k tris, unbranded). |
| Farm | 77018828706990 | Farm Pack | Gurule gaming (group) | 49/98% | Large consistent farm kit (buildings, fences, crops) | 4924285670 Barn (StarModelX, 93/93%) | S0. 642k for the whole pack: import only a barn + fences + a few props. The backup barn alone is 204k tris (heavy). |
| Military base | 1167155589 | Military base | l1l_twins | 528/88% | Compact compound: watch tower, Quonset hangar, helipad, fence | 931910200 Military base (imaginarysonic12345, 184/92%) + 4715423769 border fence | S7, 225k tris. |
| Airport hangar | 931910200 | Military base (Quonset hangar) | imaginarysonic12345 | 184/92% | Clean arched hangar, 3.9k tris | 5343886540 plane hangar (Hyperalis, 38/96%) | S0. Add 620535104 Airport Tower (Dakota41999, 72/91%). No good free whole airport (3467208856 is 723k tris). |

## Animals

| Role | Pick id | Name | Creator | Votes | Why | Backup id | Notes |
|---|---|---|---|---|---|---|---|
| Gorilla | 10594810401 | Gorilla | xor25th | 19/96% | Realistic quadruped gorilla mesh, 5k tris | 1421609150 (same mesh, re-upload) | **Static, not rigged**: animate it with tweens/hop, or rig it ourselves. All "Gorilla Tag" models skipped (IP), and King Kong skipped (film IP). |
| Bull | 5035521514 | Wood Bison | fashionzoo10 | 10/100% | Only realistic horned bovine found; works for a stampede | 11162919482 High Quality COW (7kB1ue, 19/95%) | **No real bull exists.** Static mesh. Rename the event "Bison Run", or add horns to the cow. |
| Shark | 11373688758 | Shark (With Animation) | Z_0F4R | 15/79% | Realistic grey shark, single skinned mesh with animation | 7934677313 Shark (r5styy, 172/86%) | S0, 20k tris. The backup has S3. The "Jaws" model was skipped (film IP). |
| Bear | 5049368586 | Polar Bear (Realistic) | zwinkybacon | 26/87% | Only realistic bear | none good | S0, 5.4k. No brown bear; every other result was a teddy or a "Bear Alpha" meme. |
| T-rex | 18759347676 | Rigged Dinosaur Models | happydinos115 | 184/92% | Rigged, realistic T-rex (plus others) | 430905421 DINOSAUR PACK! (ExecutiveKrab, 41/82%) | S0, but **1.68M tris for the whole pack**: keep only the T-rex, check its count, and decimate if over ~20k. |

## Summary
- **Filled:** 38 of 41 roles; the bull is filled with a stand-in (bison).
- **No good option (3):** swimming pool and concrete bunker (build both from Duvall material variants); whole tropical island map (use terrain + palms + foliage pack instead).
- **Weak picks:**
  - rocket: one semi-realistic part build;
  - castle tower;
  - trampoline;
  - gorilla (static, not rigged).
- **Style backbone:** Roblox's own PBR packs: Forest Pack, City Building/Road/Props, Sedan/SUV/Pickup, Traffic Cone, Duvall Drive material variants. Fill the gaps with single PBR meshes (crate, barrel, jersey barrier, fence, lamp, rocks).
