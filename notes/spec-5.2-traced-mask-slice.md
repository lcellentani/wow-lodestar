# M5 step 5.2: traced mask slice

Status: spec written 2026-11-06. No addon code. It evaluates a third way to get zone shapes after grid masks failed on fit (P50); the direction is decided after this slice. Probe number reserved: P51.
Design doc reference: "ThreatOverlay", "Zone shapes" tier 3, which this replaces with a simpler capture.

## What this step is for

Blizzard's highlight art has the true zone shape, but it cannot be tinted in game (P45, P48). A screenshot of it can be turned into a mask outside the game. The art is drawn on a magenta frame, so the script finds its exact edges, and the rectangle comes from the API, so placement needs no measuring.

Masks made this way derive from Blizzard's art, so they stay **local**: `Media/traced/` is git-ignored and nothing traced goes in the public repo. A fresh clone has no traced masks.

Same three zones as P50, for a direct comparison: Elwynn Forest (1429), Wetlands (1437), Silverpine Forest (1421). The points below sit well inside each zone's hover area (from the P50 grid).

## Step 1: capture (user)

With other addons off, after a `/reload`, map closed.

```
/run local f=CreateFrame("Frame",nil,UIParent) LSB=f f:SetFrameStrata("HIGH") f:SetPoint("CENTER") f:SetSize(640,440) local b=f:CreateTexture(nil,"BACKGROUND") b:SetAllPoints() b:SetColorTexture(1,0,1)
```

```
/run local t=LSB:CreateTexture(nil,"ARTWORK") LSA=t t:SetPoint("CENTER") t:SetSize(600,400) LodestarDB.art={}
```

```
/run LSZ=function(i,x,y) local v={C_Map.GetMapHighlightInfoAtPosition(1415,x,y)} LodestarDB.art[i]={v[5],v[6],v[7],v[8]} LSA:SetTexture(v[1]) LSA:SetTexCoord(0,v[3],0,v[4]) print(i,v[1],v[3],v[4]) end
```

For each zone, run its line, then take a lossless PNG screenshot of the whole game window into `screenshots/`. Keep the magenta frame fully in view.

```
/run LSZ(1429,0.479,0.709)
```

```
/run LSZ(1437,0.518,0.467)
```

```
/run LSZ(1421,0.396,0.291)
```

Then `/reload`, which saves the rectangles to `LodestarDB.art`.

## Step 2: build (Claude)

A script reads each screenshot and the rectangles, and writes white `.tga` masks with the shape in the alpha channel to `Media/traced/`.

## Step 3: restart and draw (user)

Result of steps 1-2 (2026-11-07): `scripts/trace_masks.py` built the three masks from screenshots 114916, 114931 and 114948. The art is dim (brightest pixel 28-51 of 255) but the edge is clean; rectangles come from `LodestarDB.art`.

Full client restart, then, with the map open on Eastern Kingdoms (the same helpers as P50, with the traced path):

```
/run LSC=WorldMapFrame.ScrollContainer.Child LSD=function(x,y,W,H) local w,h=LSC:GetSize() local f=CreateFrame("Frame",nil,LSC) f:SetFrameLevel(1000) f:SetPoint("TOPLEFT",x*w,-y*h) f:SetSize(W*w,H*h) return f end
```

```
/run LST=function(f,i,r,g,b,a) local t=f:CreateTexture() t:SetAllPoints() t:SetTexture("Interface\AddOns\Lodestar\Media\traced\mask-"..i) t:SetVertexColor(r,g,b,a) return t end
```

```
/run LT1=LST(LSD(0.41093,0.65652,0.09860,0.09863),1429,1,0.2,0.2,0.45)
```

```
/run LT2=LST(LSD(0.46561,0.40971,0.11748,0.11745),1437,0.2,1,0.2,0.45)
```

```
/run LT3=LST(LSD(0.35654,0.24716,0.11932,0.11932),1421,1,0.8,0,0.45)
```

The same zones at 0.25 opacity, for comparison:

```
/run LT1:SetVertexColor(1,0.2,0.2,0.25) LT2:SetVertexColor(0.2,1,0.2,0.25) LT3:SetVertexColor(1,0.8,0,0.25)
```

Compare fit, readability and labels with P50, on the small and the maximized map.

## After the slice

Choose the direction: local traced masks, a soft inner wash, or no zone shapes. Remove the temporary data with `/run LodestarDB.grid=nil LodestarDB.art=nil`.
