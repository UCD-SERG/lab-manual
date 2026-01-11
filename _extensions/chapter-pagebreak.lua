-- Lua filter to add page breaks before chapter headings
-- This filter inserts a page break before every level 1 heading (chapter)
-- except the first one, for PDF and DOCX output formats

local first_chapter = true

function Header(elem)
  -- Only process level 1 headings (chapters)
  if elem.level == 1 then
    -- Skip the first chapter (index/title page)
    if first_chapter then
      first_chapter = false
      return elem
    end
    
    -- For PDF output, insert LaTeX page break
    if FORMAT:match("latex") then
      return {pandoc.RawBlock('latex', '\\clearpage'), elem}
    end
    
    -- For DOCX output, insert Word page break
    if FORMAT:match("docx") then
      return {pandoc.RawBlock('openxml', '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'), elem}
    end
    
    -- For other formats, return the header unchanged
    return elem
  end
  
  return elem
end
