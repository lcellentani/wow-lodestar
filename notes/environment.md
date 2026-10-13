# Environment

Local paths for the dev loop (design doc, "Dev environment setup"). `<ACCOUNT>` stands for the Battle.net account folder under `WTF\Account`; there is only one, so list that folder to find it. It is left out on purpose because the repo is public.

## Beta client (until Oct 21, 2026)

| What | Path |
| --- | --- |
| Install root (launcher) | `D:\GAMES\World of Warcraft` |
| Client folder | `D:\GAMES\World of Warcraft\_classic_beta_` (`WowB.exe`) |
| Addon junction | `D:\GAMES\World of Warcraft\_classic_beta_\Interface\AddOns\Lodestar` -> `D:\DEV\wow-lodestar` (created 2026-10-13) |
| SavedVariables log | `D:\GAMES\World of Warcraft\_classic_beta_\WTF\Account\<ACCOUNT>\SavedVariables\Lodestar.lua` |

## Live client (from Nov 4, 2026)

Not installed yet. The live client will likely use its own `_classic_..._` folder; when it does, create the junction again there and add its paths here:

```powershell
New-Item -ItemType Junction -Path "<client folder>\Interface\AddOns\Lodestar" -Target "D:\DEV\wow-lodestar"
```

## Junction safety

Remove the junction with `Remove-Item` on the `Lodestar` link itself: that deletes only the link. Never delete the files *inside* it: they are the repo's files.

## Dev tools

Downloaded into the git-ignored `tools\` folder (2026-10-13):

- `tools\lua\lua5.1.exe`: Lua 5.1.5, LuaBinaries Win64
- `tools\luacheck.exe`: luacheck 1.2.0, 64-bit standalone

VS Code: `sumneko.lua` and `ketho.wow-api` installed; workspace settings in `.vscode\settings.json`.

PowerShell execution policy for the user set to `RemoteSigned` (CurrentUser scope), so `.\scripts\check.ps1` runs.
