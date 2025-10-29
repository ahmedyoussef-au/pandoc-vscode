# Pandoc Extension for VSCode

Convert Markdown files to DOCX, HTML and PDF using Pandoc directly from Visual Studio Code.

This extension integrates Pandoc into Visual Studio Code, allowing you to convert Markdown documents to various formats without leaving your editor.

## ⚡ Key Features

- **Single file or folder conversion** - Convert one file or an entire folder
- **Customizable options** - Configure Pandoc command-line arguments
- **Multiple output formats** - HTML, PDF, DOCX, and more
- **Smart output handling** - Converted files saved alongside source files
- **Fast processing** - Quick conversions powered by Pandoc

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

## Requirements

**Pandoc must be installed on your system** before using this extension.

### Installing Pandoc

- **macOS**: `brew install pandoc`
- **Windows**: Download from [pandoc.org](https://pandoc.org/installing.html)
- **Linux**: `sudo apt-get install pandoc` (Debian/Ubuntu) or `sudo dnf install pandoc` (Fedora)

Verify installation by running `pandoc --version` in your terminal.

## Extension Settings

This extension contributes the following settings:

### General Settings

* `pandoc.path`: Optional absolute path to the pandoc executable. If empty, 'pandoc' from PATH is used.
* `pandoc.outputDir`: Default output directory. Leave empty to use the source file's directory. Relative paths are resolved against the workspace folder.

### DOCX Conversion Settings

* `pandoc.docx.customArgs`: Pandoc arguments for DOCX conversion (applies to all DOCX conversions)
* `pandoc.docx.singleFileCustomArgs`: Additional arguments for DOCX conversion when converting a single file
* `pandoc.docx.multipleFilesCustomArgs`: Additional arguments for DOCX conversion when converting multiple files in a folder

### HTML Conversion Settings

* `pandoc.html.customArgs`: Pandoc arguments for HTML conversion (applies to all HTML conversions)
* `pandoc.html.singleFileCustomArgs`: Additional arguments for HTML conversion when converting a single file
* `pandoc.html.multipleFilesCustomArgs`: Additional arguments for HTML conversion when converting multiple files in a folder

### PDF Conversion Settings

* `pandoc.pdf.customArgs`: Pandoc arguments for PDF conversion (applies to all PDF conversions)
* `pandoc.pdf.singleFileCustomArgs`: Additional arguments for PDF conversion when converting a single file
* `pandoc.pdf.multipleFilesCustomArgs`: Additional arguments for PDF conversion when converting multiple files in a folder

### Example Configuration

```json
{
  "pandoc.path": "/usr/local/bin/pandoc",
  "pandoc.outputDir": "${workspaceFolder}/output",
  "pandoc.docx.customArgs": [
    "--reference-doc=${workspaceFolder}/templates/template.docx",
  ],
  "pandoc.docx.singleFileCustomArgs": [
    "--resource-path=../images:./images"
  ],
  "pandoc.docx.multipleFilesCustomArgs": [
    "--reference-doc=${workspaceFolder}/templates/template-with-cover.docx",
    "--number-sections",
    "--toc"
  ]
}
```

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

## Supported Conversions

### Input Formats
- Markdown (`.md`, `.markdown`)

### Output Formats
- **DOCX** - Microsoft Word documents
- **HTML** - Web-ready documents
- **PDF** - Requires LaTeX installation (e.g., xelatex, pdflatex)

## Release Notes

### 0.0.1

Initial release of Pandoc VSCode Extension:
- ✅ Convert single Markdown files via right-click or Command Palette
- ✅ Convert entire folders of Markdown files at once
- ✅ Configurable output settings and Pandoc options
- ✅ Support for all Pandoc output formats

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

