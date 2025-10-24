# Pandoc Markdown Converter for VSCode

Convert your Markdown files to DOCX, HTML, and PDF formats using [Pandoc](https://pandoc.org/) directly from VSCode.

## Features

- **Convert Markdown to DOCX, HTML, and PDF** using Pandoc
- **Command Palette Integration**: Access conversion commands from the Command Palette
- **Context Menu**: Right-click on Markdown files in the editor or Explorer to convert
- **Per-Format Configuration**: Customize Pandoc options for each output format
- **Auto-Open**: Converted files open automatically after successful conversion
- **Flexible Output**: Configure default output directory or use the source file's directory

## Requirements

**Pandoc must be installed on your system.** 

Download and install Pandoc from: [https://pandoc.org/installing.html](https://pandoc.org/installing.html)

After installation, ensure `pandoc` is available in your PATH, or configure the `pandoc.path` setting.

## Usage

### From Command Palette

1. Open a Markdown file (`.md`)
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
3. Type "Pandoc" and select:
   - **Pandoc: Convert Markdown to DOCX**
   - **Pandoc: Convert Markdown to HTML**
   - **Pandoc: Convert Markdown to PDF**

### From Context Menu

1. Right-click in an open Markdown editor, or
2. Right-click on a `.md` file in the Explorer
3. Select one of the conversion options

The converted file will be created and automatically opened.

## Configuration

Access settings via `Preferences > Settings` and search for "Pandoc".

### General Settings

- **`pandoc.path`** (string, default: `""`): Optional absolute path to the `pandoc` executable. Leave empty to use `pandoc` from PATH.
- **`pandoc.outputDir`** (string, default: `""`): Default output directory. Leave empty to save in the same directory as the source file. Relative paths are resolved against the workspace folder.

### DOCX Settings

- **`pandoc.docx.referenceDoc`** (string, default: `""`): Path to a reference DOCX file for custom styling (`--reference-doc`).
- **`pandoc.docx.numberSections`** (boolean, default: `false`): Add section numbers (`--number-sections`).
- **`pandoc.docx.customArgs`** (array, default: `[]`): Additional Pandoc arguments for DOCX conversion.

### HTML Settings

- **`pandoc.html.standalone`** (boolean, default: `true`): Produce a standalone HTML file with headers (`--standalone`).
- **`pandoc.html.css`** (array, default: `[]`): CSS files to include in the HTML output (`--css`).
- **`pandoc.html.customArgs`** (array, default: `[]`): Additional Pandoc arguments for HTML conversion.

### PDF Settings

- **`pandoc.pdf.pdfEngine`** (enum: `""`, `"pdflatex"`, `"xelatex"`, `"lualatex"`, `"wkhtmltopdf"`, default: `""`): Specify the PDF engine (`--pdf-engine`). Leave empty for Pandoc's default.
- **`pandoc.pdf.numberSections`** (boolean, default: `false`): Add section numbers (`--number-sections`).
- **`pandoc.pdf.customArgs`** (array, default: `[]`): Additional Pandoc arguments for PDF conversion.

## Example Configuration

```json
{
  "pandoc.outputDir": "output",
  "pandoc.docx.numberSections": true,
  "pandoc.docx.referenceDoc": "/path/to/reference.docx",
  "pandoc.html.css": ["style.css"],
  "pandoc.pdf.pdfEngine": "xelatex",
  "pandoc.pdf.customArgs": ["-V", "geometry:margin=1in"]
}
```

## Troubleshooting

**"Pandoc not found" error:**
- Ensure Pandoc is installed: [https://pandoc.org/installing.html](https://pandoc.org/installing.html)
- Verify `pandoc --version` works in your terminal
- If VSCode doesn't inherit your PATH, set `pandoc.path` to the absolute path of the Pandoc executable (e.g., `/usr/local/bin/pandoc`)

**PDF conversion fails:**
- PDF conversion requires a LaTeX distribution (e.g., TeX Live, MiKTeX) or another PDF engine like `wkhtmltopdf`
- Install a LaTeX distribution or configure `pandoc.pdf.pdfEngine` appropriately

## License

MIT

## Contributing

Contributions are welcome! Please submit issues and pull requests on GitHub.
