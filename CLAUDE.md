# Lodestar

World of Warcraft: Forever addon that shows zone level ranges, instance entrances, coordinates and a zone tooltip on the world map. Hobby project released for fun (GitHub Releases for friends now, CurseForge after the MVP), MIT licensed, English client only, original art only.

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
- No libraries (Ace3 etc.) without asking. Allowed: QuestieDB as an optional runtime quest source (2026-11-18); its data is read through its API, never copied into the repo.
- Never copy Blizzard UI source or Warcraft Wiki text into the repo; facts (IDs, level ranges, coordinates) are fine.
- After every change run `scripts/check.ps1` (luacheck + tests) and fix failures before reporting done.

## Forever platform facts

Confirmed in game; details and probe results in `notes/beta-probes.md`.

- Forever's UI is Mainline and has no `MapCanvasPinTemplate`: pin templates in `Pins.xml` are plain virtual frames (P36).
- Pins get an empty `CheckMouseButtonPassthrough`, and map size is followed through `EventRegistry`, not by hooking `Maximize`/`Minimize`; both keep combat free of taint (P42).
- Pin templates have no `OnEnter`/`OnLeave`: `AcquirePin` asserts (P59-P60).
- Quest-color yellow reaches 4 levels below the player (P35).
- Discovery reads the game's fog of war (P44); addon textures load with alpha (P46).
- No zone shape fits the painted borders (Blizzard's highlight art cannot be tinted; grid and traced masks spill), so zones are marked with pins, not fills (P48-P51).

## Status

- Design: draft, all review fixes applied.
- M0-M2 done. Step specs live in `notes/spec-<step>-<topic>.md`. `Data/Zones.lua` and `Data/Instances.lua` (43 instances) are checked by `tests/zones_spec.lua` and `tests/instances_spec.lua`; where each range comes from is in the doc's Zones and Instances "Level source". Every `Logic.lua` function has unit tests; local paths are in `notes/environment.md`.
- M3 (data): ongoing alongside M5.
- M4-M5 (overlays): steps 4.1-5.6 done: zone labels and threat pins (one pin for both map sizes, hand-set `labelX, labelY` for all 43 continent zones, `/ls place`) and instance markers (one per door, revealed through the fog of war, `/ls reveal`; Ruins and Temple of Ahn'Qiraj share one). Shen'dralas stays unlabeled until an in-game source gives its range.
- Release pipeline: done 2026-11-28 (`notes/spec-release-pipeline.md`). A `v*` tag publishes a GitHub Release through the BigWigs packager; release builds show only player commands (`/ls dev` for the rest); steps under "Releasing" in the design doc. Latest: `v0.2.0-beta1` (pre-release).
- Next: step 5.7, skull-only threat pins with the zone Tooltip; draft in `notes/spec-5.7-skull-pins-tooltip.md`, open questions before the plan.
- Pending in game: `notes/todo-p54-pending-checks.md`, `notes/todo-p60-pending-checks.md`.
- M7 (quest tracking): proposed, starts after M5; see the doc's "Quest tracking" (QuestieDB at runtime behind `ns.QuestSource`, completed quests as dimmed pins, two open questions).
