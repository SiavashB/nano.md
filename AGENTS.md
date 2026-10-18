# AI development rules

NanoMD is a lightweight native macOS Markdown app. The reader and first source editor have passed focused local UI checks; remaining runtime cases are tracked in [the roadmap](docs/ROADMAP.md). These rules apply throughout this repository.

## Start here

- The public-facing product name is `nano.md`, all lowercase with a period. `NanoMD`/`nanomd` are the existing project and code names; keep those technical identifiers unless explicitly asked to rename them.
- Read [README.md](README.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before changing app code. Consult [docs/ROADMAP.md](docs/ROADMAP.md) for scope and [CONTRIBUTING.md](CONTRIBUTING.md) for validation.
- Inspect the current code, project settings, and Git diff. Architecture documents describe the intended design; do not assume planned components exist.
- Work in the user's saved project directory and current checkout. Do not create or use a worktree unless explicitly requested. Preserve unrelated changes.
- Put temporary files, sample documents, logs, and build output in the repository-root `Temp/` folder. Create it when needed and keep it ignored by Git. Do not deliberately write project artifacts to system temporary directories or other locations without the user's permission.
- Complete the requested work with reasonable implementation choices. Ask only when a missing decision materially changes the requested behavior or cannot be resolved from context.
- For every release, including prereleases and hotfixes, follow [the release checklist](docs/RELEASING.md#each-release). Release work is incomplete until `README.md`, the public website, and GitHub release notes reflect the shipped app's features, limitations, version/build, compatibility, installation, and download facts. Review prose as well as generated metadata, confirm website deployment, and report any unfinished item explicitly.

## Architecture

- Keep one app target, organized by responsibility. Create a directory when it has real implementation to contain.
- `App` composes scenes and dependencies. `Documents` owns file decoding and document state. `Markdown` owns parsing and semantic output. `Features/Document` owns Read/Edit presentation, `Features/Editor` owns native editing and binding synchronization, and `Features/Reader` owns read-only presentation and transient reader state.
- Keep `Markdown` independent of SwiftUI, AppKit, file access, and network access. Keep parser-specific types inside that boundary.
- Treat the document's original Markdown source as the source of truth. Rendering is derived data. Never regenerate a user's file from a syntax tree, attributed string, or HTML.
- Use concrete types and explicit initializer injection by default. Add a protocol, shared abstraction, package, or view model only when a current responsibility needs it. Avoid generic service layers, dependency containers, and empty extension points.
- Keep state with its owner. Use local SwiftUI state for local presentation; introduce a document-scoped observable model when asynchronous loading or shared reader state requires one. Do not introduce a global document store.
- Keep significant decisions and their tradeoffs in the architecture document. Update it when implementation changes a boundary or invariant.

## Document editing and read-only presentation

- Use an editing `DocumentGroup`, the `Editor` document role, writable Markdown types, and read/write access to user-selected files. Keep sandboxing and concurrency settings enabled.
- Keep the value-type `NanoMDDocument` source authoritative. Serialize its exact UTF-8 representation, retaining loaded BOM metadata; new documents use UTF-8 without BOM and LF.
- The reader remains read-only and receives an immutable snapshot. Mount it only in Read mode; do not parse a hidden preview during typing.
- Keep the native editor alive across Read/Edit switches. Preserve selection, scroll position, and undo targets, and remove focus from hidden editing controls.
- Let NSTextView register native typing undo with the document's undo manager. Suppress undo registration only while publishing the source binding; do not add whole-document typing actions or a separate undo stack.
- System reloads/reverts carry a new load identity; clear stale undo actions when applying an accepted replacement. Do not replace native text on every update or disturb marked text.
- Use the system document lifecycle for reading, saving, autosaving, failures, and external conflicts. Do not read/write an open document through its URL or add watchers or custom recovery.
- Request native keep-changes confirmation on document close and app quit through the application-scoped `NSCloseAlwaysConfirmsChanges` policy. Keep the system lifecycle in charge of save, discard, and cancel; do not change global defaults.
- Preserve whitespace, line endings, Unicode representation, and trailing newlines. Reject invalid UTF-8 without lossy decoding or empty-document fallbacks. Insert line breaks using the loaded convention; preserve plain pasted text.

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

- The landing page's maintained source is in `website/`; do not edit or deploy old copies under `Temp/WebsiteBranding/`. Follow `website/README.md` for Cloudflare deployment. Keep temporary website output in `Temp/` and do not visually test the site unless requested.
- Build for Apple Silicon (`ARCHS=arm64`) with a macOS 15.0 deployment target. Keep Xcode 26.6 as the build toolchain; distinguish compiling for macOS 15 from runtime verification on that OS. Follow the app-size measurement policy in `CONTRIBUTING.md`: use Release, identical toolchain/signing settings for before/after comparisons, and regular-file bytes in decimal MB. Never compare universal or Debug bundles against arm64 Release sizes as evidence of code growth.
- Keep public website metadata tied to the exact published release, not an installed development build. `npm --prefix website run update-release` synchronizes both download links, labels, sizes, OS requirement, and structured data from the newest published release's checksum-verified arm64 Release ZIP. Website checks/deployments run this automatically; the Deploy website workflow triggers on release publication once its Cloudflare secret is configured. For local size comparisons, `update-app-size -- /path/to/NanoMD.app` still validates the current checkout and arm64 Release configuration. Do not describe uncompressed app size as download size.

- Keep validation proportional to this lightweight app: build and review the changed code. Perform visual checks only when explicitly requested; opening a requested preview does not authorize visual testing.
- Prioritize app functionality. Defer performance profiling, benchmark tooling, and optimization budgets to final polish unless the user requests them or a concrete responsiveness issue blocks the current feature.
- Do not write, update, or introduce tests unless the user explicitly asks. Run applicable existing tests if present; otherwise use builds and code review. Do not claim unperformed checks passed.
- For Swift or project changes, run the Debug build documented in `CONTRIBUTING.md`; include Release when compiler settings, dependencies, or optimization-sensitive behavior change.
- For documentation-only changes, check links, commands, consistency with the repository, and the diff. A baseline build is useful when establishing setup instructions.
- Do not weaken signing, sandboxing, concurrency, or deployment settings to hide an environment failure. Report the actual limitation.
- Keep changes focused. No unrelated refactors, cosmetic rewrites, generated output, personal Xcode state, or speculative features.
- Summarize the result, relevant validation, and remaining limitations. Distinguish designed, implemented, built, and manually verified behavior.

## Code Review Rules

- Flag source mutation in the reader, serialization of derived rendering, duplicate undo registration, stale undo targets after reloads, and hidden editors retaining keyboard focus.
- Flag parsing in UI update paths, obsolete asynchronous results replacing newer content, or shared state leaking between documents.
- Flag source normalization, lossy decoding, executable content, automatic network fetches, or access outside user-granted resources.
- Flag factual claims in documentation that exceed the implemented or verified behavior. Review concrete defects; avoid preference-only comments.
