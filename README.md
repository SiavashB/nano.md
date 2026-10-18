<p align="center">
  <img src="website/nano-md-icon.png" alt="nano.md app icon" width="128" height="128">
</p>

<h1 align="center">nano.md</h1>

<p align="center">
  A small, free, native Mac app for reading and editing <code>SKILL.md</code>, <code>AGENTS.md</code>, and the other Markdown you give your AI tools.
</p>

<p align="center">
  <a href="https://github.com/SiavashB/nano.md/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/SiavashB/nano.md?include_prereleases&label=release"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/SiavashB/nano.md"></a>
  <img alt="macOS 15+ on Apple Silicon" src="https://img.shields.io/badge/macOS-15%2B%20%C2%B7%20Apple%20Silicon-black?logo=apple">
  <img alt="App size about 4 MB" src="https://img.shields.io/badge/app%20size-3.9%20MB-blue">
  <a href="https://github.com/SiavashB/nano.md/actions/workflows/ci.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/SiavashB/nano.md/ci.yml?branch=main&label=build"></a>
</p>

<!--
  HERO GIF (add before launch)
  Suggested file: docs/images/nano-md-demo.gif  (5-10 s, under ~3 MB, ~1200 px wide)
  Show: Finder > Open With nano.md on an AGENTS.md > Read view > switch to Edit > change a line > Command-S > back to Read.
  Then uncomment:
  <p align="center"><img src="docs/images/nano-md-demo.gif" alt="Opening an AGENTS.md file in nano.md, editing it, and saving" width="800"></p>
-->

## Download

**[Download nano.md 0.1.0 beta 4](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.4)** (build 18, 2.19 MB ZIP) · [nano.thirdeyeds.com](https://nano.thirdeyeds.com/)

Requires macOS 15.0 or later on Apple Silicon. Unzip the download and move `NanoMD.app` to Applications. The app is Developer ID signed and notarized; verify the ZIP with the `SHA256SUMS.txt` attached to the release.

nano.md is a beta. Please report problems in [Issues](https://github.com/SiavashB/nano.md/issues).

<!--
  SCREENSHOTS (add before launch)
  Suggested files:
    docs/images/read-dark.png   - Read mode, Nano Dark theme, a SKILL.md with its front matter panel and a table
    docs/images/read-light.png  - Read mode, Linen Light theme, same document
    docs/images/edit.png        - Edit mode showing the literal Markdown source
  Then uncomment:
  <p align="center">
    <img src="docs/images/read-dark.png" alt="nano.md Read mode in the Nano Dark theme" width="49%">
    <img src="docs/images/read-light.png" alt="nano.md Read mode in the Linen Light theme" width="49%">
  </p>
-->

## Why nano.md

- **Free to read and edit.** No account, no subscription, no paid tier.
- **Saves your source as-is.** Edit mode is the literal Markdown in a plain-text editor. Saving keeps the file's UTF-8 BOM and line endings, and smart quotes and autocorrect are off, so nothing gets reformatted behind your back.
- **The app makes no network calls.** It is sandboxed with no network entitlement, has no telemetry, and never loads images or other remote resources.
- **SKILL.md front matter is shown as a metadata panel** instead of being rendered as a heading. Edit mode keeps the original text.
- **Light and dark themes** (Linen Light, Nano Dark), or follow the system setting.
- **Small and readable.** A native SwiftUI/AppKit app in about 1,300 lines of Swift, with one Markdown dependency ([Swift Markdown](https://github.com/swiftlang/swift-markdown)). No WebView, no Electron.

## What it isn't (yet)

- Images are not loaded; they appear as text placeholders.
- No syntax highlighting in code blocks.
- Partial CommonMark/GFM: HTML shows as literal text, task lists aren't interactive, and relative links and anchors don't navigate. See [Markdown support](#markdown-support).
- Apple Silicon only. There is no Intel or universal build.
- macOS 15 support is new in beta 4. It builds for macOS 15, but runtime checks on macOS 15 are still pending ([roadmap](docs/ROADMAP.md)).
- No Quick Look extension and no automated test suite yet.

## Reading and editing

Open a `.md` or `.markdown` file with File > Open (Command-O) or Finder's **Open With** menu. Each document opens in its own window in **Read** mode. Switch to **Edit** to change the literal Markdown in a monospaced plain-text editor, then switch back to Read to see the rendered result. New documents (Command-N) start in Edit. Saving, undo, redo, and the keep-changes prompt on close or quit follow the standard macOS document behavior.

- The editor keeps its selection, scroll position, and undo history across mode switches. The reader's selection and scroll reset when you return to Read.
- After switching to Edit, click the editor or press Tab to focus it; undo/redo shortcuts need editor focus.
- Files must be valid UTF-8, with or without a BOM. Invalid encodings show an error instead of silently replacing characters. Empty files are fine.
- New line breaks follow the file's first existing line ending (LF for new documents). Pasted text keeps its own line endings.

Failed saves, external file conflicts, input-method composition, and other remaining cases are tracked in the [roadmap](docs/ROADMAP.md#4-source-editing).

## Appearance

Choose **System**, **Light** (Linen Light), or **Dark** (Nano Dark) from **View > Appearance** or the segmented control on the right of the toolbar. System is the default. The choice applies to all windows and persists across launches. Changing it restyles the current views without touching the document source or undo history.

## Markdown support

- Headings, paragraphs, emphasis, strong emphasis, inline code, and fenced/indented code blocks.
- Nested ordered and unordered lists, blockquotes, thematic breaks, and clickable HTTP/HTTPS links.
- Pipe tables with styled headers, cell borders, column alignment, and inline formatting.
- Leading YAML front matter (a `---` line, at least one `key: value` field, then `---` or `...`) appears in a compact, selectable metadata panel. Keys may be plain names (letters, numbers, `-`, `_`, `.`) or single-line quoted names. This is a limited recognizer, not a YAML parser: values stay literal text. See the [recognition subset](docs/ARCHITECTURE.md#initial-rendering-scope).
- Images appear as text placeholders with their description and destination.
- HTML and unsupported blocks stay readable as literal text. Task markers are plain text.
- Relative links, anchors, and non-web URL schemes are shown but don't navigate.

Parsing runs off the main thread. Documents over 1 MiB, or with excessive nesting or node counts, fall back to selectable source with an explanation. These are conservative initial limits, not a measured performance guarantee.

## Build from source

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

This checks compilation only; it doesn't validate signing or distribution. Swift Package Manager resolves Swift Markdown 0.8.0 and swift-cmark 0.9.0 from the included `Package.resolved`. There are no test targets yet.

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
