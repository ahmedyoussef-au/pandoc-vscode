## Specification: Built-in Lua Filter Support

The extension ships Lua filters in `pandoc/filters/` but currently requires users to manually reference them via `customArgs`. Built-in filters should load automatically on every conversion, with a unified setting that gives users full control over filter selection and ordering.

### Objectives
- Automatically apply all packaged Lua filters during conversion without user configuration
- Provide granular control: users can enable/disable individual filters and control execution order
- Unify built-in and user-supplied filters into a single ordered setting

### Requirements
1. A new setting `pandoc.filters` (type: `string[]`) controls which filters are applied and in what order
2. Default value includes all built-in filters: `["builtin:header-id-from-comment", "builtin:html-br-to-linebreak", "builtin:mermaid-filter", "builtin:page-break"]`
3. Entries prefixed with `builtin:` resolve to `<extensionPath>/pandoc/filters/<name>.lua`
4. User-supplied entries support absolute paths or `${workspaceFolder}` variable substitution (e.g. `${workspaceFolder}/my-filters/custom.lua`)
5. Array order determines `--lua-filter` argument order passed to pandoc
6. Removing an entry from the array disables that filter; an empty array disables all filters
7. Resolved filter args are inserted after default args but before user-specified `commonArgs`/`customArgs`
8. Rename `pandoc.{format}.customArgs` to `pandoc.{format}.commonArgs` as the canonical setting name; keep `customArgs` as a deprecated alias for backward compatibility
9. When both `commonArgs` and `customArgs` are defined for a format, `commonArgs` takes precedence (ignore `customArgs`)
10. The `pandoc/filters/` directory is bundled with the extension package (included in `.vsix`)

### Constraints
- Filter paths must resolve correctly regardless of where the extension is installed (use extension context path)
- No breaking changes to existing `customArgs` behaviour

### Acceptance Criteria
- [ ] Converting a file with default settings includes all packaged Lua filters in the pandoc invocation
- [ ] Removing a filter entry from `pandoc.filters` excludes it from the invocation
- [ ] Setting `pandoc.filters` to `[]` removes all filters from the invocation
- [ ] User-supplied filter paths with `${workspaceFolder}` resolve correctly
- [ ] User-supplied absolute filter paths work as-is
- [ ] Filter order in the setting matches `--lua-filter` argument order
- [ ] User-specified args in `commonArgs`/`customArgs` still work and appear after filter args
- [ ] Extension packages correctly with filters included in the `.vsix` bundle
