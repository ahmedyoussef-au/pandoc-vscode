--[[
Pandoc Lua filter to convert HTML <br> elements to native Pandoc LineBreaks
This ensures proper rendering of line breaks in DOCX output format.

Author: Pandoc filter for MyWork documentation
Date: 2025-10-01
]]

-- Process RawInline HTML elements
function RawInline(el)
  -- Convert <br> and <br/> tags to native Pandoc line breaks
  if el.format == 'html' and el.text:match('^<br') then
    return pandoc.LineBreak()
  end
  return nil
end

-- Return the filter
return {
  { RawInline = RawInline }
}
