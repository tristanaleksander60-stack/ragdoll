> **Erstattet af [TEST-ALT.md](TEST-ALT.md)** (release 0.20.0, branch `release`). Brug den; denne fil er kun baggrund.

# Test af fase 3 (branch `fase3`, bygger på fase 2; version 0.19.0)

## SelfTest
`SelfTestOnly = "T40,T58,T63,T66"` → alle `PASS` (T66 tjekker at julelabbet ikke overlapper noget). Derefter hele suiten.

## Jul (fra 1. december)
- [ ] Før 1. dec. er julen slukket (ingen nissehuer). Admin kan stadig tænde den med "on".
- [ ] Med julen tændt: i hvert lab en SKORSTEN (gå ind i den røde plade → du flyver op), en GAVE (rør den → du bliver kastet), en SLÆDE-RAMPE. Se efter at de ikke står i noget.
- [ ] 1.-24. dec.: dagens første eksperiment er "🎁 Day N: ..." (advent) og giver 3 stjerner.

## Prank Party (2-6 spillere i samme lab)
- [ ] Inviter en ven ind i dit lab: begge får et fælles kort "🎉 TOGETHER: take down 15 dummies". Begges takedowns tæller; begge får stjerner og BOLTS.
- [ ] Går vennen ud, slutter festen.

## Opdaterings-rytme
- [ ] What's New viser 0.19.0-noten for tilbagevendende spillere.
- [ ] Sæt server-størrelse på dashboardet til `Config.SERVER_SIZE` (6) for at prøve; kan ikke sættes fra koden.
- [ ] Læs `docs/CREATOR_KIT.md` (TikTok-formater, YouTuber-guide, koder).

Kontakter: `CHRISTMAS_FROM_DEC1`, `CHRISTMAS_LAB`, `ADVENT`, `PRANK_PARTY`, `PARTY_MAX`, `SERVER_SIZE`, `UPDATE_TITLE`, `UPDATE_DAYS`.
Publish med "Shut Down All Servers". Gem place-filen.
