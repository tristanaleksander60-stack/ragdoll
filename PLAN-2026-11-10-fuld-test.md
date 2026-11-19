# Ragdoll Havoc: fuld test og plan (10. nov 2026)

Kilder: hele testsuiten i Studio, LayoutCheck og en blind gennemgang af hele koden fra syv vinkler.

## Karakterer (blind gennemgang)
| Perspektiv | Karakter | Hvorfor |
|---|---|---|
| Ny spiller (60 s / 5 min) | 5/10 | For mange beskeder på én gang, et spørgsmål om kameravinkel og et svagt første æg. Der er ingen krog før minut 3. |
| Fastholdelse | 6/10 | Streak, mål og gaver er gode, men fremskridt kan ikke ses, og de første våben er kedelige. |
| Robux | 6,5/10 | Sikker og fair, men der mangler "alle våben"-pas, startpakke og 2x. Gratis ULTRA slutter efter 3 minutter. |
| Mobil | 7/10 | God placering af knapper, men æg ligger i MENU, og man kan ikke holde for at skyde. |
| Følelse og indhold | 6,5/10 | Mange våben, men de store kommer for sent, og minigun er ikke automatisk. |
| Teknik | 7,5/10 | Solid, men der er to hukommelseslæk, en skudbegrænsning og analytics-navne. |
| Socialt | 4/10 | Private labs, og man kan kun invitere venner. Man kan ikke gribe og kaste andre spillere. |

## Plan (rækkefølge = effekt pr. indsats)
**Fase A: Krogen i de første 5 minutter (gøres nu)**
1. De første 2 æg giver et WOW-våben (Granat, Raket, C4 eller Minigun) i stedet for Poke/Slap.
2. Hurtigere stige: Granat ved 14 takedowns og Minigun ved 58.
3. Æg-kortet kan ikke længere gå tabt. Det prøver igen, til spilleren har set det.
4. Beskeder bliver læsbare: visningstid efter tekstlængde (mindst 3 s) og kø efter prioritet.
5. "NÆSTE VÅBEN"-pille over baren med ikon og "18/30", som pulserer ved hvert takedown.

**Fase B: Følelse (gøres nu)**
6. Hold nede for at skyde (minigun, sømpistol og alle våben).
7. Automatiske våben får deres egen skudgrænse på serveren, så skud ikke tabes.

**Fase C: Fejl og risici (gøres nu)**
8. Hukommelseslæk i DummySkins og PlotPrivacy.
9. Toast.isRedirected læser en variabel, før den findes.
10. Analytics: faste eventnavne med felter, ikke ét navn pr. våben.
11. Testfejl: T22 (en bar med et ukendt værktøj), T32 (kujonen kom ikke hjem).

**Fase D: Senere (kræver dig eller er store)**
- Gamepass "ALL WEAPONS" og en startpakke: du skal oprette dem på dashboardet.
- Badges (velkommen, første kill, første æg). **Kode færdig; du skal oprette de 8 badges og sende id'erne.**
- Social: gribe og kaste andre spillere på pladsen. **Færdig.** (Åbne labs: venter.)
- Gratis ULTRA skal være gaven ved 5 minutter i stedet for ved start. **Færdig.**
