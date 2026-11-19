# Test af fase 1 (branch `fase1`, bygger på fase 0)

## SelfTest
`ServerStorage.SelfTestOnly = "T54,T60,T61,T62"` → alle `PASS`. Derefter hele suiten én gang.
LayoutCheck (klient): 0 problemer; det nye "Experiment"-kort er med på alle skærme.

## Telefon (højkant) og PC
- [ ] Ca. 30 s inde (når baren er fri) kommer et EXPERIMENT-kort: "🧪 Take down 3 dummies 0/3 0:58". På telefonen sidder det, hvor den store WEAPONS-knap sad (baren har stadig WEAPONS). På PC øverst i midten.
- [ ] Kortet tæller op, giver "⭐ Experiment done! +1 star", og et nyt kort kommer efter 4 s. Tiden løber ud → nyt kort.
- [ ] Tryk på kortet: EXPERIMENTS-vindue med SKIP og en kode-boks.
- [ ] Første store slag: replay hedder "X-RAY REPLAY", kroppene er gennemsigtige blå med hvide knogler, stor "CRACK! +140" og "SHARE CODE ABC234" øverst. Knappen hedder "CLIP IT".
- [ ] Skriv koden i EXPERIMENTS → "Beat 140 with the Popper!". Slå scoren i et nyt replay → "You beat your friend's 140!".
- [ ] Kortet skjuler sig under replay, i WEAPONS, under NPC Chase og i arenaen.
- [ ] Controller: MENU (D-pad ned) har EXPERIMENTS.
- [ ] Telefon: højst 7 ting at trykke på det første minut (skyd, pind, bar, kort, Shop, Menu, Ragdoll).

## Ydelse
- [ ] Telefon: kun 1 besøgende ragdoll i labbet og højst 4 i en NPC Chase (PC: 3 og op til 10). Tal i `Config.DEVICE_CAPS`.

## Kontakter
`Config.EXPERIMENTS`, `EXPERIMENT_FIRST_AT`, `XRAY_REPLAY`, `PHONE_HUD_MAX7`, `DEVICE_CAPS`.
Publish med "Shut Down All Servers". Kan ikke testes uden Studio: X-ray-udseendet, kortets placering live, CLIP IT (Roblox' video-optagelse).
