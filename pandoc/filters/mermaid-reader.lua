--[[
Custom pandoc reader that normalises Mermaid fences into standard fenced code
blocks (```mermaid{attrs} ... ```) before the Markdown reader parses the
document.

Two authoring forms are supported:

  Azure DevOps-style colon fence:
    <!-- pandoc: scale=3 width=700 background=transparent format=png -->
    ::: mermaid
    graph LR
        A --> B
    :::

  GitHub-style backtick fence:
    <!-- pandoc: scale=3 width=700 background=transparent format=png -->
    ```mermaid
    graph LR
        A --> B
    ```

The optional preceding `<!-- pandoc: ... -->` HTML comment carries the
rendering attributes consumed by mermaid-filter.lua (scale, width,
background, format). Attributes already present on the fence itself (for
example `::: mermaid {scale=2}` or ```` ```mermaid{scale=2} ````) are also
preserved; the fence form takes precedence over the comment when both are
supplied.

Why: Azure DevOps Wiki renders Mermaid via `::: mermaid ... :::` and does
not support the ```mermaid fenced form, while the pandoc Markdown reader
mangles a `::: mermaid` Div's body (arrows, node shapes, indentation)
before any Lua filter can see it. Normalising everything to a fenced code
block here -- before pandoc.read runs -- keeps both renderers happy and
preserves the diagram body verbatim for mermaid-filter.lua.

Usage in pandoc command:
  --from=path/to/mermaid-reader.lua

The reader forwards to pandoc's Markdown parser with `hard_line_breaks`
enabled, so callers do not need to pass that extension themselves.
]]

-- Turn "scale=3 width=700 background=transparent format=png" into
-- "{scale=3 width=700 background=transparent format=png}".
local function wrap_attrs(raw)
  if not raw then return "" end
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if trimmed == "" then return "" end
  return "{" .. trimmed .. "}"
end

-- Merge fence attributes and comment attributes. Fence attributes win when
-- both forms supply the same key, but we do not attempt a per-key merge;
-- the fence form is treated as an explicit override of the comment.
local function merge_attrs(fence_attrs, comment_attrs)
  if fence_attrs and fence_attrs ~= "" then
    return fence_attrs
  end
  return wrap_attrs(comment_attrs)
end

function Reader(inputs, opts)
  local text = ""
  for _, inp in ipairs(inputs) do
    text = text .. tostring(inp.text or inp)
  end

  -- Pass 1: `<!-- pandoc: ... -->` immediately preceding a `::: mermaid`
  -- colon fence. Rewrite the whole block as a fenced code block so pass 3
  -- (below) does not need to run on it.
  text = text:gsub(
    "(\n?)<!%-%-%s*pandoc:([^\n]-)%-%->%s*\n:::%s*mermaid([^\n]*)\n(.-)\n:::",
    function(leading, comment_attrs, fence_tail, body)
      local fence_attrs = fence_tail:match("%b{}") or ""
      local attrs = merge_attrs(fence_attrs, comment_attrs)
      return leading .. "```mermaid" .. attrs .. "\n" .. body .. "\n```"
    end
  )

  -- Pass 2: `<!-- pandoc: ... -->` immediately preceding a ```mermaid
  -- backtick fence. Inject the comment attrs onto the fence.
  text = text:gsub(
    "(\n?)<!%-%-%s*pandoc:([^\n]-)%-%->%s*\n```mermaid([^\n]*)\n(.-)\n```",
    function(leading, comment_attrs, fence_tail, body)
      local fence_attrs = fence_tail:match("%b{}") or ""
      local attrs = merge_attrs(fence_attrs, comment_attrs)
      return leading .. "```mermaid" .. attrs .. "\n" .. body .. "\n```"
    end
  )

  -- Pass 3: bare `::: mermaid` fences (no preceding pandoc comment).
  -- Non-greedy body, anchored to line starts so unrelated colons are safe.
  text = text:gsub(
    "(\n?):::%s*mermaid([^\n]*)\n(.-)\n:::",
    function(leading, fence_tail, body)
      local fence_attrs = fence_tail:match("%b{}") or ""
      return leading .. "```mermaid" .. fence_attrs .. "\n" .. body .. "\n```"
    end
  )

  return pandoc.read(text, "markdown+hard_line_breaks", opts)
end
