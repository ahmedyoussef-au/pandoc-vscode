## Plan: Built-in Lua Filter Support

Unify built-in and user filters into a single ordered `pandoc.filters` setting. All bundled filters are enabled by default; users control ordering, can disable individual built-ins by removing them, and can insert their own filters at any position. Also renames `customArgs` to `commonArgs` with backward compatibility.

### Steps

1. **Pass `ExtensionContext` to conversion functions**
   - In [src/extension.ts](src/extension.ts), capture `context.extensionUri` during `activate()` and pass it (or its `.fsPath`) through to `convertMarkdown()` and `buildArgsForFormat()` in [src/pandoc.ts](src/pandoc.ts).

2. **Add `pandoc.filters` setting**
   - In [package.json](package.json) `contributes.configuration.properties`, add:
     ```
     pandoc.filters: string[] (default: ["builtin:header-id-from-comment", "builtin:html-br-to-linebreak", "builtin:mermaid-filter", "builtin:page-break"])
     ```   - Include a `description` and `items.type: "string"` so the setting renders as an editable list in the Settings UI with defaults pre-populated.   - Entries prefixed with `builtin:` resolve to `<extensionPath>/pandoc/filters/<name>.lua`.
   - All other entries are treated as user-supplied paths (absolute, or relative to workspace).
   - Order in the array = order of `--lua-filter` arguments passed to pandoc.
   - An empty array disables all filters.

3. **Resolve filter paths in `buildArgsForFormat()`**
   - In [src/pandoc.ts](src/pandoc.ts), add a helper (e.g. `resolveFilterArgs(filters, extensionPath, workspacePath)`) that maps each entry to a `--lua-filter=<resolved-path>` string:
     - `builtin:name` → `<extensionPath>/pandoc/filters/<name>.lua`
     - Entries containing `${workspaceFolder}` → substitute with workspace root path
     - Absolute paths → used as-is
   - After resolving, validate each path exists (`fs.existsSync`). If a filter file is missing, show a VS Code warning message (e.g. "Pandoc filter not found: <path>") and skip that filter.
   - Insert resolved filter args **after** `defaultArgs` but **before** other user/merged args:
     `[...defaultArgs, ...resolvedFilterArgs, ...mergedUserArgs, '-o', output, input]`

4. **Rename `customArgs` → `commonArgs` with deprecation alias**
   - In [package.json](package.json), add new `pandoc.{format}.commonArgs` properties (same schema as existing `customArgs`).
   - Mark `customArgs` descriptions as deprecated.
   - In [src/pandoc.ts](src/pandoc.ts) where args are read from config, read `commonArgs` first; fall back to `customArgs` if `commonArgs` is not defined. When both are defined, `commonArgs` wins.

5. **Ensure filters are bundled in `.vsix`**
   - Verify (or create) `.vscodeignore` does **not** exclude `pandoc/filters/`. Add an explicit include if needed.

6. **Bump extension version to `0.2.0`**
   - Update `version` in [package.json](package.json) from `0.0.1` to `0.2.0`.

7. **Update README**
   - Document the `pandoc.filters` setting (built-in prefix convention, ordering, how to add/remove), and the `commonArgs` rename.
   - Remove any examples or instructions showing `--lua-filter` in `customArgs`/`commonArgs` — filters are now managed exclusively via `pandoc.filters`.
   - Clarify that `commonArgs`/`customArgs` is for non-filter pandoc arguments only (e.g. `--reference-doc`, `--toc`, `--css`).
   - Note that the Mermaid filter requires `mermaid-cli` (`npm install -g @mermaid-js/mermaid-cli`) — without it, Mermaid diagrams stay as code blocks. Keep it brief and user-friendly; avoid exposing internal implementation details.
   - Mention that `mermaid-images/` directory is generated when using the Mermaid filter, and suggest adding it to `.gitignore`.

8. **Add "Generate Sample Markdown" command**
   - In [package.json](package.json), register a new command `pandoc.generateSampleMarkdown` (title: "Pandoc: Generate Sample Markdown").
   - In [src/extension.ts](src/extension.ts), register a handler that creates `pandoc-sample.md` in the workspace root with the content below, then opens it in the editor.
   - This replaces lengthy examples in the README — just point users to the command.

   **Sample file content (`pandoc-sample.md`):**

   ````markdown
   # Pandoc VS Code Extension — Sample Document

   This file demonstrates all built-in Lua filters. Convert it to DOCX, HTML, or PDF using the command palette or right-click menu.

   ## Introduction <!-- {#intro} -->

   This heading has a custom ID. You can link to it from anywhere in the document like this: [Back to Introduction](#intro).

   You can also link to other markdown files: [See the README](./README.md).

   ## Line Breaks

   This line has a break here<br>and continues on the next line.

   You can also use the self-closing form:<br/>like this.

   <!-- pagebreak -->

   ## Mermaid Diagram

   The diagram below will be rendered as an image in DOCX output (requires mermaid-cli installed).

   ```mermaid{scale=3 width=800 background=white format=png}
   graph TD
       A[Start] --> B{Decision}
       B -->|Yes| C[Do something]
       B -->|No| D[Do something else]
       C --> E[End]
       D --> E
   ```

   <!-- pagebreak -->

   ## Final Section

   This section appears after a page break. The document demonstrates:

   - Custom header IDs and cross-references
   - HTML line breaks converted to native breaks
   - Mermaid diagrams rendered as images
   - Page breaks between sections
   ````

9. **Add/update CHANGELOG.md**
   - Create `CHANGELOG.md` at the project root (or update if it exists) with a `## [0.2.0]` section summarizing: built-in filters auto-applied, new `pandoc.filters` setting, `customArgs` → `commonArgs` rename, new sample markdown command.

### Considerations

1. **`builtin:` prefix vs full paths** — Using a `builtin:` prefix keeps the setting concise and version-resilient (filter filenames may change across extension updates). ✅ Decided: use `builtin:` prefix.
2. **User filter path resolution** — User filter paths support absolute paths or `${workspaceFolder}` variable substitution (consistent with existing `pandoc.outputDir` behavior). ✅ Decided.
