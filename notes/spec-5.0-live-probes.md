# M5 step 5.0: day-one probes on the live client

Status: spec written 2026-10-24, for the first session on the live client (2026-11-04). No addon code: every check is a chat command. Claude records the results in `notes/beta-probes.md` (the file keeps its name), adds confirmed names to `.luacheckrc`, and updates the design doc with what each result decides.
Design doc reference: "Principles", "Discovery" (Feature set), "ThreatOverlay" and "ZoneLabels" (Module specs), "Open questions".

## What this step is for

The 2026-10-24 brainstorm (`notes/brainstorm-2026-10-24-map-ux.md`) made three decisions that rest on APIs nobody has seen work in Forever:

| Probe | Question | What the answer decides |
| --- | --- | --- |
| P43 | Does the addon load on the live client? | Whether the `.toc` interface number needs a change before anything else |
| P44 | What does `C_MapExplorationInfo` return? | "Discovery": the game's fog of war, or Lodestar's own per-character record of zones entered |
| P45 | Can Blizzard's zone highlight art be fetched for any zone and tinted? | ThreatOverlay zone shapes: tier 1 (Blizzard's art) or tier 2 (grid masks) |
| P46 | Does a texture load from the addon folder? | Whether tier 2 masks can ship at all |
| P47 | How fast is `C_Map.GetMapInfoAtPosition`? | The grid size and whether the grid probe must be spread over several frames (needed for label anchors in any case) |

The function names in P44 and P45 come from Blizzard's Mainline (retail) API, which Forever's UI is built on (P36). They are guesses until these probes confirm them; that is the point of the probes (evidence rule).

## Before the session

