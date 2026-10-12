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

Pipe-table rendering was added after the original reader smoke check, with native cells, header styling, borders, column alignment, and inline formatting. User-provided screenshots confirmed visible alignment, inline formatting, text wrapping, empty cells, and header-only tables, and exposed border gaps and tight spacing after tables. Border and spacing adjustments compile in Debug and locally signed Release; build 4 is installed at `/Applications/NanoMD.app`. The installed binary matches the Release build, and macOS resolves NanoMD to that location. The adjusted layout awaits user confirmation; selection and copying across table cells remain unverified. No tests were added.

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

The initial release process is defined in [Releasing](RELEASING.md): build-only CI on pull requests and `main`, local AI-assisted functional checks, and signed/notarized draft releases from version tags. A shared Xcode scheme is included. [The first GitHub build](https://github.com/SiavashB/nano.md/actions/runs/38302783956) passed unsigned Debug and Release on a clean macOS runner with Xcode 26.6. Local independent build and workflow validation also passed; app/source size was unchanged. Signing credentials are not configured yet, so the signed release workflow remains unverified.

The first beta candidate is version 0.1.0, build 7, intended for `v0.1.0-beta.1`. The MIT license and dependency notices are bundled byte for byte. Personal Xcode state is no longer tracked, and signing uses an optional ignored `Config/Local.xcconfig`. Independent unsigned arm64 Debug and Release builds, workflow/project lint, and shared-scheme parsing passed with Xcode 26.6. Under the same measurement method, regular-file Release bundle bytes increased from 3,640,373 to 3,641,448 (+1,075 bytes for the license and version metadata). Production Swift remains 13 files, 910 physical lines, 818 nonblank lines, and 34,586 bytes. Logs and measurements are under `Temp/FirstRelease/`. Local functional checks, Developer ID signing, and notarization remain pending; no release tag has been pushed.

## 4. Source editing

- [x] Add Read/Edit controls over the same document source and retain the existing reader path.
- [x] Enable writes intentionally across scene, document role, serialization, and entitlements.
- [x] Implement persistent native source editing and one document-scoped native undo/redo path.
- [x] Preserve UTF-8/BOM metadata and source representation in the serialization implementation.
- [x] Delegate saving, autosaving, errors, reverts, and conflict acceptance to the system lifecycle.
- [ ] Verify selection/scroll retention, undo/redo across modes, document isolation, and input-method composition at runtime.
- [ ] Verify dirty state, save/reopen, autosave, and failed-save retention at runtime.
- [ ] Verify no-edit byte preservation, BOM, whitespace, Unicode representation, and line-ending behavior at runtime.
- [ ] Verify external-change conflicts with unsaved edits, reverts, and crash recovery at runtime.

Implementation and build verification are distinct from runtime acceptance. The first editor retains a native text view across modes, publishes literal source, and clears stale undo actions on accepted system reloads. No hidden preview parses during typing. The reader's parser, tables, fallback, limits, and resource policy remain unchanged. No dependencies, targets, processes, services, database, persistent cache, tests, or visual testing were added. Build number is 5.

Completion of runtime acceptance: edits, undo, reopening, failed saves, and external changes preserve user work. These checks remain open until separately authorized and exercised. Richer Markdown features remain separately scoped.

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

Implementation review covered source/BOM preservation, exact representation comparisons, binding feedback suppression, native undo ownership and lifetime, document isolation, marked-text reload deferral, and save-error retention through system ownership. Runtime checks listed above remain unverified regardless of compilation and source review.

### Close-confirmation follow-up (build 6)

The user reported quitting after edits without a warning and confirmed that the edits were saved on reopen. That observation is consistent with native autosave, rather than lost document changes. Build 6 opts this app into AppKit’s `NSCloseAlwaysConfirmsChanges` preference at startup, scoped to application defaults, to request the native keep-changes confirmation for modified documents on close and quit. The existing editor, undo ownership, serialization, and autosave lifecycle remain unchanged. Explicit Save allows clean documents to close directly.

The same independent tester passed sequential ad-hoc signed Debug and Release builds (exit 0), Xcode 26.6 (17F113), macOS SDK 26.5, arm64, Swift 6. `git diff --check` passed; no applicable tests exist. Logs, exact commands, measurements, and the report are retained under `Temp/UnsavedEditFix/`. The Release app is still 2,012 KiB (2,060,288 bytes) on disk. Using the original measurement definitions, production Swift is now 13 files, 874 physical lines, 784 nonblank lines, and 33,211 bytes: +7 lines, +6 nonblank lines, and +267 bytes from build 5; app size and file count are unchanged.

Build 6 is now installed at `/Applications/NanoMD.app`; its executable matches the validated Release and strict signature verification passed. Both prior instances terminated normally. Build 5 is recoverable under `Temp/UnsavedEditFix/PreviousBuild5/NanoMD.app`. Only NanoMD registrations were refreshed; the Markdown default remains TextEdit. The dialog, cancel, explicit-save, and multi-document quit paths remain unverified at runtime; no tests or visual testing were added.

## 5. Final polish and performance

- [ ] Measure parsing, layout, memory, and open-to-first-content latency using representative documents.
- [ ] Validate or adjust size limits and set performance budgets from those measurements.
- [ ] Measure typing and preview responsiveness before considering incremental parsing.

Start this milestone after the app's intended functionality is in place. Until then, use builds and focused smoke checks; address performance earlier only when a concrete issue blocks normal use.
