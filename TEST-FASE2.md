# Test af fase 2 (branch `fase2`, bygger på fase 1)

## SelfTest
`SelfTestOnly = "T35,T43,T60,T63,T64,T65"` → alle `PASS`; derefter hele suiten.

## I spillet
- [ ] Tryk på EXPERIMENT-kortet → vinduet viser 🔩 BOLTS, "TODAY'S EXPERIMENTS" (3 stk, ens på alle servere i dag), BONE JOURNAL x/15 og "At 100 likes: a new code here!".
- [ ] Et færdigt eksperiment giver BOLTS (stjerner × 10); et af dagens giver +30 ekstra og får ✅.
- [ ] Nye journal-sider ("First takedown", "Cannonball!" ...) giver +25 BOLTS med en besked.
- [ ] Gave for spilletid (2/5/10/15 min) giver nu +40 BOLTS, ikke et æg. Dagligt æg og 75-takedown-æg findes stadig.
- [ ] "BUY <VÅBEN> (pris)" køber det næste låste våben for BOLTS; for få BOLTS → besked.
- [ ] Våbenstigen: de første 5 våben inden for ca. 20 takedowns, toppen (Golden Popper) ved 600 (før 1.600). Robux-priserne er de samme.
- [ ] Gem, gå ud, kom ind igen: BOLTS og journal er der stadig.

## Ejeren skal
- Like-koder: når spillet når 100/500/1.000 likes, skriv en kode i `Config.LIKE_CODES` og sæt `live = true` (koden er for alle; aldrig en belønning for at like).
- Monetisering: lav produkter/passes fra `Shop.OFFERS` på dashboardet (priser står der) og send id'erne. Kort med id 0 vises ikke.
- Kontakter: `ECONOMY`, `EGG_RATION`, `LADDER_V2`, `BOLTS_*`, `DAILY_*`, `JOURNAL_BOLTS`, `PLAYTIME_BOLTS`.
