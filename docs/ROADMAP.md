# Roadmap

nano.md is in public beta. The reader, source editor, front-matter panels, appearance controls, and signed distribution are implemented. See the [README](../README.md) for current features and limitations, and [GitHub Releases](https://github.com/SiavashB/nano.md/releases) for release history.

The priorities below track remaining work. An unchecked item is unverified or incomplete, even when its implementation already exists. Validation procedures are in [Contributing](../CONTRIBUTING.md#validation).

<a id="4-source-editing"></a>

## 1. Document reliability

- [ ] Verify input-method composition, including mode/theme switches and accepted document reloads.
- [ ] Verify autosave without explicit Save and retention of edits after a failed save.
- [ ] Verify BOM retention after editing and edits to files with mixed line endings.
- [ ] Verify external-change conflicts with unsaved edits, accepted reverts, stale undo removal, and crash recovery.
- [ ] Exercise rapid source replacement and cancellation to confirm that obsolete results cannot replace current content.

Acceptance: editing, undo, saving, and external changes preserve the user's source and unsaved work. Use disposable files and compare exact bytes where preservation is expected.

<a id="macos-15-deployment-target-010-build-18"></a>

## 2. Minimum OS compatibility

The deployment target is macOS 15.0 on Apple Silicon; the build toolchain is Xcode 26.6 with Swift 6. Compilation checks API availability. Runtime compatibility on macOS 15 remains unverified.

- [ ] On macOS 15, check the downloaded release's launch, reading/tables, editing/undo, saving/reopening, close/quit prompts, themes, toolbar, and footer controls.
- [ ] Record the tested OS and hardware with the release's verification results.

<a id="footer-shortcuts-010-beta-5-build-20"></a>
<a id="4a-appearance-themes-010-build-9"></a>

## 3. Interaction, appearance, and accessibility

Basic Control-R behavior passed focused beta 5 checks. Broader control and appearance acceptance remains open on both macOS 15 and the development OS.

- [ ] Exercise Control-R rapidly and while held, with editor, reader, source fallback, toolbar, and footer focus. Confirm one action per press, no inserted control characters, and no unintended text commands.
- [ ] Compare keyboard, footer, and View menu activation and labels. Confirm Control-G does not cycle appearance.
- [ ] Check two windows: mode changes affect only the active document, appearance updates both, and the mode menu disables without an active document.
- [ ] Check System following macOS changes, persistence after relaunch, inheritance in new windows, and legacy/invalid preference values.
- [ ] Switch modes and themes while typing, selecting, scrolling, composing input, or loading content. Check exact source, dirty state, editor selection/scroll/undo retention, and reader position during restyling.
- [ ] Review both themes in Read/Edit at narrow and wide widths, including long filenames, Untitled documents, loading/source fallback, contrast, selection/caret, control placement, and complete footer labels.
- [ ] Check code-block borders, padding, and whitespace; inline code; front matter; table headers, alignment, empty cells, and wrapping; quotes, lists, and links. Confirm continuous selection and copying.
- [ ] Audit keyboard access, focus order, VoiceOver labels, and reading order.

Known limitations remain: returning to Read resets reader selection and scroll; switching to Edit requires a click or Tab to focus the editor, and undo/redo requires editor focus.

## 4. Release presentation and deployment

- [ ] Configure the website workflow's Cloudflare credential and verify a release-triggered deployment. Local deployment is available in the meantime.

Keep the README, website, and release notes consistent with the shipped package. Follow the [release checklist](RELEASING.md#each-release) for every release; do not infer compatibility or functional verification from a successful build.

## 5. Performance

Performance profiling follows functional work unless a concrete responsiveness problem blocks normal use.

- [ ] Measure parsing, main-thread layout, memory, and time to first content with 10 KB, 100 KB, and 1 MB documents, including long lines, deep nesting, and code-heavy content.
- [ ] Check memory release after document closure and typing/preview responsiveness before considering incremental parsing.
- [ ] Use those measurements to validate the 1 MiB, 50,000-node, and 64-level formatting limits and establish performance budgets.

Record the Release configuration, toolchain, hardware, OS, corpus, and method. Current limits are conservative safeguards, not measured performance guarantees.

<a id="focused-local-ui-validation-010-build-7"></a>

## Verification baseline

| Version checked | Established scope |
| --- | --- |
| Build 7, local signed Release on macOS 26.6.2 | Reader/table selection; Read/Edit state and independent undo histories; create/save/reopen; close/quit save, discard, and cancel; no-edit byte/modification-time preservation; invalid UTF-8 rejection; CRLF insertion and new-document LF. |
| [Beta 5, build 20](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.5), downloaded package | Signature, notarization, Gatekeeper, checksum, entitlements, metadata, and bundled resources; opening, Control-R, typing, undo/redo, save/reopen, exercised byte-preservation cases, and feedback browser handoff. |

Earlier checks do not establish acceptance of later UI changes. Beta 5's functional checks used accessibility APIs without visual testing. Neither baseline resolves the unchecked cases above or establishes macOS 15 compatibility. CI compiles Debug and Release; the repository has no automated test targets.
