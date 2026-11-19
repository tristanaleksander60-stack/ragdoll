# Ragdoll Lab

Roblox ragdoll sandbox. Build, break, share.

## Layout

Each top-level folder is a Studio service linked with Script Sync (the service itself is the sync root):

| Disk | Studio |
| --- | --- |
| `ServerScriptService/` | `ServerScriptService` (code in `Server/`) |
| `ReplicatedStorage/` | `ReplicatedStorage` (code in `Shared/`) |
| `StarterPlayerScripts/` | `StarterPlayer.StarterPlayerScripts` (code in `Client/`) |

File names: `X.luau` is a ModuleScript, `X.server.luau` a Script, `X.local.luau` a LocalScript (use this in StarterPlayerScripts; a `.client.luau` Script there runs twice), a directory a Folder.
The exact sync roots on the PC are in `deploy-map.txt`.
Script Sync only carries scripts and folders. Parts, attributes and tags are created by code at startup.

## Self-test

Set the attribute `RunSelfTest = true` on `ServerStorage` and press Play.
Every ModuleScript in `Server/Tests` runs in name order and prints `[SelfTest] PASS/FAIL <name>`, then `[SelfTest] DONE pass=<n> fail=<n>`.

## Rules

- `--!strict` in every file.
- Joints may be `AnimationConstraint` or `Motor6D`; never assume one.
- Nothing triggered by TikTok LIVE may be saved, published or counted in progression (`Source = "Live"`).
- No free-form text or drawing in the world (keeps the Roblox 16+ rule off).
