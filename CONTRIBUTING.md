# Contributing

nano.md now includes the reader and the first source editor. Start with the [architecture](docs/ARCHITECTURE.md) and [roadmap](docs/ROADMAP.md). Keep contributions focused on a concrete behavior or maintenance problem.

## Development

Keep temporary files, sample documents, logs, and build output in the repository-root `Temp/` folder, which is ignored by Git.

Open `NanoMD.xcodeproj` and select the macOS `NanoMD` scheme. The current baseline is Xcode 26.6, Swift 6 language mode, and a macOS 26.5 deployment target. The source folder uses Xcode's synchronized groups; place new Swift files under the app's `NanoMD/` folder and keep tooling/documentation outside it.

Use the unsigned Debug build command in [README.md](README.md) for local compilation. Change `-configuration Debug` to `-configuration Release` when validating dependency changes, compiler settings, or performance-sensitive code. Unsigned compilation does not validate sandbox permissions, signing, notarization, or UI behavior. For a signed local run, use your own signing configuration without committing personal team changes.

For Finder and Open With checks, use the current signed Release installed at `/Applications/NanoMD.app`. Building or running in Xcode updates its build directory, not the installed app. When updating the installed copy, request normal termination of older NanoMD instances and stop if unsaved work requires user action. Preserve the previous app under `Temp/`, replace it with the validated locally signed Release, unregister only stale NanoMD build copies with Launch Services, and register the installed app. Keep unrelated associations unchanged. Confirm that macOS resolves the bundle identifier to the installed path.

## Change standards

- Follow Swift naming conventions, four-space indentation, narrow access control, and explicit state ownership.
- Keep code, project settings, and architecture documentation consistent. Distinguish proposed behavior from implemented behavior.
- Explain important constraints in code comments. Keep change history and implementation narration in the pull request.
- Justify new dependencies with their functional benefit, maintenance, license, transitive cost, and effect on build/app size.
- Preserve unrelated changes. Do not include build output, credentials, or personal Xcode state.

[AGENTS.md](AGENTS.md) contains the instructions for AI-assisted work. Keep that file as the single repository rule source rather than maintaining divergent copies for each assistant. Codex supports project instructions in a root `AGENTS.md`; see [OpenAI's instruction discovery documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md). When using another assistant, ensure it reads the same rules through that tool's supported configuration.

## Validation

For code changes, build the affected configuration and review the changed code. Run relevant existing tests if they become available. Do not create or update tests unless the maintainer explicitly requests them; the repository currently has no test targets. AI assistants must not visually test implementations, inspect rendered UI, take verification screenshots, or interact with previews unless explicitly requested.

When manual validation is requested for document and reader changes, choose the relevant checks from this list:

- Open empty, ordinary, Unicode/BOM, and invalid-encoding files, including both registered extensions.
- Check whitespace, nested lists, code blocks, long lines, and unsupported syntax against the declared rendering subset.
- Open two documents and confirm their source, loading state, selection, and close behavior stay independent.
- Compare file bytes and modification times before and after opening, reading, and closing.
- Check cancellation, rapid source replacement, error presentation, and the documented external-change behavior.
- Check Read/Edit transitions, selection and scroll retention, undo/redo in both modes, and isolation between document windows.
- Check new documents, save/reopen, failed saves, no-edit byte preservation, mixed line endings, BOM, canonically distinct Unicode, and input-method composition.
- Check system reverts and external conflicts with unsaved changes; confirm accepted replacements clear stale undo history.
- Use the keyboard, copy text across paragraphs, inspect VoiceOver reading order, and switch appearance.
- Confirm that raw HTML and unsafe links cannot execute and that viewing a document makes no network requests.
- Measure a Release build when claiming a performance improvement; record hardware, OS, corpus, method, and before/after results.

Use disposable copies for file-handling verification. Do not use personal documents as fixtures or include their content in logs or review artifacts.

For documentation changes, verify local links, commands, current project facts, and the distinction between planned and implemented work. Run `git diff --check` and review the final diff. If a tool or environment prevents verification, state what failed and what remains unverified; do not disable app protections to make a check pass.

## Pull requests

Describe the problem, resulting behavior, and any meaningful tradeoff. Include the build/configuration used, focused manual checks, and known limitations. Screenshots help for visible changes. Keep claims proportional to the evidence; do not claim compatibility, performance, security, or coverage that was not checked.

The Build workflow compiles Debug and Release for pull requests and `main`; it does not run automated tests. Functional testing is performed locally with AI assistance before release. Follow [Releasing](docs/RELEASING.md) to create a version-tagged draft. Publication prerequisites, including license selection and distribution verification, remain tracked in the [roadmap](docs/ROADMAP.md).
