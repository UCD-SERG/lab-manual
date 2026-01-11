-- Lua filter to add a "Preview - Changed" banner to modified pages
-- This filter checks for the preview-changed metadata field

function Pandoc(doc)
  -- Check if this page is marked as changed via metadata
  local is_changed = false
  
  if doc.meta and doc.meta["preview-changed"] then
    is_changed = true
  end
  
  -- If changed and rendering HTML, add a placeholder banner
  -- The Python script will replace this with the full combined banner
  if is_changed and FORMAT:match("html") then
    local banner = pandoc.Div(
      {
        pandoc.Para({
          pandoc.Str("PREVIEW_BANNER_PLACEHOLDER")
        })
      },
      {class = "preview-changed-banner"}
    )
    
    -- Insert banner at the beginning of the document
    table.insert(doc.blocks, 1, banner)
  end
  
  return doc
end
