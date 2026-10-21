<p align="center">
  <img src="website/nano-md-icon.png" alt="nano.md app icon" width="128" height="128">
</p>

<h1 align="center">nano.md</h1>

<p align="center">
  A small, free, native Mac app for reading and editing Markdown, including <code>SKILL.md</code>, <code>AGENTS.md</code>, README files, and notes.
</p>

<p align="center">
  <a href="https://github.com/SiavashB/nano.md/releases"><img alt="Latest release, including betas" src="https://img.shields.io/github/v/release/SiavashB/nano.md?include_prereleases&amp;label=release"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/SiavashB/nano.md"></a>
  <img alt="macOS 15+ on Apple Silicon" src="https://img.shields.io/badge/macOS-15%2B%20%C2%B7%20Apple%20Silicon-black?logo=apple">
  <img alt="Uncompressed app size: 3.9 MB" src="https://img.shields.io/badge/app%20bundle-3.9%20MB-blue">
  <a href="https://github.com/SiavashB/nano.md/actions/workflows/ci.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/SiavashB/nano.md/ci.yml?branch=main&amp;label=build"></a>
</p>

## Download

**[Download nano.md 0.1.0 beta 4 for Apple Silicon](https://github.com/SiavashB/nano.md/releases/download/v0.1.0-beta.4/nano.md-v0.1.0-beta.4-arm64.zip)** · [Release notes and checksum](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.4) · [Website](https://nano.thirdeyeds.com/)

Build 18 · **2.19 MB ZIP download** · **3.9 MB uncompressed app** (decimal MB).

Requires macOS 15.0 or later on Apple Silicon. Unzip the download and move `NanoMD.app` to Applications. The app is Developer ID signed and notarized; verify the ZIP with the `SHA256SUMS.txt` attached to the release.

**Beta compatibility note:** the release targets macOS 15.0, but runtime checks on macOS 15 remain pending. See the [roadmap](docs/ROADMAP.md#macos-15-deployment-target-010-build-18). Please report problems in [Issues](https://github.com/SiavashB/nano.md/issues).

## Why nano.md

- **Free to read and edit.** No account, no subscription, no paid tier.
- **Edit your Markdown directly.** Saving writes the edited source, preserving the loaded UTF-8 BOM and existing line endings. It does not reconstruct your file from the rendered view. Smart quotes and autocorrect are off.
- **Works locally.** The Mac app has no network entitlement or telemetry and does not load images or other remote resources. Clicking an HTTP/HTTPS link opens it in your browser.
- **SKILL.md front matter is shown as a metadata panel** instead of being rendered as a heading. Edit mode keeps the original text.
- **Light and dark themes** (Linen Light, Nano Dark), or follow the system setting.
- **Small and native.** A 3.9 MB app bundle built with SwiftUI and AppKit. Markdown parsing uses [Swift Markdown](https://github.com/swiftlang/swift-markdown), which depends on swift-cmark. No WebView or Electron.

## Current limitations

- Images are not loaded; they appear as text placeholders.
- No syntax highlighting in code blocks.
- Partial CommonMark/GFM: HTML shows as literal text, task lists aren't interactive, and relative links and anchors don't navigate. See [Markdown support](#markdown-support).
- Apple Silicon only. There is no Intel or universal build.
- No Quick Look extension.

## Reading and editing

Open a `.md` or `.markdown` file with File > Open (Command-O) or Finder's **Open With** menu. Each document opens in its own window in **Read** mode. Switch to **Edit** to change the literal Markdown in a monospaced plain-text editor, then switch back to Read to see the rendered result. New documents (Command-N) start in Edit. Saving, undo, redo, and the keep-changes prompt on close or quit follow the standard macOS document behavior.

- The editor keeps its selection, scroll position, and undo history across mode switches. The reader's selection and scroll reset when you return to Read.
- After switching to Edit, click the editor or press Tab to focus it; undo/redo shortcuts need editor focus.
- Files must be valid UTF-8, with or without a BOM. Invalid encodings show an error instead of silently replacing characters. Empty files are fine.
- Inserted line breaks follow the file's first existing line ending (LF for new documents). Pasted text keeps its own line endings.

Failed saves, external file conflicts, input-method composition, and other remaining cases are tracked in the [roadmap](docs/ROADMAP.md#4-source-editing).

## Appearance

Choose **System**, **Light** (Linen Light), or **Dark** (Nano Dark) from **View > Appearance** or the segmented control on the right of the toolbar. System is the default. The choice applies to all windows and persists across launches. Changing it restyles the current views without touching the document source or undo history.

The development checkout also includes a clickable footer shortcut: **^R Edit** / **^R Read** (Control-R) switches the active document's mode. The same action is available from **View > Edit/Read**. This control is not part of the beta 4 download above; runtime checks remain tracked in the [roadmap](docs/ROADMAP.md#footer-shortcuts-development-checkout).

The development checkout replaces the footer's UTF-8 label with a borderless green **Feedback** link that opens [feedback options](https://nano.thirdeyeds.com/feedback) in your browser: send with Gmail, open your email app, or copy `feedback@thirdeyeds.com`. The address is also available in **About nano.md**. These feedback controls are not part of the beta 4 download above.

## Markdown support

- Headings, paragraphs, emphasis, strong emphasis, inline code, and fenced/indented code blocks.
- Nested ordered and unordered lists, blockquotes, thematic breaks, and clickable HTTP/HTTPS links.
- Pipe tables with styled headers, cell borders, column alignment, and inline formatting.
- Leading YAML front matter (a `---` line, at least one `key: value` field, then `---` or `...`) appears in a compact, selectable metadata panel. Keys may be plain names (letters, numbers, `-`, `_`, `.`) or single-line quoted names. The field's separator colon must be followed by whitespace or the end of the line. This is a limited recognizer, not a YAML parser: values stay literal text. See the [recognition subset](docs/ARCHITECTURE.md#initial-rendering-scope).
- Images appear as text placeholders with their description and destination.
- HTML and unsupported blocks stay readable as literal text. Task markers are plain text.
- Relative links, anchors, and non-web URL schemes are shown but don't navigate.

Parsing runs off the main thread. Documents over 1 MiB, or with excessive nesting or node counts, fall back to selectable source with an explanation. These are conservative initial limits, not a measured performance guarantee.

## Build

Requires Xcode 26.6. The project uses Swift 6 language mode, a macOS 15.0 deployment target, and builds for Apple Silicon (`arm64`) only.

Open `NanoMD.xcodeproj`, select the `NanoMD` scheme, and run. For a local build without a signing team, run from the repository root:

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
  ARCHS=arm64 CODE_SIGNING_ALLOWED=NO \
  build
```

This checks compilation only; it doesn't validate signing or distribution. Swift Package Manager resolves Swift Markdown 0.8.0 and swift-cmark 0.9.0 from the included `Package.resolved`. There are no test targets. The build badge reports compilation, not functional or compatibility testing. See [CONTRIBUTING.md](CONTRIBUTING.md) for validation expectations.

For app-size measurements, build with `-configuration Release`, then run `npm --prefix website run update-app-size -- "$PWD/Temp/DerivedData/Build/Products/Release/NanoMD.app"`. See the [measurement policy](CONTRIBUTING.md#app-size-measurements).

## Project documentation

- [Architecture](docs/ARCHITECTURE.md): boundaries, state ownership, rendering decisions, and source editing.
- [Roadmap](docs/ROADMAP.md): milestones, completion criteria, and open verification items.
- [AI development rules](AGENTS.md): repository-wide instructions for coding agents.
- [Contributing](CONTRIBUTING.md): change scope, validation, and review expectations.
- [Releasing](docs/RELEASING.md): build-only CI, local AI-assisted checks, and version-tagged draft releases.
- [Website](website/README.md): landing page source and deployment.

## License

nano.md is licensed under the [MIT License](LICENSE), which is included in the app bundle. Dependency licenses and notices are in [ThirdPartyNotices.txt](NanoMD/Resources/ThirdPartyNotices.txt), also bundled with the app.
