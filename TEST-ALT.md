# Test alt før publish (version 0.20.0, branch `release`)

Én tjekliste for hele runden (fase 0-3 + release). Den erstatter TEST-FASE0..3.md (de ligger der
stadig som baggrund). Intet af det her er kørt i Studio endnu: det er din første kørsel.
Sæt kryds, og skriv ned hvad der fejler (testnavn + linjen fra Output).

## 1. Hent koden
1. Luk ikke Studio. Åbn en terminal i `Documents\RagdollLab`:
   `git fetch` og derefter `git checkout release`
2. Vent til Script Sync har lagt koden ind (et halvt minut). Tjek i Studio:
   - [ ] `ServerScriptService.Server.Tests` har `T67_PartyToss`.
   - [ ] `ReplicatedStorage.Shared.Config` siger `Version = "0.20.0"`.
3. Gem en backup af place-filen først: File → Save to File As →
   `Documents\RagdollLab-backups\2026-11-19-pre-0.20.rbxl`.

## 2. SelfTest
1. `ServerStorage.RunSelfTest = true`, `LabLive` fra.
2. Først kun de nye og ændrede (ca. 2 min):
   `ServerStorage.SelfTestOnly = "T22,T33,T35,T40,T43,T53,T54,T55,T56,T57,T58,T59,T60,T61,T62,T63,T64,T65,T66,T67,T68"` → Play.
   Alle skal give `[SelfTest] PASS`.
   - Nye: T53 Gamepad, T54 PortraitHud, T55 QuietStart, T56 BarSixSlots, T57 MildContent,
     T58 SessionRecord, T59 NoSoonCards, T60 Experiments, T61 ShareCode, T62 DeviceTier,
     T63 Economy, T64 Ladder, T65 OffersCodes, T66 ChristmasParty, T67 PartyToss, T68 Offers.
   - Rettet: T22 (bar på 7 skæres til 6), T33 (træfferlinjen siger "Chest"/"Head"), T35, T40, T43.
