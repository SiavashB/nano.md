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

## 3. Public release preparation

- [x] Choose and add the project license; retain any required dependency notices.
- [ ] Decide and validate the minimum supported macOS and Xcode versions.
- [x] Share the Xcode scheme and verify a build from a fresh checkout without personal settings.
- [x] Remove already-tracked `xcuserdata` from Git while preserving the owner's local settings; ignore rules do not untrack files.
- [x] Make contributor builds independent of the original developer's signing team.
- [x] Add build CI using a runner with the required Xcode version; do not publish a passing badge before CI is working.
- [ ] Add screenshots of the implemented app, accurate feature/limitation notes, and release instructions.
- [ ] Verify signing, sandbox behavior, and notarization if distributing an app binary.

Automated test coverage is a separate maintainer-requested task. No tests or test targets are introduced without an explicit request. Builds, focused manual verification, and honest reporting remain required.

The initial release process is defined in [Releasing](RELEASING.md): build-only CI on pull requests and `main`, local AI-assisted functional checks, and signed/notarized draft releases from version tags. A shared Xcode scheme is included. [The first GitHub build](https://github.com/SiavashB/nano.md/actions/runs/38302783956) passed unsigned Debug and Release on a clean macOS runner with Xcode 26.6. Local independent build and workflow validation also passed; app/source size was unchanged. Signing credentials are now configured. The [first beta release run](https://github.com/SiavashB/nano.md/actions/runs/38635655132) passed certificate import and the Developer ID-signed Release build on October 14, 2026. Apple processed the notarization submission but returned `Invalid` because the executable requested the debugging entitlement `com.apple.security.get-task-allow`. Draft creation and packaged-app verification were not reached.

The first beta attempt used version 0.1.0, build 7, tagged `v0.1.0-beta.1` at `76dfc6f`. The MIT license and dependency notices are bundled byte for byte. Personal Xcode state is no longer tracked, and signing uses an optional ignored `Config/Local.xcconfig`. Independent unsigned arm64 Debug and Release builds, workflow/project lint, and shared-scheme parsing passed with Xcode 26.6. Under the same measurement method, regular-file Release bundle bytes increased from 3,640,373 to 3,641,448 (+1,075 bytes for the license and version metadata). Production Swift remains 13 files, 910 physical lines, 818 nonblank lines, and 34,586 bytes. Logs and measurements are under `Temp/FirstRelease/`. Focused local UI checks passed on October 14, 2026, as recorded below. Developer ID signing passed in CI; notarization and downloaded distribution verification remain incomplete. Independent release verification evidence is under `Temp/FirstRelease/SigningVerification/`. Build 8 is prepared for `v0.1.0-beta.2`: the distribution workflow uses explicit sandbox/file-access entitlements, disables injected debugger access, checks the signed permissions, and retains detailed rejection logs. App source and dependencies are unchanged. Independent unsigned Debug/Release and corrected Developer ID-signed Release builds passed, including actual sandbox/file-access entitlements, absence of debugger access, hardened runtime, and strict signature verification. The unsigned arm64 Release measures 3,643,352 regular-file bytes versus 3,641,448 before this change (+1,904 bytes, 0.0523%); the local Developer ID-signed bundle measures 3,653,684 bytes before notarization/stapling. Source remains 13 files and 34,586 bytes. Evidence is under `Temp/FirstRelease/NotarizationFix/`. A fresh CI notarization run remains pending.

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

## 5. Final polish and performance

- [ ] Measure parsing, layout, memory, and open-to-first-content latency using representative documents.
- [ ] Validate or adjust size limits and set performance budgets from those measurements.
- [ ] Measure typing and preview responsiveness before considering incremental parsing.

Start this milestone after the app's intended functionality is in place. Until then, use builds and focused smoke checks; address performance earlier only when a concrete issue blocks normal use.
