> **Erstattet af [TEST-ALT.md](TEST-ALT.md)** (release 0.20.0, branch `release`). Brug den; denne fil er kun baggrund.

# Test af fase 0 (v0.18.0) før publish

Branch: `fase0`. Hent den, lad Script Sync lægge koden i Studio, og tjek at scripts er landet.

## 1. SelfTest i Studio
1. Sæt `ServerStorage.RunSelfTest = true` (og `LabLive` fra).
2. Kør først de nye: `ServerStorage.SelfTestOnly = "T53,T54,T55,T56,T57,T58,T59,T35"` og tryk Play.
   Alle skal give `PASS`. T59 skriver hvilke kort der er skjult (Starter Pack, gruppe).
3. Kør derefter hele suiten én gang (`SelfTestOnly` tom). Kendte ustabile: T15, T19, T24, T25, T27, T32.
4. LayoutCheck (klient, via MCP): `require(LayoutCheck).run()` → skal give 0 problemer, også på de 4 nye
   højkant-telefoner (390x844, 414x896, 360x780, 430x932). Kør også `LayoutCheck.live()`.

## 2. Telefon på højkant (vigtigst: 95 % af telefonerne)
Brug en rigtig telefon (eller Studio Device Emulator, iPhone 14 på højkant).
- [ ] Første minut: kun skyd/SHOOT, bevægelses-pinden, baren, Shop, Menu, RAGDOLL (WEAPONS efter ca. 25 s). Ingen LAB VIEW, BUILD eller RUN før 90 s.
- [ ] Ingen knapper oven i hinanden: SHOOT/GRAB ved hop-knappen, RUN og THROW lige over dem, baren over det hele.
- [ ] Pinden ligger ikke oven på WEAPONS.
- [ ] Beskeder (toasts) går over hele bredden under knapperne foroven og er ikke klippet ("Play 2 more min for a FREE weapon egg!..." står helt).
- [ ] Intet "Walk, or view from above?"-kort. Intet "Free egg!"-vindue før 90 s.
- [ ] WEAPONS-vinduet: fanen hedder BOMBS (ikke "EXPLOSI / VES").
- [ ] MENU indeholder SANDBOX og PLACES.
- [ ] Drej telefonen ned (landskab): intet overlapper; RUN gemmer sig, når Grab eller Sniper er valgt.

## 3. PC (tastatur + mus)
- [ ] Klik på dukken skyder; 1-6 vælger plads; baren har 6 pladser.
- [ ] Ingen låste NEXT-kort i baren de første 3 minutter (og først fra 25 takedowns).
- [ ] Intet "TODAY'S DEAL / SOON"-kort, ingen "SOON" i Rewards → Group gift.
- [ ] Ingen blod, kun stjerner og gnister. Settings har ingen Blood-række.
- [ ] Våbennavne: Popper, Big Popper, Rattler, Ripper, Buzz Blaster ... (ikke G17/AK/M4).
- [ ] Træffer-linjen siger fx "Chest · 80% health", ikke organer.

## 4. Xbox- eller PlayStation-controller (på PC eller konsol)
- [ ] Hint: "Press RT to shoot!" (PS: R2).
- [ ] R2 skyder mod midten (sigtekorn i midten); hold R2 på et automatvåben = bliver ved.
- [ ] L2 zoomer (Sniper). LB/RB og D-pad venstre/højre skifter plads.
- [ ] Y åbner WEAPONS; LB/RB skifter fane; A vælger; B lukker. Y lukker også.
- [ ] X griber/kaster en dukke (og en spiller på pladsen). B = ragdoll; hop (A) rejser dig.
- [ ] Select (View/Share) skifter: spiller → førsteperson → lab-visning → spiller. I lab-visning drejer højre pind, venstre flytter.
- [ ] D-pad op = SHOP, D-pad ned = MENU (alle knapper findes i MENU). Start åbner Roblox' egen menu (kan ikke ændres).
- [ ] Æg-vinduet kan åbnes og lukkes med A/B.

## 5. Før publish
- [ ] Ret evt. `Config`-kontakterne, hvis du vil have de gamle valg tilbage: `SEVERING`, `BLOOD = "purple"`, `TOY_NAMES`, `MILD_TEXT`, `VIEW_CARD`, `QUIET_START`, `NEXT_UNLOCKS_*`.
- [ ] Gem place-filen.
- [ ] Publish med **"Shut Down All Servers"** (så alle får 0.18.0).
- [ ] Sæt reklamer på pause (plan 0.9), til tallene holder.
- [ ] Indsæt ny butikstekst fra `STORE_TEXT.md` og besvar modenheds-spørgeskemaet igen (mål: Mild).
- [ ] Efter 1-2 dage: kør `tools/SessionReport.luau` og se på kolonnerne `fired`, `portr`, `step5`, input `pad`.

## Ting jeg ikke kunne teste uden Studio
Alt klient-UI (placering i virkeligheden, controller-knapper, at Roblox ikke åbner sin egen
UI-markør på Select, at tekster krymper), og at `GetStringForKeyCode` kender PlayStation-knapper.
