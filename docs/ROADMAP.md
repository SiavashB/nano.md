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

- [ ] Choose and add the project license; retain any required dependency notices.
- [ ] Decide and validate the minimum supported macOS and Xcode versions.
- [ ] Share the Xcode scheme and verify a build from a fresh checkout without personal settings.
- [ ] Remove already-tracked `xcuserdata` from Git while preserving the owner's local settings; ignore rules do not untrack files.
- [ ] Make contributor builds independent of the original developer's signing team.
- [ ] Add build CI using a runner with the required Xcode version; do not publish a passing badge before CI is working.
- [ ] Add screenshots of the implemented app, accurate feature/limitation notes, and release instructions.
- [ ] Verify signing, sandbox behavior, and notarization if distributing an app binary.

Automated test coverage is a separate maintainer-requested task. No tests or test targets are introduced without an explicit request. Builds, focused manual verification, and honest reporting remain required.

## 4. Source editing

- [ ] Add editing controls over the same document source and retain the existing preview path.
- [ ] Enable writes intentionally across scene, document role, serialization, and entitlements.
- [ ] Implement and verify undo/redo, dirty state, save/autosave, and failure recovery.
- [ ] Verify no-op round trips preserve bytes, encoding policy, BOM, whitespace, and line endings.
- [ ] Define and verify external-change conflict handling and crash recovery.

Completion: edits, undo, reopening, failed saves, and external changes preserve user work. Add richer Markdown features only as separately scoped work.

## 5. Final polish and performance

- [ ] Measure parsing, layout, memory, and open-to-first-content latency using representative documents.
- [ ] Validate or adjust size limits and set performance budgets from those measurements.
- [ ] Measure typing and preview responsiveness before considering incremental parsing.

Start this milestone after the app's intended functionality is in place. Until then, use builds and focused smoke checks; address performance earlier only when a concrete issue blocks normal use.
