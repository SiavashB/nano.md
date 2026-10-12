# Nano.MD

A lightweight native macOS app for reading and editing Markdown files.

**Status:** source editing is implemented and build-verified; runtime editing checks remain pending. nano.md opens `.md` and `.markdown` files with native formatting and continuous text selection.

## Read and edit a document

Use File > Open (Command-O) or Finder's Open With menu to open a Markdown file. Each document has its own window and initially opens in Read mode. Use the Read/Edit control to edit the literal Markdown in a native, plain-text monospaced editor, then return to Read to render the current source. New documents (Command-N) start in Edit. Standard File and Edit commands provide saving, undo, and redo through the macOS document lifecycle. The app requests macOS’s native keep-changes confirmation when closing modified documents or quitting, including documents that have been autosaved. Explicitly saved, unchanged documents can close directly. Confirmation behavior still awaits runtime verification.

The editor stays alive across mode switches to retain selection, scroll position, and native undo targets. Source is saved directly as UTF-8, retaining the loaded BOM and existing line endings; newly inserted line breaks follow the first existing line ending, or LF for a new document. Pasted plain text retains its own line endings. Smart substitutions and automatic correction are disabled. Save/reopen, undo across modes, failed saves, external conflicts, and input-method composition still need authorized runtime verification.

Files must contain valid UTF-8, with or without a byte-order mark (BOM). Empty files are supported. Invalid encodings produce an error instead of silently replacing characters. The reader never loads images or other resources automatically.

## Markdown support

- Headings, paragraphs, emphasis, strong emphasis, inline code, and fenced/indented code blocks.
- Nested ordered/unordered lists, blockquotes, thematic breaks, and clickable HTTP/HTTPS links.
- Pipe tables with styled headers, cell borders, column alignment, and inline formatting.
- Images appear as text placeholders containing their description and destination.
- HTML and unsupported blocks remain readable as literal text. Task markers remain text; they are not interactive controls.
- Relative links, anchors, and non-web URL schemes are shown without navigation.

Parsing runs off the main thread. Documents over 1 MiB, or with excessive nesting/node counts, fall back to selectable source with an explanation. These are conservative initial limits, not a measured performance guarantee. Full CommonMark/GFM presentation, image loading, syntax highlighting, and richer editing controls are not yet supported.

## Direction

- Native document windows, selectable text, keyboard interaction, and accessible reading.
- Local files remain ordinary Markdown files. Saving writes the authoritative source; the reader never rewrites it.
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

- [Architecture](docs/ARCHITECTURE.md): boundaries, state ownership, rendering decisions, and source editing.
- [Roadmap](docs/ROADMAP.md): implementation milestones and completion criteria.
- [AI development rules](AGENTS.md): repository-wide instructions for coding agents.
- [Contributing](CONTRIBUTING.md): change scope, validation, and review expectations.

## License

An open-source release is planned. A project license has not yet been selected. Dependency licenses and notices are retained in [ThirdPartyNotices.txt](NanoMD/Resources/ThirdPartyNotices.txt), which is also included in the app bundle.
