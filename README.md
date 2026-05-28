# Pandoc Extension for VSCode

Convert Markdown files to DOCX, HTML and PDF using Pandoc directly from Visual Studio Code.

This extension integrates Pandoc into Visual Studio Code, allowing you to convert Markdown documents to various formats without leaving your editor.

## Key Features

- **Single file or folder conversion** - Convert one file or an entire folder
- **Customizable options** - Configure Pandoc command-line arguments
- **Multiple output formats** - HTML, PDF, DOCX, and more
- **Built-in filters** - Page breaks, custom header IDs, Mermaid diagrams, and HTML line breaks

### Single File Conversion

Convert individual Markdown files to DOCX, HTML, or PDF using two convenient methods:

- **Right-click** on any Markdown file in the Explorer or Editor → **Pandoc** submenu → Choose format
- **Command Palette** (`Ctrl+Shift+P` / `Cmd+Shift+P`): Open a Markdown file and run:
  - `Pandoc: Convert Markdown to DOCX`
  - `Pandoc: Convert Markdown to HTML`
  - `Pandoc: Convert Markdown to PDF`

### Folder Conversion

Combine and convert all Markdown files in a folder into a single document:

- **Right-click** on any folder in the Explorer → **Pandoc** submenu → Choose format:
  - `Pandoc: Convert All Markdown to DOCX`
  - `Pandoc: Convert All Markdown to HTML`
  - `Pandoc: Convert All Markdown to PDF`

### Generate Sample Markdown

Create a ready-to-use sample Markdown file that demonstrates all built-in filter features:

- Open the **Command Palette** (`Ctrl+Shift+P` / `Cmd+Shift+P`)
- Run `Pandoc: Generate Sample Markdown`
- The sample file is created in your workspace

## Requirements

**Pandoc must be installed on your system** before using this extension.

### Installing Pandoc

