# Label style exploration (maximized map), 2026-11-08

Status: paused by the user to think; resume in a new conversation. Nothing here is decided except where marked.
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

## Ideas to pick up

- Note 2 as a concrete element: a small split disc (left half entry color, right half top color) next to or above the range, so the numbers can stay one calm neutral or light color. The threat-marker disc texture and a half-disc mask, or two half-disc textures, would do it; no gradient.
- The marker look on the small map (dark plate, 2-pixel threat outline, 10 pt number) is liked; whatever the maximized map gets should feel related.
- Collisions are still open; smaller names (10 pt) and two-line wrapping both help.
