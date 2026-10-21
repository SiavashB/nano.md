# Roadmap

Milestones describe intended work, not shipped features. Complete and verify each slice before expanding scope.

Current priority: build app functionality. Public release preparation and performance profiling follow feature work; the milestone numbers below remain stable for reference.

## 0. Architecture and repository foundations

- [x] Record the architecture, dependency direction, state ownership, and path to editing.
- [x] Add AI development rules and contributor guidance.
- [x] Document the current template and reproducible build command.
- [x] Add ignore rules and editor defaults.

## 1. Read-only document foundation

- [x] Move the template types into the planned structure as responsibilities are implemented.
- [x] Adopt Swift 6 language mode without suppressing isolation diagnostics.
- [x] Replace the example document type with consistent `.md` and `.markdown` registration.
- [x] Use a viewer scene, `Viewer` role, read-only file access, and a rejecting write adapter.
- [x] Replace the template editor with selectable literal source as the first reader slice.
- [x] Handle empty files, valid UTF-8 with/without BOM, invalid encoding, and unreadable files.
- [x] Finish the live acceptance checks below.

Completion: open documents through Finder and File > Open, open multiple windows, copy source, and close without a dirty state or save prompt. Check that file bytes and modification times are unchanged. The app must not offer document creation or editing.

Complete. Builds and basic document checks passed: opening, copying, separate windows, closing, UTF-8/BOM handling, and read errors. Sample-file bytes and modification times remained unchanged. Dedicated accessibility audits are deferred.

## 2. Markdown reader

- [x] Verify native rendering of nested blocks, code whitespace, and continuous text selection.
- [x] Select a parser release, review dependency/license costs, and include package resolution for version control.
- [x] Introduce the parser worker and immutable semantic output.
- [x] Implement the documented syntax subset, literal-source fallback, and explicit link policy.
- [x] Handle loading, cancellation, obsolete results, and document replacement.
- [x] Verify selection, copy, keyboard access, and basic appearance with a focused smoke check.

Completion: supported Markdown renders correctly across representative documents, unsupported content remains readable, no remote resource loads automatically, and opening/closing a file never modifies it. Verify the result in a running app; a successful build alone is insufficient.

Rendering is implemented. Debug and locally signed Release builds passed. A focused live smoke check covered headings, emphasis, nested lists, quotes, code, literal HTML/tables, image placeholders, continuous selection, Command-A/Command-C, and closing without a save prompt. The sample’s bytes and modification time stayed unchanged. Code-block line spacing was corrected after visual inspection. Dependency notices are bundled; the Release app occupies approximately 1.9 MiB on disk in the local arm64 build.

The reader milestone is complete within its documented syntax subset. Performance profiling is deferred to final polish and is not a gate for further feature work. The initial formatting limits (1 MiB, 50,000 nodes, 64 levels) remain conservative guardrails. Full source remains available when a limit is exceeded. No automated tests or dedicated accessibility audit were added. The live check did not exercise rapid external file replacement or browser navigation; cancellation/revision checks and the link policy were reviewed in code.

