-- Return a block element causing a page break in the given format.
local function newpage(format)
  format = format or ''

  if format:match('docx') then
    local pagebreak = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
    return pandoc.RawBlock('openxml', pagebreak)
  elseif format:match('latex') or format:match('beamer') then
    return pandoc.RawBlock('latex', '\\newpage{}')
  elseif format:match('html') or format:match('epub') then
    return pandoc.RawBlock('html', '<div style="page-break-after: always;"></div>')
  else
    -- fall back to insert a form feed character
    return pandoc.Para{ pandoc.Str '\f' }
  end
end

local function is_pagebreak(text)
  if type(text) ~= 'string' then
    return false
  end

  local normalised = text:lower()
  return normalised:match('^%s*<!%-%-%s*pagebreak%s*%-%->%s*$')
end

-- Filter function called on each RawBlock element.
local function handle_raw_block(el)
  if el.format == 'html' and is_pagebreak(el.text) then
    return newpage(FORMAT or '')
  end
  -- otherwise, leave the block unchanged
  return nil
end

-- True when an inline is a pagebreak marker rendered as RawInline html.
local function is_pagebreak_inline(inline)
  return inline.t == 'RawInline' and inline.format == 'html' and is_pagebreak(inline.text)
end

-- Handle paragraphs that contain a pagebreak marker. With
-- markdown+hard_line_breaks, a marker written on its own line (but not
-- surrounded by blank lines) is parsed as a RawInline in the MIDDLE of a
-- paragraph, flanked by LineBreaks rather than standing alone. Split such a
-- paragraph at each marker so the page break still takes effect, dropping the
-- LineBreaks that hugged the marker so we don't leave dangling blank lines.
local function handle_para(el)
  local has_marker = false
  for _, inline in ipairs(el.content) do
    if is_pagebreak_inline(inline) then
      has_marker = true
      break
    end
  end
  if not has_marker then
    return nil
  end

  local blocks = {}
  local current = {}

  local function flush()
    -- Trim a LineBreak that sat directly against the marker on either side.
    while #current > 0 and current[#current].t == 'LineBreak' do
      table.remove(current)
    end
    while #current > 0 and current[1].t == 'LineBreak' do
      table.remove(current, 1)
    end
    if #current > 0 then
      table.insert(blocks, pandoc.Para(current))
    end
    current = {}
  end

  for _, inline in ipairs(el.content) do
    if is_pagebreak_inline(inline) then
      flush()
      table.insert(blocks, newpage(FORMAT or ''))
    else
      table.insert(current, inline)
    end
  end
  flush()

  return blocks
end

return {
  {
    RawBlock = handle_raw_block,
    Para = handle_para,
  }
}