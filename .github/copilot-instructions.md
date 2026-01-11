# Copilot Instructions for UCD-SeRG Lab Manual

This file contains guidelines for GitHub Copilot and other AI assistants when working with the lab manual.

## Markdown and Quarto Formatting

### Talking about code

When talking about code in prose sections, 
use backticks to apply code formatting:
for example, `dplyr::mutate()`
When talking about packages, use backticks and curly-braces:
for example, `{dplyr}`


### Blank Lines Before Lists

**ALWAYS include a blank line before bullet lists and numbered lists** in markdown and Quarto (.qmd) files.

**Correct:**
```markdown
Here are the key points:

- First item
- Second item
- Third item
```

**Incorrect:**
```markdown
Here are the key points:
- First item
- Second item
- Third item
```

This applies to:
- Bullet lists (starting with `-` or `*`)
- Numbered lists (starting with `1.`, `2.`, etc.)
- Lists in all .qmd files throughout the repository

### Why This Matters

- Ensures consistent markdown rendering across different platforms
- Improves readability in both source and rendered forms
- Prevents rendering issues in Quarto books
- Follows markdown best practices

## R Code Style

- Follow the tidyverse style guide: https://style.tidyverse.org
- Use native pipe `|>` instead of `%>%`
- Use `snake_case` for variable and function names
- Use `.qmd` files exclusively (not `.Rmd`)
- All R projects should use R package structure

## File Organization

### Using Quarto Includes for Modular Content

**All chapters should use Quarto includes to decompose content into separate files.** This modular approach provides significant benefits for version control, collaboration, and content management.

#### Why Use Includes?

1. **Better Git History**: When sections are reordered, only the main chapter file changes (moving include statements), making it immediately clear that content was reorganized rather than edited. When content is edited, only the specific include file changes. This makes reviews focused and precise.

2. **Easier Code Review**: Reviewers can see exactly what changed—either the organization (main file) or the content (include file)—without having to parse through large diffs.

3. **Modular Maintenance**: Each section lives in its own file, making it easier to:
   - Find and edit specific content
   - Reuse sections across chapters if needed
   - Work on different sections simultaneously without merge conflicts
   - Test and preview individual sections

4. **Clear Structure**: The main chapter file becomes a table of contents showing the organization at a glance.

#### Structure Pattern

**Main chapter file** (e.g., `05-coding-practices.qmd`):

- Contains the chapter title and introduction
- Contains section headings (##, ###, etc.)
- Uses `{{< include >}}` statements to pull in content
- Shows the organization/outline of the chapter

**Include files** (e.g., `05-coding-practices/lab-protocols-for-code-and-data.qmd`):

- Stored in a subdirectory matching the chapter name
- Contains only the content for that section (no heading)
- The heading stays in the main chapter file
- Named descriptively using kebab-case

#### Required Pattern

**Always follow this pattern:**

```markdown
## Section Heading

{{< include folder/section-name.qmd >}}
```

**Correct example:**
```markdown
## Lab Protocols for Code and Data

{{< include 05-coding-practices/lab-protocols-for-code-and-data.qmd >}}
```

**Incorrect (don't do this):**
```markdown
{{< include 05-coding-practices/lab-protocols-for-code-and-data.qmd >}}
```

The heading must be in the main file, followed by a blank line, then the include statement.

#### File Naming Conventions

- Main chapter files: `##-chapter-name.qmd` (e.g., `05-coding-practices.qmd`)
- Subdirectory: `##-chapter-name/` (matches the main file name)
- Include files: `descriptive-section-name.qmd` using kebab-case
- Use descriptive names that clearly indicate the content
- Prefix with underscore `_` for partial/helper files not directly included (e.g., `_lintr-summary.qmd`)

#### Git History Benefits Example

**When reordering sections:**
```diff
-## Object naming
+## Function calls
 
-{{< include 05-coding-practices/object-naming.qmd >}}
+{{< include 05-coding-practices/function-calls.qmd >}}
 
-## Function calls
+## Object naming
 
-{{< include 05-coding-practices/function-calls.qmd >}}
+{{< include 05-coding-practices/object-naming.qmd >}}
```
This diff clearly shows a reordering (swapping two sections) with no content changes—only the main chapter file changes.

**When editing content:**
Only the specific include file (e.g., `05-coding-practices/function-calls.qmd`) appears in the git diff, making it easy to review the actual content changes without distraction.

#### When to Create a New Include File

Create a new include file when:

- Adding a new section to a chapter
- A section becomes long enough to benefit from being in its own file (>20-30 lines)
- Content might be reused elsewhere
- You want to work on a section independently

#### Migration Strategy

When working with chapters that don't yet use includes:

1. Create a subdirectory matching the chapter name
2. Extract each section into its own include file
3. Update the main chapter file to use includes
4. Keep headings in the main file
5. Ensure blank lines before include statements
6. Test that rendering still works correctly

## Working with DOCX Files

GitHub Copilot can read and process Microsoft Word (.docx) files, which is useful for translating edits made in Word back to Quarto format.

When working with DOCX files:

- **Always examine tracked changes**: Use the `view` tool to read DOCX files and pay special attention to any tracked changes (insertions, deletions, formatting changes)
- **Review comments**: Look for and address any comments in the DOCX file that may provide context or instructions for edits
- **Translate edits to Quarto**: When edits have been made in a DOCX file, apply the equivalent changes to the corresponding `.qmd` files
- **Preserve formatting**: Ensure that formatting, citations, and cross-references are properly converted to Quarto/markdown syntax
- **Verify completeness**: Check that all edits, including those in tracked changes and comments, have been addressed

This workflow enables a hybrid editing process where collaborators can make edits in familiar Word format, and Copilot can translate those edits back to the Quarto source files.

## Additional Guidelines

- Maintain consistency with existing code style
- Preserve all existing content when refactoring
- Add blank lines before all lists
- Follow the lab's R package development workflow (as described throughout this repo)
