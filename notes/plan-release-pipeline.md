# Release pipeline and dev commands — Implementation Plan

| Field | Value |
|-------|-------|
| **Spec** | `notes/spec-release-pipeline.md` |
| **Date** | 2026-11-26 |
| **Status** | Not Started |
| **Effort** | 2 sessions (one for the probe and your Logic code, one for wiring, packaging and the first beta) |

---

## 1. Overview

### Goal

After updating `CHANGELOG.md`, pushing a `v*` tag produces a GitHub Release with a correct `Lodestar-<tag>.zip`, the version taken from the tag, and `-beta` tags marked as pre-releases. Release builds list and run only `toggle`, `copy` and `log`, with `/ls dev` as an unlisted switch to turn on the rest, while the junction copy keeps every command working (spec Goals 1-8).

### Approach

- **Commands get an access level when registered:** `"player"`, `"dev"` or `"hidden"` (runs in every build but isn't listed: `/ls dev`). A missing access level counts as `"dev"`, so a command nobody marked stays out of players' sight (safe default).
- **Two pure functions** in `Logic.lua` decide whether a command runs and whether it's listed, given its access level and the dev-mode state. `Core.lua` uses them in both the `/ls` list and the dispatcher, so the rule lives in one place.
- **Dev mode:**
  - `ns.devMode` starts as `true` inside a `--@debug@` block in `Core.lua`, so the junction copy has it on with no setup. In a release, the packager turns that block into a comment, so it starts off.
  - `/ls dev` flips it for the session. It isn't saved to `LodestarDB`.
- **Packaging:** the BigWigs packager runs as a GitHub Action on `v*` tags, configured by `.pkgmeta` (exclusion list plus `manual-changelog`). The `.toc` gets `## Version: @project-version@`, and `CHANGELOG.md` holds only the current release's entry.
- **Reuse:**
  - `Logic.ParseCommand` and the existing `commands` table in `Core.lua`.
  - The "unknown command" error path, unchanged, for refused dev commands.
  - `ns.Print` for every message.
  - The "Testing a release zip" steps in `notes/environment.md` for P63.

### Scope

**In Scope:**
- the P63 probe for the add-on metadata API;
- the two `Logic.lua` functions and their tests;
- access levels in the command registry, `ns.devMode`, `/ls dev`, and the shorter login line;
- `.pkgmeta`, the release workflow, the `.toc` version token, `CHANGELOG.md`, README updates;
- the local dry run, the first `-beta` pre-release, the P63 checks in game, and the doc and status updates.

**Out of Scope:** from the spec's Non-Goals:
- uploading to CurseForge, Wago or WoWInterface (step 4);
- an options panel;
- other clients;
- automatic tagging;
- tests in CI;
- removing dev code;
- `/ls zone` and `/ls overrides`.

Also deferred: an `## IconTexture` for the AddOns list (cosmetic, not in the spec).

---

## 2. Phased Task Breakdown

### Phase 1: Metadata API probe — Not Started

**Objective:** Confirm which API reads the `.toc` version, before any code uses it (evidence rule).

#### Task 1.1: Probe the add-on metadata API (P63 step 1)

**File:** `notes/beta-probes.md`, `.luacheckrc`
**Tag:** T4 — you run one command in game; I write the probe line, record the result and update the lint config.

**Changes:**
- Give you one `/run` line that prints the result of `C_AddOns.GetAddOnMetadata("Lodestar", "Version")` if `C_AddOns` exists, and of the global `GetAddOnMetadata` if it exists.
- Record the result as P63 step 1 in `notes/beta-probes.md`.
- Add the confirmed API to `read_globals` in `.luacheckrc` with a `-- P63` comment.

**Acceptance Criteria:**
- `notes/beta-probes.md` has a P63 section naming the API that returns `0.1.0` for `"Version"` (the current `.toc` value).
- `.luacheckrc` lists that API under `read_globals`, and `scripts/check.ps1` passes.
- If neither API exists, Task 3.4 stops, and we revisit the login-line decision together before going on (no guessing).

**Rollback:** git revert the phase's commit.

---

### Phase 2: Visibility rule in Logic — Not Started

**Objective:** A tested, game-independent rule for which commands run and which are listed.

#### Task 2.1: `Logic.IsCommandRunnable` and `Logic.IsCommandListed` with tests

**File:** `Logic.lua`, `tests/logic_spec.lua`
**Tag:** T2 — Lua practice for you, in the same style as `ParseCommand` and `FindName`; I review and run the checks.

**Changes:**
- `Logic.IsCommandRunnable(access, devMode)`: `true` for `"player"` and `"hidden"` always; `true` for `"dev"` only when `devMode` is `true`; a `nil` access level counts as `"dev"`.
- `Logic.IsCommandListed(access, devMode)`: in dev mode, every command is listed; outside it, only `"player"` is. Hint: both fit in a line or two once `nil` becomes `"dev"`.
- Tests in a `describe` block for each function, covering every access level in both modes plus `nil` in both modes.

**Acceptance Criteria:**
- Both functions exist in `Logic.lua` with no WoW API calls.
- The tests cover 4 access values (`"player"`, `"dev"`, `"hidden"`, `nil`) × 2 modes for each function, and all pass in `scripts/check.ps1`.
- luacheck reports no warnings.

**Rollback:** git revert the phase's commit.

---

### Phase 3: Wiring in game code — Not Started

**Objective:** The registry, the dispatcher, `/ls dev` and the login line use the Phase 2 rule; the junction copy behaves as today.

#### Task 3.1: Access levels in the registry and dispatcher

**File:** `Core.lua`
**Tag:** T4 — wiring that the spec assigns to me; the rule itself is your Phase 2 code.

**Changes:**
- `ns.RegisterCommand(name, handler, usage, access)` stores `access` in the entry.
- A `--@debug@` / `--@end-debug@` block near the top of `Core.lua` sets `ns.devMode = true`. Outside it, `ns.devMode` defaults to `false`.
- `ns.RunCommand`: the `/ls` list shows only entries for which `Logic.IsCommandListed(entry.access, ns.devMode)` is true. A command whose entry fails `Logic.IsCommandRunnable` takes the existing "unknown command" path.

**Acceptance Criteria:**
- With `ns.devMode` true (the junction), `/ls` lists every command and each one runs as today.
- Reading the code: a `nil` access level can only be listed or run in dev mode.
- `scripts/check.ps1` passes.

#### Task 3.2: Mark every command

**File:** `Debug.lua`, `Place.lua`, `Modules/Instances.lua`, `Options.lua`
**Tag:** T4 — one argument per call, as decided in the spec.

**Changes:**
- `"player"`: `toggle`, `copy`, `log`.
- `"dev"`: `probe`, `dump`, `place`, `reveal`, `debug`.

**Acceptance Criteria:**
- Every `ns.RegisterCommand` call passes an access level (checked with a search: none are left with three arguments).
- `scripts/check.ps1` passes.

#### Task 3.3: `/ls dev`

**File:** `Options.lua`
**Tag:** T4 — a small command following the pattern of `/ls debug`; its behavior is fixed by the spec.

**Changes:**
- Register `dev` with access level `"hidden"`. It flips `ns.devMode`, then prints `dev mode on until /reload; type /ls for all commands` or `dev mode off`.
- Its usage text names the command, for when it appears in the dev-mode list.

**Acceptance Criteria:**
- On the junction, `/ls dev` prints `dev mode off`; then `/ls` lists `toggle`, `copy` and `log` only, and `/ls probe` gives "unknown command".
- A second `/ls dev` restores the full list.
- `scripts/check.ps1` passes.

#### Task 3.4: Login line

**File:** `Core.lua` (`OnLogin`)
**Tag:** T4 — the format is fixed by the spec; it uses the API confirmed in Phase 1.

**Changes:**
- Read `Version` with the Phase 1 API.
- Print `Lodestar <version> loaded`; in dev mode, append `(interface <n>), db v<n>`.

**Acceptance Criteria:**
- On the junction: `Lodestar @project-version@ loaded (interface 16001), db v1` (once Task 4.1 changes the `.toc`; before that, `Lodestar 0.1.0 loaded (interface 16001), db v1`).
- `scripts/check.ps1` passes.

**Rollback:** git revert the phase's commit(s).

---

### Phase 4: Packaging and local dry run — Not Started

**Objective:** Everything needed to release is in the repo, and a local packager run builds a correct zip without publishing anything.

#### Task 4.1: `.toc` version token, `.pkgmeta`, workflow

**File:** `Lodestar.toc`, **New File:** `.pkgmeta`, **New File:** `.github/workflows/release.yml`
**Tag:** T4 — tooling and config, which `CLAUDE.md` assigns to me.

**Changes:**
- `.toc`: `## Version: @project-version@`.
- `.pkgmeta`:
  - `package-as: Lodestar`;
  - `manual-changelog: CHANGELOG.md` (markdown);
  - `ignore:` with `tests`, `tools`, `notes`, `docs`, `scripts`, `screenshots`, `CLAUDE.md`, `.zed`, `.github`, `.luacheckrc`, `.luarc.json`, `.editorconfig`, `.gitignore`.
- Workflow:
  - runs on `push` of tags matching `v*`, with `permissions: contents: write`;
  - checks out with full history (`fetch-depth: 0`);
  - runs `BigWigsMods/packager@v2` with `GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}`.

**Acceptance Criteria:**
- `.pkgmeta` and the workflow are valid YAML.
- The workflow only triggers on `v*` tag pushes, so pushes to `main` don't run it.
- `scripts/check.ps1` passes.

#### Task 4.2: `CHANGELOG.md` and README

**File:** **New File:** `CHANGELOG.md`, `README.md`
**Tag:** T4 — I draft both and you edit the changelog wording for players before tagging.

**Changes:**
- `CHANGELOG.md` holds one entry, for `v0.2.0-beta1`: dev commands hidden (with `/ls dev`), the version in the login line, and anything else merged since `v0.1.0-test` that a player would notice.
- README:
  - Commands section: `toggle`, `copy`, `log clear`.
  - Bug-report section: mention `/ls copy` and `/ls dev`.
  - Install: the zip name becomes `Lodestar-<tag>.zip`, and the line about the dev commands being visible goes.

**Acceptance Criteria:**
- `CHANGELOG.md` has exactly one release heading.
- The README no longer says dev commands are visible.

#### Task 4.3: Local packager dry run (P63 step 2, Open question 5)

**File:** `notes/beta-probes.md`; the packager is cloned into the git-ignored `tools/`
**Tag:** T4 — I run it from Git Bash and record the result.

**Changes:**
- Clone the packager into `tools/packager`.
- Run its `release.sh` with uploads skipped and the output in the scratchpad.
- Compare the zip's contents with the `.toc` file list.
- Record in P63 whether interface 16001 caused errors or warnings, and the `release.json` flavor.
- If the packager fails on 16001, switch to the spec's fallback (`scripts/package.ps1` plus `gh release create`) and stop to agree the plan change with you first.

**Acceptance Criteria:**
- The zip holds exactly `Lodestar/` with the `.toc`, the files it lists, `Media/`, `README.md`, `LICENSE` and `CHANGELOG.md`.
- The packaged `.toc` has a real version instead of the token.
- In the packaged `Core.lua`, the `--@debug@` block is commented out.
- Open question 5 in the spec is answered.

**Rollback:** git revert the phase's commit(s); delete `tools/packager`.

---

### Phase 5: First beta release and in-game check — Not Started

**Objective:** A real `-beta` pre-release built by the workflow passes P63 in game, and the docs reflect the new pipeline.

#### Task 5.1: Push the first beta tag

**File:** none (git tag `v0.2.0-beta1`)
**Tag:** T1 — publishing a release is your call; I run the command only when you say go.

**Changes:**
- Tag `main` as `v0.2.0-beta1` and push the tag. Watch the workflow run with `gh run watch`.

**Acceptance Criteria:**
- The workflow succeeds.
- The GitHub Release `v0.2.0-beta1` is marked as a pre-release, has `Lodestar-v0.2.0-beta1.zip` attached, and shows the `CHANGELOG.md` entry as its notes.
- If it isn't marked as a pre-release, it's fixed with `gh release edit --prerelease` and the workflow gets the packager's release-type option.

#### Task 5.2: P63 steps 2-6 in game

**File:** `notes/beta-probes.md`
**Tag:** T4 — you play the checks, and I write the checklist and record the results.

**Changes:**
- You download the release zip and test it using "Testing a release zip".
- Check the zip's contents (step 2), the AddOns list and login line (step 3), the player `/ls` list and an unknown dev command (step 4), the `/ls dev` on/off sequence (step 5), then restore the junction and check the full commands and dev login line (step 6).

**Acceptance Criteria:**
- All six P63 steps are recorded with pass or fail and the screenshots' names.
- Any failure gets a fix task appended to this plan before the phase is marked Done.

#### Task 5.3: Docs and status

**File:** `docs/Lodestar – WoW Forever Map Addon Design Doc.md`, `CLAUDE.md`, `notes/spec-release-pipeline.md`
**Tag:** T4 — my own notes.

**Changes:**
- Design doc:
  - the Commands table gains `/ls dev`;
  - the "Project layout" tree gains `.pkgmeta`, `.github/` and `CHANGELOG.md`;
  - add a short "Releasing" paragraph: update `CHANGELOG.md`, run the checks, tag, push.
- `CLAUDE.md` Status mentions the pipeline.
- The spec's Status becomes `Implemented`.

**Acceptance Criteria:**
- The design doc describes the release steps, and nothing in it still says dev commands are visible to players.
- The spec is marked Implemented.

**Rollback:** delete the release and tag (`gh release delete v0.2.0-beta1 --cleanup-tag`); git revert the docs commit.

---

## 3. Files to Modify

| Path | Purpose | Est. LOC | Risk |
|------|---------|----------|------|
| `Logic.lua` | `IsCommandRunnable`, `IsCommandListed` | +15 | Low |
| `tests/logic_spec.lua` | Tests for both functions, both modes | +60 | Low |
| `Core.lua` | Access level, `ns.devMode` debug block, dispatcher and list, login line | +20 | Medium |
| `Options.lua` | Mark `toggle`/`debug`; new `/ls dev` | +20 | Low |
| `Debug.lua` | Mark `log`, `copy`, `probe`, `dump` | +4 | Low |
| `Place.lua` | Mark `place` | +1 | Low |
| `Modules/Instances.lua` | Mark `reveal` | +1 | Low |
| `Lodestar.toc` | `## Version: @project-version@` | ±1 | Low |
| `.luacheckrc` | Metadata API in `read_globals` | +1 | Low |
| `.pkgmeta` | **New** — package name, changelog, exclusions | ~20 | Medium |
| `.github/workflows/release.yml` | **New** — packager on `v*` tags | ~20 | Medium |
| `CHANGELOG.md` | **New** — current release entry | ~10 | Low |
| `README.md` | Commands, bug report, zip name | ±10 | Low |
| `notes/beta-probes.md` | P63 | +40 | Low |
| Design doc, `CLAUDE.md`, spec | Releasing paragraph, layout, status | ±15 | Low |

---

## 4. Validation Checklist

### Functional
- [ ] A `-beta` tag push produces a pre-release with the right zip and notes (Task 5.1).
- [ ] Release build: `/ls` lists `toggle`, `copy`, `log` only, and `/ls probe` gives "unknown command" (P63 step 4).
- [ ] `/ls dev` on, then off, behaves as the spec says (P63 step 5).
- [ ] The login line shows the tag in a release and the token plus dev details on the junction (P63 steps 3 and 6).

### Integration
- [ ] The zip holds exactly the runtime files, `README.md`, `LICENSE` and `CHANGELOG.md` (P63 step 2).
- [ ] Interface 16001 doesn't break the packager (Task 4.3).

### Regression
- [ ] Through the junction, every command works with no `/ls dev` (P63 step 6).
- [ ] `scripts/check.ps1` passes after every phase.
- [ ] Caught errors are still logged to `LodestarDB.log` in a release build: `ns.SafeCall`, `ns.Record` and `ns.Emit` in `Util.lua` are untouched (checked in review), and `/ls copy` stays a player command.

---

## 5. Risk Summary

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Packager fails or warns on interface 16001 | Medium | Medium | The local dry run (Task 4.3) finds it before any tag; fallback per spec: `scripts/package.ps1` plus `gh release create` |
| A file the game needs is excluded, or a dev file ships | Low | High | Exclusion list checked against the `.toc` in the dry run and again in P63 step 2 |
| `--@debug@` block not stripped, so dev mode is on in releases | Low | Medium | Dry-run acceptance checks the packaged `Core.lua`; P63 step 4 checks it in game |
| A forgotten access level hides a player command | Low | Low | A `nil` access level counts as `"dev"` by design; Task 3.2 searches for calls left with three arguments |
