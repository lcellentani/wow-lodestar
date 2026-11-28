# wow-lodestar
Lodestar is a World of Warcraft: Forever addon that puts level, faction and instance information on the world map. The name refers to a guiding star: it points to where to go at the player's level. It is inspired by the zone-level display of the old Cartographer addon; matching Cartographer's full feature set is not a requirement.

It is a hobby project, made for fun. It targets the English Forever client and works best as the only map addon.

## What it shows

- **Zone levels.** On a maximized continent map, each zone gets a marker with its level range, colored by how well it fits your level (the same colors as quest difficulty).
- **Neighboring zones.** On the small map, the zones next to yours get a marker with their level range.
- **Instance entrances.** Dungeon and raid entrances you have discovered appear on the zone and continent maps; hover one for its name, kind and level range.

## Install

1. Download the latest `Lodestar-<tag>.zip` (for example `Lodestar-v0.2.0.zip`) from the [Releases](https://github.com/lcellentani/wow-lodestar/releases) page. Releases marked **Pre-release** (tags ending in `-beta1`, `-beta2`, ...) are test builds.
2. Extract it into your Forever addon folder, so that you get
   `<WoW folder>\_forever_\Interface\AddOns\Lodestar\Lodestar.toc`.
3. Start the game (or restart it if it was running) and check that **Lodestar** is ticked in the character screen's **AddOns** list.

The folder must be named exactly `Lodestar`. If you use GitHub's "Download ZIP" button instead of a release, the folder comes out as `wow-lodestar-main`: rename it to `Lodestar` and it works too, though it also holds development files the game ignores.

To update, delete the old `Lodestar` folder and extract the new zip. Settings are kept: they live in `WTF`, not in the addon folder.

## Commands

Type `/ls` (or `/lodestar`) in chat for the list of commands. The ones for players:

- `/ls toggle <module>` turns a module on or off: `ZoneLabels`, `ThreatOverlay`, `Instances`.
- `/ls copy` shows Lodestar's last chat output (or the last error it caught) in a box, selected so you can copy it with Ctrl+C.
- `/ls log clear` empties the output log Lodestar saves between sessions.

## Feedback and bugs

Open an issue on [GitHub Issues](https://github.com/lcellentani/wow-lodestar/issues). For a bug, say what you did, what you expected and what happened; a screenshot helps. Lua errors show up with `/console scriptErrors 1`.

When Lodestar reports an error in chat, type `/ls copy` right after it and paste the text into the issue. If I ask for more details, `/ls dev` turns on the development commands until your next `/reload`; type it again to turn them off.

## License

MIT, see `LICENSE`. All art in `Media/` is original.
