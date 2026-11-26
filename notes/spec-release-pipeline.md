# Release pipeline and dev commands — SPEC

| Field | Value |
|-------|-------|
| **Status** | Ready |
| **Date** | 2026-11-26 |
| **Plan** | `notes/plan-release-pipeline.md` |
| **Supersedes** | N/A |

Design doc reference: "Target client and API assumptions" (release scope, revised 2026-11-26), "Commands", "Getting output out of the game", "Project layout" (load order). Probe number reserved: **P63** (the step in game). P61 and P62 stay with step 5.7.

---

## 1. Problem

Shipping a build is a manual chore today: `v0.1.0-test` was zipped by hand from the scratchpad, with a hand-picked file list, a hand-typed version and hand-written release notes. Each release can go wrong in a different way: a missing file, a dev file shipped, the wrong folder name, a stale version. On top of that, a player typing `/ls` sees eight commands: five are development tools (`probe`, `dump`, `place`, `reveal`, `debug`), and two more (`copy`, `log`, whose only operation is `clear`) are developer-facing today but useful to a tester filing a bug. Some of them change saved data (`/ls place clear`) or spoil discovery (`/ls reveal`).

## 2. Goals

1. **Two actions release.** After updating `CHANGELOG.md`, pushing a version tag (`v0.2.0`) produces a GitHub Release with `Lodestar-v0.2.0.zip` attached, with no other manual step.
2. **The zip is right, and a script proves it.** It holds a single `Lodestar/` folder with only the files the game loads, plus `README.md`, `LICENSE` and `CHANGELOG.md`. No `tests/`, `tools/`, `notes/`, `docs/`, `scripts/`, `art/` or editor and lint config. `scripts/check-package.ps1` reports any extra or missing file. Extracting the zip into `AddOns` works (as checked for `v0.1.0-test`).
3. **The version comes from the tag.** The packaged `.toc` says `## Version: v0.2.0`, so the version shows in the AddOns list and in the login line. No version number is edited by hand.
4. **Test builds are marked.** A tag such as `v0.2.0-beta1` produces a GitHub *pre-release*; a plain `v0.2.0` produces a normal release.
5. **Release notes are short and for players.** Each release's notes list only what changed in that release, written for players, from `CHANGELOG.md`. Writing them is the one manual step (I draft, you edit).
6. **Players see player commands only.** In a player build, `/ls` lists only `toggle`, `copy` and `log clear`, and a dev command gets the normal "unknown command" error unless `/ls dev` was typed in this session.
7. **The dev loop is unchanged.** Through the junction, every command still works as today and `scripts/check.ps1` still passes. The login line there reads `Lodestar: @project-version@ loaded (interface 16001), db v1`; the literal token is expected and marks an unpackaged copy.
8. **CurseForge is one step away.** Adding the CurseForge project ID and an API key later is all step 4 needs; nothing here has to be redone.

## 3. Non-Goals

- **Uploading to CurseForge, Wago or WoWInterface:** that's step 4, after the MVP.
- **An options panel:** a v2 task (design doc, Commands).
- **Other clients** (Classic Era, Retail): Forever only (design doc Non-goals).
- **Automatic tagging or version bumps:** you decide when to release.
- **Running the tests in CI:** `scripts/check.ps1` uses Windows binaries in the git-ignored `tools/`. The tests stay a local step before tagging. Running them in CI could be a later, separate change.
- **Removing the dev code from the repo:** the commands stay; only their visibility changes.
- **The `/ls zone` and `/ls overrides` commands** listed in the design doc: they don't exist yet, and this step doesn't add them.

## 4. Design

### Key Decisions

- **The BigWigs packager as a GitHub Action** (`BigWigsMods/packager`), run on every pushed tag starting with `v`. It's the standard tool for WoW addons. It reads a `.pkgmeta` file, puts the files in the `Lodestar/` folder, fills in the version and creates the GitHub Release using the workflow's own `GITHUB_TOKEN`. Later, it can upload to CurseForge with one more key. *Alternative rejected:* a local `scripts/package.ps1` plus `gh release create`. That's simpler, but every release stays manual, and CurseForge would need the packager anyway.
- **`.pkgmeta` lists what to leave out.** Everything not loaded by the game is excluded by name: `tests`, `tools`, `notes`, `docs`, `scripts`, `screenshots`, `art`, `CLAUDE.md`, plus the dotfiles and dot-folders (`.zed`, `.github`, `.luacheckrc`, `.luarc.json`, `.editorconfig`, `.gitignore`). `Media`, `README.md`, `LICENSE` and `CHANGELOG.md` stay in. *Assumption, checked in the dry run:* the packager also drops dot-entries on its own, and in CI the git-ignored folders (`tools`, `screenshots`) don't exist because the workflow starts from a fresh clone. They're listed anyway, because a local packager run works from the working folder, where they do exist. A denylist lets a new file ship unnoticed, so the next two decisions back it up. *Alternative rejected:* listing what to include, which the packager doesn't support well.
- **`scripts/check-package.ps1` checks contents against what the game loads** (decided 2026-11-26). Given a zip or a built `Lodestar/` folder, it works out the expected set from the package itself:
  - the `.toc` and every file it lists;
  - every `Media` file named by an `Interface\AddOns\Lodestar\Media\…` path in the packaged `.lua` and `.xml` files;
  - `README.md`, `LICENSE` and `CHANGELOG.md`.

  It fails on any **extra** file (a dev file, an unused texture, traced art) and any **missing** one (a listed or referenced file that was excluded). It runs on the local dry run, on each released zip, and in the release steps. In CI, the release is already published when the check runs, so a failure means deleting it (`gh release delete <tag> --cleanup-tag`) and fixing the problem. *Alternative rejected:* checking inside the workflow before publishing, which needs the packager split into a build step and an upload step; not worth it at this size.
