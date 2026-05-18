## Specification: Built-in Lua Filter Support

The extension ships Lua filters in `pandoc/filters/` but currently requires users to manually reference them via `customArgs`. Built-in filters should load automatically on every conversion, eliminating manual configuration while preserving user control.

### Objectives
- Automatically apply all packaged Lua filters during conversion without user configuration
- Provide an opt-out mechanism for users who don't want built-in filters

### Requirements
1. All `.lua` files in the extension's `pandoc/filters/` directory are loaded as `--lua-filter` arguments on every conversion (docx, html, pdf)
2. Built-in filter arguments are prepended before any user-specified arguments from `customArgs`/`commonArgs`, so user filters run after built-in ones
3. A new boolean setting `pandoc.disableBuiltInFilters` (default: `false`) disables all built-in filter loading when set to `true`
4. Rename `pandoc.{format}.customArgs` to `pandoc.{format}.commonArgs` as the canonical setting name; keep `customArgs` as a deprecated alias for backward compatibility
5. When both `commonArgs` and `customArgs` are defined for a format, `commonArgs` takes precedence (ignore `customArgs`)
6. Users can still add their own filters via `commonArgs` (or legacy `customArgs`) as they do today
7. The `pandoc/filters/` directory is bundled with the extension package (included in `.vsix`)

### Constraints
- Filter paths must resolve correctly regardless of where the extension is installed (use extension context path)
- No breaking changes to existing `customArgs` behaviour

### Acceptance Criteria
- [ ] Converting a file with default settings includes all packaged Lua filters in the pandoc invocation
- [ ] Setting `pandoc.disableBuiltInFilters` to `true` removes all built-in filters from the invocation
- [ ] User-specified `--lua-filter` args in `customArgs` still work and run after built-in filters
- [ ] Extension packages correctly with filters included in the `.vsix` bundle
