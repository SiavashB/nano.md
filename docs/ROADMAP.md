# Roadmap

nano.md is in public beta. The reader, source editor, front-matter panels, appearance controls, and signed distribution are implemented. See the [README](../README.md) for current features and limitations, and [GitHub Releases](https://github.com/SiavashB/nano.md/releases) for release history.

The priorities below link to open tracking issues, which hold the detailed acceptance checklists and results. Verification tasks identify untested behavior, not confirmed defects. Validation procedures are in [Contributing](../CONTRIBUTING.md#validation).

<a id="4-source-editing"></a>

## 1. Document reliability

Remaining checks cover input methods, autosave and failed saves, BOM/mixed line endings, external conflicts, reverts, recovery, and obsolete rendering results.

Track acceptance in [#11: Verify document preservation, reloads, and recovery](https://github.com/SiavashB/nano.md/issues/11).

Acceptance: editing, undo, saving, and external changes preserve the user's source and unsaved work. Use disposable files and compare exact bytes where preservation is expected.

<a id="macos-15-deployment-target-010-build-18"></a>

## 2. Minimum OS compatibility

The deployment target is macOS 15.0 on Apple Silicon; the build toolchain is Xcode 26.6 with Swift 6. Compilation checks API availability. Runtime compatibility on macOS 15 remains unverified.

Check the exact downloaded package on macOS 15 and record the release/build, OS, hardware, and outcomes.

Track acceptance in [#12: Verify the downloaded release on macOS 15](https://github.com/SiavashB/nano.md/issues/12).

<a id="footer-shortcuts-010-beta-5-build-20"></a>
<a id="4a-appearance-themes-010-build-9"></a>

## 3. Interaction, appearance, and accessibility

Basic Control-R behavior passed focused beta 5 checks. Broader control and appearance acceptance remains open on both macOS 15 and the development OS.

Complete checks for shortcut focus/repetition, independent windows, appearance persistence and System mode, state retention, layout, keyboard access, and VoiceOver. Reader-to-editor navigation also needs runtime checks for selection, scroll alignment, automatic editor focus, and force-click on supported hardware, including links, tables, Unicode, and source fallback.

Track acceptance in [#13: Complete keyboard, appearance, and accessibility acceptance checks](https://github.com/SiavashB/nano.md/issues/13).

Known limitations remain: returning to Read resets reader selection and scroll; undo/redo requires editor focus. Source navigation is approximate for generated or unmatched rendered text and when reader/editor layouts differ.

## 4. Release presentation and deployment

The website workflow's Cloudflare credential is configured, and the release-triggered deployment has passed. Local deployment remains available.

Deployment verification is recorded in [#14: Configure and verify release-triggered website deployment](https://github.com/SiavashB/nano.md/issues/14).

Keep the README, website, and release notes consistent with the shipped package. Follow the [release checklist](RELEASING.md#each-release) for every release; do not infer compatibility or functional verification from a successful build.

## 5. Performance

Performance profiling follows functional work unless a concrete responsiveness problem blocks normal use.

Measure parsing, layout, memory, time to first content, and editing responsiveness with representative documents; use the results to validate formatting limits.

Track acceptance in [#15: Establish a Release performance baseline and formatting limits](https://github.com/SiavashB/nano.md/issues/15).

Record the Release configuration, toolchain, hardware, OS, corpus, and method. Current limits are conservative safeguards, not measured performance guarantees.

<a id="focused-local-ui-validation-010-build-7"></a>

## Verification baseline

| Version checked | Established scope |
| --- | --- |
| Build 7, local signed Release on macOS 26.6.2 | Reader/table selection; Read/Edit state and independent undo histories; create/save/reopen; close/quit save, discard, and cancel; no-edit byte/modification-time preservation; invalid UTF-8 rejection; CRLF insertion and new-document LF. |
| [Beta 5, build 20](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.5), downloaded package | Signature, notarization, Gatekeeper, checksum, entitlements, metadata, and bundled resources; opening, Control-R, typing, undo/redo, save/reopen, exercised byte-preservation cases, and feedback browser handoff. |

Earlier checks do not establish acceptance of later UI changes. Beta 5's functional checks used accessibility APIs without visual testing. Neither baseline resolves the open checks in the linked issues or establishes macOS 15 compatibility. CI compiles Debug and Release; the repository has no automated test targets.
