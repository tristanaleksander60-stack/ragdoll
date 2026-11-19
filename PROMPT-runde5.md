Udfør hele planen i PLAN-2026-11-10-runde5.md (Ragdoll Havoc, Roblox). Den er godkendt af ejeren, så gå i gang med det samme og kør alle faser (00, 0, 1, 1b, 2, 2b, 3, 4, 5) i rækkefølge uden at spørge om mere. Svar mig kort og på dansk.

Læs først CLAUDE.md og planen. Læs også din memory om projektet.

VIGTIGST, før alt andet: Fase 00 "de første 60 sekunder".

Fund fra 181 spillerprofiler (Profile_v1, 10. nov):
- 15 % går inden 30 sek., 37 % inden 60 sek., 71 % inden 3 min.
- **31 % (57 spillere) har 0 takedowns.** 23 af dem spillede over 1 minut (op til 7½ min) uden en eneste.
- De samme profiler har 1-3 æg, de aldrig åbnede, og daily goals på 0.
- Onboarding-funnel: 93 % bruger et våben, så de skyder. Men de får ingen point.
  - Mistanke 1: telefonspillere forstår ikke, hvordan de rammer.
  - Mistanke 2: takedown-tællingen svigter (blame / ServerHitAt / readFailed / ingen lab).
- Roblox-analytics (open_cloud_invoke /analytics-query-api/v1/universes/10774775314/metrics) halter 2-3 dage og er næsten tom. Brug Profile_v1 til friske tal.
- Alle profiler viser seen = "0.13.0", så vi kan ikke se, hvilken build en spiller havde.

Fase 00 skal:
1. **Diagnose:**
   - Gem pr. session i en ny DataStore Session_v1, nøgle = userId + tid, ingen persondata ud over userId:
     - platform (touch, tastatur, gamepad og skærmstørrelse fra klienten)
     - Config.Version
     - sek. til første skud og antal skud
     - antal hits, serveren godkendte
     - antal knock-downs og antal krediterede takedowns
     - om æg-kortet blev vist og åbnet
     - om spilleren havde et lab
     - sek. til leave
   - Skriv et lille læse-script, der laver en tabel PC vs telefon vs tablet.
2. **Bump Config.Version ved hver ændring**, så data kan skelne builds.
3. **Ret takedown-tællingen,** hvis den svigter:
   - Det første skud på greeteren SKAL give +1 takedown.
   - Vis en stor "+1 TAKEDOWN"-pop ved hver takedown i de første 5 minutter.
   - Skriv en test, der skyder greeteren og tjekker, at takedowns går fra 0 til 1.
4. **Telefon:** tjek og forbedr skud på touch.
   - Et tydeligt sigtekorn i midten.
   - Et stort SHOOT-tryk i højre side (som i skydespil på mobil), hvis tryk-på-skærmen ikke er nok.
   - Tutorial-hånd, der viser "tap a dummy".
   - Brug LayoutCheck plus en test, der affyrer via de samme remotes som touch.
5. **Første æg åbner sig selv:**
   - Efter første minut afsløres det automatisk (WOW-våben), og våbnet sættes på baren.
   - Mindst 1 æg åbnes for alle. Senere æg bruger kortet som nu.
6. **Loadtid:** mål tid fra join til første billede og til første skud. Sørg for, at intet tungt indlæses, før spilleren kan skyde.
7. **Mål:** medianen for første besøg over 3 min, og under 10 % med 0 takedowns. Mål efter et døgns live-data og skriv tallene i CLAUDE.md.

