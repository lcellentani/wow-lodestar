# Label style exploration (maximized map), 2026-11-08

Status: restarted 2026-11-09 from the small-map marker style (see "Restart"); the first pass below is history.
Design doc reference: "Two map sizes, two questions" (Feature set), "ZoneLabels" (Module specs). The doc says only "label style iterates on the live client"; this was the first pass.

## Starting point

The maximized map shows every zone's name above its range, both in the outlined 12 pt game font (`GameFontHighlightOutline`), the range's ends colored by `GetQuestDifficultyColor`, at the hand-placed `labelX, labelY` (step 5.3). Screenshots 163010 (Eastern Kingdoms) and 165527 (Kalimdor) show it. Problems seen there:

- **Readability:** dark reds (`55-60`, `53-63`) sink into the orange-brown parchment (Moonglade, Winterspring, Silithus).
- **Hierarchy:** name and range have the same weight, so the map reads as a wall of text instead of answering "where fits me".
- **Collisions:** Duskwood and Deadwind Pass, Silverpine Forest and Alterac Mountains.

## The mockup

https://claude.ai/artifact/6nZRjNMAnem8zdt3qQvUCZ (private). Eastern Kingdoms small-map screenshot from the threat-marker mockup, labels at the hand-placed points, text at its in-game size relative to the map ("Actual size" view), level slider with Forever's colors (yellow down to 4 below, P35). "Fits" in the mockup: entry level not red and top level not grey (a mockup rule, not decided).

## What was tried, and the verdicts

