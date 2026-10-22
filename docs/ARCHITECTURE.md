# Architecture

nano.md is a native macOS Markdown reader and source editor built with SwiftUI and AppKit. Existing files open in Read mode; new documents start in Edit. This document describes the implemented design and its tradeoffs. The [roadmap](ROADMAP.md) tracks verification gaps and planned work.

## Design decisions

| Area | Decision | Reason and tradeoff |
| --- | --- | --- |
| Application | One macOS app target | Small build surface; folder boundaries are enforced through review. |
| Documents | Value-type `FileDocument` in an editing `DocumentGroup` | System ownership of saving, autosave, undo integration, and external changes. |
| Parsing | Swift Markdown behind a concrete parser boundary | Reuses a maintained grammar at the cost of a Swift/C dependency and additional binary size. |
| Presentation | Persistent native editor and a reader mounted only in Read mode | Retains editor state without parsing a hidden preview; reader state resets when remounted. |
| Rendering | One attributed-text view | Continuous native selection and table layout without an embedded browser. |
| Persistence | Original Markdown source and files | No rendered-content serialization, database, or sidecar format. |

Accounts, synchronization, plugins, and a global document store are outside the current scope. Introduce abstractions or separate packages only when a concrete responsibility requires them.

## Structure and ownership

All app code lives in the synchronized `NanoMD/` Xcode folder. The separate `NanoMDTests/` target imports production code for regression tests and is not included in app releases. Documentation and development tools stay outside the app folder so they do not become app resources.

| Directory | Responsibility |
| --- | --- |
| `App/` | Scenes, commands, shared appearance preference, and system appearance observation |
| `Documents/` | Source text, encoding metadata, content types, and the file read/write contract |
| `Markdown/` | Parser actor and immutable, `Sendable` semantic content |
| `Features/Document/` | Per-window Read/Edit mode, controls, and composition |
| `Features/Editor/` | Native editing, input methods, selection, scrolling, binding synchronization, and undo |
| `Features/Reader/` | Loading state, attributed-text rendering, selection, source fallback, and link policy |
| `Resources/` | Localized app naming, About content, and dependency notices |

`DocumentView` gives the editor a document binding and the reader an immutable source snapshot. The reader has no file adapter or persistence responsibility. `Markdown` depends on the parser package and Foundation, with no AppKit, SwiftUI, file, or network access. Parser-specific types never cross that boundary.

`NativeTextViewConfiguration` shares scroll and text-container geometry only. Each view adapter owns its native views, styling, and lifecycle. The editor and source fallback use TextKit 2; the formatted reader uses TextKit 1 for native tables.

## Document contract

`NanoMDDocument.source` is authoritative. Loading accepts regular files containing valid UTF-8, with or without a BOM, and rejects invalid bytes with an actionable error. Whitespace, Unicode representation, line endings, and trailing newlines are preserved.

Saving constructs a `FileWrapper` directly from `source.utf8`, prepending the loaded BOM when present. New documents use UTF-8 without a BOM and default to LF. The first existing CRLF, CR, or LF determines inserted line breaks; pasted text retains its own line endings. Derived parser or rendering output never reaches serialization.

The `FileDocument` read/write callbacks delegate to internal `FileWrapper` operations, allowing byte-level tests to exercise the same decoding and serialization used by the system adapter without constructing SwiftUI-owned configuration values.

The app imports the Markdown content type and registers `.md` and `.markdown`. `DocumentGroup` owns file access and supplies document bindings and filename metadata. Views do not reopen document URLs, add file watchers, or implement conflict arbitration. See Apple's [document ownership API](https://developer.apple.com/documentation/swiftui/documentgroup).

## Source editing and undo ownership

`MarkdownEditorView` remains mounted while hidden in Read mode, retaining native text storage, selection, scrolling, and undo targets. Before hiding a focused editor, it ends typing coalescing and releases first responder. Mode switches do not write the binding or register undo. Returning to Read creates a new reader from the current source, including unsaved edits.

The plain-text `NSTextView` disables smart quotes/dashes, substitutions, correction/completion, smart spacing, rich content, and automatic link/data detection. Paste uses plain text. Input methods remain under AppKit ownership.