Afgjort af ejeren:
- Nye spillere starter i den fælles server som nu. Solo bliver et valg via portalen.
- Ingen belønning for favorit eller like (Roblox forbyder det). Belønning for at joine gruppen er tilladt. Sæt den op med et group id = 0, indtil ejeren sender id'et.
- Today's deal bruger et Starter Pack-produkt med id 0, indtil ejeren opretter det. Det skal vise "soon" og aldrig fejle.
- Copyright er ikke et problem for modeller. Strip ALLE scripts fra indsatte modeller og scan for malware (vi fandt skjulte "Runtime"- og "ScreenBuilder"-scripts sidst).
- Purple blood, ingen ny fritekst i verden, intet fra TikTok LIVE tæller.

Åbent fra sidste session (Fase 0):
- art\icons\tool_Revolver, tool_SMG, tool_AK, tool_AutoShotgun og tool_LMG er gentegnet med art\tools\build-icons.ps1, men IKKE uploadet. Upload dem:
  - upload_image fra http://localhost:8787/icons/... Start en HttpListener, der serverer art\ på port 8787, hvis den ikke kører. Højst 8 pr. batch.
  - Opdatér id'erne i Shared\DrawnIcons.luau.
- Giv SMG, LMG og AutoShotgun signaturfarver i Toys.luau, så pladerne adskiller sig (SMG blå, LMG oliven, AutoShotgun mørk med rød).
- De 13 nye guns fra sidste session fik ingen review (review-agenten ramte rate limit). Tag dem med i slut-reviewen.
- **Ejeren vil se tydelig forskel på ALLE våben** (fx Revolver mod G17), både på baren og i hånden.
  - Tjek alle 69 ikoner side om side i bar-størrelse (en kontaktark-PNG via System.Drawing) og alle holdte modeller.
  - Gentegn og ombyg dem, der ligner hinanden: egen silhuet og signaturfarve pr. våben.
- **Færre startvåben (fase 1b) kan skade de første minutter.** Mål det med Session_v1 og ret tilbage, hvis 0-takedown-andelen stiger.

Fase 2b – hvert våben skal føles og se unikt ud (ejeren: "de ligner bare kasser"):
- **Modeller:**
  - Udskift ALLE kodebyggede kasse-modeller i ReplicatedStorage.N7Assets.Weapons med rigtige, detaljerede mesh-modeller. Søg først i LihFolk-vaultens asset pack (skill lihfolk:assets), derefter Creator Store (search_asset, tjek thumbnails først).
  - Gælder især de 13 nye guns, Minigun, Sniper, RPG, GravityGun, Grenade, C4 og Nuke, og alt andet der ligner kasser.
  - **Normalisér hver model:**
    - Grip-del i origo, -Z frem, en Tip ved mundingen eller klingens ende.
    - Alle dele svejset til Grip og alle scripts fjernet.
    - CanCollide, CanQuery og CanTouch false, Massless true, Anchored false (T36).
  - Se hver model i et screenshot ved siden af en avatar, så størrelsen passer i hånden.
  - Gentegn ikoner, så de matcher de nye modeller.
- **Mekanik pr. våben** (gør dem forskellige at bruge, ikke kun tal):
  - Haglgeværer: flere hagl med spredning (Shotgun, DoubleBarrel, AutoShotgun).
    - DoubleBarrel: begge løb på én gang, stort tilbageslag på spilleren.
    - Shotgun: pump mellem skud.
  - Sniper og DMR: zoom med højre musetast eller en knap på telefon. Sniper går gennem flere dummies.
  - Minigun: spin-up og spin-down med lyd. LMG: større spredning, når man bevæger sig.
  - Våben-rytme:
    - M4: 3-skuds salve.
    - AK: stigende rekyl.
    - SMG og Tommy: hurtig spray.
    - Revolver: hane-animation og "fan the hammer" ved hurtig klik.
    - Golden Deagle: headshot giver guldgnister.
  - FlareGun: lysende flare, der sidder fast og gløder et stykke tid.
  - LaserRifle: sammenhængende stråle, mens man holder. Railgun: opladning (ring på sigtekornet), gennemborer alt på linjen og efterlader et spor.
  - Melee:
    - Bat og Golf: home-run-bue.
    - Katana og Axe: tydelige snit.
    - Chainsaw: kører, mens man holder.
  - Sprængstoffer:
    - Grenade: hopper og har en nedtælling.
    - C4: fjernudløser med andet tryk.
    - RPG: røgspor.
    - Nuke: svampesky.
  - Al mekanik skal være server-autoritativ (HitService, budgetter og AUTO_PER_SECOND overholdt) og virke på telefon.
  - Opdatér/udvid T21, T22 og T24, så hver mekanik testes.

