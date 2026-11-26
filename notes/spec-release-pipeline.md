# Release pipeline and dev commands — SPEC

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Date** | 2026-11-26 |
| **Plan** | Not yet planned |
| **Supersedes** | N/A |

Design doc reference: "Target client and API assumptions" (release scope, revised 2026-11-26), "Commands", "Getting output out of the game", "Project layout" (load order). Probe number reserved: **P63** (the step in game). P61 and P62 stay with step 5.7.

---

## 1. Problem

Shipping a build is a manual chore today: `v0.1.0-test` was zipped by hand from the scratchpad, with a hand-picked file list, a hand-typed version and hand-written release notes. Each release can go wrong in a different way: a missing file, a dev file shipped, the wrong folder name, a stale version. On top of that, a player typing `/ls` sees eight commands, and seven of them (`probe`, `dump`, `place`, `reveal`, `log`, `copy`, `debug`) are development tools. Some of them change saved data (`/ls place clear`) or spoil discovery (`/ls reveal`).

## 2. Goals

1. **One action releases.** Pushing a version tag (`v0.2.0`) produces a GitHub Release with `Lodestar-v0.2.0.zip` attached, without any other manual step.
2. **The zip is right.** It holds a single `Lodestar/` folder with only the files the game loads, plus `README.md` and `LICENSE`. No `tests/`, `tools/`, `notes/`, `docs/`, `scripts/` or editor and lint config. Extracting it into `AddOns` works (as checked for `v0.1.0-test`).
3. **The version comes from the tag.** The packaged `.toc` says `## Version: v0.2.0`, so the version shows in the AddOns list and in the login line. No version number is edited by hand.
4. **Test builds are marked.** A tag such as `v0.2.0-beta1` produces a GitHub *pre-release*; a plain `v0.2.0` produces a normal release.
5. **Release notes are written without extra work.** Each release gets notes listing what changed since the previous tag.
6. **Players see player commands only.** In a player build, `/ls` lists only player commands (today just `toggle`), and the dev commands are not run.
7. **The dev loop is unchanged.** Through the junction, every command still works as today and `scripts/check.ps1` still passes.
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
- **`.pkgmeta` lists what to leave out.** Everything not loaded by the game is excluded by name: `tests`, `tools`, `notes`, `docs`, `scripts`, `.zed`, `.luacheckrc`, `.luarc.json`, `.editorconfig`, `CLAUDE.md`. `README.md` and `LICENSE` stay in. *Alternative rejected:* listing what to include, which the packager doesn't support well.
- **The `.toc` version becomes `@project-version@`,** which the packager replaces with the tag. Through the junction, the dev copy shows the literal `@project-version@`, which also makes it easy to tell a dev copy from a player build.
- **Pre-releases are told apart by the tag name.** The packager treats a tag containing `alpha` or `beta` as a test release and marks the GitHub Release as a pre-release. So test tags are `v0.2.0-beta1`, not `-test` (`v0.1.0-test` was published by hand). *To confirm in the first dry run.*
- **Release notes are generated from commit subjects.** The packager writes a changelog from the commits between two tags. *Alternative:* a hand-written `CHANGELOG.md` (see Open question 3).
- **Each command is marked as player or dev when it's registered** (`ns.RegisterCommand` gets a marker). The `/ls` list and the dispatcher check it against one switch, so the choice lives in one place instead of eight `if` statements. Which switch is used is Open question 1.
- **Logic stays testable.** Deciding which commands are visible is a pure function in `Logic.lua` with unit tests, as `ParseCommand` and `FindName` are today. You write it and its tests; I write the wiring, `.pkgmeta` and the workflow (the same split as earlier steps).

### How It Fits Existing Systems

- **Command registry** (`Core.lua`: `ns.RegisterCommand`, `ns.RunCommand`): gains the player/dev marker. The `/ls` help list and the "unknown command" path use the visibility check.
- **Command owners:** `Debug.lua` (`log`, `copy`, `probe`, `dump`), `Place.lua` (`place`), `Modules/Instances.lua` (`reveal`) and `Options.lua` (`toggle`, `debug`) mark their commands. Only `toggle` is a player command for certain; the others are Open question 2.
- **`ns.debug`** (verbose logging, toggled by `/ls debug`) is a different switch: it controls chat noise, not which commands exist. It stays separate. Whether `/ls debug` itself stays available to players is part of Open question 2.
- **`ns.Emit`, `ns.Record` and `ns.SafeCall`** (`Util.lua`) keep logging caught errors to `LodestarDB.log` in every build. A player's error report depends on them.
- **`.toc`:** `## Version` becomes the packager token; the file list is unchanged. Later, `## X-Curse-Project-ID` is added in step 4.
- **README:** the Install section already points to Releases. The Commands section changes to match Open question 2, and the zip name becomes `Lodestar-<tag>.zip`.
- **`notes/environment.md`:** "Testing a release zip" covers checking a packaged build on your machine without breaking the junction.
- **`.luacheckrc`:** no new globals expected.

### P63: the step in game (after the code)

Filled in with the plan. It will cover: a pre-release built from a `-beta` tag, extracted using the "Testing a release zip" steps, loads with the tag's version in the AddOns list and the login line. `/ls` lists player commands only, a dev command is refused, and whatever Open question 1 picks for turning dev commands on works. Then, back on the junction, every dev command works as before.

## 5. Open Questions

- [ ] **1. How dev commands get turned on.** Recommendation: **(c)**.
  - (a) **Runtime switch only:** `/ls dev` turns dev mode on or off and is saved in `LodestarDB`. The same build behaves the same everywhere. Your dev copy needs `/ls dev` once, and a curious player can find it.
  - (b) **Build-time only:** a packager comment block (`--@debug@ … --@end-debug@`) sets dev mode in the unpackaged copy, and the packager comments it out in releases. No switch to remember, but a tester can never turn the commands on.
  - (c) **Both:** dev mode is always on through the junction (build-time). In player builds it's off, but `/ls dev` turns it on for the session, so a tester can run `/ls copy` or `/ls probe` when you ask them to while chasing a bug.
- [ ] **2. Which commands players see.** `toggle` for certain. What about `copy` and `log clear` (useful for bug reports), `debug` (verbose logging), and `reveal` (it spoils discovery, but a tester might want it)? `probe`, `dump` and `place` look dev-only.
- [ ] **3. Release notes.** Generated from commit subjects (no effort, but they read like `[T4] docs(env): …`), or a short hand-written `CHANGELOG.md` updated before each tag, which the packager attaches instead?
- [ ] **4. The login line.** Players see `Lodestar: loaded (interface 16001), db v1` at every login. Keep it, show it in dev mode only, or shorten it to name and version?
- [ ] **5. Forever and the packager.** Forever's interface number (16001) is new. Does the packager handle it, or does it fail or mislabel the game version in its `release.json` (the file WowUp reads)? Checked in the first dry run on a `-beta` tag. A blocker here would only matter for step 4 (CurseForge) and WowUp, not for GitHub Releases.
