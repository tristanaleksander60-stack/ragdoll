# Prompt for the PC session: real models in, maps up (v3 step 2)

Paste everything below the line into `claude` started in the RagdollLab folder, with Studio open on the place and the Roblox Studio MCP connected.

---

You are the lead developer on Ragdoll Havoc. Follow CLAUDE.md, and talk to me in Danish, short and plain. Run `git pull` on the `release` branch first.

The goal: replace everything code-built that looks cheap with the real Creator Store models chosen in `docs/V3_ASSETS.md`, and make the maps grand and detailed. The code is ready. `Server/Systems/V3Assets` places a model by role. The landscape, cannon, cars, gorilla, bull, BIG RED BUTTON and lab dressing switch to the models by themselves once they are in `ServerStorage.V3Assets`.

Do this, in order.

1. **Import (Studio EDIT mode, not Play).**
   - Run `tools/ImportV3Assets.luau` with the MCP run_code, or paste it into the Command Bar.
   - Read its output.
   - For every role, look at the model and set its `Yaw` attribute (degrees) so its front faces -Z.
   - Check the Tank for insignia and delete them.
   - Check that every model that was a pack (`single = true`) kept the right piece. Set `childName` and run it again if not.
   - The malware pass deletes all scripts. Also look for odd objects it does not cover, and tell me what was removed.
   - **Save the place.**
2. **Play test** the lab and show me screenshots: spawn, cannon, the car (drive it), the BIG RED BUTTON (press until a gorilla and a bison come), the lab dressing, and the landscape (hills and trees).
   - Fix sizes in `LabDress.SPOTS` and `V3Assets.place` options, and positions if anything clashes.
   - Tune `Config.VEHICLES` until driving feels good.
3. **Maps (Phase B in docs/V3_PLAN.md).** Build them as large outdoor places, each grand and dense: 40 or more real props each, terrain, paths and lights.
   - **City block:** Roblox City Building, Road and Props packs (6418277837, 6432233485, 6370681139), plus the Sedan and SUV.
   - **Island:** terrain sand and water, palms 1567799120, tropical foliage 12157426374, a jetty and a catapult.
   - **Construction site:** meshes 9527353073, crane 404337655, scaffolding and a pit.
   - **Farm:** pack 77018828706990, keeping only the barn, fences and a field.
   - **Military base:** 1167155589.

   They replace or join the rooms in `Shared/Places` and `WorldMaps`. Outdoor maps need far more room than `ROOM_SPACING` 420, so give them their own row.
   - Keep every map's part and triangle count phone-safe: stream it, and never use whole packs with millions of triangles.
   - Take Studio screenshots of each map from 3 angles and show them to me.
4. After each step:
   - commit and push `release`;
   - update the State line in `docs/V3_PLAN.md`;
   - remind me to save the place.
