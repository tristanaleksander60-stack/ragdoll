# Plan: ikon, thumbnails, beskrivelse + dine 8 ønsker (venter på godkendelse)

## Status lige nu
- Runde 5 er sat på pause midt i fase 2b. Fase 00, 0, 1, 1b og 2 er færdige og testet.
  - I fase 2b er 22 våben skiftet til rigtige modeller.
  - Mekanikken pr. våben er skrevet, men endnu ikke testet.
- **Roblox Assistant:** intet af det, den skulle have lavet, findes i det place, der er åbent i Studio.
  - Alle scripts i Studio er de samme som filerne på disken.
  - Der er ingen "put ragdoll here", ingen NPC Chase, ingen helbredsbjælke og ingen serverudfyldning.
  - Måske arbejdede den i et andet Studio-vindue, eller dens ændringer blev ikke gemt. Jeg bygger det selv (punkt B).

## A. Ikon, thumbnails og beskrivelse (højest CTR + folk bliver)
Hvad virker på Roblox:
- Ét tydeligt motiv.
- En stor, overdrevet ragdoll-krop midt i en eksplosion.
- Mættede farver og en mørk kant, så det kan læses i 150 px.
- Højst 2-3 ord tekst.
- Billederne skal vise det, man faktisk får. Det giver høj CTR **og** lav afgang.

Metode (billigt, ingen AI-generering):
1. Byg én scene i Studio med spillets egne ting: dummy, eksplosion, Minigun, kanon, lava og purple blood.
2. Tag 4-5 screenshots fra udvalgte vinkler.
3. Beskær, sæt kontrast op og læg tekst på lokalt med System.Drawing. Værktøjet findes allerede i `art/tools`.
4. Upload via `upload_image`.

Leverancer:
- **Ikon 512×512:** dummy midt i luften, der bliver blæst væk af et rødt BOOM, på blå himmel. Ingen tekst, kun "RAGDOLL"-logoet småt nederst.
- **Thumbnail 1 (hook):** "BLOW THEM UP!" + eksplosion + 3 flyvende dummies.
- **Thumbnail 2:** dummy skudt ud af kanonen mod bullseye ("LAUNCH YOURSELF").
- **Thumbnail 3:** våbenvæggen med 69 våben ("69 WEAPONS").
- **Thumbnail 4:** multiplayer-kaos i plazaen ("PLAY WITH FRIENDS").
- **Beskrivelse (udkast, engelsk):**
  - Linje 1-2 ses i søgning: "Blast, launch and smash ragdolls with 69 weapons! Minigun, RPG, nuke and more – unlock them all and wreck your own lab."
  - Derefter punkter: våben, kanon/fælder, events, venner, daglige gaver.
  - Søgeord: ragdoll, physics, sandbox, guns, explosions.
- **A/B:** Roblox' indbyggede thumbnail-test (du slår den til på dashboardet). Jeg læser resultatet efter 3-5 dage.
- Pris: cirka 6-8 Studio-kald og 1 upload-batch.

## B. Dine ønsker til Assistant (bygges af mig)
1. **Skyd i luften og hold for automatisk ild overalt.**
   - Fejl: hold-for-ild starter i dag kun, når det første tryk rammer en dummy.
   - Fix: hold-for-ild uanset mål (LabCamera).
   - Lille ændring.
2. **"PUT RAGDOLL HERE" + launch dig selv.**
   - Ved kanonen kommer en plade: stil dig selv eller en dummy på den, og kanonen skyder.
   - **Flere stationer:**
     - Faldtårn (du falder 60 studs).
     - Vindmølle-kaster.
     - Kværn/hakkelse-rulle (purple blood).
     - Raketslæde mod en mur.
     - Trampolin-kanon.
   - Hver station har en sokkel og et skilt "PUT RAGDOLL HERE". Server-styret, og spilleren ragdoller (PlayerRagdoll.knock).
3. **Flere likes/favoritter uden at genere.**
   - Ingen belønning (Roblox forbyder det).
   - Vis like-boksen lige efter et "wow"-øjeblik (bullseye, nuke eller 10-combo) i stedet for efter 6 minutter.
   - Højst én gang pr. besøg, og aldrig i det første minut.
   - Et lille ♥ "Favorite for updates" i MENU og på slutskærmen.
   - Mål effekten i Session_v1.
4. **Lobbyer fylder op til 10, før der laves en ny.**
   - Billigst: dashboardet → Places → Server Fill = "Maximum" (det gør du, 1 klik).
   - Kode: PLAY NOW-portalen vælger altid den fyldteste server.
5. **NPC Chase for nye spillere.**
   - 4-10 NPC'er løber ind og angriber.
   - Helbredsbjælke på spilleren. Der skal mange slag til, før man dør (fx 100 HP, 4 HP pr. slag).
   - Respawn efter 1 sekund. Du slår tilbage med dine våben, og hver NPC giver takedowns.
   - Bygges oven på HordeService.
   - Udløses for nye spillere efter cirka 90 sekunder og derefter hver 6.-8. minut. Aldrig mens et æg åbnes eller en menu er åben.
6. **NPC'er skifter langsomt farve til grøn og tilbage.**
   - ⚠️ Grøn betyder i dag "død".
   - Forslag: en anden farve (fx lilla glød), eller død bliver grå.
   - Sig til, hvad du vil have. Jeg bruger lilla, hvis du ikke svarer.
7. **Fiks "Most time played".**
   - Lab-tavlen viser "Nobody yet".
   - Jeg finder fejlen (LeaderboardService: tiden skrives måske kun ved leave) og retter den, så tiden tæller live.
8. **Spar credits:** én samlet runde, få store Studio-kald, kun de berørte tests og én kort review til sidst.

## Rækkefølge (efter effekt)
1. A (ikon, thumbnails, beskrivelse).
2. B1, B7 og B4 (små fejl).
3. B2 (stationer).
4. B5 (NPC Chase).
5. B3 og B6.
6. Færdiggør runde 5's fase 2b-test, og fortsæt fase 3-5 bagefter.

## Det skal du gøre
- Godkend planen (og svar på farven i B6).
- Dashboardet: Server Fill = Maximum. Slå thumbnail-A/B-test til, når billederne er oppe.
