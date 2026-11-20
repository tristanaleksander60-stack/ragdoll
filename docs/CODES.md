# Ragdoll Havoc codes

The codes live in `ReplicatedStorage/ReplicatedStorage/Shared/Codes.luau` (V9-0t). Players type them in **More → CODES** or **SHOP → HAVE A CODE?**.

- Upper and lower case are the same, and spaces are ignored.
- Each player can use each code once.
- Dates are in UTC.
- Codes are never tied to likes or favourites (Roblox rules).

| Code | Gives | Live |
|---|---|---|
| `RELEASE` | 500 BOLTS | from the 0.31 release |
| `BETA` | 300 BOLTS + the Railgun free for 30 minutes | while the game is in beta (`Config.BETA`) |
| `RAGDOLL` | 250 BOLTS | from the 0.31 release |
| `CHRISTMAS` | 750 BOLTS + the Fire Trail for 24 hours | 1 Dec to 31 Dec 2026 |

**How the rewards behave:**
- **BOLTS** are exact: never doubled by 2x BOLTS.
- **A weapon's free try** and **a cosmetic's hours** are saved with the player. They carry on after a rejoin. A weapon try waits if another free try is running.
- **Owned already:** a player who owns the weapon or the cosmetic just gets the BOLTS.

**What players see when a code fails:**
- an unknown code, or one that has not started yet: "That code does not work";
- a code used before: "You already used this code";
- a code after its end: "This code has expired";
- more than 5 tries in a minute: "Too many tries. Wait a minute".

## For the game description (paste as is)

Now:

```
🎁 CODES (More → CODES): RELEASE · BETA · RAGDOLL
```

From 1 December:

```
🎁 CODES (More → CODES): RELEASE · BETA · RAGDOLL · CHRISTMAS
```

## Adding a code

Add a line to `Codes.LIST` with:
- `code`;
- one or more rewards: `bolts`, `trialWeapon` + `trialMinutes`, `cosmetic` (a map-shop item key) + `cosmeticHours`;
- optional `from` / `to` dates (use the `utc(y, m, d)` helper);
- `live = true`.

Then publish. A code with `live = false` stays hidden.
