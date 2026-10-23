<p align="center">
  <img src="website/nano-md-icon.png" alt="nano.md app icon" width="80" height="80">
</p>

<h1 align="center">nano.md</h1>

<p align="center">
  A small, free, native Markdown reader and editor for macOS.
</p>

<p align="center">
  <a href="https://github.com/SiavashB/nano.md/releases"><img alt="Latest release, including betas" src="https://img.shields.io/github/v/release/SiavashB/nano.md?include_prereleases&amp;label=release"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/SiavashB/nano.md"></a>
  <a href="https://github.com/SiavashB/nano.md/actions/workflows/ci.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/SiavashB/nano.md/ci.yml?branch=main&amp;label=build"></a>
</p>

<p align="center">
  <a href="docs/images/nano-md-dark.png"><img src="docs/images/nano-md-dark.png" alt="nano.md displaying a SKILL.md file in Nano Dark, with a front-matter panel, code block, and table" width="800"></a>
</p>

<p align="center">
  <sub>SKILL.md in Nano Dark. The current release replaces the pictured UTF-8 footer label with Feedback.</sub>
</p>

## Download

**[Download nano.md 0.1.0 beta 8 for Apple Silicon](https://github.com/SiavashB/nano.md/releases/download/v0.1.0-beta.8/nano.md-v0.1.0-beta.8-arm64.zip)** · [Release notes and checksum](https://github.com/SiavashB/nano.md/releases/tag/v0.1.0-beta.8) · [Website](https://nano.thirdeyeds.com/)

Build 23 · **2.29 MB ZIP download** · **4.2 MB uncompressed app** (decimal MB).

Unzip and move `NanoMD.app` to Applications. The app is Developer ID signed and notarized; verify the ZIP with the release's `SHA256SUMS.txt`.

Requires Apple Silicon and macOS 15.0 or later. **Beta compatibility:** runtime checks on macOS 15 remain pending; see [issue #12](https://github.com/SiavashB/nano.md/issues/12).

## Why nano.md

- **Small and native.** Built with SwiftUI and AppKit, with a 4.2 MB app bundle.
- **Read and edit ordinary Markdown.** Open README files, notes, `AGENTS.md`, and `SKILL.md`. Switch between formatted reading and source editing with Control-R.
- **Native Find.** Search in Read or Edit with Command-F, then move between matches with Command-G.
- **Readable front matter.** Leading YAML metadata appears in a compact panel, while Edit keeps the original text.
- **Local and free.** No account, subscription, or paid tier. The Mac app has no telemetry or network entitlement and does not load remote resources. See the [privacy policy](https://nano.thirdeyeds.com/privacy).
- **Your preferred appearance.** Choose Nano Dark, Linen Light, or follow the system setting.

<a id="reading-and-editing"></a>
<a id="appearance"></a>
<a id="markdown-support"></a>

## Using nano.md

Open `.md` or `.markdown` files with Command-O or Finder's **Open With** menu. Existing files start in Read; new documents (Command-N) start in Edit. Saving and undo use the macOS document system.

Switch Read/Edit with Control-R, the toolbar, the footer button, or View > Edit/Read. Choose System, Light (Linen Light), or Dark (Nano Dark) from View > Appearance or the toolbar. Appearance applies to all windows and persists across launches.

Switching to Edit places the caret near the selected reader text, or near the top of the visible content when scrolled, and focuses the editor. On a supported trackpad, force-click text in Read to start editing near that location.

Find text in either mode with Command-F. Read searches displayed text; Edit searches Markdown source. Find appears over the document header, below the system toolbar, and highlights matches as you type. Command-G moves to the next match, Shift-Command-G to the previous match, and Escape closes the bar.

The reader supports headings, paragraphs, emphasis, lists, quotes, code blocks, pipe tables, HTTP/HTTPS links, and a selectable panel for leading YAML front matter. Metadata values stay literal; the app does not interpret YAML.

Files must be valid UTF-8. Saving preserves the loaded BOM and existing line endings; new files use UTF-8 without a BOM and LF. Inserted line breaks follow the file's first existing line ending, while pasted text keeps its own. Smart quotes, autocorrect, and automatic substitutions are disabled.

## Current limitations

- Images appear as text placeholders; code blocks have no syntax highlighting.
- CommonMark/GFM support is partial: HTML stays literal, task lists are noninteractive, and relative links, anchors, and non-web URL schemes do not navigate.
- Reader-to-editor positioning is approximate where rendered text or layouts differ. Returning to Read resets reader selection and scroll. Undo/redo requires editor focus.
- Documents over 1 MiB or beyond complexity limits fall back to selectable source.
- Apple Silicon only; no Intel build or Quick Look extension.

Remaining save-error, input-method, external-conflict, and recovery checks are tracked in [issue #11](https://github.com/SiavashB/nano.md/issues/11); broader interaction and accessibility checks are in [issue #13](https://github.com/SiavashB/nano.md/issues/13). Use the [bug report form](https://github.com/SiavashB/nano.md/issues/new?template=bug_report.yml) or [Feedback](https://nano.thirdeyeds.com/feedback) for ordinary problems. Feedback opens email options in your browser; you review and send the message through your own account. Report security vulnerabilities [privately](SECURITY.md).

## Build

Requires Xcode 26.6, Swift 6 language mode, and Apple Silicon. Open `NanoMD.xcodeproj`, select the `NanoMD` scheme, and run. For unsigned compilation from the repository root:

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

For a Release build, use `-configuration Release` and add `ENABLE_CODE_COVERAGE=NO` to apply the setting to app and package targets.

CI compiles Debug and Release and runs the `NanoMDTests` regression suite. The tests cover file-byte preservation, front matter, Markdown parsing and limits, and allowed link destinations. See [Contributing](CONTRIBUTING.md#automated-tests) to run them locally. These checks do not establish signing, UI behavior, or minimum-OS runtime compatibility.

## Contributing

See [Contributing](CONTRIBUTING.md) for development and validation, [GitHub Issues](https://github.com/SiavashB/nano.md/issues) for open work, and [GitHub Releases](https://github.com/SiavashB/nano.md/releases) for release notes.

## License

[MIT](LICENSE). The app bundles its license and [third-party notices](NanoMD/Resources/ThirdPartyNotices.txt).
