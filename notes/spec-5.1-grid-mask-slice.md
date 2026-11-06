# M5 step 5.1: grid mask slice

Status: spec written 2026-11-06. No addon code: every in-game step is a chat command, and Claude writes the mask script. If the slice passes, Claude writes the ThreatOverlay module spec.
Design doc reference: "ThreatOverlay" (Module specs), "Zone shapes" tier 2. Probe number reserved: P50.

## What this step is for

P45 and P48 closed Blizzard's art, so ThreatOverlay rests on grid masks. P46 and P47 confirmed the parts, but nobody has seen a mask on the map. This slice answers three questions before any module code exists:

1. **Fit:** does a mask from the game's hover areas match the zone borders painted on the map?
2. **Readability:** at which tint strength does the threat color read while the map stays legible?
3. **Labels:** do range labels stay readable with the tint, including red text on a red zone?

## Decisions

- Grid: 256 x 256 over Eastern Kingdoms (1415), about 4 pixels per cell on the 1002-pixel map. A finer grid was the plan for rough edges, but step 1 showed the lookup itself is coarse.
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

Result of step 1 (2026-11-06): 256 rows of 256 cells, 27 maps. The hover lookup is coarse: zones come back as blocks about 3 grid rows tall (roughly 8 pixels on the map), so a finer grid would add little. 5,487 land and coast cells return the continent itself (1415), not a zone. Elwynn plus Stormwind City spans x 0.406-0.508, y 0.660-0.754, against the art's 0.411-0.510, 0.657-0.755 (P45). `scripts/make_masks.py` smooths the steps; Stormwind City's cells are merged into Elwynn's mask (`1429+1453`).

Open the map on Eastern Kingdoms. Two helpers, then the three zones in three colors at 0.45 opacity. Frame level 1000 should put them above the map art and under the pins:

```
/run LSC=WorldMapFrame.ScrollContainer.Child LSD=function(x,y,W,H) local w,h=LSC:GetSize() local f=CreateFrame("Frame",nil,LSC) f:SetFrameLevel(1000) f:SetPoint("TOPLEFT",x*w,-y*h) f:SetSize(W*w,H*h) return f end
```

```
/run LST=function(f,i,r,g,b,a) local t=f:CreateTexture() t:SetAllPoints() t:SetTexture("Interface\AddOns\Lodestar\Media\mask-"..i) t:SetVertexColor(r,g,b,a) return t end
```

```
/run LT1=LST(LSD(0.39844,0.65234,0.11719,0.10938),1429,1,0.2,0.2,0.45)
```

```
/run LT2=LST(LSD(0.45703,0.40234,0.13281,0.12891),1437,0.2,1,0.2,0.45)
```

```
/run LT3=LST(LSD(0.34766,0.24219,0.11328,0.13281),1421,1,0.8,0,0.45)
```

A lighter tint (half of the above), for comparison:

```
/run for _,t in ipairs({LT1,LT2,LT3}) do t:SetAlpha(0.5) end
```

Screenshots go to Claude, on the small and the maximized map, and P50 records the answers to the three questions.

## After the slice

Remove the temporary data with `/run LodestarDB.grid=nil`. If the masks pass, the same script covers every zone and both continents, and Claude writes the ThreatOverlay spec. If they fail, a finer grid is unlikely to help, because the lookup itself is coarse: the fallback tiers need rethinking.