| Style | Idea | Verdict |
| --- | --- | --- |
| L0 Today | name over range, outlined | reference |
| L1 Range plate | range on a dark plate, like the marker tabs | not chosen |
| **L2 Range first** | larger range, smaller dimmer name below | **preferred direction** (user, 2026-11-08) |
| L3 Fit focus | zones that don't fit fade back (`SetAlpha`) | became a checkbox for any style; not judged on its own |
| L4 One line | name and range on one line on a plate | **rejected**: hard to make work everywhere (wide plates collide sideways in the south) |
| L5 Plate and focus | L1 + L3 | not chosen |
| L6 Bordered plate | range first on a dark plate with a thin warm border | none of L6-L10 chosen |
| L7 Bordered card | range and name in one bordered card | |
| L8 Gradient border | L6 with the border fading from entry color to top color | |
| L9 Threat ribbon | outlined range over a thin bar fading entry to top color | |
| L10 Blended digits | each character colored a step between the two ends | |
| G1-G4 Gradient host | ribbon, pointed plate, cut corners, scroll; the shape's fill runs entry to top color, neutral digits | **rejected** |
| M1-M3 Medieval stack | range plate over name plate (like the marker's disc and tab); gradient frame, dark field; cut corners, side pins, horns, shield point; long names wrapped to two lines | **rejected**: "none of those work well" |

The M-series was inspired by a reference sheet of game badges (screenshot 155955, lower-left: a gold shield frame, dark field, horn points, side pins). The two-element stack and the two-line names came from the user; the shapes did not land.

## The user's notes for next time (2026-11-08)

1. **No gradient in the background of the information**: too invasive, it hurts readability.
2. **A dedicated element for the color range**: for example a disc split in two halves, each half showing one end's color (min, max).
3. **Keep the information clean and readable.**
4. **No gradient on borders.**
5. **Borders must be thin**: next to font text, thick borders look bad; a 2-pixel border may work, or something else entirely.

Still standing from the session: range first (L2) reads best; one-line labels are out; two lines for long names is a useful tool.

## Constraints learned (evidence)

- The game cannot fill text with a gradient: a FontString has one color. Per-character color codes give steps (L10), not a gradient.
- A texture gradient (`Texture:SetGradient`) is **not probed** on Forever. Only needed if a gradient comes back, which notes 1 and 4 rule out for now.
- A font larger than 12 pt is **not probed**. Range first needs one (for example `GameFontHighlightLarge`); probe it like P55 before coding.
- P55: `GameFontHighlightSmallOutline` is 10 pt with **no** outline on Forever; `GameFontHighlightOutline` and `NumberFontNormalSmall` are 12 pt `OUTLINE`; `GameFontHighlightSmall` and `SystemFont_Shadow_Small` are 10 pt.
- Thin borders work as on the threat markers: a tinted shape behind a dark copy 2 pixels smaller (P54 tuning). Addon textures tint with `SetVertexColor` (P46); a changed texture reloads on `/reload`, a new file needs a client restart.
- Fading a label is `SetAlpha` on the pin, no probe.

## Restart, 2026-11-09: follow the small-map marker

The user scrapped every style above (L0-L10, G, M): none of them work. The maximized map follows the threat-marker style instead (`Pins.xml` `LodestarThreatPinTemplate`, `notes/spec-5.4-threat-markers.md`).

The marker style as rules:

1. Information sits on dark plates (`0.1, 0.08, 0.05`, opaque), not on bare parchment.
2. Threat color goes on outlines and symbols only, never on fills behind text, never on text.
3. Outline: a solid 2-pixel ring, the colored shape 2 px larger each way behind the plate. One flat color, no gradient.
4. Simple crisp shapes: a disc and a rounded rectangle (three textures).
5. Neutral white text, 10 pt (`GameFontHighlightSmallOutline`, which has no outline on Forever, P55).
6. About 3 px of margin around text.
7. A symbol over a value: disc on top, tab below, 1 px overlap.
8. Small: about 22 px wide, scaling `1.0-1.2`.

Decided (user, 2026-11-09):

- **Base shape:** the marker's disc over a tab, plus the zone name under it.
- **Disc:** a split fill, the left half the entry color and the right half the top color; the 2 px edge is a fixed neutral (dark or warm, to judge); no skull. A deliberate exception to rule 2: the disc is the dedicated color element (note 2), so the numbers stay neutral.
- **Tab:** dark plate with a threat-neutral edge, the range in white.
- **Name:** 10 pt light text directly on the parchment (an exception to rule 1, to keep the map uncluttered); long names wrap to two lines.

Open:

- The edge color for the disc and tab (dark plate color or a fixed warm tone).
- An outlined 10 pt font is not confirmed: P55 found `GameFontHighlightSmallOutline` has no outline. Probe another font object, or accept 12 pt `GameFontHighlightOutline` for the name.
- Split-disc art: two half-disc textures, or one disc texture plus a half-disc. New files need a client restart (P46).
- Fit focus (`SetAlpha` on zones that don't fit) stays available as an option.

Second pass, 2026-11-09 (user feedback on the first marker-style mockup):

- **Edge: warm bronze** (decided): it reads less heavy than black.
- The disc should become shield art; the range should be bigger than the name, above 12 pt; the black plate is heavy ("a punch in the face"), and the user feels the same about the small-map markers' dark disc and tab.
- In the mockup now: shields S1 heater, S2 round-bottom, S3 kite (S0 disc for reference), split per pale (entry left, top right), drawn over the range plate's top edge; range backings B1 no plate (outlined digits), B2 see-through dark plate, B3 bronze plate, B4 vellum plate with dark digits (B0 dark for reference); range 12, 14 or 16 pt.
- Needed in game whatever wins: a range font above 12 pt (probe; outlined for B1/B2, plain for B3/B4), shield textures from the art script (client restart), and for B2 a probe of texture alpha. Whatever backing wins may go back to the small-map markers.

## Ideas to pick up

- Note 2 as a concrete element: a small split disc (left half entry color, right half top color) next to or above the range, so the numbers can stay one calm neutral or light color. The threat-marker disc texture and a half-disc mask, or two half-disc textures, would do it; no gradient.
- The marker look on the small map (dark plate, 2-pixel threat outline, 10 pt number) is liked; whatever the maximized map gets should feel related.
- Collisions are still open; smaller names (10 pt) and two-line wrapping both help.
