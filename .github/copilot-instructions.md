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

**Do not use raw HTML** (`<a href="...">`) in .qmd files.
Always use Quarto/markdown link syntax instead.

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
- [`{lubridate}`](https://lubridate.tidyverse.org/)


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

**Important: Store images locally in the repository**

**DO NOT link to external image URLs** (especially `https://github.com/user-attachments/assets/`).
Always save images locally in the `assets/images/` directory
and reference them using relative paths.

External image links can break over time,
are not included in repository archives,
and may fail to render in PDF or other output formats.

**Correct:**
```markdown
![Screenshot description](assets/images/my-screenshot.png)
```

**Incorrect:**
```markdown
![Screenshot description](https://github.com/user-attachments/assets/...)
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

**Important: Always use cross-references for sections**

When referring to other sections within the manual,
**always use the Quarto cross-reference system** (`@sec-label`)
instead of plain text references like "the section above" or "see the X section".

**Correct:**
```markdown
See @sec-r-ci for setting up GitHub Actions workflows.
See @sec-ai-best-practices for security considerations.
```

**Incorrect:**
```markdown
See the "Continuous Integration" section above.
See the "Best Practices" section for more details.
```

**Benefits of using cross-references:**

- Automatically generates proper section titles and numbers
- Creates clickable links in HTML output
- Updates automatically if section titles change
- Works correctly across all output formats (HTML, PDF, DOCX, EPUB)
- Quarto will warn you if a reference is broken

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
- **Avoid redundant logical comparisons**: Use logical variables directly in conditional statements (e.g., `if (x)` instead of `if (x == TRUE)` or `if (x == 1)`)
- Use `lubridate::NA_Date_` instead of `as.Date(NA)` for missing date values

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

#### Using Includes for Code Examples and Reusable Content

**Prefer using Quarto's include shortcode over copy-pasting content whenever feasible.**
This applies to code examples, configuration files, and any content that exists elsewhere in the repository.

**Benefits:**

- Single source of truth: Changes to the original file automatically propagate
- Reduces maintenance burden and sync issues
- Ensures examples stay current and accurate
- Better git history (changes appear in one place)

**For including code files:**

Use the include shortcode inside a code fence with the appropriate language.
For example, to include a YAML workflow file:

````markdown
```{.yaml filename="demo-folder/yml.yml"}
{{< include demo-folder/yml.yml >}}
```
````

When you need to show the include shortcode syntax itself in documentation
(without it being processed),
add an extra pair of curly braces:
`{{{< include path/to/file >}}}`.
This prevents Quarto from recognizing it as a shortcode,
allowing the literal syntax to appear in the rendered output.

**When to copy-paste instead:**

Only copy-paste when:

- The content is a simplified example that doesn't exist elsewhere
- You need to show a partial excerpt with modifications
- The source file contains content that shouldn't be fully shown
- You need to demonstrate different variations of similar code

**File naming for included code:**

- Prefix standalone code files with `_` so Quarto doesn't try to render them (e.g., `_helper-functions.R`)
- Use descriptive names that indicate the purpose
- Keep included files in appropriate subdirectories

## Working with DOCX Files

GitHub Copilot can read and process Microsoft Word (.docx) files, which is useful for translating edits made in Word back to Quarto format.

When working with DOCX files:

- **Check git metadata first**: DOCX files generated from this repository include a "Document Generation Metadata" section at the end with the branch name, commit hash, and commit date. Use this information to:
  - Identify which commit generated the original DOCX
  - Set up the resulting PR correctly with the appropriate base branch
  - Account for any commits that have been added since the DOCX was generated
  - Understand the state of the repository when the DOCX was created
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
- **When discussing current world conditions or technology capabilities**:
  Always mention the date or time period (e.g., "as of early 2025", "in 2024") to provide temporal context and prevent content from becoming misleading as time passes

### Citations and Evidence for Claims

**All factual claims should be backed by either citations or direct evidence.**

When writing documentation:

- **Cite sources** for factual statements about how tools, systems, or processes work
- **Provide direct evidence** by demonstrating behavior yourself (e.g., showing command output, testing functionality)
- **Remove unverified explanations** rather than including speculative or unsubstantiated claims
- Link to authoritative sources like official documentation, GitHub issues, or peer-reviewed materials

**When adding links to external resources:**

- **Always verify the content** of linked pages before adding them to the manual
- Read the repository README, DESCRIPTION file, or website content to understand what the resource actually contains
- Use accurate descriptions based on the actual content, not assumptions based on the URL or name
- For GitHub repositories, check key files like README.md, DESCRIPTION, index.qmd, or _quarto.yml to understand the project's purpose

**Example of what NOT to do:**

In [PR #151](https://github.com/UCD-SERG/lab-manual/pull/151/), the initial approach failed to verify the actual content of the linked repository:
- Assumed "PSW" meant "Propensity Score Weighting" based on the acronym
- Created a mischaracterized description: "R package for propensity score weighting and related methods for causal inference in observational studies"
- Placed the link in an incorrect section ("Useful R Packages")

**Example of what TO do:**

After reviewing the actual repository files (DESCRIPTION, _quarto.yml, index.qmd):
- Verified that PSW stands for "Principles of Scientific Writing"
- Determined it's a Quarto book (later revised to "handbook") about scientific writing principles
- Placed the link in the appropriate "Writing" section
- Used an accurate description based on the actual content: "a handbook covering scientific writing principles including citations and evidence, word choice, and conciseness"

This practice ensures accuracy, builds trust, and helps readers verify information independently.

### Testing and Validation

**ALWAYS render the full Quarto book before requesting code review or finalizing your work.**

Run `quarto render` to ensure the book builds successfully in all output formats (HTML, PDF, DOCX, EPUB).
This validates that:

- All cross-references are valid
- All images can be properly converted for PDF output (use PNG format for images, not SVG)
- All code chunks execute without errors
- The book structure is correct

If the render fails,
fix the issues before committing or requesting review.
Common issues include:

- SVG images that cannot be converted to PDF (use PNG instead)
- Invalid cross-references
- Missing or incorrect file paths
- Syntax errors in code chunks