- **macOS**: `brew install pandoc`
- **Windows**: Download from [pandoc.org](https://pandoc.org/installing.html)
- **Linux**: `sudo apt-get install pandoc` (Debian/Ubuntu) or `sudo dnf install pandoc` (Fedora)

Verify installation by running `pandoc --version` in your terminal.

### Optional: Install Mermaid CLI for Diagram Support
To render Mermaid diagrams in your documents, install the Mermaid CLI:

Requires Node.js and npm to be installed first.

```sh
npm install -g @mermaid-js/mermaid-cli
```

### Required for PDF Output: Install a LaTeX Engine

Pandoc does not generate PDFs directly — it hands off to a LaTeX engine (`xelatex` is recommended for Unicode support). Install one of the following:

- **macOS** — [MacTeX](https://tug.org/mactex/) (full, ~4 GB) or BasicTeX (minimal, ~100 MB):
  ```sh
  brew install --cask mactex-no-gui    # full
  # or
  brew install --cask basictex         # minimal
  ```
- **Windows** — [MiKTeX](https://miktex.org/download) or [TeX Live](https://tug.org/texlive/)
- **Linux** — `sudo apt-get install texlive-xetex` (Debian/Ubuntu) or `sudo dnf install texlive-xetex` (Fedora)

Verify with `xelatex --version`. After installing, **fully quit and relaunch VS Code** so the extension picks up the updated `PATH` — without this you may see a `xelatex: createProcess: find_executable: failed` error even though `xelatex` works in your terminal.

If you need a non-LaTeX path, Pandoc also supports `--pdf-engine=wkhtmltopdf`, `weasyprint`, or `typst` — set this via `pandoc.pdf.commonArgs`.

## Extension Settings

This extension contributes the following settings:

### General Settings

* `pandoc.path`: Optional absolute path to the pandoc executable. If empty, 'pandoc' from PATH is used.
* `pandoc.outputDir`: Default output directory. Leave empty to use the source file's directory. Relative paths are resolved against the workspace folder.

### Filters

* `pandoc.filters`: Ordered list of Lua filters to apply during conversion. Filters are executed in the order listed.

Built-in filters use the `builtin:` prefix. The defaults are:

| Filter | Description |
|--------|-------------|
| `builtin:header-id-from-comment` | Custom header IDs via `<!-- {#id} -->` comments and cross-reference linking |
| `builtin:html-br-to-linebreak` | Converts `<br>` tags to native line breaks |
| `builtin:mermaid-filter` | Renders Mermaid diagrams as images (requires [mermaid-cli](https://github.com/mermaid-js/mermaid-cli): `npm install -g @mermaid-js/mermaid-cli`) |
| `builtin:page-break` | Converts `<!-- pagebreak -->` comments to page breaks |

To add your own filters, use absolute paths or `${workspaceFolder}`:

```json
{
  "pandoc.filters": [
    "builtin:header-id-from-comment",
    "builtin:page-break",
    "${workspaceFolder}/my-filters/custom.lua"
  ]
}
```

To disable all filters, set to an empty array: `"pandoc.filters": []`

> **Note:** The Mermaid filter generates a `mermaid-images/` directory for cached diagram images. Consider adding it to your `.gitignore`.

### Conversion Arguments

* `pandoc.{format}.commonArgs`: Pandoc arguments for the specified format (e.g. `--reference-doc`, `--toc`, `--css`).
* `pandoc.{format}.singleFileCustomArgs`: Additional arguments when converting a single file. Merged with `commonArgs`.
* `pandoc.{format}.multipleFilesCustomArgs`: Additional arguments when converting multiple files. Merged with `commonArgs`.

Where `{format}` is `docx`, `html`, or `pdf`.

> **Note:** `customArgs` is deprecated in favour of `commonArgs`. If both are defined, `commonArgs` takes precedence.

### Example Configuration

```json
{
  "pandoc.path": "/usr/local/bin/pandoc",
  "pandoc.outputDir": "${workspaceFolder}/output",
  "pandoc.filters": [
    "builtin:header-id-from-comment",
    "builtin:html-br-to-linebreak",
    "builtin:mermaid-filter",
    "builtin:page-break",
    "${workspaceFolder}/my-project-filters/word-count.lua"
  ],
  "pandoc.docx.commonArgs": [
    "--reference-doc=${workspaceFolder}/my-project-templates/template.docx"
  ],
  "pandoc.docx.singleFileCustomArgs": [
    "--resource-path=../images:./images"
  ],
  "pandoc.docx.multipleFilesCustomArgs": [
    "--reference-doc=${workspaceFolder}/my-project-templates/template-with-cover.docx",
    "--number-sections",
    "--toc"
  ],
  "pandoc.html.commonArgs": [
    "--standalone",
    "--embed-resources"
  ],
  "pandoc.pdf.commonArgs": [
    "--pdf-engine=xelatex"
  ]
}
```

### Format-Specific Notes

- **HTML** — Without `--standalone --embed-resources`, Pandoc emits an unstyled HTML fragment with no `<html>`/`<head>` wrapper, and Mermaid images are referenced by relative path (so moving the `.html` file breaks them). Adding these args produces a single self-contained file with syntax-highlighting CSS and base64-inlined images.
- **PDF** — Requires a TeX install (MacTeX or TinyTeX on macOS, MiKTeX on Windows). Use `--pdf-engine=xelatex` or `lualatex` to handle Unicode characters; the default `pdflatex` will fail on common symbols like `•`.

## Usage

### Convert a Single File

#### Method 1: Right-Click Menu (Explorer or Editor)
1. Right-click on a Markdown file in the Explorer or inside the editor
2. Select **"Pandoc"** from the context menu
3. Choose your desired format:
   - **Convert Markdown to DOCX**
   - **Convert Markdown to HTML**
   - **Convert Markdown to PDF**
4. The converted file appears in the same directory (or your configured `pandoc.outputDir`)

#### Method 2: Command Palette
1. Open a Markdown file in the editor
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
3. Type **"Pandoc"** and select one of:
   - **Pandoc: Convert Markdown to DOCX**
   - **Pandoc: Convert Markdown to HTML**
   - **Pandoc: Convert Markdown to PDF**
4. Done!

### Convert an Entire Folder

1. Right-click on any folder in the Explorer
2. Select **"Pandoc"** from the context menu
3. Choose your desired format:
   - **Convert All Markdown to DOCX**
   - **Convert All Markdown to HTML**
   - **Convert All Markdown to PDF**
4. All Markdown files (`.md`) in the folder will be converted
5. Converted files are saved with the same names in the new format

### Generate Sample Markdown

This sample demonstrates how the built-in filters work together and provides a practical formatting reference you can reuse to produce cleaner structure, more consistent styling, and higher-quality DOCX, HTML, and PDF output.

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Run **Pandoc: Generate Sample Markdown**
3. A sample file is created in your workspace demonstrating built-in filters

## Supported Conversions

### Input Formats
- Markdown (`.md`, `.markdown`)

### Output Formats
- **DOCX** - Microsoft Word documents
- **HTML** - Web-ready documents
- **PDF** - Requires LaTeX installation (e.g., xelatex, pdflatex)

## Release Notes

### 0.2.1

- Documented LaTeX engine prerequisite for PDF output, including install commands per OS and the VS Code restart needed for `PATH` updates

### 0.2.0

- Built-in Lua filters auto-applied on every conversion (page breaks, header IDs, Mermaid diagrams, HTML line breaks)
- New `pandoc.filters` setting for full control over filter selection and ordering
- Renamed `customArgs` to `commonArgs` (old name still works)
- New command: "Pandoc: Generate Sample Markdown"

### 0.0.1

Initial release of Pandoc VSCode Extension:
- Convert single Markdown files via right-click or Command Palette
- Convert entire folders of Markdown files at once
- Configurable output settings and Pandoc options
- Support for all Pandoc output formats

---

## Contributing

Contributions are welcome! Please visit our [GitHub repository](https://github.com/ayoussef-insight/pandoc-vscode) to:

- Report bugs
- Suggest features
- Submit pull requests

## License

This extension is licensed under the [MIT License](./LICENSE).

## Acknowledgements

This extension is powered by [Pandoc](https://pandoc.org/), a universal document converter by John MacFarlane.

