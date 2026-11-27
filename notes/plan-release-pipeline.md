# Release pipeline and dev commands — Implementation Plan

| Field | Value |
|-------|-------|
| **Spec** | `notes/spec-release-pipeline.md` |
| **Date** | 2026-11-26 (review fixes applied the same day) |
| **Status** | In Progress (Phases 1-2 and Tasks 3.1-3.3 done 2026-11-27) |
| **Effort** | 2 sessions (one for the probe and your Logic code, one for wiring, packaging and the first beta) |

---

## 1. Overview

### Goal

After updating `CHANGELOG.md`, pushing a `v*` tag produces a GitHub Release with a correct `Lodestar-<tag>.zip`, the version taken from the tag, and `-beta` tags marked as pre-releases. Release builds list and run only `toggle`, `copy` and `log`, with `/ls dev` as an unlisted switch to turn on the rest, while the junction copy keeps every command working (spec Goals 1-8).

### Approach

- **Commands get an access level when registered:** `"player"`, `"dev"` or `"hidden"` (runs in every build but isn't listed: `/ls dev`). A missing access level counts as `"dev"`, so a command nobody marked stays out of players' sight (safe default; spec Key Decisions).
- **Two pure functions** in `Logic.lua` decide whether a command runs and whether it's listed, given its access level and the dev-mode state. `Core.lua` uses them in both the `/ls` list and the dispatcher, so the rule lives in one place.
- **Dev mode:**
  - `Core.lua` sets `ns.devMode = false` and, right after, a `--@debug@` block sets it to `true`. So the junction copy has it on with no setup. In a release, the packager turns that block into a comment, so it stays off.
  - `/ls dev` flips it for the session. It isn't saved to `LodestarDB`.
- **Packaging:** the BigWigs packager runs as a GitHub Action on `v*` tags, configured by `.pkgmeta` (exclusion list plus `manual-changelog`). The `.toc` gets `## Version: @project-version@`, and `CHANGELOG.md` holds only the current release's entry.
- **Package contents are checked:** `scripts/check-package.ps1` compares a zip or built folder against what the game loads (the `.toc` list plus the `Media` paths the code references). `Media/` holds only loaded files; working art lives in the git-ignored `art/`.
- **Reuse:**
  - `Logic.ParseCommand` and the existing `commands` table in `Core.lua`.
  - The "unknown command" error path, unchanged, for refused dev commands.
  - `ns.Print`, including its `Lodestar:` prefix, for every message.
  - The "Testing a release zip" steps in `notes/environment.md` for P63.

### Scope

**In Scope:**
- the P63 probe for the add-on metadata API;
- the two `Logic.lua` functions and their tests;
- access levels in the command registry, `ns.devMode`, `/ls dev`, and the shorter login line;
- `.pkgmeta`, the release workflow, the `.toc` version token, `CHANGELOG.md`, README updates;
- `scripts/check-package.ps1`;
- the local dry run, the first `-beta` pre-release, the P63 checks in game, and the doc and status updates.

Already done on 2026-11-26, before Phase 1: the `Media/` rule in the spec and design doc, and the `art/` ignore rule replacing `Media/traced/`.

**Out of Scope:** from the spec's Non-Goals:
- uploading to CurseForge, Wago or WoWInterface (step 4);
- an options panel;
- other clients;
- automatic tagging;
- tests in CI;
- removing dev code;
- `/ls zone` and `/ls overrides`.

Also deferred: an `## IconTexture` for the AddOns list (cosmetic, not in the spec), and running the package check inside the workflow before publishing (spec: not worth splitting the packager).

---

## 2. Phased Task Breakdown

### Phase 1: Metadata API probe — Done (2026-11-27: `C_AddOns.GetAddOnMetadata`)

**Objective:** Confirm which API reads the `.toc` version, before any code uses it (evidence rule).

#### Task 1.1: Probe the add-on metadata API (P63 step 1)

**File:** `notes/beta-probes.md`, `.luacheckrc`
**Tag:** T4 — you run one command in game; I write the probe line, record the result and update the lint config.

**Changes:**
- Give you one guarded `/run` line, so a missing API prints `nil` instead of raising an error that could be mistaken for an answer. It prints:
  - whether `C_AddOns` exists;
  - `C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("Lodestar", "Version")`;
  - `GetAddOnMetadata and GetAddOnMetadata("Lodestar", "Version")`.
- Record the result as P63 step 1 in `notes/beta-probes.md`.
- Add the confirmed API to `read_globals` in `.luacheckrc` with a `-- P63` comment.

**Acceptance Criteria:**
- `notes/beta-probes.md` has a P63 section naming the API that returns `0.1.0` for `"Version"` (the current `.toc` value).
- `.luacheckrc` lists that API under `read_globals`, and `scripts/check.ps1` passes.
- If neither API exists, Task 3.4 stops, and we revisit the login-line decision together before going on (no guessing).

**Rollback:** git revert the phase's commit.

---

### Phase 2: Visibility rule in Logic — Done (2026-11-27)

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

### Phase 3: Wiring in game code — In Progress (Tasks 3.1-3.3 done 2026-11-27)

**Objective:** The registry, the dispatcher, `/ls dev` and the login line use the Phase 2 rule; the junction copy behaves as today.

#### Task 3.1: Access levels in the registry and dispatcher — Done

**File:** `Core.lua`
**Tag:** T4 — wiring that the spec assigns to me; the rule itself is your Phase 2 code.

**Changes:**
- Right after `local addonName, ns = ...`, in this order: `ns.devMode = false`, then the `--@debug@` block with `ns.devMode = true` and `--@end-debug@`. The block comes second, so the junction copy ends up with dev mode on.
- `ns.RegisterCommand(name, handler, usage, access)` stores `access` in the entry. If `access` is `nil` while `ns.devMode` is on, it prints a one-line warning naming the command, so a forgotten mark shows up at the next `/reload` on the junction.
- `ns.RunCommand`: the `/ls` list shows only entries for which `Logic.IsCommandListed(entry.access, ns.devMode)` is true. A command whose entry fails `Logic.IsCommandRunnable` takes the existing "unknown command" path.

**Acceptance Criteria:**
- On the junction, with no `/ls dev`, `/ls` lists `probe` (dev mode is on), and every command runs as today.
- Reading the code: `ns.devMode = false` comes before the `--@debug@` block, and a `nil` access level can only be listed or run in dev mode.
- `scripts/check.ps1` passes.

#### Task 3.2: Mark every command — Done (2026-11-27: no warnings after `/reload`, `/ls` lists all 8)

**File:** `Debug.lua`, `Place.lua`, `Modules/Instances.lua`, `Options.lua`
**Tag:** T4 — one argument per call, as decided in the spec.

**Changes:**
- `"player"`: `toggle`, `copy`, `log`.
- `"dev"`: `probe`, `dump`, `place`, `reveal`, `debug`.

**Acceptance Criteria:**
- After a `/reload` on the junction, the login shows no "no access level" warning from Task 3.1.
- A search for `ns.RegisterCommand(` finds 9 call sites (8 existing plus `dev`). Each one is reviewed in the diff, which shows its access argument: 3 `"player"`, 5 `"dev"`, 1 `"hidden"`.
- `scripts/check.ps1` passes.

#### Task 3.3: `/ls dev` — Done (2026-11-27: on/off sequence checked, `screenshots/Screenshot 2026-11-27 184151.png`)

**File:** `Options.lua`
**Tag:** T4 — a small command following the pattern of `/ls debug`; its behavior is fixed by the spec.

**Changes:**
- Register `dev` with access level `"hidden"`. It flips `ns.devMode`, then prints `dev mode on until /reload; type /ls for all commands` or `dev mode off` (shown with the `Lodestar:` prefix).
- Its usage text names the command, for when it appears in the dev-mode list.

**Acceptance Criteria:**
- On the junction, `/ls dev` prints `Lodestar: dev mode off`; then `/ls` lists `toggle`, `copy` and `log` only, and `/ls probe` gives "unknown command".
- A second `/ls dev` restores the full list.
- `scripts/check.ps1` passes.

#### Task 3.4: Login line

**File:** `Core.lua` (`OnLogin`)
**Tag:** T4 — the format is fixed by the spec; it uses the API confirmed in Phase 1.

**Changes:**
- Read `Version` with the Phase 1 API.
- Pass `"<version> loaded"` to `ns.Print`, which adds the `Lodestar:` prefix. In dev mode, append ` (interface <n>), db v<n>`.

**Acceptance Criteria:**
- On the junction, chat shows `Lodestar: @project-version@ loaded (interface 16001), db v1` once Task 4.1 changes the `.toc`. Before that, it shows `Lodestar: 0.1.0 loaded (interface 16001), db v1`.
- `scripts/check.ps1` passes.

**Rollback:** git revert the phase's commit(s).

---

### Phase 4: Packaging, package check and local dry run — Not Started

**Objective:** Everything needed to release is in the repo, and a local packager run builds a package that passes the content check, without publishing anything.

#### Task 4.1: `.toc` version token, `.pkgmeta`, workflow

**File:** `Lodestar.toc`, **New File:** `.pkgmeta`, **New File:** `.github/workflows/release.yml`
**Tag:** T4 — tooling and config, which `CLAUDE.md` assigns to me.

**Changes:**
- `.toc`: `## Version: @project-version@`.
- `.pkgmeta`:
  - `package-as: Lodestar`;
  - `manual-changelog: CHANGELOG.md` (markdown);
  - `ignore:` with `tests`, `tools`, `notes`, `docs`, `scripts`, `screenshots`, `art`, `CLAUDE.md`, `.zed`, `.github`, `.luacheckrc`, `.luarc.json`, `.editorconfig`, `.gitignore`.
- Workflow:
  - runs on `push` of tags matching `v*`, with `permissions: contents: write`;
  - checks out with full history (`fetch-depth: 0`);
  - runs `BigWigsMods/packager@v2` with `GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}`.

**Acceptance Criteria:**
- `.pkgmeta` parses: the Task 4.4 dry run reads it without error and applies the ignore list.
- The workflow parses: after it's pushed, the repo's Actions tab shows it with no "Invalid workflow file" error (`gh workflow list` shows it). It only triggers on `v*` tag pushes, so pushes to `main` don't run it.
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

#### Task 4.3: `scripts/check-package.ps1`

**File:** **New File:** `scripts/check-package.ps1`
**Tag:** T4 — tooling, which `CLAUDE.md` assigns to me.

**Changes:**
- Takes a path to a zip or to a built `Lodestar/` folder.
- Works out the expected set from the package itself:
  - `Lodestar/Lodestar.toc` and every file it lists;
  - every `Media` file named by an `Interface\AddOns\Lodestar\Media\<name>` path in the packaged `.lua` and `.xml` files, matched by name without the extension;
  - `README.md`, `LICENSE` and `CHANGELOG.md`.
- Prints each extra and each missing file, and exits non-zero if there are any.
- Also fails if anything sits outside the top-level `Lodestar/` folder, or if the packaged `.toc` still holds `@project-version@`.
- Runs under Windows PowerShell 5.1 (the `scripts/check.ps1` environment), with no extra tools.

**Acceptance Criteria:**
- Run on the `v0.1.0-test` zip (downloaded with `gh release download`), it passes except for `CHANGELOG.md` being missing (that release has none). This shows it works on a real, known-good package.
- Run on a copy of that zip with an extra `Media/stray.tga` and with `Pins.xml` removed, it reports both and exits non-zero.

#### Task 4.4: Local packager dry run (P63 step 2, Open question 5)

**File:** `notes/beta-probes.md`; the packager is cloned into the git-ignored `tools/`
**Tag:** T4 — I run it from Git Bash and record the result.

**Changes:**
- **Prerequisites first:** clone the packager into `tools/packager`. Read the tools its `release.sh` calls (expected: `git`, `curl`, `jq` for uploads only, and `zip`), and check each one with `command -v` in Git Bash. Git for Windows doesn't ship `zip`. If it's missing, run with zip creation skipped and check the built `Lodestar/` folder instead (Task 4.3 accepts a folder), rather than installing anything. A missing tool is recorded as a missing tool, never as an interface 16001 failure.
- Run `release.sh` with uploads skipped and the output in the scratchpad.
- Run `scripts/check-package.ps1` on the result.
- Record in P63 whether interface 16001 caused errors or warnings, and the `release.json` flavor.
- Only if the packager itself fails on 16001 (not on a missing tool), switch to the spec's fallback (`scripts/package.ps1` plus `gh release create`), and stop to agree the plan change with you first.

**Acceptance Criteria:**
- `scripts/check-package.ps1` passes on the dry-run output (zip or folder).
- The packaged `.toc` has a real version instead of the token. With no tag on `HEAD`, the packager uses a commit-based version.
- In the packaged `Core.lua`, the `--@debug@` block is commented out.
- Open question 5 in the spec is answered, and the prerequisites found are recorded in P63.

**Rollback:** git revert the phase's commit(s); delete `tools/packager`.

---

### Phase 5: First beta release and in-game check — Not Started

**Objective:** A real `-beta` pre-release built by the workflow passes P63 in game, and the docs reflect the new pipeline.

#### Task 5.1: Push the first beta tag

**File:** none (git tag `v0.2.0-beta1`)
**Tag:** T1 — publishing a release is your decision and your action: you run the two commands I give you (`git tag v0.2.0-beta1`, `git push origin v0.2.0-beta1`), and I watch the run with `gh run watch`.

**Changes:**
- You tag `main` and push the tag. I watch the workflow and report the result.

**Acceptance Criteria:**
- The workflow succeeds.
- The GitHub Release `v0.2.0-beta1` is marked as a pre-release, has `Lodestar-v0.2.0-beta1.zip` attached, and shows the `CHANGELOG.md` entry as its notes.
- `scripts/check-package.ps1` passes on the downloaded release zip. If it fails, the release is deleted (`gh release delete v0.2.0-beta1 --cleanup-tag`) and the problem fixed before a new tag.
- If it isn't marked as a pre-release, it's fixed with `gh release edit --prerelease` and the workflow gets the packager's release-type option.

#### Task 5.2: P63 steps 2-6 in game

**File:** `notes/beta-probes.md`
**Tag:** T4 — you play the checks, and I write the checklist and record the results.

**Changes:**
- You download the release zip and test it using "Testing a release zip".
- The checks:
  - the zip's contents (step 2; the Task 5.1 package check);
  - the AddOns list and the login line `Lodestar: v0.2.0-beta1 loaded` (step 3);
  - the player `/ls` list and an unknown dev command (step 4);
  - the `/ls dev` on/off sequence (step 5);
  - then restore the junction and check the full commands and the dev login line (step 6).

**Acceptance Criteria:**
- All six P63 steps are recorded with pass or fail and the screenshots' names.
- Any failure gets a fix task appended to this plan before the phase is marked Done.

#### Task 5.3: Docs and status

**File:** `docs/Lodestar – WoW Forever Map Addon Design Doc.md`, `CLAUDE.md`, `notes/spec-release-pipeline.md`
**Tag:** T4 — my own notes.

**Changes:**
- Design doc:
  - the Commands table gains `/ls dev`;
  - the "Project layout" tree gains `.pkgmeta`, `.github/`, `CHANGELOG.md` and `scripts/check-package.ps1`;
  - add a short "Releasing" paragraph: update `CHANGELOG.md`, run `scripts/check.ps1`, tag, push, then run `scripts/check-package.ps1` on the released zip.
- `CLAUDE.md` Status mentions the pipeline.
- The spec's Status becomes `Implemented`.

**Acceptance Criteria:**
- The design doc describes the release steps, including the package check, and nothing in it still says dev commands are visible to players.
- The spec is marked Implemented.

**Rollback:** delete the release and tag (`gh release delete v0.2.0-beta1 --cleanup-tag`); git revert the docs commit.

---

## 3. Files to Modify

| Path | Purpose | Est. LOC | Risk |
|------|---------|----------|------|
| `Logic.lua` | `IsCommandRunnable`, `IsCommandListed` | +15 | Low |
| `tests/logic_spec.lua` | Tests for both functions, both modes | +60 | Low |
| `Core.lua` | Dev-mode lines, access level and warning, dispatcher and list, login line | +25 | Medium |
| `Options.lua` | Mark `toggle`/`debug`; new `/ls dev` | +20 | Low |
| `Debug.lua` | Mark `log`, `copy`, `probe`, `dump` | +4 | Low |
| `Place.lua` | Mark `place` | +1 | Low |
| `Modules/Instances.lua` | Mark `reveal` | +1 | Low |
| `Lodestar.toc` | `## Version: @project-version@` | ±1 | Low |
| `.luacheckrc` | Metadata API in `read_globals` | +1 | Low |
| `.pkgmeta` | **New** — package name, changelog, exclusions | ~20 | Medium |
| `.github/workflows/release.yml` | **New** — packager on `v*` tags | ~20 | Medium |
| `scripts/check-package.ps1` | **New** — package contents vs. `.toc` and `Media` references | ~70 | Medium |
| `CHANGELOG.md` | **New** — current release entry | ~10 | Low |
| `README.md` | Commands, bug report, zip name | ±10 | Low |
| `notes/beta-probes.md` | P63 | +40 | Low |
| Design doc, `CLAUDE.md`, spec | Releasing paragraph, layout, status | ±15 | Low |
| `tools/packager/` | Not tracked (git-ignored): packager clone for the local dry run, deleted on rollback | — | Low |

Already changed before Phase 1 (2026-11-26): `.gitignore` (`art/` replaces `Media/traced/`), the doc line in `scripts/trace_masks.py`, a dated note in `notes/spec-5.2-traced-mask-slice.md`, the `Media/` rule in the design doc and spec.

---

## 4. Validation Checklist

### Functional
- [ ] A `-beta` tag push produces a pre-release with the right zip and notes (Task 5.1).
- [ ] Release build: `/ls` lists `toggle`, `copy`, `log` only, and `/ls probe` gives "unknown command" (P63 step 4).
- [ ] `/ls dev` on, then off, behaves as the spec says (P63 step 5).
- [ ] The login line shows `Lodestar: <tag> loaded` in a release, and the token plus dev details on the junction (P63 steps 3 and 6).

### Integration
- [ ] `scripts/check-package.ps1` passes on the dry run and on the released zip (P63 step 2).
- [ ] Interface 16001 doesn't break the packager (Task 4.4).

### Regression
- [ ] Through the junction, every command works with no `/ls dev`, and no "no access level" warning appears (P63 step 6).
- [ ] `scripts/check.ps1` passes after every phase.
- [ ] Caught errors are still logged to `LodestarDB.log` in a release build: `ns.SafeCall`, `ns.Record` and `ns.Emit` in `Util.lua` are untouched (checked in review), and `/ls copy` stays a player command.

---

## 5. Risk Summary

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Packager fails or warns on interface 16001 | Medium | Medium | The local dry run (Task 4.4) finds it before any tag; fallback per spec: `scripts/package.ps1` plus `gh release create` |
| The dry run fails on a missing tool (`zip`) and is taken for a 16001 failure | Medium | Low | Prerequisites checked first; check the built folder instead of the zip (Task 4.4) |
| A file the game needs is excluded, or a dev file or working art ships | Low | High | `scripts/check-package.ps1` on the dry run and on every released zip; the `Media/` rule keeps working art in `art/` |
| `--@debug@` block not stripped, so dev mode is on in releases | Low | Medium | Dry-run acceptance checks the packaged `Core.lua`; P63 step 4 checks it in game |
| A forgotten access level hides a player command | Low | Low | `nil` counts as `"dev"` by design; the dev-mode warning in `RegisterCommand` names it at `/reload` |