The delegate supplies the document-scoped environment undo manager. NSTextView owns incremental typing undo; the coordinator briefly disables registration while publishing source through the `FileDocument` binding to avoid duplicate whole-document actions. Each window owns its binding and coordinator. Teardown removes actions retaining native editor targets. See [NSTextView's undo delegate](https://developer.apple.com/documentation/appkit/nstextviewdelegate/undomanager(for:)) and [FileDocument undo semantics](https://developer.apple.com/documentation/swiftui/updating-your-document-based-app).

Every system read creates a transient `loadIdentity`. Ordinary edits and saves retain it; accepted reloads and reverts replace it, clearing stale undo even for an identical-byte replacement. Applying a reload waits until marked text ends, suppresses delegate feedback, and compares exact UTF-8 representations before replacing native text. Callbacks from an older load cannot publish over the replacement.

Saves, autosaves, errors, reverts, external conflicts, and recovery belong to the system document lifecycle. App startup sets `NSCloseAlwaysConfirmsChanges` in application defaults to request native keep-changes confirmation on close and quit. The app does not change global defaults or implement a custom confirmation flow. Remaining runtime checks are tracked under [document reliability](ROADMAP.md#1-document-reliability).

## Rendering flow and concurrency

Each reader owns a `ReaderModel` and `MarkdownParser` actor.

1. `ReaderView` starts a source-keyed task whose identity compares exact UTF-8 representations.
2. The parser actor converts the source into immutable blocks and styled runs.
3. The main actor accepts current results and builds AppKit attributed text.
4. The reader presents ready content or selectable source with an explanation when formatting fails.

SwiftUI cancels work when the source changes or the reader disappears. Revision checks reject obsolete results. Cancellation is checked before parsing, during tree conversion, and before returning; the synchronous cmark parse cannot be interrupted mid-call.

Formatting is capped at 1 MiB of source. After parsing, the tree is limited to 50,000 nodes and 64 levels of nesting. These safeguards are not measured performance budgets. An empty document is a valid ready state.

Attributed-text construction stays on the main actor and yields between blocks and table rows. Parsing never runs in view bodies, native view updates, resizing, or theme changes. The reader retains only current semantic content and the latest attributed output, without a historical or cross-document cache.

Loading and restyling have separate tasks and revisions. A theme change does not cancel parsing; accepted content renders with the latest palette. Restyling keeps the ready reader mounted and restores selection and scroll after layout. Switching from Edit to Read remounts the reader and resets those reader-only states.

<a id="initial-rendering-scope"></a>

## Markdown rendering

The [user guide](USAGE.md#markdown-support) lists supported syntax. Tables use `NSTextTable` and paragraph-level `NSTextTableBlock` cells inside the same text view, preserving continuous selection and inline formatting. The reader explicitly selects TextKit 1 and ensures layout before drawing table decorations. This can lay out the full formatted document when layout is pending; it is a performance consideration for the planned profiling work.

Unsupported blocks use the parser's Markdown formatter as a readable literal representation. That derived text is never saved. Images are descriptive placeholders, HTML is literal text, and task markers are noninteractive.

### Front matter

Before parsing Markdown, `MarkdownFrontMatter` recognizes a leading mapping envelope:

- The opening line is exactly `---`; the closing line is exactly `---` or `...`, with no indentation or surrounding whitespace.
- At least one unindented, single-line field has a nonempty plain key containing letters, numbers, hyphens, underscores, or dots, or a single- or double-quoted key.
- Quoted keys may contain spaces and colons. Doubled single quotes and backslash-escaped characters in double quotes are skipped when locating the closing quote. Spaces or tabs may precede the separator colon.
- The separator colon is followed by whitespace or end of line.

Unterminated quotes, trailing double-quoted escapes, and extra characters before the separator do not qualify as fields. The recognizer does not parse YAML values, decode keys, validate escapes or the full header, or support complex/multiline keys. One recognizable field qualifies the envelope; other lines, including malformed YAML, remain literal.

Metadata appears in a selectable, single-cell native table without creating links or headings. Only its derived display line separators are normalized. The body retains its source representation, and Edit and serialization retain the complete original source. Missing closing delimiters or headers without a qualifying field remain ordinary Markdown.

## Appearance and commands

`AppTheme` supplies the Nano Dark and Linen Light palettes to SwiftUI and AppKit. Native text blocks provide code backgrounds, padding, and borders; tables and metadata panels use the same palette. Styling is independent of parsing and serialization.

One app-owned `AppStorage` preference selects Dark, Light, or System across windows. Missing/invalid values use System; legacy `nanoDark` and `linenLight` values map to Dark and Light. Explicit modes override the window color scheme. System follows an app-owned observation of `NSApplication.effectiveAppearance`, avoiding stale per-window SwiftUI overrides.

Theme changes restyle existing native views. Editor foreground and typing attributes defer until marked text ends. The toolbar and View menu share the preference. The native filename title is hidden; the content header uses document URL metadata without reading the file again.

`DocumentCommands` registers Control-R through the native menu. A scene-scoped focused value supplies the active document's action and destination label; the footer calls that same action without a second keyboard registration. Repetition is disabled and the menu item disables without an active document scene.

The public display name `nano.md` is supplied through localized `InfoPlist.strings`. The base display name matches `$(PRODUCT_NAME)` so Finder honors localization. The target, executable, bundle identifier, and `NanoMD.app` filename retain their technical names.

## Content and resource policy

Document content is untrusted. The reader executes no HTML, scripts, commands, or code blocks and loads no local or remote images. The app has no network entitlement or telemetry. Document content and full paths must not be logged.

`ReaderLinkPolicy` permits only HTTP/HTTPS URLs with a host, activated explicitly through `NSWorkspace.open`. Both attributed-link creation and the text-view delegate apply the policy. The delegate consumes rejected events so AppKit cannot navigate by default. Relative links, anchors, and other schemes remain readable but inactive; source views disable automatic link detection.

App-owned feedback links are separate: the footer opens the static feedback page in a browser, and About exposes a fixed email address. The [website documentation](../website/README.md#feedback) describes the feedback options and separate website analytics. These links do not broaden the document URL policy or app permissions.

Future local assets would require user-granted access to those resources; access to one Markdown file does not grant its containing directory. Remote loading requires an explicit product decision.

## Dependencies and build contract

Swift Markdown 0.8.0 and swift-cmark 0.9.0 are recorded in `Package.resolved`. The app does not link the upstream documentation plugin or Argument Parser. Swift Markdown uses Apache 2.0 with the Swift Runtime Library Exception; cmark includes BSD and MIT component notices. Required texts are bundled in [ThirdPartyNotices.txt](../NanoMD/Resources/ThirdPartyNotices.txt), alongside the project's MIT license.

Debug and Release target arm64 and macOS 15.0 with Xcode 26.6 and Swift 6. UI uses the project's main-actor default; document adapters and semantic values declare their isolation explicitly. Sandboxing and hardened runtime remain enabled.

The bundle records `NanoMDBuildConfiguration`; size tooling checks Release configuration and arm64 architecture. Comparisons follow the [measurement policy](../CONTRIBUTING.md#app-size-measurements). Published metadata comes from the exact release package.

Build success establishes compilation only. See the [verification baseline and outstanding work](ROADMAP.md) for runtime, accessibility, compatibility, and performance status.
