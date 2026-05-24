--[[
Pandoc Lua filter to render Mermaid diagrams to images
This filter converts mermaid code blocks to images for DOCX output.

Configuring render options:
  Recommended — HTML comment immediately before the fence. GitHub and other
  markdown viewers ignore the comment and render the plain `mermaid` fence
  normally, so the source stays portable:

    <!-- mermaid scale=3 width=1200 background=white format=png -->
    ```mermaid
    graph TD; A-->B; B-->C; C-->A;
    ```

  Alternative — inline code-block attributes (Pandoc-only syntax; will
  display as literal text in GitHub/most markdown previewers):

    ```mermaid{scale=3 width=1200 background=white format=png}
    graph TD; A-->B; B-->C; C-->A;
    ```

  If both are present, inline attributes override comment attributes.

  Supported attributes:
    scale       : Multiplies base diagram resolution (0.5 .. MERMAID_MAX_SCALE). Default from MERMAID_SCALE or 3.
    width       : Target width in pixels (forwarded to mmdc -w). Optional.
    background  : Background color or 'transparent'. Default MERMAID_BACKGROUND or 'transparent'.
    format      : png | svg | pdf | webp (limited by mermaid-cli support). Default MERMAID_FORMAT or png.

  Environment variables:
    MERMAID_BIN        : Path to mermaid CLI binary (default 'mmdc')
    MERMAID_OUT_DIR    : Output directory for generated images (default 'mermaid-images')
  MERMAID_SCALE      : Default scale multiplier (default 3)
  MERMAID_MAX_SCALE  : Maximum allowed scale clamp (default 16) – raise for ultra‑high DPI exports
    MERMAID_FORMAT     : Default output format (png)
    MERMAID_BACKGROUND : Default background color (transparent)
    MERMAID_CACHE      : 1 to enable (default), 0 to disable caching of identical diagrams

  Caching strategy:
    A hash of content + rendering parameters names the file so identical diagrams are generated once.
    Disable with MERMAID_CACHE=0 if live regeneration always needed.

  Rationale:
    DOCX embeds raster images; default 1x renders can look blurry. Increasing scale (2+) improves clarity in Word.

  Example pandoc invocation (shell):
    MERMAID_SCALE=3 pandoc -L pandoc/filters/mermaid-filter.lua -o out.docx in.md

  Note:
    For SVG output (if desired for HTML/PDF), set format=svg; DOCX will rasterize via Pandoc if needed.

Requirements:
- mermaid-cli (mmdc) must be installed: npm install -g @mermaid-js/mermaid-cli
- Set MERMAID_BIN environment variable to 'mmdc' or ensure it's in PATH

Author: Pandoc filter for MyWork documentation
Date: 2025-10-01
]]

local system = require 'pandoc.system'
local path = require 'pandoc.path'

-- Configuration
local mermaid_bin = os.getenv("MERMAID_BIN") or "mmdc"
local output_dir = os.getenv("MERMAID_OUT_DIR") or "mermaid-images"
-- Default scale (multiplies base resolution). Higher values => higher DPI.
local default_scale = tonumber(os.getenv("MERMAID_SCALE") or "3") -- bump default to 3x for sharper DOCX
local max_scale = tonumber(os.getenv("MERMAID_MAX_SCALE") or "16")
if max_scale < 1 then max_scale = 1 end
if max_scale > 64 then max_scale = 64 end -- hard safety ceiling
-- Optionally allow overriding output format (png, svg, pdf, webp if supported by mmdc)
local default_format = (os.getenv("MERMAID_FORMAT") or "png"):lower()
-- Allow default background; 'transparent' keeps previous behavior
local default_background = os.getenv("MERMAID_BACKGROUND") or "transparent"
-- Allow caching (avoid regenerating identical diagrams). Set MERMAID_CACHE=0 to disable.
local cache_enabled = (os.getenv("MERMAID_CACHE") or "1") ~= "0"

local image_counter = 0

-- Create output directory if it doesn't exist
local function ensure_output_dir()
  -- make_directory(path, create_parents) — safe across paths with spaces/metachars
  pcall(system.make_directory, output_dir, true)
end

-- Generate a unique filename for the diagram
local function sanitize_ext(fmt)
  if fmt == "svg" or fmt == "png" or fmt == "pdf" or fmt == "webp" then
    return fmt
  end
  return "png"
end

-- Simple hash (djb2) for caching based on diagram content + parameters
local function hash(s)
  local h = 5381
  for i = 1, #s do
    h = ((h * 33) ~ string.byte(s, i)) & 0xFFFFFFFF
  end
  return string.format("%08x", h)
end

local function generate_filename(key, ext)
  if key then
    return path.join({output_dir, string.format("mermaid-%s.%s", key, ext)})
  end
  image_counter = image_counter + 1
  return path.join({output_dir, string.format("mermaid-diagram-%d.%s", image_counter, ext)})
end

