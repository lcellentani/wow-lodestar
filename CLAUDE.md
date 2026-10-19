# Lodestar

World of Warcraft: Forever addon that shows zone level ranges, instance entrances, coordinates and a zone tooltip on the world map. Personal use, MIT licensed, English client only.

The design doc is the source of truth: `docs/Lodestar – WoW Forever Map Addon Design Doc.md`. Read the relevant section before changing code, and update the doc when a decision changes.

## How work happens here

- Claude Code cannot run the game; the user is the test harness. They `/reload` in game and report back.
- In-game output (`/ls probe`, `/ls dump`, caught errors) is read from `WTF/Account/<ACCOUNT>/SavedVariables/Lodestar.lua` in the game folder (exact path in `notes/environment.md`). Never edit that file: the game overwrites it at logout.
- Probe results live in `notes/beta-probes.md`: P1-P17 as in the doc's "Beta verification checklist", then P18 onwards for the in-game checks of each step (the step spec reserves the numbers).
- The user is learning Lua and writes the addon's Lua code; Claude gives a small spec with hints, then reviews, runs the checks and points out issues instead of rewriting their code. Claude writes tooling and config (scripts, `.luacheckrc`, settings) and edits code only when asked.

## Rules

- Lua 5.1 only. Always declare variables `local`. Indent with 2 spaces.
- One shared namespace: every file starts with `local addonName, ns = ...`.
- No new globals except those allowed by the doc's "One namespace" rule (`LodestarDB`, slash command globals, `LodestarTooltip`, `LodestarCopyFrame`, `Lodestar...PinMixin`). Every allowed global is listed in `.luacheckrc`.
- Game-independent logic goes in `Logic.lua` with no WoW API calls, and gets unit tests.
- Evidence rule: use only WoW APIs confirmed in `notes/beta-probes.md`. If an API is not confirmed there, ask the user to probe it; do not guess. The WoW API annotations in `tools/wow-api` (Zed autocomplete) describe Retail/Classic, not Forever, and are not evidence.
- When an API is confirmed or used, add it to `read_globals` in `.luacheckrc`.
- Map overlays are data providers with pins from `Pins.xml`; never create frames or FontStrings inside `OnUpdate` or per map refresh.
- No taint: never replace or reassign Blizzard functions or fields; use `hooksecurefunc` or `HookScript`; `SetScript` only on our own frames.
- No libraries (Ace3 etc.) without asking.
- Never copy Blizzard UI source or Warcraft Wiki text into the repo; facts (IDs, level ranges, coordinates) are fine.
- After every change run `scripts/check.ps1` (luacheck + tests) and fix failures before reporting done.

## Status

- Design: draft, all review fixes applied.
- M0: design probes P1-P9 done (`notes/beta-probes.md`); `Data/Zones.lua` seeded 2026-10-18 (50 zones from P30; checked by `tests/zones_spec.lua`); since 2026-10-19 its ranges come from the beta's group finder (P33) for 41 zones, see the doc's Zones "Level source"; `Data/Instances.lua` seeded 2026-10-19 (42 instances; levels from the beta's group finder, P33; vanilla entrances approximate; the four Forever dungeons in the beta have their meeting stones measured, P12; checked by `tests/instances_spec.lua`). M0 done.
- M1 (dev environment): done. Every `Logic.lua` function has unit tests in `tests/`; the game junction and local paths are in `notes/environment.md`.
- API probes P16 (M2) and P17 (M4-M5) done on 2026-10-13; the confirmed names are in `.luacheckrc`.
- M2 (skeleton): done 2026-10-19. Steps 2.1 (`.toc`, `PLAYER_LOGIN`, P18), 2.2 (`Util.lua`: `ns.Print`, `ns.SafeCall`, P19), 2.3 (`LodestarDB` defaults via `Logic.MergeDefaults`, `ns.db`, P20), 2.4 (event dispatcher, module registry, map tick, P21-P23), 2.5 (`Options.lua`: `/ls`, `/lodestar`, `toggle`, `debug`, P24-P25) and 2.6 (`Debug.lua`: log and `/ls log clear`, `/ls copy`, `/ls dump`, `/ls probe`, `/ls probe here`, P27-P31, P34). Step specs live in `notes/spec-<step>-<topic>.md`.
- M3 (data): ongoing alongside M4; the zone ranges and the Forever entrances above are its first results.
- M4 (overlays): step 4.1 done 2026-10-19 (`Logic.MergeZoneInfo`, `ColorCode`, `FormatLevelRange`; `ns.GetZoneInfo`, `ns.LevelColorCode`; ranges in `/ls probe hover`, P35). Forever's client keeps quest-color yellow down to 4 levels below the player, not 2 (P35). Next: step 4.2, ZoneLabels (`notes/spec-4.2-zone-labels.md`): probe P36, test pin P37, real labels P38. The beta closes 2026-10-21; the live client opens 2026-11-04.