Pipe-table rendering was added after the original reader smoke check, with native cells, header styling, borders, column alignment, and inline formatting. User-provided screenshots confirmed visible alignment, inline formatting, text wrapping, empty cells, and header-only tables, and exposed border gaps and tight spacing after tables. Border and spacing adjustments compiled in Debug and locally signed Release; build 4 was installed at `/Applications/NanoMD.app` and its binary and registration were verified. The [build 7 UI check](#focused-local-ui-validation-010-build-7) subsequently verified table layout at two window widths and copying a selection across cells. No tests were added.

### SKILL.md front matter (0.1.0, build 11)

On October 16, 2026, opening a disposable copy of the installed `listing-floor-plan/SKILL.md` confirmed that its opening YAML rendered as a thematic break and an oversized heading. Build 11 separates a closed leading mapping block before Markdown parsing and displays all metadata literally in a compact native text panel. Edit retains the original YAML; no dependency, test target, or automated test was added.

Unsigned Debug and Developer ID-signed arm64 Release builds passed with Xcode 26.6, along with strict signature verification and `git diff --check`. Focused app checks passed for the real SKILL.md's panel and body, Read/Edit source visibility, folded multiline descriptions and nested fields in a UTF-8 BOM/CRLF fixture, ordinary leading thematic breaks, and a missing closing delimiter. The real SKILL.md retained its original SHA-256 after reading and switching modes. The local signed Release bundle contains 3,674,213 regular-file bytes, and the website's size/version fields were refreshed from that bundle. Logs and disposable files are under ignored `Temp/SkillFrontMatter/`. These checks do not replace the broader outstanding editor checks or downloaded-package verification.

The [beta 3 release](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.3) was published on October 17, 2026, from `4e6710e`. The downloaded package passed checksum, strict Developer ID signature/timestamp, hardened runtime, sandbox/file-access entitlements without debugger access, stapling, Gatekeeper, version/architecture metadata, and bundled-license checks. The packaged app passed launch, real SKILL.md panel/body rendering, Edit, undo/redo, saving, closing, and reopening. A file comparison showed only the intended metadata-name edit changed. The released ZIP is 2,143,224 bytes and its app totals 3,671,818 regular-file bytes; website metadata was refreshed from that exact bundle. This focused release check leaves the broader unchecked editor cases below open.

### Front-matter keys and shared native setup (0.1.0, build 16)

The front-matter envelope recognizer now accepts dotted plain keys and single-line quoted keys, locating the separator after the closing quote while skipping double-quoted escapes and doubled single quotes. Metadata stays literal; delimiter rules and source serialization are unchanged. The [architecture](ARCHITECTURE.md#initial-rendering-scope) documents the limited recognition subset. A concrete `NativeTextViewConfiguration` helper shares only identical scrolling and text-container geometry across editor, formatted reader, and source fallback. Each adapter retains its insets, TextKit choice, theme calls, and lifecycle behavior.

One independent tester (`gpt-6-luna`, low reasoning, fresh context) performed baseline and final validation in the same checkout with implementation edits paused. Unsigned Debug and Release builds passed before and after on macOS 26.6.2 (25G83), Xcode 26.6 (17F113), Apple T6000. Both stages used the README build command unchanged, including `CODE_SIGNING_ALLOWED=NO` and repository-root `Temp/` build/cache paths. Debug selected arm64; Release built arm64 and x86_64. Initial sandbox cache-access failures were resolved by normal Xcode/SwiftPM cache access without changing project protections. The build warning was skipped App Intents metadata extraction because that framework is not linked. Xcode lists only the app target; no applicable existing tests exist, and no tests were created or updated. Bundle metadata is 0.1.0, build 16, and `git diff --check` passed.

Initial code review covered each example independently (`"title": My document`, `'display name': My document`, `app.version: 1.0`), ordinary `name`/`description`/`title`, quoted colons, escaped quotes/backslashes, doubled single quotes, empty quoted keys, and empty values. Negative cases reviewed include unterminated/mismatched quotes, trailing escapes, junk after a closing quote, separators lacking following whitespace, missing closing delimiters, indented/nested-only fields, and leading thematic breaks without a mapping. Both closing delimiters and exact delimiter-line constraints were reviewed. Values resembling types, tags, or aliases remain literal. BOM, line-ending, body-slicing, serialization, native-view identity, TextKit, theme, undo/reload, selection, and link paths were reviewed. No input fixtures, app launch, visual testing, or runtime byte-preservation checks were executed during this initial pass; functional follow-up is recorded below.

| Metric | Before (build 15) | After (build 16) | Change |
| --- | ---: | ---: | ---: |
| Universal unsigned Release app bytes | 6,115,777 | 6,116,177 | +400 |
| Release app allocated bytes | 6,139,904 | 6,139,904 | 0 |
| Production Swift files | 15 | 16 | +1 |
| Physical Swift lines | 1,262 | 1,271 | +9 |
| Nonblank Swift lines | 1,138 | 1,143 | +5 |
| Production Swift bytes | 48,070 | 48,075 | +5 |

App bytes sum regular nonsymlink files in the complete Release bundle; allocated bytes sum those files' `st_blocks * 512`. These are uncompressed app measurements, not download sizes. Source measurements include only production `NanoMD/**/*.swift`, excluding dependencies and generated output. Physical lines use byte `splitlines()` counts; nonblank lines use UTF-8 text `splitlines()` with `strip()`; source bytes use actual file lengths. Definitions and build settings are identical before and after. This universal build is not directly comparable to earlier arm64-only measurements.

Exact commands, logs, reports, and the measurement script are under ignored `Temp/FocusedFixes/`; the validated Release is under `Temp/DerivedData/Build/Products/Release/`. Website app-size/version metadata was refreshed from that bundle. The recognizer does not validate complete YAML or escape syntax. No dependency, installed-app replacement, website deployment, release publication, merge, or push was performed.

At the maintainer's subsequent request, the same tester functionally exercised both fixes in a locally Apple Development-signed Release, with implementation edits paused. The signed build and disposable fixtures are isolated under `Temp/FocusedFixes/Functional/`; the installed app was untouched. The app displayed metadata and retained body content for each quoted/dotted example, ordinary fields, quoted colons, escaped quotes/backslashes, doubled single quotes, empty keys/values, and literal tag/alias/type-looking values. Both closing delimiters worked. Malformed quoted keys, missing separator whitespace, missing/spaced delimiters, ordinary thematic breaks, and indented-only fields stayed on the Markdown path.

Runtime checks passed for reader/editor wrapping without horizontal scrollbars, native table layout, reader selection and copying verified by pasting into a disposable editor, editor vertical scrolling, selection/scroll retention across mode switches, undo/redo across a switch, and Light/Dark restyling. A BOM/CRLF/Unicode fixture retained its exact SHA-256 after reading and switching modes without edits. An intended edit was saved, closed, and reopened with the saved content intact. A 1,806,149-byte fixture triggered source fallback; its text wrapped and scrolled, rejected a typing attempt without changing displayed text or file bytes, and restyled with the theme. The original Dark preference was restored. Exact inset dimensions, TextKit versions, and native object identity remain code-review findings; fallback selection and copy commands were exercised, while pasteback verification used the formatted reader. No product code, configuration, or automated tests changed during this follow-up. Detailed executed cases, hashes, build log, and cleanup notes are in `Temp/FocusedFixes/Functional/functional-report.md`.

## 3. Public release preparation

- [x] Choose and add the project license; retain any required dependency notices.
- [ ] Decide and validate the minimum supported macOS and Xcode versions.
- [x] Share the Xcode scheme and verify a build from a fresh checkout without personal settings.
- [x] Remove already-tracked `xcuserdata` from Git while preserving the owner's local settings; ignore rules do not untrack files.
- [x] Make contributor builds independent of the original developer's signing team.
- [x] Add build CI using a runner with the required Xcode version; do not publish a passing badge before CI is working.
- [ ] Add screenshots of the implemented app, accurate feature/limitation notes, and release instructions.
- [x] Verify signing, sandbox behavior, and notarization if distributing an app binary.

Automated test coverage is a separate maintainer-requested task. No tests or test targets are introduced without an explicit request. Builds, focused manual verification, and honest reporting remain required.

The initial release process is defined in [Releasing](RELEASING.md): build-only CI on pull requests and `main`, local AI-assisted functional checks, and signed/notarized draft releases from version tags. A shared Xcode scheme is included. [The first GitHub build](https://github.com/SiavashB/nano.md/actions/runs/38302783956) passed unsigned Debug and Release on a clean macOS runner with Xcode 26.6. Local independent build and workflow validation also passed; app/source size was unchanged. Signing credentials are now configured. The [first beta release run](https://github.com/SiavashB/nano.md/actions/runs/38635655132) passed certificate import and the Developer ID-signed Release build on October 14, 2026. Apple processed the notarization submission but returned `Invalid` because the executable requested the debugging entitlement `com.apple.security.get-task-allow`. Draft creation and packaged-app verification were not reached.

The first beta attempt used version 0.1.0, build 7, tagged `v0.1.0-beta.1` at `76dfc6f`. The MIT license and dependency notices are bundled byte for byte. Personal Xcode state is no longer tracked, and signing uses an optional ignored `Config/Local.xcconfig`. Independent unsigned arm64 Debug and Release builds, workflow/project lint, and shared-scheme parsing passed with Xcode 26.6. Under the same measurement method, regular-file Release bundle bytes increased from 3,640,373 to 3,641,448 (+1,075 bytes for the license and version metadata). Production Swift remains 13 files, 910 physical lines, 818 nonblank lines, and 34,586 bytes. Logs and measurements are under `Temp/FirstRelease/`. Focused local UI checks passed on October 14, 2026, as recorded below. At that stage, Developer ID signing had passed in CI while notarization and downloaded distribution verification were still incomplete. Independent release verification evidence is under `Temp/FirstRelease/SigningVerification/`. Build 8 is prepared for `v0.1.0-beta.2`: the distribution workflow uses explicit sandbox/file-access entitlements, disables injected debugger access, checks the signed permissions, and retains detailed rejection logs. App source and dependencies are unchanged. Independent unsigned Debug/Release and corrected Developer ID-signed Release builds passed, including actual sandbox/file-access entitlements, absence of debugger access, hardened runtime, and strict signature verification. The unsigned arm64 Release measures 3,643,352 regular-file bytes versus 3,641,448 before this change (+1,904 bytes, 0.0523%); the local Developer ID-signed bundle measures 3,653,684 bytes before notarization/stapling. Source remains 13 files and 34,586 bytes. Evidence is under `Temp/FirstRelease/NotarizationFix/`. The subsequent beta.2 attempt 2 completed successfully on October 14, 2026, as recorded below.

Beta.2 (`3358691`, version 0.1.0 build 8) is [published as a prerelease](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.2). Apple accepted the new submission `724df31c-f072-43a8-9e88-cb3ce00429d3` in [release attempt 2](https://github.com/SiavashB/nano.md/actions/runs/38641897124/attempts/2). Independent verification of the downloaded ZIP passed checksum, strict Developer ID signature and secure timestamp, hardened runtime, sandbox/file-access entitlements with no debugger access, stapling, Gatekeeper, version/architecture/deployment metadata, and both bundled licenses. The ZIP is 2,138,600 bytes; the extracted app totals 3,652,073 regular nonsymlink-file bytes across 9 files. Production Swift is unchanged. Evidence is under `Temp/FirstRelease/Beta2RetryVerification/`. The maintainer subsequently tested the notarized package and confirmed that launch, opening, editing, undo, saving, and reopening passed, then approved publication. This completes the basic distribution checks; the broader unchecked editor cases below remain open. The release workflow now retains submission ZIPs and IDs for future timeout recovery; this change was not exercised by the beta.2 run.

### Apple Silicon build and measurement policy (0.1.0, build 17)

Debug and Release now default to arm64 only. The website size updater verifies the executable architecture and the bundle's build-configuration metadata, rejecting universal/Intel, Debug, and unidentified older builds. The [measurement policy](../CONTRIBUTING.md#app-size-measurements) standardizes Release measurements and requires matching architecture, toolchain, and signing mode for comparisons.

On October 18, 2026, independent unsigned Debug and Release builds passed with Xcode 26.6 and no command-line architecture override; both executables contained only arm64. The updater rejection checks passed without changing the page. The accepted build 17 Release contains 3,853,896 regular-file bytes (3.9 decimal MB), and website source metadata was refreshed from it. The earlier build 16 figure of 6,116,177 bytes included Intel code; this correction reflects packaging rather than code-size optimization. Production Swift remains 16 files, 1,271 physical lines, 1,143 nonblank lines, and 48,075 bytes. Validation details are under ignored `Temp/AppleSilicon/`. No tests were added, and no app launch, installation, website deployment, or release publication was performed.

### macOS 15 deployment target (0.1.0, build 18)

Debug and Release now target macOS 15.0 on Apple Silicon, retaining Xcode 26.6. The existing toolbar title-removal API is available from macOS 15, and no Swift implementation changes or compatibility branches were needed. Independent unsigned Debug/Release builds passed on October 18, 2026 with no command-line deployment or architecture overrides, no API-availability errors, and no higher-minimum linker warnings. Both bundles report arm64 and minimum system version 15.0; the Release Mach-O also records minimum OS 15.0.

The unsigned Release contains 3,862,520 regular-file bytes (3.9 decimal MB), 8,624 bytes above the identically built arm64 build 17. The increase is confined to the executable; no frameworks or dylibs were added to the bundle. Website source metadata reflects build 18 while the beta 3 download section retains its actual macOS 26.5 requirement. Evidence is under ignored `Temp/MacOS15/`. No app launch, installation, deployment, release publication, or test creation occurred. Runtime validation on macOS 15 remains pending: launch, reading/tables, editing/undo, saving/reopening, and theme/toolbar behavior must be checked on that OS before claiming verified compatibility.

### macOS display name (0.1.0, build 19)

The installed bundle previously exposed `NanoMD` as its base name without a public display name. Build 19 supplies `nano.md` through localized bundle-name/display-name values, while the base display name matches the existing product filename so Finder honors localization. Technical target, executable, bundle identifier, and product filename remain unchanged.

Unsigned arm64 Debug and locally Apple Development-signed arm64 Release builds passed with Xcode 26.6 and the macOS 15.0 target. Property-list checks, `git diff --check`, and strict signature verification passed. Native macOS name APIs resolved the localized bundle name and running application name to `nano.md`, and Finder's file display name to `nano.md.app`. These are API checks; no rendered UI, screenshots, or automated tests were used.

With maintainer approval, the running build 18 quit normally and was preserved under `Temp/DisplayName/PreviousInstalled/NanoMD.app`. Build 19 was installed and reopened at `/Applications/NanoMD.app`; its executable SHA-256 matches the validated Release and its signature passed strict verification. Only stale registrations with the exact nano.md bundle identifier were removed, then the installed app was registered. macOS resolves that identifier to the installed path. Logs, API results, and the validation report are under `Temp/DisplayName/`. Public website metadata remains tied to the published beta 4 release; no release or website deployment occurred.

## 4. Source editing

- [x] Add Read/Edit controls over the same document source and retain the existing reader path.
- [x] Enable writes intentionally across scene, document role, serialization, and entitlements.
- [x] Implement persistent native source editing and one document-scoped native undo/redo path.
- [x] Preserve UTF-8/BOM metadata and source representation in the serialization implementation.
- [x] Delegate saving, autosaving, errors, reverts, and conflict acceptance to the system lifecycle.
- [x] Verify editor selection/scroll retention, undo/redo after returning to the focused editor, and document isolation at runtime.
- [x] Verify save/reopen and modified-document close/quit confirmation, including save, discard, and cancel.
- [x] Verify no-edit byte and modification-time preservation for BOM, whitespace, Unicode, and CRLF fixtures.
- [x] Verify inserted CRLF line breaks in an existing document and LF without BOM in a new document.
- [ ] Verify input-method composition at runtime.
- [ ] Verify autosave without explicit Save and failed-save retention at runtime.
- [ ] Verify BOM retention after editing and mixed-line-ending edits at runtime.
- [ ] Verify external-change conflicts with unsaved edits, reverts, and crash recovery at runtime.

Implementation and build verification are distinct from runtime acceptance. The first editor retains a native text view across modes, publishes literal source, and clears stale undo actions on accepted system reloads. No hidden preview parses during typing. The reader's parser, tables, fallback, limits, and resource policy remain unchanged. The original implementation was build 5 and added no dependencies, targets, processes, services, database, persistent cache, tests, or visual testing. Later runtime results are recorded below.

Completion of runtime acceptance: edits, undo, reopening, failed saves, and external changes preserve user work. The unchecked cases above remain open; the focused build 7 check does not establish full runtime acceptance. Richer Markdown features remain separately scoped.

### Footer shortcuts (development checkout)

The development checkout adds a terminal-style footer button and matching View menu command. Control-R toggles the active document between Read and Edit; the footer shows the destination (`^R Edit` or `^R Read`). The plain native button uses a rectangular green accent key badge and muted monospaced text, separated by one character-sized gap, following the maintainer's nano reference for highlighting. The app's existing palette supplies all colors. Reduced header/footer vertical padding targets roughly 20% thinner bars while keeping the text size. Only the menu command registers the keyboard equivalent; the footer click uses the same action. Native button repetition is disabled. At the maintainer's request, the Control-G appearance cycle and footer/menu cycle controls were removed; the toolbar and View > Appearance pickers still use the existing saved preference. The single-row footer retains the informational UTF-8 encoding label; the filename appears only in the header. No editor, parser, serialization, dependency, or project-setting changes are included.

One independent `gpt-6-luna` tester with low reasoning effort validated the baseline and implementation in the current checkout on `feature/nano-footer-shortcuts`, with edits paused during validation. Baseline Release and final Debug/Release builds passed using Xcode 26.6 (17F113), SDK 26.5, `ARCHS=arm64`, macOS 15.0 deployment, pinned package versions, and `CODE_SIGNING_ALLOWED=NO`. Both measured bundles report arm64, Release, minimum OS 15.0, version 0.1.0/build 19. `git diff --check` and focused code review passed. No applicable existing test targets exist; no tests were written. The only build warning was skipped App Intents metadata extraction. Simulator-service diagnostics did not prevent the macOS builds.

| Metric | Before | After | Change |
| --- | ---: | ---: | ---: |
| Unsigned arm64 Release app bytes | 3,896,993 | 3,979,617 | +82,624 |
| App decimal MB | 3.896993 | 3.979617 | +0.082624 |
| Production Swift files | 16 | 17 | +1 |
| Production Swift bytes | 48,918 | 51,183 | +2,265 |
| Physical Swift lines | 1,301 | 1,370 | +69 |
| Nonblank Swift lines | 1,170 | 1,230 | +60 |

App measurements sum regular-file bytes across the complete `.app` without following symlinks; adjacent dSYMs, caches, and archives are excluded. Source measurements include only `NanoMD/**/*.swift`: actual file bytes, physical lines from byte `splitlines()`, and nonblank decoded lines. Toolchain, architecture, signing, build paths, and measurement method match before and after. Commands, logs, measurements, and the tester's report are under ignored `Temp/FooterShortcuts/`. After removing the footer filename and adopting the nano-style indicators, the same tester repeated Debug/Release builds, code review, and measurements. The table reflects the final Read/Edit-only shortcut, original muted footer text color, and compact layout under `Temp/FooterShortcuts/RemoveAppearanceShortcut/`, including the two-point outer top inset below the toolbar. Only the Read/Edit key badge uses highlighted colors. The same tester repeated both builds and measurements after these styling adjustments, and earlier records remain preserved. With the appearance shortcut removed, the Read/Edit control and UTF-8 label fit in a compact single-row footer.

Static conflict review found no other app shortcut handlers and no Control-R/Control-G entries in the development OS's standard AppKit key-binding dictionary. The Read/Edit command shares its action with the footer button and uses native menu dispatch before text input, with repetition disabled. Independent validation did not exercise runtime behavior, visual presentation, signing, or macOS 15 compatibility. The installed app, published release, and live website were not updated.

Remaining manual checks for these controls:

- [ ] With the editor focused, press Control-R once, rapidly in succession, and while holding the keys; confirm one action per press, no inserted control characters, and no unexpected text command. Also check Read mode, source fallback, and toolbar/footer focus.
- [ ] Compare keyboard, footer, and View > Edit/Read menu activation; confirm mode labels. Confirm Control-G no longer cycles appearance, and the existing toolbar/View > Appearance pickers still work with saved legacy/invalid appearance values.
- [ ] Open two documents; confirm mode changes affect only the active document, appearance updates both, and the mode menu disables without an active document. Confirm preference persistence after relaunch.
- [ ] Type, select text, scroll, switch mode/appearance, and refocus the editor; confirm exact source, selection, scroll, dirty state, and undo/redo retention. Include marked-text composition.
- [ ] Check both themes at narrow and wide window sizes with long filenames; confirm the complete Read/Edit shortcut label, usable controls, footer metadata, keyboard focus, and VoiceOver labels.
- [ ] Run these checks on macOS 15 as well as the current development OS.

### Editing implementation validation

Starting checkout: `main`, commit `9a278123033405c4325d9d1ba8db4952470ec7e5`, no pre-existing changes. Implementation is on `feature/source-editing`, in the existing project directory. Exactly one independent tester uses `gpt-6-luna` with medium reasoning and a fresh context for baseline and final verification. No applicable existing test targets exist.

Baseline: freshly built locally ad-hoc signed Release, Xcode 26.6 (17F113), macOS SDK 26.5, arm64, deployment 26.5, Swift 6. Same build settings and measurement definitions are required for final comparison. Baseline app: 1,932 KiB (1,978,368 on-disk bytes); production Swift: 12 files, 696 physical lines, 627 nonblank lines, 25,893 bytes. Raw measurements, command/environment details, measurement script, and build logs are retained under `Temp/SourceEditing/`.

Independent final Debug and Release builds passed (exit 0), sequentially with the baseline settings. `git diff --check` passed. There are no test targets or applicable existing tests. No Swift compiler warnings/errors occurred; Xcode emitted its standard App Intents metadata notice because that framework is not linked. Logs: `Temp/SourceEditing/final-debug.log`, `final-release.log`; command/environment report: `final-report.txt`.

| Metric | Baseline | Final | Absolute change | Percentage change |
| --- | ---: | ---: | ---: | ---: |
| Complete Release app on disk | 1,932 KiB (1,978,368 bytes) | 2,012 KiB (2,060,288 bytes) | +80 KiB (+81,920 bytes) | +4.14% |
| Production Swift files | 12 | 13 | +1 | +8.33% |
| Physical Swift lines | 696 | 867 | +171 | +24.57% |
| Nonblank Swift lines | 627 | 778 | +151 | +24.08% |
| Swift file bytes | 25,893 | 32,944 | +7,051 | +27.23% |

Measurement method: `du -sk Temp/SourceEditing/DerivedData/Build/Products/Release/NanoMD.app` measures the complete bundle's allocated KiB; on-disk bytes are KiB × 1,024. Source scripts recursively include all production `NanoMD/**/*.swift`, with file count, physical lines via `splitlines()`, nonblank lines via `line.strip()`, and actual file bytes. Temp, dependencies, generated files, build products, assets, and documentation are excluded. Both scripts use identical scope and definitions; `measure_source.py` writes the baseline JSON, and `measure_final_source.py` writes the final JSON. Both raw reports remain preserved.

Build method for baseline Release and final Debug/Release (substitute the configuration):

```sh
xcodebuild -project NanoMD.xcodeproj -scheme NanoMD -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$PWD/Temp/SourceEditing/DerivedData" \
  -clonedSourcePackagesDirPath "$PWD/Temp/SourcePackages" \
  -packageCachePath "$PWD/Temp/PackageCache" \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= build
```

Growth comes from the persistent native editor/coordinator, Read/Edit composition, and source serialization, partly offset by removing ReaderCommands. The final bundle contains only the executable, Info.plist, PkgInfo, signature metadata, and the existing ThirdPartyNotices resource. No dependencies or bundled build artifacts were added; the executable accounts for the bundle growth. No speculative optimization or size budget was introduced.

Build 5 was installed at `/Applications/NanoMD.app` from the validated locally signed Release; the follow-up below supersedes that installed version. Both older instances closed through normal termination; no force quit was used. A recoverable build 4 copy is retained at `Temp/SourceEditing/PreviousBuild4/NanoMD.app`. Installed and validated executable SHA-256 values match; strict signature verification passed. Only NanoMD's stale build registrations were removed, and its installed copy registered. NSWorkspace resolves its bundle identifier to `/Applications/NanoMD.app`; the Markdown default remains TextEdit. Registration and installed-binary evidence is retained in `Temp/SourceEditing/registration-after-install.json` and `installed-binary-sha256.txt`.

Implementation review covered source/BOM preservation, exact representation comparisons, binding feedback suppression, native undo ownership and lifetime, document isolation, marked-text reload deferral, and save-error retention through system ownership. That review and compilation did not establish runtime behavior; subsequent build 7 results are recorded below.

### Close-confirmation follow-up (build 6)

The user reported quitting after edits without a warning and confirmed that the edits were saved on reopen. That observation is consistent with native autosave, rather than lost document changes. Build 6 opts this app into AppKit’s `NSCloseAlwaysConfirmsChanges` preference at startup, scoped to application defaults, to request the native keep-changes confirmation for modified documents on close and quit. The existing editor, undo ownership, serialization, and autosave lifecycle remain unchanged. Explicit Save allows clean documents to close directly.

The same independent tester passed sequential ad-hoc signed Debug and Release builds (exit 0), Xcode 26.6 (17F113), macOS SDK 26.5, arm64, Swift 6. `git diff --check` passed; no applicable tests exist. Logs, exact commands, measurements, and the report are retained under `Temp/UnsavedEditFix/`. The Release app is still 2,012 KiB (2,060,288 bytes) on disk. Using the original measurement definitions, production Swift is now 13 files, 874 physical lines, 784 nonblank lines, and 33,211 bytes: +7 lines, +6 nonblank lines, and +267 bytes from build 5; app size and file count are unchanged.

Build 6 was installed at `/Applications/NanoMD.app`; its executable matched the validated Release and strict signature verification passed. Both prior instances terminated normally. Build 5 is recoverable under `Temp/UnsavedEditFix/PreviousBuild5/NanoMD.app`. Only NanoMD registrations were refreshed; the Markdown default remained TextEdit. No tests or visual testing were added during that change. The dialog, cancel, explicit-save, and multi-document quit paths were subsequently verified in build 7.

### Focused local UI validation (0.1.0, build 7)

On October 14, 2026, the Apple Development-signed arm64 Release from `main` at `76dfc6f` passed the six requested local checks on macOS 26.6.2 using Xcode 26.6:

- Reader: `.md`/`.markdown`, representative formatting, table alignment/wrapping/empty cells at two window widths, and copying across cells.
- Read/Edit: initial modes, retained editor selection/scroll, and no hidden-editor mutation in Read.
- Editing and undo: typing, Unicode paste, deletion, undo/redo after mode switches with editor focus, and independent document histories.
- Saving: create, save, close, and reopen with exact source bytes, including decomposed Unicode and trailing whitespace.
- Close and quit: save, discard, and cancel on modified documents, including a two-document quit review.
- File preservation: unchanged bytes and modification times for no-edit fixtures, invalid UTF-8 rejection, inserted CRLF line breaks, and new-document LF without BOM.

The reader's selection and scroll reset on returning to Read. Switching to Edit requires a click or Tab to focus the editor. Undo/redo shortcuts were inactive with reader/window focus; the editor's history survived mode switches. These are observed limitations, not claims of retained reader state or undo availability in every focus context.

The build blocker was corrected by using absolute build/cache paths; no source or configuration changes were needed. The exact bundle was launched from `Temp/UIValidation/AbsoluteBuild/Build/Products/Release/NanoMD.app`, and strict signature verification passed. The installed `/Applications` copy was not replaced or tested. Local evidence is retained in `Temp/UIValidation/REPORT.md` and its associated logs and fixtures; it is intentionally excluded from Git.

This focused pass did not verify the unchecked editor cases above, browser navigation, other hardware/macOS versions, accessibility, profiling, stress cases, or the downloaded Developer ID/notarized package and its Gatekeeper first launch. No source edits or automated tests were introduced.

## 4a. Appearance themes (0.1.0, build 9)

Implemented on `feature/app-themes` in the current checkout: exactly Nano Dark and Linen Light, with a single native Settings Appearance picker (Command-comma), app-wide persistence, and Linen Light as the missing/invalid-preference default. Both share native monospaced typography, layout, themed selection/caret colors, content filename header/footer, and padded one-point code-block borders. No dependencies, tests, or Markdown features were added. The reader retains only current semantic content for restyling, with separate source/render revisions; the native editor remains mounted and its source/undo path is unchanged. Foreground styling defers during input-method composition.

The same independent tester (`gpt-6-luna`, low reasoning, fresh context) performed baseline and final unsigned Debug/Release builds with code edits paused. Both configurations passed before and after on macOS 26.6.2 (25G83), Xcode 26.6 (17F113), arm64, Swift 6, using `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`. The existing Xcode scheme and incidental project-file formatting changes were preserved. Initial sandboxed builds could not access Xcode's shared caches; normal permission escalation allowed successful builds without weakening project settings. No applicable existing test targets exist. Final `git diff --check` and focused code review passed. The only final build warning was skipped App Intents metadata extraction because the app does not link that framework.

| Metric | Before (build 8) | After (build 9) | Change |
| --- | ---: | ---: | ---: |
| Release app regular-file bytes | 3,641,096 | 3,793,128 | +152,032 (+4.18%) |
| Production Swift files | 13 | 14 | +1 |
| Physical Swift lines | 910 | 1,111 | +201 |
| Nonblank Swift lines | 818 | 1,001 | +183 |
| Production Swift bytes | 34,586 | 42,378 | +7,792 |

App size sums regular, nonsymlink files throughout the complete unsigned Release bundle; it is uncompressed size, not download size. Source counts include production `NanoMD/**/*.swift` only, excluding dependencies and generated output. Physical lines use byte `splitlines()`; nonblank lines use UTF-8 text `splitlines()` with `strip()`; bytes use actual file lengths. Identical measurement definitions and build settings were used before and after. The extra source is the concrete palette/Settings UI, header/footer, native text styling, and retained semantic restyling. App growth reflects the executable and version metadata, with no new bundled assets or dependencies. No performance benchmarks were performed.

Evidence is retained under ignored `Temp/AppThemes/`: baseline/final reports, Debug/Release logs, measurement scripts, and JSON results. Builds used `-derivedDataPath "$PWD/Temp/AppThemes/DerivedData" -clonedSourcePackagesDirPath "$PWD/Temp/SourcePackages" -packageCachePath "$PWD/Temp/PackageCache"`, with the other README build arguments unchanged. Website app-size/version fields were refreshed from that exact Release bundle. No installed app replacement, release publication, merge, or deployment was performed.

On the maintainer's subsequent installation request, a locally signed arm64 Release of build 9 passed compilation and strict signature verification and was installed at `/Applications/NanoMD.app`. The prior build 6 exited through normal termination and is preserved at `Temp/AppThemes/Install/PreviousInstalled/NanoMD.app`. Installed and built executable SHA-256 values match; stale nano.md build/backup registrations were removed, and macOS resolves the bundle identifier to the installed path. Installation evidence is under `Temp/AppThemes/Install/`. The signed app measures 3,787,204 regular-file bytes, and website metadata was refreshed from it; the unsigned before/after comparison above remains unchanged. The installed app was not launched or visually tested. No publication, merge, or deployment occurred.

Visual and runtime validation of the appearance implementation remains pending. Prior UI checks do not establish acceptance of these themes. Build 10's controls below replace the original Settings picker. Remaining manual checks:

- [ ] Open both themes in Read/Edit, resize, and check typography, contrast, native controls, selection/caret, filename/Untitled metadata, and loading/source fallback.
- [ ] Use View > Appearance and the right-side toolbar menu; check centered Read/Edit placement, System/Light/Dark selection, following macOS changes in System, persistence after relaunch, immediate changes in multiple open windows, and inheritance in new windows.
- [ ] Check fenced and indented code borders/padding/whitespace, inline code without borders, and continuous selection across blocks.
- [ ] Check tables (headers, alignment, empty cells, wrapping, selection), quotes, lists, and links in both themes.
- [ ] Switch while editing and composing input; check source, dirty state, focus, selection, scrolling, and native undo/redo. Switch while reading/loading to check position and stale-result behavior.

### Appearance controls follow-up (0.1.0, build 10)

At the maintainer's request, appearance now offers System, Light, and Dark in View > Appearance and the right-side toolbar menu; Read/Edit uses the native toolbar's center placement. The single-setting Settings window was removed. System is the missing/invalid-preference default and follows macOS through SwiftUI's effective color scheme. Light and Dark retain the existing Linen Light and Nano Dark palettes. Previously saved explicit choices map to Light/Dark, preserving the existing preference. Palette resolution still updates existing native text views and current semantic reader content without changing source or adding hidden preview parsing.

The same independent tester passed unsigned arm64 Debug and Release builds with the identical build 9 settings and measurement definitions, plus `git diff --check` and focused code review. No applicable test targets exist, and no tests were added. The only build warning was skipped App Intents metadata extraction. Evidence is under `Temp/AppThemes/AppearanceModes/`; the original build 9 records remain preserved. This validation did not launch the app or verify toolbar layout, menu interaction, System-following behavior, preference migration, composition, or undo at runtime.

| Metric | Build 9 | Build 10 | Change |
| --- | ---: | ---: | ---: |
| Unsigned Release app regular-file bytes | 3,793,128 | 3,802,361 | +9,233 |
| Production Swift files | 14 | 14 | 0 |
| Physical Swift lines | 1,111 | 1,152 | +41 |
| Nonblank Swift lines | 1,001 | 1,039 | +38 |
| Production Swift bytes | 42,378 | 43,550 | +1,172 |

The added source is the concrete appearance-mode mapping and shared picker/menu/toolbar wiring. The two palettes and existing document serialization, editor, parser, and reader internals remain unchanged from build 9. No new dependency or bundled asset was added.

The locally signed arm64 Release also passed compilation and strict signature verification and was installed at `/Applications/NanoMD.app`. Build 9 exited normally and is retained at `Temp/AppThemes/AppearanceModes/Install/PreviousInstalled/NanoMD.app`. Installed and built executable SHA-256 values match; macOS resolves the bundle identifier to the installed path, with stale nano.md build/backup registrations removed. The signed app measures 3,812,789 regular-file bytes; website metadata was refreshed from that installed bundle. Signed build and installation evidence is under `Temp/AppThemes/AppearanceModes/Install/`. No app launch, visual/runtime testing, release publication, merge, or deployment occurred during this follow-up.

### Front-matter integration (0.1.0, build 12)

Build 12 combines beta 3's SKILL.md front matter with the System/Light/Dark appearance implementation. Metadata panels use the selected palette's code-block background, one-point border, primary label, and secondary literal text, with compact monospaced typography. The existing semantic-content restyling path updates the panel alongside the document body; parsing and source serialization are unchanged.

Unsigned Debug and Release builds passed with Xcode 26.6, including an arm64 Release matching the published distribution's architecture. `git diff --check` and focused integration review passed. The only build warning was skipped App Intents metadata extraction. Website source metadata was refreshed from the exact unsigned arm64 Release bundle: 3,808,153 regular-file bytes, version 0.1.0 build 12. Beta 3 download links remain in place. Logs and build output are under ignored `Temp/AppThemes/MetadataIntegration/`. No tests were introduced. Visual/runtime verification of the combined themes and metadata panel remains pending; earlier beta 3 checks do not validate this styling. The installed app and live website were not updated.

At the maintainer's installation request on October 17, 2026, the locally Apple Development-signed arm64 Release of build 12 passed compilation and strict signature verification and was installed at `/Applications/NanoMD.app`. All three older running copies exited through normal termination. The prior installed build 10 is preserved under `Temp/AppThemes/MetadataIntegration/Install/PreviousInstalled/NanoMD.app`. Installed and built executable SHA-256 values match. Stale nano.md build/backup registrations were removed, and macOS resolves the bundle identifier to the installed Applications copy. The signed bundle contains 3,817,589 regular-file bytes; website source metadata was refreshed from it. Installation evidence is retained under `Temp/AppThemes/MetadataIntegration/Install/`. The new app was not launched or visually tested, and no release or website deployment occurred.

### Three-way appearance control (0.1.0, build 13)

The document toolbar's Appearance dropdown is now a native segmented System / Light / Dark picker. It uses the same app-wide preference and existing two palettes; View > Appearance remains available. The existing centered Read/Edit icons were preserved. No parser, editor, persistence, dependency, or test changes were introduced.

The same independent tester passed unsigned arm64 Debug and locally signed arm64 Release builds, metadata checks, `git diff --check`, and focused code review. Strict signature verification passed with normal keychain access; the sandboxed verification initially could not establish certificate trust. No applicable test targets exist. Build 13 was installed at `/Applications/NanoMD.app`, with the previous installed build 12 retained at `Temp/AppThemes/AppearanceToggle/PreviousInstalled/NanoMD.app`. Installed and built executable hashes match, and macOS resolves nano.md to the installed copy. Website metadata was refreshed from the signed Release (3,832,165 regular-file bytes). Evidence and logs are under `Temp/AppThemes/AppearanceToggle/`.

At the maintainer's request, the installed app was opened with a disposable README copy, `Temp/AppThemes/AppearanceToggle/Preview.md`, to show the control. Opening the preview does not establish visual or runtime verification: no rendered UI was inspected, screenshots taken, or controls exercised. No release, merge, or website deployment occurred.

### Hidden native window title (0.1.0, build 14)

The native toolbar's filename title is hidden using `toolbar(removing: .title)`. The document header/footer still show its filename, and document metadata and native window controls retain their existing ownership. Independent unsigned arm64 Debug and signed arm64 Release builds, strict signature verification, focused review, and `git diff --check` passed. No applicable test targets exist. Build 14 was installed and reopened with the existing disposable preview; build 13 is preserved under `Temp/AppThemes/HiddenWindowTitle/PreviousInstalled/NanoMD.app`. Installed and built executable hashes match, and macOS resolves nano.md to the installed copy. Website metadata was refreshed from the signed Release (3,835,845 regular-file bytes). Logs are under `Temp/AppThemes/HiddenWindowTitle/`. No visual testing, publication, merge, or deployment occurred.

### System appearance synchronization (Debug preview)

Returning from explicit Dark to System could lighten the native toolbar while leaving the document dark because SwiftUI's inherited color scheme retained the earlier window override. System palette resolution now uses an app-owned observation of `NSApplication.effectiveAppearance`, independent of per-window overrides. Main-actor updates propagate the current macOS scheme to each document without replacing native editor/reader views. The manually chosen Dark / Light / System order is preserved.

An independent ad-hoc signed arm64 Debug build, signature verification, `git diff --check`, and focused review passed. No tests were added and no applicable test targets exist. The corrected Debug preview was reopened for the maintainer to try; no rendered UI was inspected or controls exercised by the agents. Logs are under `Temp/DebugPreview/SystemAppearanceFix/`. No Release build, installed app replacement, website metadata refresh, merge, or deployment was performed for this preview iteration.

### Theme consolidation (0.1.0, build 15)

Build 15 consolidates the segmented Dark / Light / System selector, Read/Edit icons, hidden native filename title, and System appearance synchronization. Independent unsigned arm64 Debug and Release builds and `git diff --check` passed for the final source. No applicable test targets exist; no tests or visual checks were added. The only build warning was skipped App Intents metadata extraction. Website source metadata was refreshed from the exact unsigned Release bundle (3,858,301 regular-file bytes). Logs and the validation report are under `Temp/AppThemes/MergeValidation/`. The installed app and live website were not replaced or deployed during this consolidation; runtime acceptance remains separate from these build/code checks.

## 5. Final polish and performance

- [ ] Measure parsing, layout, memory, and open-to-first-content latency using representative documents.
- [ ] Validate or adjust size limits and set performance budgets from those measurements.
- [ ] Measure typing and preview responsiveness before considering incremental parsing.

Start this milestone after the app's intended functionality is in place. Until then, use builds and focused smoke checks; address performance earlier only when a concrete issue blocks normal use.
