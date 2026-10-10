# Nano.MD

A lightweight native macOS app for reading Markdown files, with source editing planned for a later milestone.

**Status:** read-only Markdown reader. NanoMD opens `.md` and `.markdown` files with native formatting and continuous text selection.

## Read a document

Use File > Open (Command-O) or Finder's Open With menu to open a Markdown file. Each document has its own window. Select text to copy it; the reader does not offer document creation, editing, or saving.

Files must contain valid UTF-8, with or without a byte-order mark (BOM). Empty files are supported. Invalid encodings produce an error instead of silently replacing characters. The reader never loads images or other resources automatically.

## Markdown support

- Headings, paragraphs, emphasis, strong emphasis, inline code, and fenced/indented code blocks.
- Nested ordered/unordered lists, blockquotes, thematic breaks, and clickable HTTP/HTTPS links.
- Pipe tables with styled headers, cell borders, column alignment, and inline formatting.
- Images appear as text placeholders containing their description and destination.
- HTML and unsupported blocks remain readable as literal text. Task markers remain text; they are not interactive controls.
- Relative links, anchors, and non-web URL schemes are shown without navigation.

Parsing runs off the main thread. Documents over 1 MiB, or with excessive nesting/node counts, fall back to selectable source with an explanation. These are conservative initial limits, not a measured performance guarantee. Full CommonMark/GFM presentation, image loading, syntax highlighting, and editing are not yet supported.

## Direction

- Native document windows, selectable text, keyboard interaction, and accessible reading.
- Local files remain ordinary Markdown files. The reader never rewrites them.
- SwiftUI application shell, native text presentation, and a separate Markdown parsing boundary.
- A small dependency footprint and measured performance.

## Build

The project uses Xcode 26.6, Swift 6 language mode, and a macOS 26.5 deployment target. The broader compatibility policy has not yet been finalized.

Open `NanoMD.xcodeproj`, select the `NanoMD` scheme, and run the macOS app. For a local build without configuring a signing team, run from the repository root:

```sh
xcodebuild \
  -project NanoMD.xcodeproj \
  -scheme NanoMD \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$PWD/Temp/DerivedData" \
  -clonedSourcePackagesDirPath "$PWD/Temp/SourcePackages" \
  -packageCachePath "$PWD/Temp/PackageCache" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

This checks compilation; it does not validate signing or distribution. Swift Package Manager resolves Swift Markdown 0.8.0 and swift-cmark 0.9.0 using the included `Package.resolved` file. There are no test targets. See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

## Project documentation

- [Architecture](docs/ARCHITECTURE.md): boundaries, state ownership, rendering decisions, and the path to editing.
- [Roadmap](docs/ROADMAP.md): implementation milestones and completion criteria.
- [AI development rules](AGENTS.md): repository-wide instructions for coding agents.
- [Contributing](CONTRIBUTING.md): change scope, validation, and review expectations.

## License

An open-source release is planned. A project license has not yet been selected. Dependency licenses and notices are retained in [ThirdPartyNotices.txt](NanoMD/Resources/ThirdPartyNotices.txt), which is also included in the app bundle.
