# Copilot Instructions for UCD-SeRG Lab Manual

This file contains guidelines for GitHub Copilot and other AI assistants when working with the lab manual.

## Markdown and Quarto Formatting

### Talking about code

When talking about code in prose sections, 
use backticks to apply code formatting:
for example, `dplyr::mutate()`

When talking about packages in prose,
use backticks and curly-braces with a hyperlink to the package website.
For example: [`{dplyr}`](https://dplyr.tidyverse.org/)

Common package URLs:

- [`{dplyr}`](https://dplyr.tidyverse.org/)
- [`{ggplot2}`](https://ggplot2.tidyverse.org/)
- [`{tidyr}`](https://tidyr.tidyverse.org/)
- [`{readr}`](https://readr.tidyverse.org/)
- [`{purrr}`](https://purrr.tidyverse.org/)
- [`{tibble}`](https://tibble.tidyverse.org/)
- [`{stringr}`](https://stringr.tidyverse.org/)
- [`{forcats}`](https://forcats.tidyverse.org/)
- [`{styler}`](https://styler.r-lib.org/)
- [`{lintr}`](https://lintr.r-lib.org/)
- [`{roxygen2}`](https://roxygen2.r-lib.org/)
- [`{testthat}`](https://testthat.r-lib.org/)
- [`{usethis}`](https://usethis.r-lib.org/)
- [`{devtools}`](https://devtools.r-lib.org/)
- [`{renv}`](https://rstudio.github.io/renv/)
- [`{targets}`](https://docs.ropensci.org/targets/)
- [`{data.table}`](https://rdatatable.gitlab.io/data.table/)
- [`{assertthat}`](https://cran.r-project.org/package=assertthat)


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

### Line Breaks in Plain Text

**ALWAYS line-break at the ends of sentences and long phrases in plain-text paragraphs in .qmd files** to avoid long lines.

**Correct:**
```markdown
When talking about code in prose sections,
use backticks to apply code formatting.
This helps maintain readability in source files
and makes diffs easier to review.
```

**Incorrect:**
```markdown
When talking about code in prose sections, use backticks to apply code formatting. This helps maintain readability in source files and makes diffs easier to review.
```

**Benefits:**

- Improves readability of source .qmd files
- Makes git diffs clearer and easier to review
- Helps identify specific changes in version control
- Prevents horizontal scrolling when editing
- Follows semantic line breaks best practice

**Guidelines:**

- Break after complete sentences (at periods)
- Break after long phrases or clauses (at commas or conjunctions)
- Break after approximately 60-80 characters when appropriate
- Keep related short phrases together on one line
- Don't break in the middle of inline code, links, or formatting

### Why This Matters

- Ensures consistent markdown rendering across different platforms
- Improves readability in both source and rendered forms
- Prevents rendering issues in Quarto books
- Follows markdown best practices

### Cross-References for Figures and Tables

**ALWAYS use Quarto's cross-reference system for figures, tables, and other captioned content.**
See [Quarto Cross-References documentation](https://quarto.org/docs/authoring/cross-references.html) for complete details.

**Required label prefixes:**

- Figures: `#fig-` (e.g., `#fig-data-masking`, `#fig-workflow-diagram`)
- Tables: `#tbl-` (e.g., `#tbl-git-commands`, `#tbl-summary-stats`)
- Equations: `#eq-` (e.g., `#eq-regression-model`)
- Sections: `#sec-` (e.g., `#sec-introduction`) - already in use throughout manual
- Theorems: `#thm-` (e.g., `#thm-central-limit`)
- Lemmas: `#lem-` (e.g., `#lem-auxiliary-result`)
- Corollaries: `#cor-` (e.g., `#cor-special-case`)
- Propositions: `#prp-` (e.g., `#prp-main-result`)
- Examples: `#exm-` (e.g., `#exm-simple-case`)
- Exercises: `#exr-` (e.g., `#exr-practice-problem`)

**For figures (images):**

```markdown
![Caption text](path/to/image.png){#fig-label}
```

**For tables (markdown tables):**

```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data     | Data     |

: Caption text {#tbl-label}
```

**For code-generated figures:**

```{{r}}
#| label: fig-plot-name
#| fig-cap: "Caption text"

# R code to generate plot
```

**For code-generated tables:**

```{{r}}
#| label: tbl-table-name
#| tbl-cap: "Caption text"

# R code to generate table
```

**Referencing in text:**

- Figures: `@fig-label` produces "Figure X"
- Tables: `@tbl-label` produces "Table X"
- Equations: `@eq-label` produces "Equation X"
- Sections: `@sec-label` produces "Section X"

**Benefits:**

- Automatic numbering of figures, tables, and equations
- Automatic updates when content is reordered
- Clickable cross-references in HTML and PDF output
- Consistent formatting across all output formats
- Better accessibility for screen readers

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
- Uses the `include` shortcode to pull in content
(see <https://quarto.org/docs/authoring/includes.html> for details) 
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

{{< include demo-folder/section-name.qmd >}}
```

**Correct example:**
```markdown
## Section heading

{{< include demo-folder/section-name.qmd >}}
```

**Incorrect (don't do this):**
```markdown
{{< include demo-folder/section-name.qmd >}}
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
 
-{{< include demo-folder/section-name.qmd >}}
+{{< include demo-folder/section-2.qmd >}}
 
-## Function calls
+## Object naming
 
-{{< include demo-folder/section-2.qmd >}}
+{{< include demo-folder/section-name.qmd >}}
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
