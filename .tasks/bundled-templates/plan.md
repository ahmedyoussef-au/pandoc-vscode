## Plan: Bundled Templates with Dedicated Settings

Add first-class `pandoc.<format>.template` settings (and `pandoc.docx.referenceDoc`) that default to the bundled templates shipped in [assets/templates/](assets/templates/), so users get styled output with zero configuration. The settings use a visible sentinel value (`"default"`) so the default is self-documenting in the Settings UI, and clearing the field opts out to plain Pandoc output — no hidden behavior, no dead-end. Existing `commonArgs` continue to work unchanged: Pandoc's last-wins rule means a `--template`/`--reference-doc` in `commonArgs` always beats the setting. A convenience command copies a bundled template into the workspace for easy customization.

### Design principles

- **Default-on, but visible and reversible.** The setting's default value is the string `"default"`, shown as-is in the Settings UI. Three states, all intuitive:
  - `"default"` → use the bundled template (the out-of-box experience).
  - `""` (cleared) → no template arg at all; pristine Pandoc behavior. Clearing a setting to get vanilla behavior is what users already expect from VS Code settings.
  - any other value → treated as a path (`${workspaceFolder}` and `~` supported).
- **Never break a conversion that worked before.** The bundled PDF template must work on every PDF engine (see step 1) rather than requiring XeLaTeX, so no user's PDF export starts failing after the update. No engine detection, no injected `--pdf-engine` flags, no fallback popups.
- **No forced migration, no notifications.** Users with templates in `commonArgs` keep their setup untouched (last-wins). The behavior change for zero-config users is announced in the changelog and README, not via popup.

### Steps

1. **Make the bundled PDF template engine-agnostic.** [pdf-template.tex](assets/templates/pdf-template.tex) currently loads `fontspec` unconditionally (line ~53), which crashes under pdflatex — Pandoc's default engine. Wrap the font handling in `iftex` guards:
   - `\ifPDFTeX` branch: fall back to pdflatex-safe fonts (`lmodern` + `helvet`/`\sfdefault`, `[T1]{fontenc}`, `[utf8]{inputenc}`).
   - `\else` branch (XeLaTeX/LuaLaTeX): the existing `fontspec` setup with the system-font fallback chain.
   - Everything else in the template (colors, headings, tables, verbatim styling) is base-LaTeX and stays unconditional.
   - Verify by converting the sample document with `--pdf-engine=pdflatex` and `--pdf-engine=xelatex`; both must succeed. Document in the template header that XeLaTeX gives the nicer fonts.

2. **Guarantee templates ship in the `.vsix`.** Update [.vscodeignore](.vscodeignore) to add an explicit `!assets/**` negation so future broad exclusions can't silently drop the templates (nothing excludes them today; this is insurance). Verify with `vsce ls` that `assets/templates/*` appears in the package output.

3. **Declare new settings** in [package.json](package.json) under `contributes.configuration.properties`, alongside the existing `commonArgs` entries (around lines 163–235):
   - `pandoc.pdf.template` — string, **default `"default"`**.
   - `pandoc.html.template` — same shape.
   - `pandoc.docx.referenceDoc` — same shape; name matches Pandoc's own `--reference-doc` flag.
   - Each `markdownDescription` spells out the three states: `"default"` = bundled template, empty = no template (plain Pandoc output), or a file path (supports `${workspaceFolder}` and `~`). Mention that a `--template`/`--reference-doc` in `commonArgs` takes precedence.

4. **Add a template-path resolver** in [src/pandoc.ts](src/pandoc.ts) (near `resolveVariables` at line 105). New helper `resolveTemplateArg(fmt, cfg, extensionPath, uri)` that:
   - Reads the relevant setting (`pdf.template`, `html.template`, or `docx.referenceDoc`) and trims it.
   - `"default"` → returns the path to the matching bundled file under `path.join(extensionPath, 'assets', 'templates', ...)`.
   - `""` → returns `null`; no arg is added.
   - Anything else → runs the value through `resolveVariables` and expands a leading `~` to the user's home directory.
   - Returns the fully-formed CLI arg (`--template=<path>` for pdf/html, `--reference-doc=<path>` for docx) or `null`. Does **not** check file existence — let Pandoc surface a clear error for a wrong user-supplied path, matching existing behavior.

