# Changelog

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
