# AI development rules

NanoMD is a lightweight native macOS Markdown app. The first product milestone is a read-only viewer; source editing follows later. These rules apply throughout this repository.

## Start here

- The public-facing product name is `nano.md`, all lowercase with a period. `NanoMD`/`nanomd` are the existing project and code names; keep those technical identifiers unless explicitly asked to rename them.
- Read [README.md](README.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before changing app code. Consult [docs/ROADMAP.md](docs/ROADMAP.md) for scope and [CONTRIBUTING.md](CONTRIBUTING.md) for validation.
- Inspect the current code, project settings, and Git diff. Architecture documents describe the intended design; do not assume planned components exist.
- Work in the user's saved project directory and current checkout. Do not create or use a worktree unless explicitly requested. Preserve unrelated changes.
- Put temporary files, sample documents, logs, and build output in the repository-root `Temp/` folder. Create it when needed and keep it ignored by Git. Do not deliberately write project artifacts to system temporary directories or other locations without the user's permission.
- Complete the requested work with reasonable implementation choices. Ask only when a missing decision materially changes the requested behavior or cannot be resolved from context.

## Architecture

- Keep one app target, organized by responsibility. Create a directory when it has real implementation to contain.
- `App` composes scenes and dependencies. `Documents` owns file decoding and document state. `Markdown` owns parsing and semantic output. `Features/Reader` owns presentation and transient reader state.
- Keep `Markdown` independent of SwiftUI, AppKit, file access, and network access. Keep parser-specific types inside that boundary.
- Treat the document's original Markdown source as the source of truth. Rendering is derived data. Never regenerate a user's file from a syntax tree, attributed string, or HTML.
- Use concrete types and explicit initializer injection by default. Add a protocol, shared abstraction, package, or view model only when a current responsibility needs it. Avoid generic service layers, dependency containers, and empty extension points.
- Keep state with its owner. Use local SwiftUI state for local presentation; introduce a document-scoped observable model when asynchronous loading or shared reader state requires one. Do not introduce a global document store.
- Keep significant decisions and their tradeoffs in the architecture document. Update it when implementation changes a boundary or invariant.

## Read-only milestone

- Use the viewer document scene, declare the document role as `Viewer`, and request only read access to user-selected files.
- Expose source values to the reader without mutable document bindings. No editor, document creation, saving, autosaving, or source transformation belongs in this milestone.
- Reject write requests at the document boundary until editing is implemented. Disabling a control is insufficient protection.
- Use the system document lifecycle for document I/O. Do not reread or write an open document through its URL from a view or renderer.
- Preserve whitespace, line endings, Unicode, and the original file. Report unsupported encodings or read failures without lossy decoding or empty-document fallbacks.

## Swift and UI

- Use descriptive Swift API naming, four-space indentation, and the narrowest useful access control. Prefer value types and immutable state.
- Keep views focused on composition. Move parsing, file operations, and nontrivial state transitions out of view bodies.
- UI and AppKit objects belong on the main actor. Parsing belongs on an explicitly isolated worker; adding `async` or wrapping work in `Task` alone does not move it off the main actor.
- Pass immutable, `Sendable` values across isolation boundaries. Do not silence concurrency diagnostics with `@unchecked Sendable`, `nonisolated(unsafe)`, or broad compiler-setting changes.
- Tie asynchronous work to the document/view lifetime. Discard obsolete results, handle cancellation, and avoid redundant parsing on redraw or appearance changes.
- Handle recoverable failures explicitly. Avoid force unwraps, `try!`, swallowed errors, and fabricated success states for file or user input.
- Use native controls, semantic colors, accessible labels, keyboard interaction, and selectable text. Do not visually test implementations, inspect rendered UI, take verification screenshots, or interact with previews unless explicitly requested.
- Comments explain non-obvious intent, constraints, or workarounds that matter in the finished code. Do not narrate changes, restate code, add generated author/date headers, or document every declaration.

## Dependencies and content handling

- Prefer system frameworks. A new package needs a concrete benefit, license and maintenance review, and consideration of transitive dependencies, app size, and build cost. Record the rationale; do not add packages for convenience alone.
- Use Swift Package Manager for app dependencies and commit `Package.resolved` when dependencies are introduced. Use a release requirement, not a moving branch.
- Treat Markdown and its links as untrusted input. Do not execute embedded HTML, JavaScript, commands, or code blocks. Do not automatically load remote resources.
- Allow external navigation only through explicit user interaction and the documented URL policy. Do not expand sandbox access to make a renderer work.
- Do not log document content or full user paths. Do not add telemetry, accounts, background services, or network access without a feature requirement.

## Validation and delivery

- Keep validation proportional to this lightweight app: build and review the changed code. Perform visual checks only when explicitly requested; opening a requested preview does not authorize visual testing.
- Prioritize app functionality. Defer performance profiling, benchmark tooling, and optimization budgets to final polish unless the user requests them or a concrete responsiveness issue blocks the current feature.
- Do not write, update, or introduce tests unless the user explicitly asks. Run applicable existing tests if present; otherwise use builds and code review. Do not claim unperformed checks passed.
- For Swift or project changes, run the Debug build documented in `CONTRIBUTING.md`; include Release when compiler settings, dependencies, or optimization-sensitive behavior change.
- For documentation-only changes, check links, commands, consistency with the repository, and the diff. A baseline build is useful when establishing setup instructions.
- Do not weaken signing, sandboxing, concurrency, or deployment settings to hide an environment failure. Report the actual limitation.
- Keep changes focused. No unrelated refactors, cosmetic rewrites, generated output, personal Xcode state, or speculative features.
- Summarize the result, relevant validation, and remaining limitations. Distinguish designed, implemented, built, and manually verified behavior.

## Code Review Rules

- Flag any path that can modify a document during the read-only milestone.
- Flag parsing in UI update paths, obsolete asynchronous results replacing newer content, or shared state leaking between documents.
- Flag source normalization, lossy decoding, executable content, automatic network fetches, or access outside user-granted resources.
- Flag factual claims in documentation that exceed the implemented or verified behavior. Review concrete defects; avoid preference-only comments.
