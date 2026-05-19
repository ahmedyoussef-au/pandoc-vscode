--[[
Pandoc Lua filter to render Mermaid diagrams to images
This filter converts mermaid code blocks to images for DOCX output.

High resolution / customization:
  Code block attributes (example):
    ```mermaid{scale=3 width=1200 background=white format=png}
    graph TD; A-->B; B-->C; C-->A;
    ```

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
    MERMAID_SCALE=3 pandoc -F docs/pandoc/filters/mermaid-filter.lua -o out.docx in.md

  Note:
    For SVG output (if desired for HTML/PDF), set format=svg; DOCX will rasterize via Pandoc if needed.

Requirements:
- mermaid-cli (mmdc) must be installed: npm install -g @mermaid-js/mermaid-cli
- Set MERMAID_BIN environment variable to 'mmdc' or ensure it's in PATH

Author: Pandoc filter for MyWork documentation
Date: 2025-10-01
]]

local system = require 'pandoc.system'
local utils = require 'pandoc.utils'

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
  os.execute("mkdir -p " .. output_dir)
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
  image_counter = image_counter + 1
  if key then
    return string.format("%s/mermaid-%s.%s", output_dir, key, ext)
  end
  return string.format("%s/mermaid-diagram-%d.%s", output_dir, image_counter, ext)
end

-- Write mermaid content to a temporary file
local function write_temp_file(content)
  local temp_file = os.tmpname() .. ".mmd"
  local file = io.open(temp_file, "w")
  if not file then
    io.stderr:write("Error: Could not create temporary file\n")
    return nil
  end
  file:write(content)
  file:close()
  return temp_file
end

-- Execute mermaid-cli to generate image
local function render_mermaid(content, attrs)
  ensure_output_dir()
  
  local temp_file = write_temp_file(content)
  if not temp_file then
    return nil
  end
  
  -- Resolve attributes: scale, width, format, background
  local scale = tonumber(attrs["scale"]) or default_scale
  if scale < 0.5 then scale = 0.5 end
  if scale > max_scale then scale = max_scale end -- configurable safety cap
  local width = tonumber(attrs["width"]) -- optional pixel width hint
  local background = attrs["background"] or default_background
  local fmt = sanitize_ext((attrs["format"] or default_format):lower())

  -- Build cache key
  local cache_key = nil
  if cache_enabled then
    cache_key = hash(table.concat({content, scale, width or '', background, fmt}, '|'))
  end

  local output_file = generate_filename(cache_key, fmt)

  -- Skip regeneration if cached file exists
  local existing = io.open(output_file, 'r')
  if existing ~= nil then
    existing:close()
    return output_file
  end

  -- Build mermaid command. mmdc flags:
  --   -s scale multiplier
  --   -w width (in pixels) if provided
  --   -b background color (or transparent)
  local width_part = width and (" -w " .. width) or ""
  local cmd = string.format(
    '%s -i "%s" -o "%s" -b %s -s %s%s 2>&1',
    mermaid_bin,
    temp_file,
    output_file,
    background,
    scale,
    width_part
  )
  
  -- Execute command
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  local success = handle:close()
  
  -- Clean up temp file
  os.remove(temp_file)
  
  if not success then
    io.stderr:write("Error rendering Mermaid diagram:\n")
    io.stderr:write(result .. "\n")
    return nil
  end
  
  return output_file
end

-- Process code blocks
function CodeBlock(block)
  -- Check if this is a mermaid code block
  if block.classes[1] == "mermaid" then
  local image_path = render_mermaid(block.text, block.attributes or {})
    
    if image_path then
      -- Return an image element
      local attr = {}
      -- Preserve width attribute for Pandoc if provided (DOCX may scale accordingly)
      if block.attributes and block.attributes["width"] then
        attr["width"] = block.attributes["width"]
      end
      return pandoc.Para({ pandoc.Image({}, image_path, "", attr) })
    else
      -- If rendering failed, return the original code block with an error message
      io.stderr:write("Warning: Failed to render Mermaid diagram, keeping as code block\n")
      return block
    end
  end
  
  -- Not a mermaid block, return unchanged
  return nil
end

-- Return the filter
return {
  { CodeBlock = CodeBlock }
}
