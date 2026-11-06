# M5 step 5.1: grid mask slice

Status: spec written 2026-11-06. No addon code: every in-game step is a chat command, and Claude writes the mask script. If the slice passes, Claude writes the ThreatOverlay module spec.
Design doc reference: "ThreatOverlay" (Module specs), "Zone shapes" tier 2. Probe number reserved: P50.

## What this step is for

P45 and P48 closed Blizzard's art, so ThreatOverlay rests on grid masks. P46 and P47 confirmed the parts, but nobody has seen a mask on the map. This slice answers three questions before any module code exists:

1. **Fit:** does a mask from the game's hover areas match the zone borders painted on the map?
2. **Readability:** at which tint strength does the threat color read while the map stays legible?
3. **Labels:** do range labels stay readable with the tint, including red text on a red zone?

## Decisions

- Grid: 256 x 256 over Eastern Kingdoms (1415), about 4 pixels per cell on the 1002-pixel map. Move to 512 if the edges look rough.
- Test zones: Elwynn Forest (1429), Wetlands (1437) and Silverpine Forest (1421). Elwynn is the known case; the other two have long, awkward shapes.
- `LodestarDB.grid` and the global `LSG` are temporary; the key is removed at the end.

## Step 1: sample (user)

Run from a `/reload`, with other addons off. Define the lookup:

```
/run LSG=function(x,y) local m=C_Map.GetMapInfoAtPosition(1415,(x+.5)/256,(y+.5)/256) return m and m.mapID or 0 end
```

Sample the grid. The game may freeze for a moment. Expected: `256`.

```
/run local R={} for y=0,255 do local t,p,n={},0,0 for x=0,255 do local i=LSG(x,y) if i==p then n=n+1 else t[#t+1]=p..":"..n p,n=i,1 end end t[#t+1]=p..":"..n R[y+1]=table.concat(t," ") end LodestarDB.grid=R print(#R)
```

Each row is a string of `mapID:count` runs from west to east, `0` meaning no map (sea), and every row adds up to 256 cells. Tested with a stub on Lua 5.1 before the session. Then `/reload` to write the file.

## Step 2: build (Claude)

A script in `scripts/` reads the grid from the SavedVariables file, reports the cells per map (which also shows how cities such as Stormwind City come back), and writes one smoothed white `.tga` per test zone to `Media/`, with the shape in the alpha channel, plus each zone's rectangle as map fractions.

## Step 3: restart (user)

Close the client fully and start it again: it only sees files that existed when it started.

## Step 4: draw and judge (both)

`/run` commands, written once the rectangles are known, place the masks on the map over the labels' layer and under it, at a few tint strengths. Screenshots go to Claude, and P50 records the answers to the three questions.

## After the slice

Remove the temporary data with `/run LodestarDB.grid=nil`. If the masks pass, the same script covers every zone and both continents, and Claude writes the ThreatOverlay spec. If they fail, the first thing to try is the 512 grid.
