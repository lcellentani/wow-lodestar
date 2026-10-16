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
- M0: design probes P1-P9 done (`notes/beta-probes.md`); seeding `Data/Zones.lua` and `Data/Instances.lua` still to do.
- M1 (dev environment): done. `Logic.lua` has five tested pure functions; the game junction and local paths are in `notes/environment.md`.
- API probes P16 (M2) and P17 (M4-M5) done on 2026-10-13; the confirmed names are in `.luacheckrc`.
- M2 (skeleton): steps 2.1 (`.toc`, `PLAYER_LOGIN`, P18), 2.2 (`Util.lua`: `ns.Print`, `ns.SafeCall`, P19) and 2.3 (`LodestarDB` defaults via `Logic.MergeDefaults`, `ns.db`, P20) done. Next: 2.4, event dispatcher and module registry. Step specs live in `notes/spec-<step>-<topic>.md`.
