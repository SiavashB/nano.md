# Nano.MD

A lightweight native macOS app for reading and editing Markdown files.

**Status:** [0.1.0 beta 3](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.3), build 11, is signed and notarized and adds compact SKILL.md metadata panels. The downloaded app passed opening, metadata rendering, editing, undo/redo, saving, and reopening checks. Broader runtime cases remain tracked in the [roadmap](docs/ROADMAP.md). nano.md opens `.md` and `.markdown` files with native formatting and continuous text selection.

## Read and edit a document

Use File > Open (Command-O) or Finder's Open With menu to open a Markdown file. Each document has its own window and initially opens in Read mode. Use the Read/Edit control to edit the literal Markdown in a native, plain-text monospaced editor, then return to Read to render the current source. New documents (Command-N) start in Edit. Standard File and Edit commands provide saving, undo, and redo through the macOS document lifecycle. The app requests macOS’s native keep-changes confirmation when closing modified documents or quitting, including documents that have been autosaved. Explicitly saved, unchanged documents can close directly. Save, discard, and cancel were verified for closing documents and quitting with multiple edited windows.

The editor stays alive across mode switches to retain selection, scroll position, and native undo targets. The reader's selection and scroll position reset on returning to Read. After switching to Edit, click the editor or press Tab to focus it; undo/redo shortcuts require editor focus. Source is saved directly as UTF-8, retaining the loaded BOM and existing line endings; newly inserted line breaks follow the first existing line ending, or LF for a new document. Pasted plain text retains its own line endings. Smart substitutions and automatic correction are disabled. Failed saves, external conflicts, input-method composition, and other remaining runtime cases are tracked in the [roadmap](docs/ROADMAP.md#4-source-editing).

Files must contain valid UTF-8, with or without a byte-order mark (BOM). Empty files are supported. Invalid encodings produce an error instead of silently replacing characters. The reader never loads images or other resources automatically.

## Appearance

Choose **System**, **Light**, or **Dark** from **View > Appearance** in the menu bar or **Appearance** on the right of the document toolbar. The Read/Edit control sits in the toolbar's center. System is the default and follows macOS appearance; Light uses Linen Light and Dark uses Nano Dark. Previously saved explicit theme choices remain selected. This app-wide preference persists across launches and updates all document windows, including the plain-source editor and source fallback. Both palettes use native monospaced system fonts, the same layout, and outlined code blocks. The compact content header and footer show the document scene's filename, or Untitled until saved; the footer also shows UTF-8.

Appearance changes restyle the existing native views without changing the document source or undo history. The reader retains its current parsed content to restyle without parsing again, preserving selection and scroll position where layout permits. Editor text-color updates wait for active input-method composition to finish. The three appearance modes and toolbar placement are implemented in build 10; visual appearance and runtime behavior, including following macOS changes in System mode, still require manual verification. The previous build's focused UI results do not validate these changes.

## Markdown support

- Headings, paragraphs, emphasis, strong emphasis, inline code, and fenced/indented code blocks.
- Nested ordered/unordered lists, blockquotes, thematic breaks, and clickable HTTP/HTTPS links.
- Pipe tables with styled headers, cell borders, column alignment, and inline formatting.
- Leading YAML front matter, including SKILL.md names and descriptions, appears in a compact, selectable metadata panel styled with the selected theme. All fields remain literal text; Edit retains the original source.
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
- [Releasing](docs/RELEASING.md): build-only CI, local AI-assisted checks, and version-tagged draft releases.
- [Website](website/README.md): landing page source and Cloudflare deployment commands.

## License

nano.md is licensed under the [MIT License](LICENSE), which is included in the app bundle. Dependency licenses and notices are retained in [ThirdPartyNotices.txt](NanoMD/Resources/ThirdPartyNotices.txt), which is also bundled. Download the signed, notarized [0.1.0 beta 3 release](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.3) for Apple Silicon and macOS 26.5 or later.