Tekniske noter:
- **Toys.SLOTS** er i dag #DEFAULT_LOADOUT. Når startvåbnene skæres ned til G17, Grab og Punch, skal SLOTS være en fast konstant og ikke følge listen.
  - Gemte bars, grandfather, ProgressService.isUnlocked, T35 og T42 skal stadig virke.
- **Doctor mode** flyttes fra V til L. V bliver first person (tjek Keybinds og ControlsUI).
- **Reload:**
  - Magasin og reload-tid i Toys pr. gun.
  - Serveren tæller skud i HitService og afviser skud under reload.
  - Klienten viser ammo ved sigtekornet (Crosshair) og på pladen.
  - Automatisk reload ved tom og R tidligt.
  - Automatiske våben skal stadig overholde AUTO_PER_SECOND.
- **First-person viewmodel:** klienten kloner det holdte våben og armene ind foran kameraet (LocalTransparencyModifier), med svaj, rekyl og mundingsglimt.
- **Lyde:** én rigtig optagelse pr. gun via search_asset (Audio). Tilføj dem i SoundManifest.SOUNDS/GUNS, plus reload-lyde. T41 skal bestå.
- **Besøgende ragdolls i labbet:** byg det på DummyLife/ActiveRagdoll (klient-simuleret). T37 (netværksbudget) skal bestå.
- **Multiplayer:**
  - TeleportService (ReserveServer til MAKE MY OWN og solo).
  - MemoryStoreService SortedMap som serverliste, med heartbeat og udløb.
  - Sjove servernavne fra en fast ordliste. Region fra LocalizationService.
  - Sort overgangsskærm med TeleportService:SetTeleportGui.
  - Teleport kan ikke testes i Studio, så test logikken med test-hooks.
- **Modeller:** nye modeller (kanon, drop tower, wrecking ball, trampolin) ligger kun i place-filen. Mind ejeren om at gemme.

Kvalitet og credits:
- Test med ServerStorage.RunSelfTest og SelfTestOnly. Kør kun de berørte tests efter hver fase. Kør den fulde suite (T01-T44 + nye) og LayoutCheck på alle 8 skærme én gang til sidst. Kendte ustabile: T15, T19, T24, T25, T27, T32.
- Tjek at scripts er synket ind i Studio, før du tester. Execute_luau på Client/Server får sin egen kopi af modulerne, så test klientkode via serverens remotes eller gennem tests.
- Spar credits:
  - Få, store Studio-kald.
  - Screenshots i halv størrelse og kun når noget visuelt er ændret.
  - Brug vaultens asset pack (plugin lihfolk) og Creator Store frem for at bygge modeller med kode.
  - Ingen AI-generering af meshes eller materialer.
  - Asset-søgning og den blinde review må køre på en billigere model (Sonnet).
- Én blind review til sidst mod skills/quality-score i LihFolk-vaulten. Krav 8,5, højst 3 fix-runder.
- Backup til Documents\RagdollLab-backups\2026-11-1x-runde5-<fase> efter hver fase. Opdatér CLAUDE.md kort med hvad der er gjort.
- Hvis du rammer en rate limit, så gem fremskridt i CLAUDE.md og fortsæt hvor du slap.

Når alt er færdigt: giv mig en kort dansk opsummering. Sig hvad jeg selv skal gøre (gemme place, publicere med "Shut Down All Servers", Starter Pack-produkt, gruppe-id).
