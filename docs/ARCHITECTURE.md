# Architecture

Status: the read-only document foundation and native Markdown rendering are implemented. App functionality is the current priority; performance profiling and budgets are deferred to final polish.

## Goals and constraints

NanoMD opens local Markdown files in native macOS document windows. The first milestone displays documents without changing them. A later milestone adds source editing, undo/redo, and saving while reusing the reader.

Favor small, explicit boundaries and macOS conventions. Keep document ownership in the system document lifecycle, preserve the user's source, and measure performance before adding caches or custom infrastructure. Accounts, synchronization, a document database, plugins, and an embedded browser are outside the initial scope.

## Decisions

| Area | Direction | Reason and tradeoff |
| --- | --- | --- |
| Application | SwiftUI, one macOS app target | Native scenes and commands with a small build surface. Folder boundaries are enforced through review rather than separate modules. |
| Document lifecycle | `DocumentGroup` with a value-type `FileDocument` adapter | Reuse system document ownership. Move to a reference document only if actual editing or size requirements justify it. |
| Read-only mode | Viewer scene, `Viewer` document role, read-only file entitlement, rejecting write adapter | Read-only behavior is enforced at multiple boundaries. Editing will require an intentional change to those boundaries. |
| Parsing | `swiftlang/swift-markdown` 0.8.0, behind a concrete parser boundary | Avoid maintaining a Markdown grammar. Use the maintained Swift/cmark parser instead of maintaining a grammar. The native view owns presentation. |
| Presentation | SwiftUI shell with a read-only, selectable AppKit `NSTextView` adapter | Native continuous text selection and text layout. Block styling uses attributed text and paragraph indentation; a dedicated accessibility audit is deferred. |
| State | Document-owned source, document-scoped reader state, derived render output | One authoritative source with no application-wide document store. |
| Persistence | Markdown files only | No database, rendered-content sidecars, or custom file format. |

