# Using nano.md

For installation and compatibility, see the [README](../README.md#download).

## Reading and editing

Open a `.md` or `.markdown` file with File > Open (Command-O) or Finder's **Open With** menu. Each document opens in its own window in **Read** mode. New documents (Command-N) start in **Edit**.

Switch modes with the toolbar, Control-R, the **^R Edit** / **^R Read** footer button, or **View > Edit/Read**. Edit shows the literal Markdown in a monospaced plain-text editor; return to Read to render the current source, including unsaved edits.

Saving, undo, redo, and the keep-changes prompt on close or quit use the macOS document system.

- The editor keeps its selection, scroll position, and undo history across mode switches.
- The reader's selection and scroll reset when returning to Read.
- After switching to Edit, click the editor or press Tab to focus it. Undo/redo shortcuts require editor focus.

## Files and source preservation

Saving writes the Markdown source directly, preserving the loaded UTF-8 BOM and existing line endings. It does not reconstruct the file from rendered content.

- Files must be valid UTF-8, with or without a BOM. Invalid encodings show an error instead of silently replacing characters. Empty files are supported.
- New documents use UTF-8 without a BOM and LF line endings.
- Inserted line breaks follow the file's first existing line ending. Pasted text keeps its own line endings.
- Smart quotes, autocorrect, and automatic text substitutions are disabled.

Failed saves, external file conflicts, input-method composition, and remaining preservation checks are tracked under [document reliability](ROADMAP.md#1-document-reliability).

## Appearance

Choose **System**, **Light** (Linen Light), or **Dark** (Nano Dark) from **View > Appearance** or the segmented control on the right of the toolbar. System is the default. The preference applies to all windows and persists across launches.

Changing appearance restyles the views without modifying the document source or undo history. Remaining interaction and appearance checks are listed in the [roadmap](ROADMAP.md#3-interaction-appearance-and-accessibility).

## Markdown support

- Headings, paragraphs, emphasis, strong emphasis, inline code, and fenced/indented code blocks.
- Nested ordered and unordered lists, blockquotes, thematic breaks, and clickable HTTP/HTTPS links.
- Pipe tables with styled headers, cell borders, column alignment, and inline formatting.
- Leading YAML front matter displayed as a compact, selectable metadata panel.

Front matter begins with an exact `---` line, contains at least one `key: value` field, and ends with `---` or `...`. Keys may be plain names containing letters, numbers, hyphens, underscores, or dots, or single-line quoted names. The separator colon must be followed by whitespace or end of line. Values remain literal text; this is a limited recognizer rather than a YAML parser. See the [recognition rules](ARCHITECTURE.md#front-matter).

Images appear as text placeholders with their description and destination. HTML and unsupported blocks remain readable as literal text. Task markers are noninteractive, and code blocks have no syntax highlighting. Relative links, anchors, and non-web URL schemes are shown but do not navigate.

Parsing runs off the main thread. Documents over 1 MiB, or with excessive nesting or node counts, fall back to selectable source with an explanation. These are conservative limits, not measured performance guarantees.

## Privacy and feedback

The Mac app has no telemetry or network entitlement and does not load images or other remote resources. Activating an HTTP/HTTPS document link opens it in the default browser.

The **Feedback** footer link opens [feedback options](https://nano.thirdeyeds.com/feedback) in your browser: send with Gmail, open your email app, or copy `feedback@thirdeyeds.com`. You review and send the message through your own account. The address is also available in **About nano.md**.

Website analytics are separate from the native app; see the [website documentation](../website/README.md#visit-and-download-tracking).
