# Beta final checklist (2026-10-20 to 2026-10-21)

Status: done 2026-10-21. Every item ran: P14 and P15 passed on run 3 after two fixes (pin pass-through override, map size through `EventRegistry` instead of hooks, P42); P40, P41, P13 passed; P12 got the Deadmines stone; P26 answered. Results in `notes/beta-probes.md`.

Goal: use the last beta days to consolidate, not to add features. Label style iterates on the live client. Run the items in order; each one is independent, so stopping halfway loses nothing. Send screenshots after each item; Claude records them in `notes/beta-probes.md`.

Before starting: script errors on, so Lua errors show as popups.

```
/console scriptErrors 1
```

## 1. Taint: the map in combat (P14, P15)

Why first: since step 4.2, Lodestar adds a map data provider and hooks `WorldMapFrame.Maximize` and `Minimize`. The design's "no taint" rule says this is safe; only a fight proves it.

Turn on the taint log, then reload so it starts clean:

```
/console taintLog 1
```

```
/reload
```

Then, in one fight against any mob (attack it and keep fighting while doing the steps):

1. Open the map (`M`) on a continent, with the labels showing. Close it.
2. Open it again, maximize it, minimize it, close it.
3. Still in combat, use an action bar ability.

Expected (P14): no error popup. Expected (P15): no "Interface action failed because of an AddOn" in chat.

After the fight, reload so the game writes the log, then turn logging off:

```
/reload
```

```
/console taintLog 0
```

Claude reads `Logs\taint.log` in the game folder for lines naming Lodestar.

## 2. Probes for M5 (P40, P41, P13)

All one line each, anywhere in the world, no fight needed.

### P40: the level-up event

Labels should recolor when you level. The event name is unprobed, and registering an unknown event raises an error in modern clients, so `pcall` tells. The second line is a control with a made-up name, which should fail:

```
/run local f=CreateFrame("Frame") print("PLAYER_LEVEL_UP", pcall(f.RegisterEvent, f, "PLAYER_LEVEL_UP"))
```

```
/run local f=CreateFrame("Frame") print("LODESTAR_FAKE_EVENT", pcall(f.RegisterEvent, f, "LODESTAR_FAKE_EVENT"))
```

Expected: `PLAYER_LEVEL_UP true`, then `LODESTAR_FAKE_EVENT false` with an error message. If the fake one also prints `true`, the client accepts any name and this probe proves nothing; then the real check is leveling once with the map open.

### P41: icons for dungeon and raid markers

The Instances module needs an icon. Forever's UI is the retail code (P36), which draws dungeon entrances with texture atlases:

```
/dump C_Texture ~= nil, C_Texture.GetAtlasInfo("Dungeon") ~= nil, C_Texture.GetAtlasInfo("Raid") ~= nil
```

```
/run local t=UIParent:CreateTexture() print("SetAtlas", t.SetAtlas ~= nil)
```

Expected: `true, true, true`, then `SetAtlas true`. If an atlas name is `false`, Claude suggests other names to try.

### P13: exploration API (v2)

```
/dump C_MapExplorationInfo ~= nil, C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures ~= nil
```

Expected: `true, true` if the v2 "unexplored areas" idea can use it.

## 3. Optional

- **P12, one more vanilla entrance**: the seeded entrances are Claude's recall and the Stockade one was far off. One spot-check: at The Deadmines' meeting stone in Westfall (or any dungeon's stone you pass), run `/ls probe here`.
- **P26, chat order**: log out and back in (not `/reload`), and screenshot the first chat lines; then `/reload` and screenshot again.

## After the beta

- M5: Instances markers and the Tooltip (first decision: cursor tooltip or Cartographer-style header).
- 4.3 leftovers: refresh on level-up (with P40), automatic collision handling for overlapping labels (Duskwood, Deadwind Pass, Swamp of Sorrows).
- Label style iterations.
- Re-check on the live client: group finder ranges, `GetMapLevels`, Zephras Isle on the world map, the Dalaran portal.