SwiftUI provides a dedicated viewer scene initializer and documents how it relates to the document role. Use the API available in the installed stable SDK; the Xcode 26.6 SDK includes `DocumentGroup(viewing:viewer:)`. See [Apple's viewer initializer documentation](https://developer.apple.com/documentation/swiftui/documentgroup/init(viewing:viewer:)-6dq9n).

Swift Markdown provides a syntax tree backed by `cmark-gfm`; it is a parser, not a complete macOS presentation layer. The project pins release 0.8.0; `Package.resolved` also records swift-cmark 0.9.0. Parser types stay inside `Markdown/`. See the [Swift Markdown repository](https://github.com/swiftlang/swift-markdown).

## Structure and dependency direction

Current source layout inside the existing `NanoMD/` synchronized Xcode folder:

```text
NanoMD/
  App/
    NanoMDApp.swift
    ReaderCommands.swift
  Documents/
    NanoMDDocument.swift
    MarkdownContentType.swift
  Markdown/
    MarkdownContent.swift
    MarkdownParser.swift
  Features/
    Reader/
      ReaderView.swift
      ReaderModel.swift
      MarkdownTextRenderer.swift
      MarkdownTextView.swift
      MarkdownSourceView.swift
      ReaderLinkPolicy.swift
  Resources/
    ThirdPartyNotices.txt
  Assets.xcassets/
  Info.plist
```

`MarkdownParser` produces immutable, Sendable blocks and styled text runs. `ReaderModel` owns loading, ready, and source-fallback states. `MarkdownTextRenderer` builds attributed text and `MarkdownTextView` provides native selection and link handling. `MarkdownSourceView` remains the literal-source fallback. Keep documentation and development scripts outside the synchronized app folder so they do not become app resources.

Dependency direction:

```text
App ──────────> Documents ──────────> SwiftUI document APIs + Foundation
 │
 └────────────> Reader ─────────────> Markdown ─────────────> parser package
                  │
                  └────────────────> SwiftUI + AppKit
```

`App` supplies the document's source to `Reader`. The reader does not need to own or import a file adapter. `Markdown` has no knowledge of views, windows, file URLs, or persistence. The parser package's types do not escape into document or UI interfaces.

| Boundary | Owns | Must not own |
| --- | --- | --- |
| `App` | Scenes, commands, dependency construction | Parsing, file encoding, render state |
| `Documents` | Source text, required encoding metadata, content types, file read/write contract | Fonts, attributed text, reader selection |
| `Markdown` | Parsing and immutable semantic output for supported syntax | AppKit objects, file/network access, global state |
| `Reader` | Loading state, presentation, selection, native text adapter, link policy | Source mutation or document I/O |

Use a small semantic render model for supported blocks and inline content, not a second general-purpose Markdown syntax library. Parser nodes remain temporary implementation details. Keep styling in the reader so changing appearance does not require reparsing.

## Document contract

The document's decoded source is authoritative. Preserve whitespace, Unicode, line endings, and trailing newlines; do not trim or normalize during load. Initially support valid UTF-8, including a UTF-8 BOM, retaining BOM information separately if decoding removes it. Reject unsupported or invalid byte sequences with an actionable error. Broader encoding support requires an explicit policy.

Register `.md` and `.markdown` with a Markdown content type in both the document adapter and `Info.plist`. Import an established type for an existing format; do not export a new proprietary Markdown format or claim all plain-text documents.

For the read-only milestone:

- Use a viewing `DocumentGroup`, set the bundle document role to `Viewer`, and reduce user-selected file access to read-only.
- Give the reader a source value rather than a mutable document binding.
- Declare no writable content types and make the required `FileDocument.fileWrapper` implementation throw a write-permission error.
- Provide no editor, new-document action, save command, or custom autosave path.

`ReaderCommands` replaces the framework's creation and save command groups, retaining File > Open and a Close action routed through the native responder chain. The Close command follows the focused document scene. This is necessary because the viewer scene alone still exposes document-writing commands in the Xcode 26.6 runtime.

The system reads the document through the adapter. A renderer must not reopen the same document URL to obtain content. File identity and display metadata may be passed separately when needed. Rely on the system lifecycle for external changes initially; verify reload behavior and document any limitation before adding a file watcher. Apple's [DocumentGroup documentation](https://developer.apple.com/documentation/swiftui/documentgroup) describes document ownership and URL access constraints.

## Rendering flow and concurrency

`ReaderView` starts a source-keyed SwiftUI task. Its identity compares UTF-8 representations, so canonically equivalent but byte-distinct source changes still trigger rendering. Each reader owns its parser actor and model.

1. The system loads the file through `NanoMDDocument` and reports file errors through the document UI.
2. The app supplies the source snapshot to a reader scoped to that document window.
3. A reader-owned task requests parsing from a worker actor, using an identity or revision tied to the source snapshot.
4. The worker returns immutable, `Sendable` semantic output. Parser-owned data stays on the worker.
5. The main actor accepts the result only if it still matches the current source and the reader is active, then builds native text attributes and presents them.

An empty file is a valid ready state. SwiftUI cancels the task when the view disappears or the source changes. A model revision check prevents obsolete work from replacing newer content. The actor checks cancellation before parsing, during tree conversion, and before returning. The synchronous cmark call cannot be interrupted mid-call. Formatting is capped at 1 MiB, 50,000 syntax nodes, and 64 levels of nesting; exceeding a limit shows source. Canceled requests waiting on the actor exit before parsing.

AppKit view creation, attribute application, and layout remain on the main actor. Attributed-text construction yields between blocks, including nested blocks and table rows, to allow cancellation and UI work. Profile that cost separately from parsing. Do not reparse during `body`, native view updates, window resizing, or theme changes. Keep only the latest attributed output per reader; add caching or incremental updates only when measurements justify them.

The parser handles malformed Markdown as content when possible. Unsupported presentation features retain readable content or show a clear fallback; they must not silently disappear. Failed rendering must offer access to selectable literal source without an editable control.

## Initial rendering scope

The formatted reader supports paragraphs, headings, emphasis, strong emphasis, inline code, fenced/indented code blocks, ordered/unordered lists, blockquotes, pipe tables, thematic breaks, and explicitly activated web links. Preserve nested structure and code whitespace. Present images as descriptive text placeholders initially.

Interactive task lists, syntax highlighting, image loading, HTML rendering, and advanced extensions follow separately. Parser support does not imply renderer support. Document the implemented subset rather than claiming complete CommonMark or GitHub-flavored Markdown compatibility.

Tables cross the parser boundary as rows of styled runs and column alignments. The reader uses `NSTextTable` and paragraph-level `NSTextTableBlock` cells within the same selectable text view. Native column sizing accounts for padding and borders within the available width; cells retain inline formatting and the existing link policy. Cell borders do not collapse, and spacing after a table uses a separate paragraph outside its cells. Header styling, borders, padding, and alignment belong to the reader. The formatted view explicitly uses TextKit 1 for native table layout, avoiding an implicit compatibility switch from TextKit 2. The plain-source fallback continues to use TextKit 2. No browser engine or additional dependency is required.

The native renderer uses one text view for continuous selection. List markers and quote indentation preserve nesting; code uses a monospaced font and retains parsed whitespace. Unsupported blocks use the parser’s Markdown formatter for a readable literal representation; this derived text is never used for saving. Task checkboxes remain literal markers. Dedicated VoiceOver and large-document performance audits are deferred. SwiftUI block views and a web view would introduce different selection and resource tradeoffs without a current need.

## Content and resource policy

Render raw HTML as literal content; never execute code blocks, scripts, or embedded commands. The initial reader performs no automatic network requests and does not resolve image paths. Image placeholders should expose alt text and the destination without loading it.

The literal-source reader disables automatic link and data detection. Formatted links allow only `https` and `http` through an explicit user action and `NSWorkspace.open`. `ReaderLinkPolicy` checks both attribute creation and the text-view delegate. The delegate always consumes the event to prevent default navigation for rejected destinations; it rejects custom schemes, `javascript:`, `data:`, and `file:` navigation. Relative links and same-document anchors remain readable until their behavior is implemented.

Later local assets require explicit user-granted access to the needed resources; access to a Markdown file does not imply access to its containing directory. Remote loading requires a deliberate product policy. Keep document content and full paths out of logs.

## Path to editing

Add source editing as another presentation of the same document. The editor mutates the document source through its binding; the preview consumes snapshots through the existing parser boundary. Selection, scroll position, loading state, and preview output remain outside persisted document content.

The editing milestone intentionally changes the scene to an editing document group, enables writable types and file access, and implements serialization. Preserve encoding/BOM policy, line endings, and unchanged source bytes on a no-op round trip. Never serialize the render model or format Markdown implicitly.

Integrate native undo/redo and verify that edits register correctly with the document lifecycle. Settle autosave, external-change conflicts, failure recovery, and crash recovery before claiming reliable editing. Debounce preview work if typing measurements require it. Do not add editing protocols or dormant mutation APIs to the reader milestone.

## Quality and evolution

Keep acceptance focused on rendering, selection/copying, keyboard access, and basic appearance. Dedicated accessibility audits are deferred. Performance profiling belongs to final polish, after the intended functionality is in place. At that stage, establish Release measurements for open-to-first-content latency, parsing, main-thread layout, and memory using representative 10 KB, 100 KB, and 1 MB documents. Include long lines, nested structures, and code-heavy files; input shape matters as well as size.

The initial 1 MiB formatting cap and complexity limits are conservative guardrails, not measured budgets. No latency or memory guarantees are claimed yet. Performance work should validate or adjust these limits on a named reference Mac and check memory release after document closure.

Keep the current deployment target until compatibility is deliberately evaluated. Swift 6 language mode is enabled in both build configurations; the document adapter and content-type declaration are explicitly nonisolated, while UI uses the project's main-actor default. Resolve future isolation diagnostics at their actual boundaries. Extract a Swift package only when reuse or a compile-time boundary has demonstrated value.

Record major changes here with context, decision, alternatives, and consequences. Add a separate decision record only when the reasoning warrants more space.

## Dependency review

Swift Markdown 0.8.0 supplies the grammar and immutable parser tree, with swift-cmark 0.9.0 supplying cmark-gfm and its extensions. Its `CAtomic` target is bundled in the same package. The app links these libraries without a browser engine or runtime network dependency. Xcode’s resolved app graph contains these two packages; the package manifest’s documentation plugin is not part of the app product.

Swift Markdown uses Apache 2.0 with the Swift Runtime Library Exception; cmark’s copying file includes BSD and MIT notices for its components. Upstream license and notice texts are included in `Resources/ThirdPartyNotices.txt`. The upstream notice also mentions Argument Parser used by upstream tooling; it is not linked by NanoMD. The released parser has an active Swift project upstream and avoids a custom grammar, at the cost of extra Swift/C compilation and binary size. Exact build time and size observations belong in validation notes, not product guarantees.
