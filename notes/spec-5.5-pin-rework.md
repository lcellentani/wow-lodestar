# M5 step 5.5: the threat pin on both maps

Status: spec written 2026-11-13. `Logic.FitLevel` and the pin mixin by the user; `Pins.xml`, module wiring, `.toc`, `.luacheckrc` and the design doc by Claude. Probe number reserved: P58 (the pins in game). No API probe needed: everything used is confirmed (P8, P46, P55, P56, P57, and the 5.4 list).
Design doc reference: "Difficulty colors" (fit level), "ThreatOverlay", "ZoneLabels", "How map overlays draw". Look decided in `notes/label-style-exploration-2026-11-08.md`, "Current choice".

## What this step is for

The label style pass ended with one pin for both maps (2026-11-09): the small-map threat marker, with the zone's range in its tab and one color per zone, the **fit level**. The maximized map gets a larger copy of the same pin on every zone, in place of today's name and colored range text. Both get a soft dark shadow.

## Decisions

- **Same pin, two sizes.** Small map: today's sizes. Maximized map: drawn larger by the art script, so edges stay crisp (not the small pin scaled up).
- **Color:** `GetQuestDifficultyColor(fit)` with `fit = Logic.FitLevel(UnitLevel("player"), min, max)`. It colors the disc edge, tab edge and skull. Plates stay dark, text stays white.
- **Tab:** the range `min-max` in white (one number for a single-level zone). The tab grows with the text: a sliced texture (P57), so its corners keep their radius.
- **Shadow:** a soft dark shadow under the disc and under the tab, black at the opacity stored in the texture.
- **Which zones:** unchanged. Small map: the player's neighbors (ThreatOverlay). Maximized map: every zone of the continent with a range and a point (ZoneLabels). No zone names on either map: the Tooltip (later step) gives names on hover.
- **Modules** (user, 2026-11-13): ZoneLabels keeps the maximized map and draws the large pin; ThreatOverlay keeps the small map. The mixin moves to its own file so both modules share it. The module names and `/ls toggle` keys do not change.
- **Level-up:** both modules refresh on `PLAYER_LEVEL_UP`. For ZoneLabels this is the step 4.3 leftover; ThreatOverlay already has it.

| | Small (`LodestarThreatPinTemplate`) | Large (`LodestarThreatPinLargeTemplate`) |
| --- | --- | --- |
| Disc edge / plate | 22 / 18 | 30 / 24 |
| Edge width | 2 | 3 |
| Skull | 14 | 20 |
| Tab height (outer) | 18 | 32 |
| Room left and right of the text | 4 (start value, tune live) | 11 |
| Font | `GameFontHighlightSmallOutline` (10 pt, P55) | `GameFontHighlightLarge` (16 pt, P56) |
| Tab texture, slice margin | `threat-tab-small`, 4 | `threat-tab-large`, 5 |
| Tab shadow, slice margins (L, T, R, B) | `threat-shadow-tab-small`, 17, 16, 17, 16 | `threat-shadow-tab-large`, 18, 16, 18, 16 |
| Disc shadow | `threat-shadow-disc-small` | `threat-shadow-disc-large` |

All the art exists since `83961e8` (`scripts/make_marker_art.py`; numbers from its header). `threat-disc` and `threat-skull` serve both sizes. `threat-tab.tga` (the stretched one-level tab) retires after P58.

## Logic.lua (yours, unit tested)

### `Logic.FitLevel(playerLevel, min, max)`

Returns the player's level clamped into the zone's range: `min` when the player is below it, `max` when above, the player's level inside. Design doc, "Difficulty colors": below a zone the color warns (yellow, orange, red), inside it is yellow, above it fades (green, grey).

- `max == nil` means a single-level zone: treat it as `max = min`.
- `min == nil` (no range): return `nil`.
- Hint: `math.min` and `math.max` do it in one line; mind the order (clamp from below, then from above).
- Tests in `tests/logic_spec.lua`: below the range returns `min`; inside returns the player's level; above returns `max`; exactly `min` and exactly `max`; `max == nil` behaves as single level (below, equal, above); `min == nil` returns `nil`. Use the doc's examples: level 24 in Duskwood `18-34` gives 24; in Westfall `8-24` gives 24; level 30 in Westfall gives 24.

