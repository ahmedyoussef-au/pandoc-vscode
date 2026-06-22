# Changelog

## [0.3.0]

- Added template settings for DOCX, HTML, and PDF conversions, defaulting to Pandoc's built-in templates when unset
- Added command: "Pandoc: Generate Templates" — copies bundled templates into the workspace and updates template settings
- Explicit `--template` and `--reference-doc` Pandoc arguments continue to override template settings

## [0.2.1]

- Documented LaTeX engine prerequisite for PDF output, including install commands per OS and the VS Code restart needed for `PATH` updates

## [0.2.0]

- Built-in Lua filters are now auto-applied on every conversion (page breaks, header IDs, Mermaid diagrams, HTML line breaks)
- New `pandoc.filters` setting for full control over filter selection and ordering
- Renamed `customArgs` to `commonArgs` (old name still works as a deprecated alias)
- New command: "Pandoc: Generate Sample Markdown" — creates a sample file demonstrating all filter features

## [0.0.1]

- Initial release
- Convert single Markdown files via right-click or Command Palette
- Convert entire folders of Markdown files at once
- Configurable output settings and Pandoc options