3. Derefter hele suiten én gang (`SelfTestOnly` tom, ca. 12 min): `DONE pass= fail=`.
   Kendte ustabile (må fejle én gang, kør dem igen alene): T15, T19, T24, T25, T27, T32
   (og T37 hvis PC'en kører langsomt).
4. Testene giver din egen Studio-profil lidt BOLTS og stjerner. Det er ufarligt.

## 3. LayoutCheck (telefon-beviset)
Kør i Play (klient), via Studio MCP: `require(StarterPlayer.StarterPlayerScripts.Client.LayoutCheck).run()`
og `.live()`.
- [ ] 0 problemer på alle 12 skærme (8 gamle + 4 telefoner på højkant: 390x844, 414x896, 360x780, 430x932).

## 4. Telefon på højkant (Device Emulator, iPhone 14 på højkant, eller en rigtig telefon)
- [ ] De første 90 s: kun SHOOT, pinden, baren, SHOP, MENU, RAGDOLL. Ingen LAB VIEW eller RUN før 90 s.
      Intet "Walk, or view from above?"-kort, intet æg-vindue.
- [ ] Intet ligger oven i hinanden: SHOOT/GRAB ved hop-knappen, RUN og THROW over dem, baren over det.
- [ ] Toasts går i hele bredden og er ikke klippet.
- [ ] Efter ca. 30 s: eksperiment-kortet ("🧪 Take down 3 dummies 0/3 1:00") står hvor WEAPONS-knappen var.
      Tryk på det: EXPERIMENTS-vinduet åbner (SKIP, kode-felt, BOLTS).
- [ ] MENU har SANDBOX og PLACES. WEAPONS-fanen hedder BOMBS.
- [ ] Drej til landskab: intet overlapper; RUN gemmer sig når Grab eller Sniper er valgt.

## 5. PC (tastatur + mus)
- [ ] Klik på dukken skyder; 1-6 vælger plads; baren har 6 pladser.
- [ ] Ingen NEXT-kort i baren før 3 min og 25 takedowns. Intet "SOON"-kort nogen steder.
- [ ] Ingen blod, kun stjerner/gnister; Settings har ingen Blood-række. Navne: Popper, Rattler, Ripper ...
- [ ] Træffer-linjen: fx "Chest · 80% health", ingen organer.
- [ ] Et stort hit giver X-RAY REPLAY: blå gennemsigtige kroppe med hvide knogler, "CRACK! +N",
      SHARE CODE øverst og CLIP IT.
- [ ] Eksperiment-kortet står øverst i midten og går væk under en chase og i arenaen.

## 6. Xbox/PS-controller (sæt en pad i PC'en)
- [ ] Hint: "Press RT to shoot!" (PS: R2). R2 skyder mod midten (sigtekorn); hold = automat.
- [ ] L2 zoom, LB/RB og D-pad ←/→ skifter plads, Y åbner/lukker WEAPONS (LB/RB = faner), A vælger, B lukker.
- [ ] X griber/kaster, B = ragdoll, Select = spiller → førsteperson → lab-visning (pinde drejer/flytter).
- [ ] D-pad ↑ SHOP, ↓ MENU. MENU har EXPERIMENTS for pad. Start = Roblox' egen menu.

## 7. To spillere / Prank Party (Studio: Test → Clients and Servers → 2 spillere)
1. Spiller 1 inviterer spiller 2 ind i sit lab (FRIENDS). Begge står i labbet.
- [ ] Inden for 5-10 s får begge et fælles kort "🎉 TOGETHER: ...". Begges hændelser tæller; begge får stjerner og BOLTS.
2. Kast din ven (nyt i 0.20): vælg Grab, klik på vennen i labbet (eller X på pad), slip/kast mod
   kanonen, lavaen, piggene eller en station.
- [ ] Grebet virker i labbet mens festen kører (og stadig i plazaen). Uden fest kan man ikke gribe hinanden i et lab.
- [ ] Lander vennen i en fælde inden 4 s: stor guld-tekst "TOSS COMBO! <navn> into the LAVA" hos kasteren,
      "<navn> tossed you into the LAVA!" hos vennen. Flere hurtigt efter hinanden: "x2", "x3".
- [ ] Kortet "TOGETHER: toss friends into 3 traps" bliver færdigt efter 3 combos.
- [ ] Går vennen ud af labbet, slutter festen; et kort der løber ud uden point forsvinder ved 0:00.
- [ ] I plazaen: kast vennen ind på kanonens plade → combo-pop.

## 8. Jul
Julen starter først 1. december (`Config.CHRISTMAS_FROM_DEC1`). For at se den nu:
SHOP → SERVER EVENTS → ADMIN EVENTS (OWNER) → CHRISTMAS THEME → **ON**. Sæt den tilbage på **AUTO** bagefter.
- [ ] Sne og nissehuer. I hvert lab: SKORSTEN (rød plade = du flyver op), GAVE (kaster dig), SLÆDE-RAMPE; de står ikke i noget.
- [ ] 1.-24. dec. (kun med julen på): dagens første eksperiment er "🎁 Day N: ...".

## 9. Økonomi og BOLTS
- [ ] Et færdigt eksperiment giver "+10 BOLTS" pr. stjerne; et dagligt eksperiment +30 ekstra.
- [ ] Gave for spilletid (2, 5, 10, 15 min) giver +40 BOLTS (ikke æg); teksten siger "FREE BOLTS".
- [ ] EXPERIMENTS-vinduet: BOLTS, "Next weapon: X for N BOLTS", dagens 3 eksperimenter, BONE JOURNAL x/16.
- [ ] BUY-knappen køber det billigste låste våben når du har nok BOLTS.
- [ ] **Forlad spillet og kom tilbage: BOLTS og journal er der stadig** (det var fejlen der blev rettet).
- [ ] Like-koder: når likes når 100/500/1000, skriv en kode i `Config.LIKE_CODES` (`code = "..."`, `live = true`), bump version, publish.

## 10. Creator Hub (create.roblox.com → Ragdoll Havoc)
**Produkter og passes fra `Shop.OFFERS`** (Monetization → Passes / Developer Products):

| Type | Navn | Pris (R$) | Giver |
|---|---|---|---|
| Developer Product | Starter Crate | 49 | 300 BOLTS og Rattler |
| Game Pass | All Melee | 69 | Alt nærkamp-legetøj |
| Game Pass | All Explosives | 99 | Alle bomber |
| Game Pass | 2x BOLTS | 129 | Dobbelt BOLTS |
| Game Pass | VIP Lab | 199 | Flere dukker der går rundt i dit lab (+2) |
| Game Pass | Events Pass | 249 | Alle server-events gratis hele sæsonen |
| Game Pass | Everything | 699 | Alt legetøj, 2x BOLTS, VIP Lab og Events Pass |

- Navn og pris præcis som i tabellen. Sæt dem "on sale".
- **Det eneste du skal gøre i koden:** åbn `ReplicatedStorage\ReplicatedStorage\Shared\Shop.luau`, find
  `Shop.OFFERS = table.freeze({`, og skift `id = 0` til tallet fra Creator Hub på den linje med samme `key`
  (fx `key = "DoubleBolts"` → `id = 1234567890`). Gem; Script Sync tager det. Intet andet skal ændres.
- Så virker det hele: kortet kommer frem i SHOP → OFFERS (id 0 = skjult live, "TEST" i Studio, hvor et tryk giver det med det samme),
  købet går gennem Roblox' eget vindue, et produkt gives én gang pr. køb (gemt i Orders_v1 som de andre produkter),
  og et pass tjekkes hver gang man kommer ind (et refunderet pass forsvinder igen).
- Test efter id'erne er sat (rigtig spiller, live eller Studio med API-adgang):
  - [ ] Starter Crate: +300 BOLTS og Rattler; kommer ikke igen ved rejoin.
  - [ ] All Melee / All Explosives: alle våben på den hylde er åbne i WEAPONS. Everything: alle hylder.
  - [ ] 2x BOLTS: et eksperiment giver dobbelt. VIP Lab: 2 ekstra dukker går rundt i dit lab.
  - [ ] Events Pass: tryk på et server-event i SHOP → det starter gratis (højst ét hvert 2. minut).
- Stadig åbne id'er: `Shop.STARTER_PACK` (R$29, "3 weapon eggs + the Revolver"; obs: tilfældige æg for Robux
  kræver odds-visning), `Shop.GROUP_ID`, badges Takedowns100 / Nuke / Takedowns1000.