5. **Wire the resolver into `buildArgsForFormat`** at [src/pandoc.ts:58-76](src/pandoc.ts#L58-L76). Insert the resolved template arg (when non-null) immediately before `resolvedArgs`, so any `--template=`/`--reference-doc=` the user already has in `commonArgs` appears later on the command line and wins via Pandoc's last-wins semantics. Final order: `[...defaultArgs, ...filterArgs, templateArg?, ...resolvedArgs, '-o', output, input]`.

6. **Fix folder-conversion arg handling before injecting paths.** Folder conversion currently runs with `shell: true` ([src/pandoc.ts:116](src/pandoc.ts#L116)) so the shell expands the `*.md` glob — but `spawn` with `shell: true` does not quote array args, so the extension-install path this plan injects (which can contain spaces, e.g. a username with a space) would break folder conversions. Fix properly rather than patching around it:
   - [src/extension.ts](src/extension.ts) `registerFolder` already collects the full file list via `findMarkdownFiles` (line 36) and then discards it in favor of a glob. Pass the explicit file list through to `convertMarkdown` instead (e.g. an optional `inputs: string[]` parameter), append all files as separate args, and drop `shell: true` from `runProcess` entirely.
   - This removes the whole quoting/injection class of bugs and makes folder conversion work for filenames with spaces too.

7. **Add a `Pandoc: Copy Template to Workspace` command.**
   - Declare in [package.json](package.json) under `contributes.commands` (`pandoc.copyTemplateToWorkspace`).
   - Register handler in [src/extension.ts](src/extension.ts) `activate()`.
   - Behavior: `showQuickPick` for format (PDF / HTML / DOCX) → copy the bundled file from `vscode.Uri.joinPath(context.extensionUri, 'assets/templates', …)` to `${workspaceFolder}/.pandoc/<filename>` (create the folder via `vscode.workspace.fs.createDirectory`), copy with `overwrite: false`, **open the copied file in the editor** (matching `generateSampleMarkdown` behavior), then prompt "Set this as the template for <format> in this workspace?" — on yes, write `${workspaceFolder}/.pandoc/<filename>` to the corresponding setting at **workspace** scope via `getConfiguration('pandoc').update(...)`, leaving user/global settings untouched.
   - Edge cases: no workspace open → error message; destination already exists → info message with an "Open" action that opens the existing file rather than overwriting.

8. **Update the README** to document:
   - The new settings and their three states, with "set to empty for plain Pandoc output" called out as the opt-out.
   - The precedence rule: `commonArgs` entries win because they appear later on the command line; existing `commonArgs` template examples stay, labeled as the manual alternative.
   - That the bundled PDF template works on any engine, with XeLaTeX recommended for the full font styling (`pandoc.pdf.commonArgs: ["--pdf-engine=xelatex"]`).
   - The copy command as the customization workflow.

9. **Add a changelog entry** that explicitly flags the behavior changes for zero-config users, not just the feature:
   - Output is now styled by default via bundled templates; set the template settings to empty to restore previous plain output.
   - HTML output becomes a full standalone document (`--template` implies `--standalone`) instead of a fragment.
   - Folder conversion no longer uses a shell glob (fixes paths/filenames with spaces).

### Considerations

1. **Why a sentinel instead of empty-means-bundled** — with `""` = bundled (the earlier draft), there is no value that means "no template", so users could never get plain Pandoc output back. `"default"` as the shipped value is visible in the Settings UI, and clearing the field maps to the universally expected "turn it off".

2. **Why engine-agnostic template instead of injecting `--pdf-engine=xelatex`** — injecting the flag would fix the fontspec crash only for users who have XeLaTeX installed; pdflatex-only users would go from working PDFs to failing PDFs after the update. Guarding the template costs a few LaTeX lines, has no runtime moving parts, and degrades gracefully (slightly plainer fonts) instead of failing.

3. **Path-variable parity with `commonArgs`** — `resolveVariables` handles `${workspaceFolder}` and `${workspaceFolderBasename}`. Add `~` expansion inside the new resolver only, to avoid changing existing `commonArgs` behavior.

4. **DOCX setting name** — `pandoc.docx.referenceDoc` matches Pandoc vocabulary (`--reference-doc`) rather than the `*.template` pattern. Keep it: users who know Pandoc will look for that term; the description clarifies the parallel.

5. **No conflict warning, no popups** — when both the setting and `commonArgs` specify a template, Pandoc's last-wins decides silently; the README sets the expectation. No one-time "templates have changed" notification either — popups are exactly the forceful behavior to avoid; changelog + README carry the announcement.

6. **Bundled template versioning** — users who copy a template via the new command won't receive future updates to it. Out of scope; track as a follow-up (e.g. a version comment in the template header and a "check for template updates" command).

7. **Alternatives considered and rejected** — Pandoc defaults files (`--defaults` + `${.}` paths) are the most Pandoc-native packaging and worth revisiting if templates grow into multi-option "themes", but are a bigger lift for no UX gain today. The `--data-dir` trick (bundled `reference.docx` + `templates/default.*`) needs zero flags but hijacks the user's own `~/.pandoc` data dir — exactly the kind of override this plan avoids.
