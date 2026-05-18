--[[
  Combined filter: Header ID extraction and internal link conversion
  
  1. Extracts custom IDs from HTML comments in headers: <!-- {#id} -->
  2. Converts markdown file links to internal cross-references for DOCX
  
  This ensures proper internal linking in the generated Word document.
]]

local headers = {}

-- Extract ID from HTML comment pattern
local function extract_id_from_html_comment(s)
  -- matches <!-- {#anything} -->
  return s:match("^%s*<!%-%-%s*{%#([%w:._-]+)}%s*%-%->%s*$")
end

-- Process the entire document in two passes
function Pandoc(doc)
  -- First pass: Process headers - extract IDs from comments and collect them
  doc = doc:walk({
    Header = function(h)
      local id_found
      local new_inlines = {}
      
      -- Extract ID from HTML comment
      for _, inline in ipairs(h.content) do
        if inline.t == "RawInline" and inline.format == "html" then
          local id = extract_id_from_html_comment(inline.text)
          if id then
            h.identifier = id
            id_found = true
          else
            table.insert(new_inlines, inline)
          end
        else
          table.insert(new_inlines, inline)
        end
      end
      
      if id_found then
        h.content = new_inlines -- drop the visible comment from output
      end
      
      -- Collect header ID for later link processing
      if h.identifier and h.identifier ~= "" then
        headers[h.identifier] = pandoc.utils.stringify(h.content)
      end
      
      return h
    end
  })
  
  -- Second pass: Convert markdown file links to internal references
  doc = doc:walk({
    Link = function(link)
      local target = link.target
      
      -- Handle markdown file links (convert to internal anchors)
      if target:match("%.md") then
        local file_part, anchor_part = target:match("^(.-)%.md(#?.*)$")
        
        if file_part then
          file_part = file_part:gsub("^%./", "")
          
          if anchor_part and anchor_part:match("^#.+") then
            -- Use explicit anchor
            target = anchor_part
          else
            -- Infer ID from filename
            local inferred_id = file_part:gsub("^%d+%-", "")
            
            -- Find matching header
            if headers[inferred_id] then
              target = "#" .. inferred_id
            elseif headers[file_part] then
              target = "#" .. file_part
            else
              -- Fuzzy match
              for id, _ in pairs(headers) do
                if id:find(inferred_id, 1, true) or inferred_id:find(id, 1, true) then
                  target = "#" .. id
                  break
                end
              end
              
              -- Fallback
              if not target:match("^#") then
                target = "#" .. inferred_id
              end
            end
          end
        end
      end
      
      -- For DOCX output: ensure internal links have proper formatting
      if target:match("^#(.+)") then
        local anchor = target:match("^#(.+)")
        
        -- Verify the anchor exists and add title for better Word compatibility
        if headers[anchor] then
          link.target = "#" .. anchor
          if not link.title or link.title == "" then
            link.title = headers[anchor]
          end
        end
      end
      
      return link
    end
  })
  
  return doc
end