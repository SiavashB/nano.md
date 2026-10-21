# Contributing

Contributions should address a concrete behavior or maintenance problem. Start with an [open issue](https://github.com/SiavashB/nano.md/issues), the [roadmap](docs/ROADMAP.md), and the [architecture](docs/ARCHITECTURE.md).

## Reporting bugs

Search existing issues, then use the [bug report form](https://github.com/SiavashB/nano.md/issues/new?template=bug_report.yml). Include the app version/build, macOS version and hardware, steps to reproduce, and expected versus actual behavior. A small Markdown sample helps; remove private content, credentials, and personal paths before sharing it.

Report suspected security vulnerabilities through the [private reporting process](SECURITY.md), rather than a public issue or pull request.

## Proposing changes

Use the [feature request form](https://github.com/SiavashB/nano.md/issues/new?template=feature_request.yml) to describe the problem and proposed behavior before starting a substantial feature. Small documentation fixes can go directly to a pull request. Link related issues and keep each PR focused on one change.

## Development

Keep temporary files, sample documents, logs, and build output in the repository-root `Temp/` folder, which is ignored by Git.

Open `NanoMD.xcodeproj` and select the macOS `NanoMD` scheme. Use Xcode 26.6, Swift 6, and Apple Silicon. The deployment target is macOS 15.0; runtime verification on that OS remains pending. The project uses Xcode's synchronized groups: place app source under `NanoMD/` and keep tooling/documentation outside it.

Use the unsigned Debug build command in [README.md](README.md) for local compilation. Change `-configuration Debug` to `-configuration Release` when validating dependency changes, compiler settings, or performance-sensitive code. Unsigned compilation does not validate sandbox permissions, signing, notarization, or UI behavior.

For a signed local run, create `Config/Local.xcconfig` with `DEVELOPMENT_TEAM = YOUR_TEAM_ID`, using the team shown in Xcode's account settings. Both configurations optionally load that ignored file through `Config/Signing.xcconfig`; a fresh checkout needs no local file for unsigned builds. Keep automatic signing enabled and do not commit your team or certificate settings. CI provides signing settings explicitly.

Finder and Open With verification requires an installed signed Release; see the [maintainer procedure](docs/RELEASING.md#installed-app-checks).

## App-size measurements

Use Apple Silicon (`ARCHS=arm64`), the Release configuration, Xcode 26.6, and the committed package versions for size measurements, matching the release workflow. For local before/after comparisons, run the README command with `-configuration Release` and `CODE_SIGNING_ALLOWED=NO` for both builds; keep the toolchain, architecture, signing mode, and measurement method identical. Record those settings with the results. Do not compare Debug, universal, or differently signed bundles as evidence of code growth.

Measure the complete `.app` by summing regular-file bytes without following symbolic links; report decimal MB (1 MB = 1,000,000 bytes). Exclude adjacent dSYMs, build caches, and ZIPs. Published download metadata must come from the exact signed release bundle; signing can change its size slightly from a local unsigned build. `website/update-app-size.mjs` checks the executable's architecture and the build configuration recorded in `Info.plist` before updating the page. Older bundles without that configuration metadata must be rebuilt.

After building Release, use Node.js 22 or newer to record the local bundle's size:

```sh
npm --prefix website run update-app-size -- "$PWD/Temp/DerivedData/Build/Products/Release/NanoMD.app"
```

This command updates local website metadata for development measurements. Deployment replaces those values with the exact published release's metadata.

## Change standards

- Follow Swift naming conventions, four-space indentation, narrow access control, and explicit state ownership.
- Keep code, project settings, and architecture documentation consistent. Distinguish proposed behavior from implemented behavior.
- Explain important constraints in code comments. Keep change history and implementation narration in the pull request.
- Justify new dependencies with their functional benefit, maintenance, license, transitive cost, and effect on build/app size.
- Preserve unrelated changes. Do not include build output, credentials, or personal Xcode state.

[AGENTS.md](AGENTS.md) is the shared instruction source for AI-assisted contributions.

## Validation

For code changes, build the affected configuration and review the changed code. Run relevant existing tests if they become available. Test additions or updates require explicit maintainer agreement; the repository currently has no test targets. AI-assisted validation follows [AGENTS.md](AGENTS.md), including its requirements for visual testing.

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

The [PR template](.github/pull_request_template.md) asks for the problem, resulting behavior, validation, and meaningful limitations. Include the build/configuration used and any focused manual checks. Screenshots help for visible changes. Keep claims proportional to the evidence; do not claim compatibility, performance, security, or coverage that was not checked.

The Build workflow compiles Debug and Release for pull requests and `main`; it does not run automated tests. Functional checks are performed locally before release. Follow [Releasing](docs/RELEASING.md) for package verification and publication. The [roadmap](docs/ROADMAP.md) tracks outstanding work.
