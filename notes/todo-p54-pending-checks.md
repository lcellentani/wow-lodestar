# To do: P54 pending checks (5, 6, 9)

Written 2026-11-13. Checks 1-4, 7 and 8 of P54 passed on 2026-11-08 (`notes/beta-probes.md`); these three are left. Full checklist in `notes/spec-5.4-threat-markers.md`. The code is already in `Modules/ThreatOverlay.lua`; these only confirm it in game.

Character: the level-1 Paladin in Deathknell, Tirisfal Glades. Checks 5 and 6 take about ten minutes.

## [ ] Check 5: crossing a border with the map open

Tests: the map tick (`OnMapTick`) notices the zone change and redraws, and redraws only when the zone changes.

1. Open the **small** Eastern Kingdoms map in Tirisfal Glades: markers on Silverpine Forest (8), Alterac Mountains (28), Western Plaguelands (48).
2. Walk south-west into Silverpine Forest with the map open.
3. Within a second of crossing: markers on Silverpine's neighbors, Alterac, Tirisfal and Hillsbrad; none on Silverpine itself.
4. Walk back: the first set returns.

Not wanted: flicker or errors while standing still.

## [ ] Check 6: in a capital (Undercity)

Tests: a city counts as the zone around it. `Data/Zones.lua` links Undercity (`1458`) to Tirisfal (`1420`), but that row is marked **unverified** (vanilla map ID), so this also checks the ID.

1. Go into Undercity and open the small map.
2. Expected: the same three markers as in Tirisfal (Silverpine, Alterac, Western Plaguelands).
3. If nothing shows: run `/ls probe here` inside Undercity and report back; Claude reads the map ID from the SavedVariables file.

## [ ] Check 9: color changes on level-up

Tests: `PLAYER_LEVEL_UP` triggers a redraw (`OnLevelUp`), and the colors change without reopening the map.

**Do it after the pin rework** (fit level, range in the tab): the colors change then anyway, and one level-up then tests the final code. The expected result below is the same before and after the rework.

1. Keep the small map open while reaching level 4.
2. Expected: Silverpine's marker turns from **red to orange** (8 is 4 above you, Forever's orange band). Alterac and Western Plaguelands stay red.
3. If the color only changes after closing and reopening the map: in some clients `UnitLevel` still returns the old level when `PLAYER_LEVEL_UP` fires. The fix is small: use the level the event passes in, or delay the redraw by one frame.

## After

Report what you saw (screenshots help); Claude records the result under P54 in `notes/beta-probes.md` and deletes this file.