- **`Media/` holds only files the game loads** (decided 2026-11-26). Working art (sources, sketches, the traced masks of step 5.2, which derive from Blizzard's art) lives in a git-ignored top-level `art/` folder, which is also on the `.pkgmeta` ignore list. `Media/traced/` moved to `art/traced/` the same day. With this rule, the check's "extra file" result means a real mistake, not noise.
- **The `.toc` version becomes `@project-version@`,** which the packager replaces with the tag. Through the junction, the dev copy shows the literal `@project-version@`, which also makes it easy to tell a dev copy from a player build.
- **Pre-releases are told apart by the tag name.** The packager treats a tag containing `alpha` or `beta` as a test release and marks the GitHub Release as a pre-release. So test tags are `v0.2.0-beta1`, not `-test` (`v0.1.0-test` was published by hand).
- **Dry run before the first tag, in two stages.**
  1. **Local:** run the packager script in Git Bash with uploads skipped. It builds the zip in a scratch folder, so the zip's contents and the handling of interface 16001 are checked without publishing anything.
  2. **Real:** push the first `-beta` tag, which is a pre-release meant for testers anyway. This checks the pre-release flag and the attached notes.
  - *Fallbacks:* if the release isn't marked as a pre-release, fix it with `gh release edit <tag> --prerelease` and set the release type through the workflow's packager options. If the packager fails on interface 16001, the step falls back to a local `scripts/package.ps1` that builds the zip as `v0.1.0-test` was built, plus `gh release create`, until the packager can be configured or patched. Either fallback keeps GitHub Releases working, and step 4 would have to solve the same problem.
- **Release notes come from a hand-written `CHANGELOG.md`** (decided 2026-11-26), short and written for players. It holds **only the current release's entry**: before each tag it's rewritten with the new release's changes, and the history lives in the GitHub Releases pages. The packager attaches the whole file through `manual-changelog` in `.pkgmeta`, so a single entry means each release's notes show just that release. I draft each entry from the commits and you edit it. *Alternatives rejected:* a running changelog, whose every past entry would be repeated in each release's notes; and notes generated from commit subjects, which read like `[T4] docs(env): …`.
- **Each command gets an access level when it's registered** (`ns.RegisterCommand(name, handler, usage, access)`). The `/ls` list and the dispatcher check it against one switch, so the choice lives in one place instead of eight `if` statements. There are three levels (added in the plan, 2026-11-26):
  - `"player"`: listed and runs in every build.
  - `"dev"`: listed and runs only in dev mode.
  - `"hidden"`: runs in every build, listed only in dev mode. Only `/ls dev` uses it.

  A missing access level counts as `"dev"`, so a command nobody marked can never reach players.
- **Dev mode has two sources** (decided 2026-11-26). A packager comment block (`--@debug@ … --@end-debug@`) turns it on in the unpackaged copy, so through the junction every command works with no setup; the packager comments that block out in releases. In a player build, `/ls dev` turns dev mode on for the session only, not saved, so a tester can run `/ls probe` when asked while chasing a bug. `/ls dev` is itself a player command, but it isn't shown in the `/ls` list; the README's bug-report section mentions it. *Alternatives rejected:* a runtime switch only (your copy would need `/ls dev` after every fresh SavedVariables), or build-time only (testers could never help debug).
- **Player commands** (decided 2026-11-26): `toggle`, `copy` and `log`; `clear` is `log`'s only operation, so marking the whole command is enough. The last two let a tester copy a caught error or the last output into a bug report. Dev commands: `probe`, `dump`, `place`, `reveal`, `debug`.
- **`/ls dev` toggles** (decided 2026-11-26), like `/ls debug`. It prints `dev mode on until /reload; type /ls for all commands`, or `dev mode off` when typed again. While dev mode is on, the `/ls` list shows every command, dev ones included, so a tester sees what they're asked to run. In the unpackaged copy it can turn dev mode off for the session too, which is a quick way to see the player view without packaging; `/reload` brings it back.
- **A dev command outside dev mode** gets the same "unknown command, type /ls for help" error as a typo. It stays hidden from players, and testers learn about `/ls dev` from the README or from you. *Alternative rejected:* a separate "dev command, type /ls dev" message, which would advertise the dev commands to every player who mistypes.
- **Login line** (decided 2026-11-26): players see `Lodestar: v0.2.0 loaded`. The `Lodestar:` part is the prefix `ns.Print` already adds, so the code passes only `"<version> loaded"`. In dev mode, `(interface <n>), db v<n>` is appended as today.
- **Logic stays testable.** Deciding which commands are visible is a pure function in `Logic.lua` that takes the dev-mode state as an argument. Its unit tests cover **both** modes: in player mode, only player commands are visible and runnable; in dev mode, all of them are. You write it and its tests; I write the wiring, `.pkgmeta` and the workflow (the same split as earlier steps). *Gap accepted:* `scripts/check.ps1` runs the unpackaged code, where dev mode is always on, so the dispatcher's player-mode path is only checked in game (P63 steps 3-4).

### How It Fits Existing Systems

- **Command registry** (`Core.lua`: `ns.RegisterCommand`, `ns.RunCommand`): gains the access level. The `/ls` help list and the "unknown command" path use the visibility check.
- **Command owners:** `Debug.lua` (`log`, `copy`, `probe`, `dump`), `Place.lua` (`place`), `Modules/Instances.lua` (`reveal`) and `Options.lua` (`toggle`, `debug`, and the new `dev`) mark their commands as decided above.
- **`ns.debug`** (verbose logging, toggled by `/ls debug`) is a different switch: it controls chat noise, not which commands exist. It stays separate, and `/ls debug` becomes a dev command.
- **Login line** (`Core.lua`, `OnLogin`): reads the version from the `.toc`, and adds the interface and db version in dev mode. Reading `.toc` metadata needs an API that isn't in `notes/beta-probes.md` yet (`C_AddOns.GetAddOnMetadata` or the older `GetAddOnMetadata`), so P63 starts by probing which one exists.
- **`ns.Emit`, `ns.Record` and `ns.SafeCall`** (`Util.lua`) keep logging caught errors to `LodestarDB.log` in every build. A player's error report depends on them.
- **`.toc`:** `## Version` becomes the packager token; the file list is unchanged. Later, `## X-Curse-Project-ID` is added in step 4.
- **README:** the Install section already points to Releases. The Commands section lists `toggle`, `copy` and `log clear`, the bug-report section mentions `/ls dev` and `/ls copy`, and the zip name becomes `Lodestar-<tag>.zip`.
- **`CHANGELOG.md`:** new, in the repo root, shipped in the zip.
- **`.gitignore` and `scripts/trace_masks.py`:** `Media/traced/` becomes `art/traced/` (the folder had no local files on 2026-11-26, so only the ignore rule and the script's doc line change).
- **`notes/environment.md`:** "Testing a release zip" covers checking a packaged build on your machine without breaking the junction.
- **`.luacheckrc`:** whichever metadata API P63 step 1 confirms (`C_AddOns` or `GetAddOnMetadata`) is added to `read_globals` with a `-- P63` comment. No new writable globals.

### P63: the step in game (after the code)

Filled in with the plan. It will cover, in this order:
1. **Before any code:** which add-on metadata API exists (`C_AddOns.GetAddOnMetadata` or `GetAddOnMetadata`), for the version in the login line.
2. **The zip's contents** (from the local dry run, and again from the release): `scripts/check-package.ps1` passes, meaning exactly the `.toc`, the files it lists, the referenced `Media` files, `README.md`, `LICENSE` and `CHANGELOG.md`, all inside `Lodestar/`. Nothing else.
3. **A pre-release built from a `-beta` tag,** extracted using the "Testing a release zip" steps: it loads with the tag's version in the AddOns list and the login line (`Lodestar: v0.2.0-beta1 loaded`), and the GitHub Release is marked as a pre-release with `CHANGELOG.md`'s single entry as its notes.
4. `/ls` lists `toggle`, `copy` and `log clear` only, and a dev command gets the "unknown command" error.
5. `/ls dev` prints `dev mode on until /reload; type /ls for all commands`, after which `/ls` lists every command and the dev ones run. A second `/ls dev` prints `dev mode off`, and the player view is back. `/ls dev` followed by `/reload` also ends in the player view.
6. **Back on the junction:** every command works without `/ls dev`, and the login line reads `Lodestar: @project-version@ loaded (interface 16001), db v1`.

## 5. Open Questions

- [x] **1. How dev commands get turned on.** Both: build-time in the junction copy, `/ls dev` for the session in player builds (2026-11-26, see Key Decisions).
- [x] **2. Which commands players see.** `toggle`, `copy`, `log clear` (2026-11-26).
- [x] **3. Release notes.** A hand-written `CHANGELOG.md` (2026-11-26).
- [x] **4. The login line.** Name and version for players; interface and db version added in dev mode (2026-11-26).
- [ ] **5. Forever and the packager.** Forever's interface number (16001) is new. Does the packager handle it, or does it fail or mislabel the game version in its `release.json` (the file WowUp reads)? Answered by the local dry run; the fallback if it fails is under "Dry run" in Key Decisions.
- [x] **6. `/ls dev` behavior.** It toggles, prints its state with a hint, and the `/ls` list shows every command while it's on (2026-11-26, see Key Decisions).
