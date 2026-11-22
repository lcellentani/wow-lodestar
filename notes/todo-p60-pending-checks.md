# To do: P60 pending checks

Written 2026-11-22. P60 checks 1-8 passed (`notes/beta-probes.md`); these are left, to do in play. Full checklist in `notes/spec-5.6-instances.md`.

## [ ] Check 9: entrances that look wrong

The vanilla entrances in `Data/Instances.lua` are approximate (Claude's recall of Classic data). When a character reaches one, open its zone map with `/ls reveal` on and compare the marker with the door. For a marker clearly off, either note where the door is ("Uldaman: at the north edge, marker in the middle") or stand at the door and run `/ls probe here`; Claude reads the position from the SavedVariables file and fixes the row.

Still to check:

- Eastern Kingdoms: Shadowfang Keep, Gnomeregan, Scarlet Monastery, Uldaman, Sunken Temple, Blackrock Mountain, Scholomance, Stratholme (both gates), Naxxramas, Zul'Gurub.
- Kalimdor: Wailing Caverns, Razorfen Kraul, Razorfen Downs, Blackfathom Deeps, Zul'Farrak, Maraudon, Dire Maul, Onyxia's Lair, Ruins and Temple of Ahn'Qiraj.

Measured already (meeting stones, P12): The Deadmines, The Stockade, Ragefire Chasm and the Forever dungeons with a position.

## [ ] Check 5, second half: a city's entrance for a character who never entered its zone

With reveal off, a character who has never been in Durotar (or Elwynn Forest, Dun Morogh, Tirisfal Glades) sees no marker for Ragefire Chasm (or the Stockade, Hall of Thanes, Ruins of Lordaeron) on the city map or the continent. A new character on the other faction is the easy case.

## After

Report what you saw; Claude records it under P60 in `notes/beta-probes.md` and deletes this file once nothing is left.