-- Execute mermaid-cli to generate image
local function render_mermaid(content, attrs)
  -- Resolve attributes: scale, width, format, background
  local scale = tonumber(attrs["scale"]) or default_scale
  if scale < 0.5 then scale = 0.5 end
  if scale > max_scale then scale = max_scale end -- configurable safety cap
  local width = tonumber(attrs["width"]) -- optional pixel width hint
  local background = attrs["background"] or default_background
  local fmt = sanitize_ext((attrs["format"] or default_format):lower())

  -- Build cache key and short-circuit before any I/O if a cached file already exists.
  local cache_key = nil
  if cache_enabled then
    cache_key = hash(table.concat({content, scale, width or '', background, fmt}, '|'))
  end

  local output_file = generate_filename(cache_key, fmt)

  if cache_key then
    local existing = io.open(output_file, 'r')
    if existing ~= nil then
      existing:close()
      return output_file
    end
  end

  ensure_output_dir()

  -- Render inside a managed temp directory so the .mmd input is cleaned up
  -- automatically — even on early returns — and works cross-platform.
  local ok, result = pcall(system.with_temporary_directory, "mermaid", function(tmpdir)
    local temp_file = path.join({tmpdir, "diagram.mmd"})
    local file = io.open(temp_file, "w")
    if not file then
      error("Could not create temporary file: " .. temp_file)
    end
    file:write(content)
    file:close()

    -- Build mermaid argv. mmdc flags:
    --   -s scale multiplier
    --   -w width (in pixels) if provided
    --   -b background color (or transparent)
    local args = {
      "-i", temp_file,
      "-o", output_file,
      "-b", tostring(background),
      "-s", tostring(scale),
    }
    if width then
      table.insert(args, "-w")
      table.insert(args, tostring(width))
    end

    -- pandoc.pipe spawns directly (no shell), so values can't be interpreted as shell syntax.
    -- Lets pandoc.pipe's error propagate up through with_temporary_directory's cleanup.
    pandoc.pipe(mermaid_bin, args, "")
    return output_file
  end)

  if not ok then
    io.stderr:write("Error rendering Mermaid diagram:\n")
    if type(result) == "table" then
      -- pandoc.pipe raises a table with .command/.error_code/.output on failure
      io.stderr:write(tostring(result.output or result.error_code or "unknown error") .. "\n")
    else
      io.stderr:write(tostring(result) .. "\n")
    end
    return nil
  end

  return result
end

-- Parse key=value pairs from a mermaid HTML comment.
-- Matches: <!-- mermaid key=value ... -->
-- Returns a table of attrs, or nil if the comment is not a mermaid config comment.
local function parse_mermaid_comment_attrs(text)
  local body = text:match("^%s*<!%-%-+%s*mermaid(.-)%-%-+>%s*$")
  if not body then return nil end
  local attrs = {}
  for key, val in body:gmatch("(%a[%w_]*)=(%S+)") do
    attrs[key] = val
  end
  return attrs
end

-- Render a mermaid code block with the given attrs and return a Para(Image) node.
-- Falls back to fallback_block if rendering fails.
local function render_mermaid_block(text, attrs, fallback_block)
  attrs = attrs or {}
  local image_path = render_mermaid(text, attrs)
  if image_path then
    local img_attr = {}
    if attrs["width"] then img_attr["width"] = attrs["width"] end
    return pandoc.Para({ pandoc.Image({}, image_path, "", img_attr) })
  else
    io.stderr:write("Warning: Failed to render Mermaid diagram, keeping as code block\n")
    return fallback_block
  end
end

-- Process block lists.
-- Detects a <!-- mermaid key=value ... --> HTML comment immediately preceding a
-- ```mermaid code block and uses the comment's key-value pairs as render attrs.
-- Also handles standalone mermaid blocks with inline attrs (backward compat).
function Blocks(blocks)
  local new_blocks = {}
  local i = 1
  while i <= #blocks do
    local block = blocks[i]
    local next_block = blocks[i + 1]
    -- Check for a mermaid config comment followed by a mermaid code block
    if block.t == "RawBlock" and block.format == "html" then
      local comment_attrs = parse_mermaid_comment_attrs(block.text)
      if comment_attrs
          and next_block
          and next_block.t == "CodeBlock"
          and next_block.classes
          and next_block.classes[1] == "mermaid" then
        -- Comment attrs are defaults; inline block attrs override them
        local merged = {}
        for k, v in pairs(comment_attrs) do merged[k] = v end
        for k, v in pairs(next_block.attributes or {}) do merged[k] = v end
        table.insert(new_blocks, render_mermaid_block(next_block.text, merged, next_block))
        i = i + 2  -- consume both the comment and the code block
      else
        table.insert(new_blocks, block)
        i = i + 1
      end
    elseif block.t == "CodeBlock" and block.classes and block.classes[1] == "mermaid" then
      -- Standalone mermaid block (plain ```mermaid or with inline attrs)
      table.insert(new_blocks, render_mermaid_block(block.text, block.attributes or {}, block))
      i = i + 1
    else
      table.insert(new_blocks, block)
      i = i + 1
    end
  end
  return new_blocks
end

-- Return the filter
return {
  { Blocks = Blocks }
}
