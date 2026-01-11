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

## R Code Style

- Follow the tidyverse style guide: https://style.tidyverse.org
- Use native pipe `|>` instead of `%>%`
- Use `snake_case` for variable and function names
- Use `.qmd` files exclusively (not `.Rmd`)
- All R projects should use R package structure

## File Organization

- Use include files for modular organization
- Keep headings in main chapter files
- Content goes in subdirectory include files
- Follow the pattern: `## Heading\n\n{{< include folder/file.qmd >}}`

## Additional Guidelines

- Maintain consistency with existing code style
- Preserve all existing content when refactoring
- Add blank lines before all lists
- Follow the lab's R package development workflow (as described throughout this repo)
