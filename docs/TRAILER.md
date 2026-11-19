# Store video (trailer) for the Roblox experience page

## For the owner (Danish)
1. Skriv `/klar lav trailer-videoen` i Claude Code på pc'en. Den gør spillet klar og fortæller dig, hvornår du skal trykke optag.
2. Optag med **Win + Alt + R** (Xbox Game Bar), eller med OBS hvis du har det. Studio-vinduet skal være i fuld skærm 1920x1080, med grafikken på max.
3. Videoen kører cirka 30 sekunder af sig selv:
   - luftfoto over laben;
   - kanonen skyder dummies afsted;
   - bilen kører ind i rækken af dummies;
   - gorillaen;
   - slowmotion;
   - en tornado;
   - Downtown;
   - øen.
4. Stop optagelsen, når der står "[Trailer] done" i outputtet.
5. Upload videoen i Creator Hub: dit spil, Configure, Thumbnails/Media, tilføj video. Brug den videolængde, Roblox viser der. Hvis siden kræver det, skal din konto være ID-verificeret.

Det er det rigtige spil, så videoen overholder Robloxs regel om ikke at vise noget, der ikke er i spillet.

## For the PC session (when the owner asks for the trailer)
1. Before filming, check that the shots look their best:
   - the newest build;
   - real models in the lab;
   - the gorilla and the tornado work;
   - Downtown and the Island are built.
2. Graphics level 10. Studio's viewport at 1920x1080 (or the Device emulator set to 1080p). Christmas off, unless it is December.
3. Press Play (solo) with the MCP and wait until the lab is built and the dummies stand.
4. Run `tools/TrailerCam.luau` on the **client** (run_code). Tell the owner: "Start optagelsen nu (Win + Alt + R)". Wait for them to answer.
5. Run `tools/TrailerServer.luau` on the **server**. It takes about 30 s and ends with "[Trailer] done".
6. If a shot fails (no car, no map, the event queue is full), fix the script or that part of the game, then run it again. Take a capture of each shot first to check the framing.
7. If the owner wants text or music: Roblox store videos work best without text. Never put a claim in the video that is not in the game.
