-- Lua filter to append git branch and commit information to DOCX output
-- This filter adds a section at the end of the document with metadata about
-- the git branch and commit that was used to generate the document.
-- This helps when transferring edits from DOCX back to Quarto source files.

--- Get git branch name
-- @return The current git branch name or "unknown"
local function get_git_branch()
  local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  local branch = handle:read("*a")
  handle:close()
  
  -- Remove trailing newline
  branch = branch:gsub("%s+$", "")
  
  if branch == "" then
    return "unknown"
  end
  return branch
end

--- Get git commit hash
-- @return The current git commit hash (short form) or "unknown"
local function get_git_commit()
  local handle = io.popen("git rev-parse --short HEAD 2>/dev/null")
  local commit = handle:read("*a")
  handle:close()
  
  -- Remove trailing newline
  commit = commit:gsub("%s+$", "")
  
  if commit == "" then
    return "unknown"
  end
  return commit
end

--- Get git commit hash (full form)
-- @return The current git commit hash (full form) or "unknown"
local function get_git_commit_full()
  local handle = io.popen("git rev-parse HEAD 2>/dev/null")
  local commit = handle:read("*a")
  handle:close()
  
  -- Remove trailing newline
  commit = commit:gsub("%s+$", "")
  
  if commit == "" then
    return "unknown"
  end
  return commit
end

--- Get git commit date
-- @return The date of the current commit or "unknown"
local function get_git_commit_date()
  local handle = io.popen("git show -s --format=%ci HEAD 2>/dev/null")
  local date = handle:read("*a")
  handle:close()
  
  -- Remove trailing newline
  date = date:gsub("%s+$", "")
  
  if date == "" then
    return "unknown"
  end
  return date
end

--- Append git metadata to the document
-- This function is called at the end of document processing to add
-- a section with git branch and commit information
-- @param doc The Pandoc document
-- @return The modified document with git metadata appended
function Pandoc(doc)
  -- Only apply this filter for DOCX output
  if not FORMAT:match("docx") then
    return doc
  end
  
  -- Get git information
  local branch = get_git_branch()
  local commit_short = get_git_commit()
  local commit_full = get_git_commit_full()
  local commit_date = get_git_commit_date()
  
  -- Create the metadata section
  local metadata_blocks = {
    pandoc.RawBlock('openxml', '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'),
    pandoc.Header(1, pandoc.Str("Document Generation Metadata")),
    pandoc.Para({
      pandoc.Str("This document was generated from the following git commit:")
    }),
    pandoc.BulletList({
      {pandoc.Plain({pandoc.Strong(pandoc.Str("Branch: ")), pandoc.Str(branch)})},
      {pandoc.Plain({pandoc.Strong(pandoc.Str("Commit: ")), pandoc.Str(commit_short)})},
      {pandoc.Plain({pandoc.Strong(pandoc.Str("Full commit hash: ")), pandoc.Str(commit_full)})},
      {pandoc.Plain({pandoc.Strong(pandoc.Str("Commit date: ")), pandoc.Str(commit_date)})}
    }),
    pandoc.Para({
      pandoc.Str("When transferring edits from this DOCX file back to the Quarto source files, "),
      pandoc.Str("use this commit information to set up the PR correctly and account for any "),
      pandoc.Str("commits that have been added since this document was generated.")
    })
  }
  
  -- Append metadata blocks to the document
  for _, block in ipairs(metadata_blocks) do
    table.insert(doc.blocks, block)
  end
  
  return doc
end
