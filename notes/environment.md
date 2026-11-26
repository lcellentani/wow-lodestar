# Environment

Local paths for the dev loop (design doc, "Dev environment setup"). `<ACCOUNT>` stands for the Battle.net account folder under `WTF\Account`; there is only one, so list that folder to find it. It is left out on purpose because the repo is public.

## Live client (since Nov 4, 2026)

| What | Path |
| --- | --- |
| Install root (launcher) | `D:\GAMES\World of Warcraft` |
| Client folder | `D:\GAMES\World of Warcraft\_forever_` (`Wow.exe`) |
| Addon junction | `D:\GAMES\World of Warcraft\_forever_\Interface\AddOns\Lodestar` -> `D:\DEV\wow-lodestar` (created 2026-11-05) |
| SavedVariables log | `D:\GAMES\World of Warcraft\_forever_\WTF\Account\<ACCOUNT>\SavedVariables\Lodestar.lua` |

The client also holds addons the user plays with (Baganator, Chattynator, DialogueUI, the Spoken family). Turn them off in the character screen's AddOns list for probes and taint checks, so that errors and taint can only come from Lodestar; turn them back on to play.

To recreate the junction (with the game closed: the client only sees files that exist when it starts):

```powershell
New-Item -ItemType Junction -Path "D:\GAMES\World of Warcraft\_forever_\Interface\AddOns\Lodestar" -Target "D:\DEV\wow-lodestar"
```

## Beta client (closed Oct 21, 2026)

Kept for reference.

| What | Path |
| --- | --- |
| Client folder | `D:\GAMES\World of Warcraft\_classic_beta_` (`WowB.exe`) |
| Addon junction | `D:\GAMES\World of Warcraft\_classic_beta_\Interface\AddOns\Lodestar` -> `D:\DEV\wow-lodestar` (created 2026-10-13) |

## Junction safety

`AddOns\Lodestar` *is* the repo: anything written into it (an extracted zip, a copied file) lands in `D:\DEV\wow-lodestar`, and anything deleted inside it is deleted from the repo. Never extract a release zip over it, and never delete the files inside it.

Remove the junction with `cmd /c rmdir`, which deletes only the link and never touches the target:

```powershell
cmd /c rmdir "D:\GAMES\World of Warcraft\_forever_\Interface\AddOns\Lodestar"
```

Do not use `Remove-Item -Recurse` (or confirm a recurse prompt) on the junction: Windows PowerShell 5.1 can follow it and delete the repo's files. *(Corrected 2026-11-26: this section used to recommend `Remove-Item`.)*

## Testing a release zip

To load a release zip (for example from GitHub Releases) instead of the repo:

1. Close the game. Commit or stash work in progress.
2. Remove the junction with `cmd /c rmdir` (above), then check that `D:\DEV\wow-lodestar` is intact.
3. Extract the zip into `D:\GAMES\World of Warcraft\_forever_\Interface\AddOns\`, so `AddOns\Lodestar\Lodestar.toc` exists. Start the game and test.
4. Close the game and delete the extracted `AddOns\Lodestar` folder; it is a real folder now, so this is safe.
5. Recreate the junction (command under "Live client"). Settings in `WTF` are not touched by any of this.

## Dev tools

Downloaded into the git-ignored `tools\` folder (2026-10-13):

- `tools\lua\lua5.1.exe`: Lua 5.1.5, LuaBinaries Win64
- `tools\luacheck.exe`: luacheck 1.2.0, 64-bit standalone

- `tools\wow-api`: Ketho's WoW API annotations, git clone of `Ketho/vscode-wow-api` at tag `0.22.3` (2026-10-14). To update, delete the folder and clone a newer tag (`notes/zed-setup.md`, step 2).

Editor: Zed with the Lua, World of Warcraft TOC and XML extensions (since 2026-10-14; before that, VS Code). Settings: `.luarc.json` (language server), `.editorconfig` (indentation), `.zed\settings.json` (Lua tab size, which the language server's formatter needs), `.zed\tasks.json` (the "Lodestar: check" task). Setup steps in `notes/zed-setup.md`.

PowerShell execution policy for the user set to `RemoteSigned` (CurrentUser scope), so `.\scripts\check.ps1` runs.
