# Quick Start Guide

## Your VSCode Extension is Ready! 🎉

The Pandoc Markdown Converter extension has been successfully created and compiled.

## Testing the Extension

### Option 1: Run in Extension Development Host (Recommended)

1. **Open the project in VSCode**:
   ```bash
   code /Users/ahmedyoussef/Projects/Insight/Pandoc-VSCode
   ```

2. **Press F5** to launch the Extension Development Host
   - A new VSCode window will open with your extension loaded

3. **Open the test file**:
   - In the Extension Development Host window, open `test.md`

4. **Test the conversion commands**:

   **Via Command Palette:**
   - Press `Cmd+Shift+P`
   - Type "Pandoc"
   - Select one of:
     - `Pandoc: Convert Markdown to DOCX`
     - `Pandoc: Convert Markdown to HTML`
     - `Pandoc: Convert Markdown to PDF`

   **Via Context Menu:**
   - Right-click in the editor while viewing `test.md`
   - Or right-click on `test.md` in the Explorer
   - Select your desired conversion option

5. **Expected behavior**:
   - The converted file will be created in the same directory
   - The file will automatically open in VSCode
   - You'll see a notification with the output path

### Option 2: Quick Test from Terminal

You can also test the conversion directly with Pandoc to verify it works:

```bash
cd /Users/ahmedyoussef/Projects/Insight/Pandoc-VSCode
pandoc test.md -o test.docx
pandoc test.md -o test.html --standalone
```

## Project Structure

```
Pandoc-VSCode/
├── .vscode/
│   ├── launch.json          # Debug configuration
│   └── tasks.json           # Build tasks
├── dist/                    # Compiled JavaScript
│   ├── extension.js
│   └── pandoc.js
├── src/                     # TypeScript source
│   ├── extension.ts         # Command registration
│   └── pandoc.ts            # Conversion logic
├── package.json             # Extension manifest
├── tsconfig.json            # TypeScript config
├── README.md                # User documentation
└── test.md                  # Sample test file
```

## Configuration Examples

After installing the extension, you can configure it in VSCode settings:

### Example 1: Set Output Directory
```json
{
  "pandoc.outputDir": "output"
}
```

### Example 2: Enable Section Numbers for DOCX
```json
{
  "pandoc.docx.numberSections": true
}
```

### Example 3: Add Custom CSS for HTML
```json
{
  "pandoc.html.css": ["style.css", "theme.css"]
}
```

### Example 4: Use XeLaTeX for PDF
```json
{
  "pandoc.pdf.pdfEngine": "xelatex"
}
```

### Example 5: Custom Pandoc Arguments
```json
{
  "pandoc.docx.customArgs": ["-V", "fontsize=12pt"],
  "pandoc.pdf.customArgs": ["-V", "geometry:margin=1in"]
}
```

## Available Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `pandoc.path` | string | `""` | Path to pandoc executable |
| `pandoc.outputDir` | string | `""` | Output directory for converted files |
| `pandoc.docx.referenceDoc` | string | `""` | Reference DOCX for styling |
| `pandoc.docx.numberSections` | boolean | `false` | Add section numbers |
| `pandoc.docx.customArgs` | array | `[]` | Additional Pandoc arguments |
| `pandoc.html.standalone` | boolean | `true` | Create standalone HTML |
| `pandoc.html.css` | array | `[]` | CSS files to include |
| `pandoc.html.customArgs` | array | `[]` | Additional Pandoc arguments |
| `pandoc.pdf.pdfEngine` | string | `""` | PDF engine (pdflatex, xelatex, etc.) |
| `pandoc.pdf.numberSections` | boolean | `false` | Add section numbers |
| `pandoc.pdf.customArgs` | array | `[]` | Additional Pandoc arguments |

## Development Commands

```bash
# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Watch mode (auto-compile on changes)
npm run watch

# Lint code
npm run lint
```

## Next Steps

### 1. Test All Features
- ✅ Command Palette integration
- ✅ Right-click context menu (editor)
- ✅ Right-click context menu (Explorer)
- ✅ Output directory configuration
- ✅ Per-format settings
- ✅ Auto-open converted file
- ✅ Error handling for missing Pandoc

### 2. Optional: Package the Extension
```bash
npm install -g @vscode/vsce
vsce package
```
This creates a `.vsix` file you can install locally or share.

### 3. Optional: Publish to Marketplace
```bash
vsce publish
```
(Requires a publisher account and access token)

## Troubleshooting

### "Pandoc not found" Error
- Verify Pandoc is installed: `pandoc --version`
- If VSCode doesn't find it, set `pandoc.path` in settings

### PDF Conversion Fails
- PDF requires LaTeX (TeX Live, MiKTeX) or another PDF engine
- macOS: `brew install basictex`
- Or use `wkhtmltopdf` as the PDF engine

### Extension Doesn't Load
- Check the Debug Console in the Extension Development Host for errors
- Ensure `npm run compile` completed without errors

## Support

For issues or questions, check:
- README.md for user documentation
- Extension Development Host Debug Console for runtime errors
- VSCode Extension API docs: https://code.visualstudio.com/api

Happy coding! 🚀
