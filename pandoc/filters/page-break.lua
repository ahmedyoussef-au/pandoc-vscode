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

-- Handle paragraphs containing only a pagebreak marker rendered as RawInline.
local function handle_para(el)
  if #el.content == 1 then
    local inline = el.content[1]
    if inline.t == 'RawInline' and inline.format == 'html' and is_pagebreak(inline.text) then
      return newpage(FORMAT or '')
    end
  end
  return nil
end

return {
  {
    RawBlock = handle_raw_block,
    Para = handle_para,
  }
}