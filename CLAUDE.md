# Lodestar

World of Warcraft: Forever addon that shows zone level ranges, instance entrances, coordinates and a zone tooltip on the world map. Personal use, MIT licensed, English client only.

The design doc is the source of truth: `docs/Lodestar – WoW Forever Map Addon Design Doc.md`. Read the relevant section before changing code, and update the doc when a decision changes.

## How work happens here

- Claude Code cannot run the game; the user is the test harness. They `/reload` in game and report back.
- In-game output (`/ls probe`, `/ls dump`, caught errors) is read from `WTF/Account/<ACCOUNT>/SavedVariables/Lodestar.lua` in the game folder (exact path in `notes/environment.md` once recorded). Never edit that file: the game overwrites it at logout.
- Probe results live in `notes/beta-probes.md`, numbered P1-P15 as in the doc's "Beta verification checklist".

## Rules

- Lua 5.1 only. Always declare variables `local`.
- One shared namespace: every file starts with `local addonName, ns = ...`.
- No new globals except those allowed by the doc's "One namespace" rule (`LodestarDB`, slash command globals, `LodestarTooltip`, `LodestarCopyFrame`, `Lodestar...PinMixin`). Every allowed global is listed in `.luacheckrc`.
- Game-independent logic goes in `Logic.lua` with no WoW API calls, and gets unit tests.
- Evidence rule: use only WoW APIs confirmed in `notes/beta-probes.md`. If an API is not confirmed there, ask the user to probe it; do not guess. VS Code WoW API annotations describe Retail/Classic, not Forever, and are not evidence.
- When an API is confirmed or used, add it to `read_globals` in `.luacheckrc`.
- Map overlays are data providers with pins from `Pins.xml`; never create frames or FontStrings inside `OnUpdate` or per map refresh.
- No taint: never replace or reassign Blizzard functions or fields; use `hooksecurefunc` or `HookScript`; `SetScript` only on our own frames.
- No libraries (Ace3 etc.) without asking.
- Never copy Blizzard UI source or Warcraft Wiki text into the repo; facts (IDs, level ranges, coordinates) are fine.
- After every change run `scripts/check.ps1` (luacheck + tests) and fix failures before reporting done. Until M1 is complete the script does not exist yet; say so instead of claiming checks passed.

## Status

- Design: draft, all review fixes applied.
- M0 (design probes P1-P9) and M1 (dev environment): not started.
- No addon code yet.