- **Junction.** Install the live client, then create the junction in its folder and add its paths to `notes/environment.md` (Claude does the notes; the command is in that file's "Live client" section).
- **Test texture.** `Media/probe-white.tga` (64x64 white disc with soft edges, made by Claude 2026-10-24) is already in the repo, so the junction shows it. The game only sees files that existed when it started, so start the client after the junction exists.
- **Character.** A fresh character is ideal: only its starting area is explored, which is exactly what P44 needs. Any faction.
- Script errors on:

```
/console scriptErrors 1
```

Screenshot after each probe; the results also land in chat only, not in the SavedVariables log.

## P43: the addon loads

```
/dump (select(4, GetBuildInfo()))
```

Expected: `16001`, the `.toc`'s `## Interface`. If it differs, the character screen's AddOns list shows Lodestar as out of date: tick "Load out of date AddOns", carry on with the probes, and Claude updates the `.toc`.

```
/ls
```

Expected: the command list, and no error popup since login.

## P44: exploration

**Step 1, the functions exist.**

```
/dump C_MapExplorationInfo.GetExploredMapTextures ~= nil, C_MapExplorationInfo.GetExploredAreaIDsAtPosition ~= nil, CreateVector2D ~= nil
```

Expected: three `true`. A `false` for the second or third is not fatal: step 2 still runs.

**Step 2, explored pieces of your zone against a zone you have never visited** (Tanaris, 1446).

```
/dump #(C_MapExplorationInfo.GetExploredMapTextures(C_Map.GetBestMapForUnit("player")) or {}), #(C_MapExplorationInfo.GetExploredMapTextures(1446) or {})
```

Expected: a number above 0, then `0`. That would confirm "entered a zone = any of its areas explored". If Tanaris is above 0 too, the game reveals maps without exploring them, and "Discovery" falls back to Lodestar's own record.

**Step 3, what one explored piece looks like.**

```
/dump (C_MapExplorationInfo.GetExploredMapTextures(C_Map.GetBestMapForUnit("player")) or {})[1]
```

Expected: a table. Claude needs its field names (offsets, sizes, texture IDs) to tell whether an entrance lies inside an explored piece, in case step 4 fails.

**Step 4, explored at a point** (only if step 1's second value was `true`). Where you stand, then the middle of Tanaris:

```
/dump C_MapExplorationInfo.GetExploredAreaIDsAtPosition(C_Map.GetBestMapForUnit("player"), C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"))
```

```
/dump C_MapExplorationInfo.GetExploredAreaIDsAtPosition(1446, CreateVector2D(0.5, 0.5))
```

Expected: one or more area IDs, then `nil` or an empty table. That is exactly the "has the area holding this entrance been explored?" question, one call per entrance.

**Step 5 (whenever convenient), the same after walking into a new sub-area.** Walk until the game shows "Discovered: <name>" (or the area name appears for the first time), then repeat step 2's first value. Expected: the number has grown.

## P45: Blizzard's zone highlight art

Open the world map on any continent first (the call does not need it, but the screenshot does).

**Step 1, the function exists and answers for a zone you are not hovering** (Elwynn Forest on Eastern Kingdoms, at the center of its rectangle):

```
/dump C_Map.GetMapHighlightInfoAtPosition ~= nil
```

```
/run local a,b,c,d=C_Map.GetMapRectOnMap(1429,1415) LSH={C_Map.GetMapHighlightInfoAtPosition(1415,(a+b)/2,(c+d)/2)} print(unpack(LSH))
```

Expected: `true`, then eight values: a texture file ID, an atlas ID, two fractions between 0 and 1, two sizes, two positions. If the first value is `0` or `nil` and the second is not, the art is an atlas; send the line and Claude adapts step 2.

**Step 2, draw it tinted.** The zone's shape should appear in the middle of the screen in red (it is not placed on the map; this only checks that it can be drawn and tinted):

```
/run local t=UIParent:CreateTexture(nil,"OVERLAY") LST=t t:SetPoint("CENTER") t:SetSize(LSH[5],LSH[6]) t:SetTexture(LSH[1]) t:SetTexCoord(0,LSH[3],0,LSH[4]) t:SetVertexColor(1,0.2,0.2,0.8)
```

Expected: Elwynn's outline in red. Then the multiply blend mode, which should darken the screen under it instead:

```
/run LST:SetBlendMode("MOD") print(LST:GetBlendMode())
```

Expected: `MOD` and a visible change. Remove the test texture:

```
/run LST:Hide()
```

If step 1 or 2 fails, ThreatOverlay uses tier 2 (grid masks), which P46 checks.

## P46: a texture from the addon folder

```
/run local t=UIParent:CreateTexture(nil,"OVERLAY") LSX=t t:SetPoint("CENTER") t:SetSize(128,128) print(t:SetTexture("Interface\\AddOns\\Lodestar\\Media\\probe-white")) t:SetVertexColor(1,0.8,0)
```

Expected: a yellow disc with soft edges in the middle of the screen; the chat value is whatever `SetTexture` returns (likely `true`) and is recorded but not relied on. White tinted yellow proves `SetVertexColor` colors a white mask, and the soft edge proves the alpha channel loads. A plain square or nothing means the file did not load (most often: the client was started before the file existed).

```
/run LSX:Hide()
```

## P47: grid sampling speed

10,000 zone lookups on Eastern Kingdoms (a 100 x 100 grid), timed in milliseconds:

```
/dump debugprofilestop ~= nil
```

```
/run local s=debugprofilestop() for i=0,9999 do C_Map.GetMapInfoAtPosition(1415,(i%100+0.5)/100,(math.floor(i/100)+0.5)/100) end print(debugprofilestop()-s)
```

Expected: `true`, then a number. Below about 200 ms, a 128 x 128 grid can run in one go behind a "the screen will freeze for a moment" warning; above it, the grid probe spreads its work over several frames. The game may freeze briefly during this line: that is the measurement.

## After the session

Claude records P43-P47 in `notes/beta-probes.md`, adds the confirmed names to `.luacheckrc` (at least `CreateVector2D` and `debugprofilestop` if they exist), closes or updates the design doc's open question on live probes, and writes the step spec for the first M5 module with the results in hand. Commits as before: Claude's notes and data `[T4]`; no user code in this step.