**Modenheds-spørgeskema** (Experience Questionnaire, mål **Mild**). Svar for det mest ekstreme i spillet:
- Vold: ja, mild, gentaget (tegneserie-dukker og spillere der væltes; ingen bliver såret).
- Blod: nej (`Config.BLOOD = "off"`). Afskårne lemmer: nej (`SEVERING = false`).
- Frygt/horror, romantik, alkohol/stoffer, grimt sprog, sex: nej.
- Hasardspil / betalte tilfældige ting: nej (æg er gratis; Starter Pack ikke oprettet).
- Fri tekst: nej (kun koder fra et fast alfabet; Roblox' egen chat).
- Hvis du senere sætter `BLOOD = "purple"` eller `SEVERING = true`: svar igen.

**Andet:**
- [ ] Server-størrelse: Places → Ragdoll Havoc → Server Size = **6** (`Config.SERVER_SIZE`). Server Fill = Maximum.
- [ ] Butikstekst: kopier fra `STORE_TEXT.md` (titel `Ragdoll Havoc 💥 Toy Lab`, fra 1. dec. `[🎄] Ragdoll Havoc 💥`).
- [ ] Sæt reklamer (Ads Manager) på **pause** til tallene holder (median-session over 90 s).

## 11. Publish
1. Gem place-filen (Ctrl+S). Modellerne i `N7Assets` findes kun i place-filen.
2. File → Publish to Roblox.
3. Creator Hub → Places → ... → **Shut Down All Servers** (så alle får 0.20.0).
4. Efter 1-2 dage: kør `tools/SessionReport.luau` (Studio, Edit) og kig på `v 0.20.0`.

## 12. Hvis noget går galt (rollback)
- **Før publish:** fejl i test → skriv til mig med testnavn + Output-linjen; publish ikke.
- **En enkelt ting driller live:** slå den kontakt fra i `Config.luau`, bump `Version`, publish med Shut Down:
  `PARTY_THROWS` (kast i labbet), `PRANK_PARTY`, `EXPERIMENTS`, `XRAY_REPLAY`, `ECONOMY` / `EGG_RATION`
  (giver æg igen), `CHRISTMAS_LAB`, `ADVENT`. Slå **ikke** `LADDER_V2` fra når den har været live
  (våben spillerne har nået bliver låst igen).
- **Det hele skal tilbage:** Creator Hub → Places → Ragdoll Havoc → Version History → vælg versionen før
  0.20 → Restore → Shut Down All Servers. Koden: `git checkout main` i `Documents\RagdollLab`
  (eller åbn backup-filen fra trin 1). Gemte BOLTS forsvinder ikke: den gamle version gemmer felter den ikke kender.

## 13. World/Feel v2 (branch `world-polish`, kun hvis den er merget)
Alt her står bag to kontakter i `Config.luau`: `WORLD_V2` (labbets nye pynt, dukkernes dragter) og
`FEEL_V2` (rystelser, partikler, spor, mundingsglimt, hylstre, rekyl, combo-slowmo, lemmer der ikke
"eksploderer"). Slå én fra, hvis den driller: spillet er så som 0.20. Intet her er kørt i Studio endnu.
1. SelfTest: `ServerStorage.SelfTestOnly = "T80,T81,T82"` → Play. Alle tre skal give PASS.
   T80 = budgetter pr. enhed (lamper, partikler, spor, hylstre, ragdolls), T81 = labbets pynt
   (kolliderer ikke, inden for 320 dele og 12 lamper), T82 = lemme-vagten.
   Kør også T31, T36, T50, T66 (labbet, modellerne, stationerne, julelabbet): de skal stadig give PASS.
2. Dit eget lab, set fra spawn (pc og telefon på højkant):
   - [ ] Bagvæg med hvide paneler, mørke piller, gul-sort fodliste og tre lamper.
   - [ ] En stålportal "CRASH TEST ZONE" over dukkernes række, to spots på den. Den skygger ikke for dukkerne.
   - [ ] Orange og gule pile på gulvet fra spawn til kanonen, et "HUMAN CANNON"-skilt ved kanonen,
         en mast med orange flag og blink.
   - [ ] En prikket bue i luften fra kanonen ned til BULLSEYE.
   - [ ] Advarselsskilte ved lava, pigge og mace, med gul-sorte striber. De står ikke foran dukkerne.
   - [ ] Kasser, tønder, dæk, vogne, lystårne med kabler langs siderne og bagerst. Man kan gå igennem
         dem (de er kun pynt): sig til, hvis det ser forkert ud et sted.
   - [ ] Rækværk på faldtårnet, "FALL TOWER"-skilt, stivere på wrecking ball, kanter på rampen,
         skilte bag de tre stationer.
   - [ ] Dukkerne har hver sin dragtfarve (orange, blå, gul, hvid, grå) og et nummer på ryggen.
         Ingen er grønne, før de er døde.
3. Lamper: på pc lyser op til 14 lamper ad gangen, på telefon 4 (de nærmeste). Tjek at fps holder på
   telefon (Ctrl+Shift+F5 i Studio, eller en rigtig telefon): sig til, hvis det falder.
4. Følelse (slå "Camera shake" fra i SETTINGS bagefter og tjek at alle rystelser og rekyl er væk):
   - [ ] Et hårdt slag eller en eksplosion tæt på: kort ryk i kameraet (blødt, ikke hakkende), stjerner,
         gnister og støv. Intet blod.
   - [ ] En dukke der lander hårdt: "flop" / "thud" / "slam" efter farten, og en støvring.
   - [ ] Kanonen, en station eller et kast: kroppen trækker en farvet hale (orange = skudt afsted,
         blå = kastet, hvid = slået langt).
   - [ ] Skyd med G17, AK, Shotgun, Revolver: mundingsglimt ved løbet, messinghylstre (røde
         haglpatroner) ud til siden; Revolver og Double Barrel smider ingen. Kameraet sparker lidt op
         (Sniper og Railgun mest).
   - [ ] Combo på 5 (og 10, 15 ...): farverne falmer et øjeblik, billedet trækker sig ind, et dybt "whoosh".
         Med Motion = LESS: kun farven.
   - [ ] Dukker eksploderer ikke: skyd/slå dem hårdt mange gange, kast dem i kanonen: ingen arme eller
         ben der flyver af sted eller strækkes.
5. Hvis noget driller live: `WORLD_V2 = false` eller `FEEL_V2 = false`, bump `Version`, publish med Shut Down.