## The pin mixin (yours): `Pins.lua`

A new file next to `Pins.xml`, listed in `Lodestar.toc` after `Core.lua` and before `Modules\ZoneLabels.lua` (Claude edits the `.toc`). Move `LodestarThreatPinMixin` and its empty `CheckMouseButtonPassthrough` out of `Modules/ThreatOverlay.lua` into it; both templates use this one mixin.

The sizes live in the XML. The only numbers Lua needs are the slice margins, which differ per size, so put two style tables on the namespace:

```lua
ns.ThreatPinStyle = {
  small = { tab = 4, shadowSide = 17 },
  large = { tab = 5, shadowSide = 18 },
}
```

(The shadow's top and bottom margins are 16 for both.)

**`OnAcquired(style, min, max, x, y)`** (the signature the modules will call; keep it):

1. Slice margins, every time (cheap, and a reused pin may come from either module): `self.TabEdge` and `self.Tab` get `SetTextureSliceMargins(style.tab, style.tab, style.tab, style.tab)`; `self.ShadowTab` gets `SetTextureSliceMargins(style.shadowSide, 16, style.shadowSide, 16)`.
2. Color: `local fit = ns.Logic.FitLevel(UnitLevel("player"), min, max)`, then `GetQuestDifficultyColor(fit)` on `DiscEdge`, `TabEdge` and `Skull`, as today.
3. Plates: `Disc` and `Tab` dark, as today (`PLATE_R, PLATE_G, PLATE_B` move with the mixin).
4. Shadows: `ShadowDisc` and `ShadowTab` get `SetVertexColor(0, 0, 0)`; the texture carries the opacity.
5. Text: `self.Range:SetText(...)` with `min-max`, or `min` alone when `max` is `nil` or equal to `min`. Plain text, no color codes.
6. `SetPosition(x, y)` and `SetScalingLimits(1, 1.0, 1.2)`, as today.

The `Level` FontString is renamed `Range` in the templates.

Hint: the tab sizes itself from the text through XML anchors (below), so the mixin never measures the string.

## The WoW side (Claude)

### `Pins.xml`

`LodestarZoneLabelPinTemplate` is removed. `LodestarThreatPinTemplate` is rebuilt, and `LodestarThreatPinLargeTemplate` added with the same structure and the large numbers. Both use `mixin="LodestarThreatPinMixin"`, `enableMouse="false"`, `virtual="true"`, size 1 x 1. For the small pin (large values in brackets):

| parentKey | Layer | Texture | Placement |
| --- | --- | --- | --- |
| `ShadowDisc` | `BACKGROUND` | `threat-shadow-disc-small` | 64 x 64, `CENTER` on `DiscEdge`, y -1.5 |
| `ShadowTab` | `BACKGROUND` | `threat-shadow-tab-small` | `TOPLEFT` on `TabEdge`'s `TOPLEFT` (-13, 21.5 [14.5]); `BOTTOMRIGHT` on its `BOTTOMRIGHT` (13, -24.5 [-17.5]) |
| `DiscEdge` | `BORDER` | `threat-disc` | 22 x 22 [30], `CENTER` of the pin: the disc sits on the zone's point |
| `TabEdge` | `BORDER` | `threat-tab-small` | `TOPLEFT` on `Range`'s `LEFT` (-6 [-14], 9 [16]); `BOTTOMRIGHT` on `Range`'s `RIGHT` (6 [14], -9 [-16]) |
| `Disc` | `ARTWORK` | `threat-disc` | 18 x 18 [24], `CENTER` on `DiscEdge` |
| `Tab` | `ARTWORK` | `threat-tab-small` | `TOPLEFT` on `TabEdge` (2 [3], -2 [-3]); `BOTTOMRIGHT` on `TabEdge` (-2 [-3], 2 [3]) |
| `Skull` | `OVERLAY` | `threat-skull` | 14 x 14 [20], `CENTER` on `Disc` |
| `Range` (FontString) | `OVERLAY` | font from the table above | `CENTER` on `DiscEdge`'s `BOTTOM`, y -8 [-15] |

How the numbers come out:

- The text is placed first, at the tab's center: the tab's top overlaps the disc by 1 pixel, so its center is `1 - tabHeight / 2` below the disc's bottom.
- The tab edge hangs off the text: half the tab height up and down, and room plus edge width (4 + 2 [11 + 3]) left and right. A wider range widens the tab with no Lua.
- The plate is the edge inset by the edge width on all sides, so the outline is the same as today.
- The tab shadow is 13 pixels (the blur reach) wider than the tab on each side and 64 pixels high, centered on the tab and dropped 1.5 pixels, as the art script's preview composes it.
- The layers move up one step from 5.4 so the shadows can sit underneath: shadows, then edges, then plates, then skull and text.

### Modules

- **`Modules/ThreatOverlay.lua`:** loses the mixin (now in `Pins.lua`). `AcquirePin(TEMPLATE, ns.ThreatPinStyle.small, info.min, info.max, info.labelX, info.labelY)`. Nothing else changes.
- **`Modules/ZoneLabels.lua`:** loses its mixin and the name color. Template `LodestarThreatPinLargeTemplate`; for each child zone with a `min` and a position, `AcquirePin(TEMPLATE, ns.ThreatPinStyle.large, info.min, info.max, x, y)`; the position still comes from `Logic.LabelPosition` (hand-set point, else rectangle center). Adds `PLAYER_LEVEL_UP` like ThreatOverlay (`ns.RegisterEvent` in `OnEnable`, `ns.UnregisterEvent` in `OnDisable`), refreshing only if the map is shown.
- **`.luacheckrc`:** `LodestarZoneLabelPinMixin` leaves `globals`.
- **Design doc:** "Two map sizes", the feature table, the overlay table, ZoneLabels and ThreatOverlay "Look" updated to the pin on both maps (Claude, with this spec).

## Order

1. You: `Logic.FitLevel` and its tests; run `scripts/check.ps1`.
2. You: `Pins.lua` with the mixin. Claude, at the same time: `Pins.xml`, `.toc`, `.luacheckrc`.
3. Claude: the two modules, once the mixin is in (they call your `OnAcquired`).
4. Claude reviews your part and runs the checks; then P58 in game.

## P58: the pins in game

**Restart the client first**: the small and large tab and shadow textures are new files since the last start of 2026-11-09, unless you have restarted since. Other addons off. Level-1 Paladin in Tirisfal Glades.

1. **Small map:** markers on Silverpine, Alterac and Western Plaguelands, each tab showing the range (`8-24`, ...), with round corners at any width, about 4 pixels of room around the text, and a soft shadow under disc and tab.
2. **Fit colors at level 1:** all three red, as in P54 (every zone above you uses its entry level).
3. **Maximized map:** a large pin on every zone with a range on both continents, at its hand-placed point; no names, no old text labels; none on Shen'dralas. Your own zone (Tirisfal `1-14`) is yellow: inside the range.
4. **Overlaps:** on the maximized map, note any pins that touch or cover each other (likely spots: Duskwood and Deadwind Pass, Silverpine and Alterac, the small zones south of Ironforge). Screenshot both continents.
5. **Map size:** maximize and minimize a few times: the sets swap, with no leftovers.
6. **Toggles:** `/ls toggle ZoneLabels` and `/ls toggle ThreatOverlay` each remove only their own pins, then bring them back.
7. **Zoom** on the maximized map: pins grow at most a little (up to 1.2) and stay sharp.
8. **Combat:** a fight with each map size open: no error popup, no "blocked action" message.
9. **Level-up** (also P54 check 9, `notes/todo-p54-pending-checks.md`): with the small map open, at level 4 Silverpine's pin turns orange; on the maximized map Tirisfal stays yellow.

Screenshots of 1, 3 and 4, and any error popup. Claude records P58 and tunes the room and offsets in follow-ups.

## After the step

Look tuning (room around the text, shadow strength, text centering by a pixel) in small follow-ups. Claude deletes `Media/threat-tab.tga` and its entry in the art script once P58 passes. Commits: your code `[T2]`; Claude's XML, wiring and notes `[T4]`, separately.
