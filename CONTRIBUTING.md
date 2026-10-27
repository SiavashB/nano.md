# Contributing

Contributions should address a concrete behavior or maintenance problem. Start with an [open issue](https://github.com/SiavashB/nano.md/issues) and the [code organization](#code-organization) below.

## Reporting bugs

Search existing issues, then use the [bug report form](https://github.com/SiavashB/nano.md/issues/new?template=bug_report.yml). Include the app version/build, macOS version and hardware, steps to reproduce, and expected versus actual behavior. A small Markdown sample helps; remove private content, credentials, and personal paths before sharing it.

Report suspected security vulnerabilities through the [private reporting process](SECURITY.md), rather than a public issue or pull request.

## Proposing changes

Use the [feature request form](https://github.com/SiavashB/nano.md/issues/new?template=feature_request.yml) to describe the problem and proposed behavior before starting a substantial feature. Small documentation fixes can go directly to a pull request. Link related issues and keep each PR focused on one change.

## Development

Keep temporary files, sample documents, logs, and build output in the repository-root `Temp/` folder, which is ignored by Git.

Open `NanoMD.xcodeproj` and select the macOS `NanoMD` scheme. Use Xcode 27.1 locally, Swift 6, and Apple Silicon. Local builds use the active developer directory reported by `xcode-select -p`; confirm the toolchain with `xcodebuild -version`. CI and release builds remain pinned to Xcode 26.6, which is available on GitHub’s `macos-26` runner. The deployment target is macOS 15.0; runtime verification on that OS remains pending. The project uses Xcode's synchronized groups: place app source under `NanoMD/` and keep tooling/documentation outside it.

Use the unsigned Debug build command in [README.md](README.md) for local compilation. Change `-configuration Debug` to `-configuration Release` when validating dependency changes, compiler settings, or performance-sensitive code. Unsigned compilation does not validate sandbox permissions, signing, notarization, or UI behavior. Release builds must also pass `ENABLE_CODE_COVERAGE=NO` so the setting applies to Swift package dependencies as well as app targets. Debug tests can retain coverage support; the CI and release workflows reject Release binaries containing coverage sections.

For a signed local run, create `Config/Local.xcconfig` with `DEVELOPMENT_TEAM = YOUR_TEAM_ID`, using the team shown in Xcode's account settings. Both configurations optionally load that ignored file through `Config/Signing.xcconfig`; a fresh checkout needs no local file for unsigned builds. Keep automatic signing enabled and do not commit your team or certificate settings. CI provides signing settings explicitly.

Finder and Open With verification requires an installed signed Release. Building in Xcode does not update the installed copy; preserve unsaved work when replacing or relaunching it.

## Code organization

- `NanoMD/App` composes scenes and commands; `Documents` owns source text, encoding metadata, and the file read/write contract.
- `NanoMD/Markdown` parses immutable source snapshots into semantic content, independently of SwiftUI, AppKit, file access, and networking.
- `NanoMD/Features/Document`, `Editor`, and `Reader` own window composition, native source editing, and read-only presentation respectively.

Keep the original Markdown source authoritative and serialize its exact UTF-8 representation, retaining a loaded BOM, whitespace, Unicode representation, and line endings. Rendering must never become the saved source. Reject invalid UTF-8 rather than using lossy decoding.

The system document lifecycle owns saves, autosave, conflicts, and recovery. Keep the native editor alive across mode changes and let NSTextView own typing undo. Accepted reloads must clear stale undo targets. Parsing belongs off the main actor, obsolete results must be discarded, and reader state must stay document-scoped.

Treat document content as untrusted. Keep HTML literal and resources unloaded; document navigation allows only explicitly activated HTTP/HTTPS links. See [Security](SECURITY.md) for private reporting and the content policy.

## App-size measurements

Use Apple Silicon (`ARCHS=arm64`), the Release configuration, and the committed package versions for size measurements. Use Xcode 27.1 for local comparisons and the workflow’s pinned Xcode 26.6 when reproducing distribution builds. Do not attribute size differences between toolchains to app changes. For local before/after comparisons, run the README command with `-configuration Release` and `CODE_SIGNING_ALLOWED=NO` for both builds; keep the toolchain, architecture, signing mode, and measurement method identical. Record those settings with the results. Do not compare Debug, universal, or differently signed bundles as evidence of code growth.

Measure the complete `.app` by summing regular-file bytes without following symbolic links; report decimal MB (1 MB = 1,000,000 bytes). Exclude adjacent dSYMs, build caches, and ZIPs. Published download metadata must come from the exact signed release bundle; signing can change its size slightly from a local unsigned build. `website/update-app-size.mjs` checks the executable's architecture and the build configuration recorded in `Info.plist` before updating the page. Older bundles without that configuration metadata must be rebuilt.

After building Release, use Node.js 22 or newer to record the local bundle's size:

```sh
npm --prefix website run update-app-size -- "$PWD/Temp/DerivedData/Build/Products/Release/NanoMD.app"
```

This command updates local website metadata for development measurements. Deployment replaces those values with the exact published release's metadata.

## Change standards

- Follow Swift naming conventions, four-space indentation, narrow access control, and explicit state ownership.
- Keep code, project settings, and contributor guidance consistent. Distinguish proposed behavior from implemented behavior.
- Explain important constraints in code comments. Keep change history and implementation narration in the pull request.
- Justify new dependencies with their functional benefit, maintenance, license, transitive cost, and effect on build/app size.
- Preserve unrelated changes. Do not include build output, credentials, or personal Xcode state.

## Validation

For code changes, build the affected configuration, run the regression suite below, and review the changed code. Test additions or updates require explicit maintainer agreement. AI-assisted visual testing requires explicit maintainer authorization.

### Automated tests

Select **Product > Test** in Xcode with the shared `NanoMD` scheme, or run this command from the repository root:

```sh
xcodebuild \
  -project NanoMD.xcodeproj \
  -scheme NanoMD \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$PWD/Temp/DerivedData" \
  -clonedSourcePackagesDirPath "$PWD/Temp/SourcePackages" \
  -packageCachePath "$PWD/Temp/PackageCache" \
  -onlyUsePackageVersionsFromResolvedFile \
  ARCHS=arm64 CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM= \
  test
```

`NanoMDTests/` is a separate Swift Testing target that imports the app's production code. It uses synthetic, in-memory inputs to cover exact UTF-8/BOM/line-ending preservation, invalid files, reload identities, front-matter recognition, link restrictions, Markdown semantics, and formatting-limit boundaries. The main-actor, serialized editor integration suite mounts the production SwiftUI editor in disposable AppKit windows with observable synthetic document bindings and native window undo managers. It covers typing and undo/redo publication, accepted reloads (including identical bytes), deferred reloads during simulated marked text, activation and hidden-editor focus, selection/scroll retention, and independent document histories. Tests and fixtures are not shipped in the app. No additional package dependency is required.

The same suite runs in GitHub Actions for pull requests and pushes to `main`. Build/test logs and the `.xcresult` bundle are retained for seven days. The editor harness simulates `NSTextInputClient` composition with `setMarkedText`, `insertText`, and `unmarkText`; it does not exercise a real input method or establish IME acceptance. Reload tests supply new document load identities to the binding; they do not exercise system revert/conflict acceptance. The suite does not establish autosave, save failures, recovery, full keyboard/menu dispatch, visual behavior, or accessibility; remaining lifecycle and interaction checks are tracked in [GitHub Issues](https://github.com/SiavashB/nano.md/issues).

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

The [Build workflow](.github/workflows/ci.yml) compiles Debug and Release and runs regression tests for pull requests and `main`. Runtime acceptance checks are performed locally before release. Track outstanding work in [GitHub Issues](https://github.com/SiavashB/nano.md/issues).

## Releases

Confirm regression tests passed for the release commit before tagging. Maintainers prepare a versioned `v*` tag on a commit included in `main`. The [release workflow](.github/workflows/release.yml) uses repository Actions secrets for Developer ID signing and notarization, then creates a draft with an arm64 ZIP and SHA-256 checksum. The tag's numeric version must match `MARKETING_VERSION`; increment `CURRENT_PROJECT_VERSION` for each release.

Verify the downloaded package's checksum, signature, notarization, entitlements, metadata, and relevant runtime behavior before publishing the draft. Keep README, website, and release notes consistent with the shipped package and the OS versions actually checked. Never move a published tag or replace a published binary. Publishing triggers the website workflow; confirm deployment succeeded.

## Website

The static site lives in `website/`. Its asset allowlist is `website/.assetsignore`; keep source files and deployment tooling out of published assets. Deployment uses the pinned Wrangler dependency and requires macOS, Node.js 22 or newer, and an authenticated GitHub CLI to verify the latest published app package.

```sh
npm --prefix website ci --cache ./Temp/npm-cache --logs-dir ./Temp/npm-logs
npm --prefix website run check
```

`check` synchronizes release metadata and validates packaging without publishing. Maintainers can authorize a local Cloudflare session with `npm --prefix website run login` and publish with `npm --prefix website run deploy`. Both check and deploy synchronize from the exact checksum-verified published ZIP; review generated changes before committing. Output stays under `Temp/`.

The [website workflow](.github/workflows/website.yml) uses the `CLOUDFLARE_API_TOKEN` repository Actions secret, separately from local login. Scope replacement tokens to the deployment account and the site's zone, rotate them before expiration, and verify a successful deployment after replacement. Keep credential values out of source, chat, and logs.

Website analytics are separate from the Mac app: `website/analytics.js` records page views and download clicks with an anonymous browser ID, referrer hostname, device category, and timezone. Its public Supabase key depends on database policies that permit anonymous inserts and restrict reads to administrators. Feedback messages are sent through the visitor's own email account.
