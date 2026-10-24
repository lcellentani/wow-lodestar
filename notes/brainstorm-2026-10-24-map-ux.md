# Brainstorm 2026-10-24: what the map should tell the player

A brainstorm between the beta (closed 2026-10-21) and the live client (2026-11-04). The beta experiments started from layout (ranges on the small map, names and ranges on the maximized map); this session started from what the player needs to know. Decisions that change the addon are copied into the design doc; this note keeps the reasoning.

## Why the map gets opened

Three decisions, in the user's words from beta play:

1. **Where do I level next?** See at a glance which zones fit the current level.
2. **Where must I not go?** In the beta the user walked into a zone far above their level while passing through and died almost at once.
3. **How do I reach a dungeon?** Meeting stones matter, and the map did not say which zone a dungeon is in, or what lies on the way.

Also: on the beta's continent map, hovering a zone gave nothing beyond Blizzard's one-line name label (P7). Vanilla 1.12 and WoW Classic show no level ranges on the map either; players used addons (Cartographer, later Leatrix Maps, Atlas).

## Principles

- **Danger is graded, not forbidden.** Passing through a zone slightly above your level is fine if you know it: at level 18 the user crossed a 19-27 zone on the way to Dalaran by keeping to the road. The addon's job is awareness before the border, not avoidance.
- **No GPS (anti-goal).** Vanilla was about the journey. Lodestar gives the facts a well-informed guildmate would have told you in 2004 ("Wetlands is 20-30, careful at 18; the Deadmines are in Westfall"), never routes, paths, boat connections or travel instructions. A version that works but turns the journey into following directions has failed.
- **Facts are earned by discovery, like flight paths.** Information about places appears once the character has been there; safety information (zone ranges) is known from the start.
- **Behavior before presentation.** What Lodestar knows and when it reveals it is decided separately from how it looks.

## Behaviors decided

| What the character has done | What Lodestar reveals |
| --- | --- |
| Nothing yet | Every zone's level range on the continent maps (always on) |
| Entered a zone | The zone's dungeons and raids: name and level range, no location |
| Explored the sub-area holding an entrance (the game's fog of war lifted there) | That entrance's marker (meeting stone) on the map |

- **Threat measure:** the game's quest-difficulty scale (`Logic.ColorCode`, P35). Revisit if the live client exposes its own zone difficulty through an API.
- **Neighbor** means two zones share a border on the map, whether or not the border can be walked across. "Walkable from here" was rejected: it would give away where the passes are.
- Why name and level range rather than a count: a count makes you curious but gives you nothing to plan with; name plus range is what a guildmate would say, and the entrance is still yours to find.

## Presentation idea: neighbor threat overlay

On the continent map (the user described the small map), the zones bordering the player's current zone get a colored overlay in their threat color. The player's arrow is Blizzard's own. Hovering a zone opens the zone tooltip for details. It answers "what can I step into from here?" without a route.

Drawing the overlay, best first:

1. **Blizzard's zone highlight art** (Forever's continent map lights up the hovered zone in its real shape, P7), fetched for any zone and tinted. Mainline gets that art through an API that takes a map and a point; whether Forever exposes it, and whether the `MOD` (multiply) blend mode works, is unprobed.
2. **Custom masks from grid sampling.** A one-off probe asks `C_Map.GetMapInfoAtPosition` (confirmed, P7) which zone owns each cell of a grid over each continent and saves it to SavedVariables. A script outside the game turns the grid into one smoothed white mask per zone, cropped to the zone's rectangle (`GetMapRectOnMap`, P5). In game the mask is tinted with `SetVertexColor`, so one file serves every color. Pure API data, so it stays within the repo's "facts only" rule.
3. **Screenshots** as the backup for tier 2: a screenshot of the continent with no hover and one with each zone hovered; the difference is the zone's shape. Traced from Blizzard's art, so it sits in a grey area under the "no copied Blizzard material" rule.
4. Rejected: a soft circle at the label point. It fits long zones (Wetlands, Silverpine) badly and spills over borders.

The grid also gives a cross-check for the hand-written neighbor list: two zones are neighbors if their cells touch.

## Parked: observe on live

In the beta the user was optimizing to reach test spots, not playing, so these wait for a couple of weeks of normal play:

- **Connection points between zones** (passes, tunnels, bridges). They are facts about places, so not against the no-GPS rule, but the explored map art already shows most passes, and there is no data source (each would be measured by hand, as the meeting stones were in P12).
- **What orientation information is actually missing** when the map is opened. Note each time the map fails to answer a question.

## Follow-up: two map sizes, two questions

After the first write-up, "Best zone for your level" turned out to be the **global** question ("anywhere on this continent, which zones fit me?"), while the neighbor overlay answers the **local** one ("from here, what is next door, and is it OK?"). At 30 in Stranglethorn the best next zone may be Arathi, far from any border you touch. Decided:

1. **Small map:** neighbor overlay only, no text labels. In the beta the labels could not be kept from spilling over small zones; color fills the zone's own shape and cannot. The current labels stay until the overlay works on live, so the small map is never empty.
2. **Maximized map:** overlay on every zone, names and ranges on top. The overlay carries one color (the zone's minimum); the labels keep both colored ends (Redridge at 21: green 15, orange 25).
3. **The overlay becomes MVP** (it was v2), so M5 depends on zone shapes: Blizzard's art if the live probe allows, otherwise grid masks.
4. **Label anchors from the grid:** the point deepest inside each zone's shape replaces the rectangle center, with hand-set `labelX, labelY` as the override. This replaces the earlier plan of automatic collision handling. The grid probe runs once even if Blizzard's art is used, for the anchors alone.
5. **"Best zone for your level" is dropped:** the maximized overlay is that answer.

## Closed: the caveat on the reveal table

The user's caveat on the first row ("every zone's level range, always on") was about text labels on every zone of the small map. It is resolved by the split above: the small map shows no text labels, only the neighbor overlay, and the ranges stay always known through the maximized map and the tooltip.
