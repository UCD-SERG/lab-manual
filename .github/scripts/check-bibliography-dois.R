#!/usr/bin/env Rscript
# Check bibliography files for DOI requirements:
# 1. Every book and article must have a DOI field (except DOI_EXEMPT keys)
# 2. Every DOI must resolve to a valid URL
# 3. Reference information must match the document at the DOI URL

suppressPackageStartupMessages({
  library(bib2df)
  library(httr)
  library(jsonlite)
  library(stringr)
})

# Entries that legitimately have no DOI and are therefore exempt from the
# "must have a DOI field" requirement (online-only / O'Reilly / self-published
# books that publishers never registered a DOI for). DOIs that *are* present
# on other books are still validated normally.
DOI_EXEMPT <- c(
  "wickham2023r4ds",   # R for Data Science (O'Reilly, online: r4ds.hadley.nz)
  "wickham2023rpkgs",  # R Packages (O'Reilly, online: r-pkgs.org)
  "wickham2021shiny",  # Mastering Shiny (O'Reilly, online: mastering-shiny.org)
  "bryan2023happygit"  # Happy Git and GitHub for the useR (self-published online)
)

#' Parse BibTeX file and extract entries
#'
#' @param filepath Path to BibTeX file
#' @return Data frame of bibliography entries
parse_bibtex_file <- function(filepath) {
  tryCatch({
    bib_df <- bib2df(filepath)
    return(bib_df)
  }, error = function(e) {
    cat(sprintf("Error parsing BibTeX file: %s\n", e$message))
    return(NULL)
  })
}

#' Check if entry has a DOI field
#'
#' @param entry Single bibliography entry (row from data frame)
#' @return List with has_doi (logical) and error (string or NULL)
check_doi_field <- function(entry) {
  entry_type <- tolower(entry$CATEGORY)
  entry_key <- entry$BIBTEXKEY
  
  if (entry_type %in% c("book", "article")) {
    if (is.na(entry$DOI) || entry$DOI == "") {
      return(list(
        has_doi = FALSE,
        error = sprintf("Entry '%s' (%s) is missing DOI field", entry_key, entry_type)
      ))
    }
  }
  
  return(list(has_doi = TRUE, error = NULL))
}

#' Validate that a DOI resolves to a valid URL
#'
#' Requests are retried with exponential backoff so that a transient
#' resolver hiccup (timeout, 5xx) does not fail the whole check (#358).
#'
#' @param doi DOI string
#' @return List with is_valid, error, status_code, and transient
#'   (TRUE when the failure looks like resolver unavailability rather than
#'   a genuinely broken DOI)
validate_doi_url <- function(doi) {
  # Clean up DOI
  doi <- trimws(doi)

  # Extract just the DOI identifier
  doi_match <- str_extract(doi, "10\\.\\d+/[^\\s]+")

  if (is.na(doi_match)) {
    return(list(
      is_valid = FALSE,
      error = sprintf("Invalid DOI format: %s", doi),
      status_code = NULL,
      transient = FALSE
    ))
  }

  doi_identifier <- doi_match
  doi_url <- sprintf("https://doi.org/%s", doi_identifier)

  tryCatch({
    # RETRY with exponential backoff; a 404/410 is definitive (the DOI
    # itself is wrong), so it terminates the retries immediately.
    response <- RETRY(
      "GET",
      doi_url,
      timeout(30),
      user_agent("Mozilla/5.0 (compatible; BibliographyChecker/1.0)"),
      times = 3,
      pause_base = 2,
      pause_cap = 16,
      terminate_on = c(404, 410),
      quiet = TRUE
    )

    status_code <- status_code(response)

    if (status_code == 200) {
      return(list(
        is_valid = TRUE,
        error = NULL,
        status_code = status_code,
        transient = FALSE
      ))
    } else {
      return(list(
        is_valid = FALSE,
        error = sprintf("DOI URL returned status %d", status_code),
        status_code = status_code,
        # 404/410 mean the DOI is genuinely broken; any other non-200
        # that survived the retries (5xx, 429, other 4xx from an
        # overloaded or bot-blocking resolver) is treated as transient.
        transient = !(status_code %in% c(404, 410))
      ))
    }
  }, error = function(e) {
    # A request that still errors after retries (timeout, connection
    # failure) means the resolver was unavailable, not that the DOI is
    # wrong.
    return(list(
      is_valid = FALSE,
      error = sprintf("Error accessing DOI: %s", e$message),
      status_code = NULL,
      transient = TRUE
    ))
  })
}

#' Get DOI metadata from CrossRef API
#'
#' @param doi DOI string
#' @return Metadata list or NULL if failed
get_doi_metadata <- function(doi) {
  doi <- trimws(doi)
  doi_match <- str_extract(doi, "10\\.\\d+/[^\\s]+")
  
  if (is.na(doi_match)) {
    return(NULL)
  }
  
  doi_identifier <- doi_match
  api_url <- sprintf("https://api.crossref.org/works/%s", doi_identifier)
  
  tryCatch({
    response <- RETRY(
      "GET",
      api_url,
      timeout(30),
      user_agent("Mozilla/5.0 (compatible; BibliographyChecker/1.0)"),
      times = 3,
      pause_base = 2,
      pause_cap = 16,
      terminate_on = c(404, 410),
      quiet = TRUE
    )

    if (status_code(response) == 200) {
      data <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
      return(data$message)
    }
  }, error = function(e) {
    # Failed to fetch metadata
  })
  
  return(NULL)
}

#' Normalize string for comparison
#'
#' @param s String to normalize
#' @return Normalized string
normalize_string <- function(s) {
  if (is.na(s) || s == "") {
    return("")
  }
  
  # Convert to lowercase, remove punctuation, remove extra whitespace
  s <- tolower(s)
  s <- str_replace_all(s, "[^a-zA-Z0-9\\s]", "")
  s <- str_replace_all(s, "\\s+", " ")
  return(trimws(s))
}

#' Compare BibTeX entry with DOI metadata
#'
#' @param entry Bibliography entry
#' @param metadata CrossRef metadata
#' @return List with match (logical) and warnings (character vector)
compare_metadata <- function(entry, metadata) {
  warnings <- c()
  
  # Check title
  if (!is.na(entry$TITLE) && !is.null(metadata$title)) {
    bib_title <- normalize_string(entry$TITLE)
    
    crossref_title <- metadata$title
    if (is.list(crossref_title) && length(crossref_title) > 0) {
      crossref_title <- crossref_title[[1]]
    }
    crossref_title <- normalize_string(as.character(crossref_title))
    
    # Check word overlap (at least 50%)
    if (bib_title != "" && crossref_title != "") {
      bib_words <- str_split(bib_title, "\\s+")[[1]]
      crossref_words <- str_split(crossref_title, "\\s+")[[1]]
      
      if (length(bib_words) > 0 && length(crossref_words) > 0) {
        overlap <- length(intersect(bib_words, crossref_words))
        total <- min(length(bib_words), length(crossref_words))
        
        if (total > 0 && overlap / total < 0.5) {
          warnings <- c(warnings, sprintf(
            "Title mismatch: BibTeX='%s' vs DOI='%s'",
            entry$TITLE, metadata$title
          ))
        }
      }
    }
  }
  
  # Check author (basic check)
  if (!is.na(entry$AUTHOR) && !is.null(metadata$author)) {
    bib_author <- normalize_string(entry$AUTHOR)
    
    crossref_authors <- metadata$author
    if (is.data.frame(crossref_authors) && nrow(crossref_authors) > 0) {
      family_names <- crossref_authors$family[!is.na(crossref_authors$family)]
      
      if (length(family_names) > 0) {
        found_match <- FALSE
        for (name in family_names) {
          norm_name <- normalize_string(name)
          if (norm_name != "" && grepl(norm_name, bib_author)) {
            found_match <- TRUE
            break
          }
        }
        
        if (!found_match) {
          warnings <- c(warnings, sprintf(
            "Author mismatch: BibTeX='%s' vs DOI authors",
            entry$AUTHOR
          ))
        }
      }
    }
  }
  
  # Check year
  if (!is.na(entry$YEAR)) {
    bib_year <- as.character(entry$YEAR)
    
    # Try published-print first, then published-online
    crossref_year <- NULL
    if (!is.null(metadata$`published-print`$`date-parts`)) {
      date_parts <- metadata$`published-print`$`date-parts`
      if (length(date_parts) > 0 && length(date_parts[[1]]) > 0) {
        crossref_year <- as.character(date_parts[[1]][1])
      }
    }
    
    if (is.null(crossref_year) && !is.null(metadata$`published-online`$`date-parts`)) {
      date_parts <- metadata$`published-online`$`date-parts`
      if (length(date_parts) > 0 && length(date_parts[[1]]) > 0) {
        crossref_year <- as.character(date_parts[[1]][1])
      }
    }
    
    if (!is.null(crossref_year) && bib_year != crossref_year) {
      warnings <- c(warnings, sprintf(
        "Year mismatch: BibTeX='%s' vs DOI='%s'",
        bib_year, crossref_year
      ))
    }
  }
  
  return(list(match = TRUE, warnings = warnings))
}

#' Check bibliography file for DOI requirements
#'
#' @param filepath Path to bibliography file
#' @param verify_metadata Whether to verify metadata (default TRUE)
#' @return List with checked_count, errors_count, errors, and warnings
check_bibliography_file <- function(filepath, verify_metadata = TRUE) {
  cat(sprintf("\nChecking %s...\n", filepath))
  
  bib_df <- parse_bibtex_file(filepath)
  if (is.null(bib_df)) {
    return(list(
      checked_count = 0,
      errors_count = 1,
      errors = c("Failed to parse BibTeX file"),
      warnings = c()
    ))
  }
  
  errors <- c()
  resolver_warnings <- c()
  checked_count <- 0
  
  for (i in seq_len(nrow(bib_df))) {
    entry <- bib_df[i, ]
    entry_type <- tolower(entry$CATEGORY)
    
    # Only check books and articles
    if (!(entry_type %in% c("book", "article"))) {
      next
    }

    # DOI-exempt entries are allowed to have no DOI. Only skip when the DOI
    # is actually absent; if one is present it is still validated below.
    doi_present <- !is.na(entry$DOI) && nzchar(trimws(entry$DOI))
    if (entry$BIBTEXKEY %in% DOI_EXEMPT && !doi_present) {
      cat(sprintf("  Skipping %s '%s' (DOI-exempt, no DOI)\n", entry_type, entry$BIBTEXKEY))
      next
    }

    checked_count <- checked_count + 1
    cat(sprintf("  Checking %s '%s'...\n", entry_type, entry$BIBTEXKEY))
    
    # Check 1: DOI field exists
    doi_check <- check_doi_field(entry)
    if (!doi_check$has_doi) {
      errors <- c(errors, doi_check$error)
      cat(sprintf("    ❌ %s\n", doi_check$error))
      next
    }
    
    doi <- entry$DOI
    cat(sprintf("    DOI: %s\n", doi))
    
    # Check 2: DOI URL is valid
    url_check <- validate_doi_url(doi)
    if (!url_check$is_valid && url_check$transient) {
      warning_msg <- sprintf(
        "Entry '%s': %s (resolver unavailable after retries; not treated as an error)",
        entry$BIBTEXKEY, url_check$error
      )
      resolver_warnings <- c(resolver_warnings, warning_msg)
      cat(sprintf("    ⚠️  %s\n", warning_msg))
      next
    }
    if (!url_check$is_valid) {
      error_msg <- sprintf("Entry '%s': %s", entry$BIBTEXKEY, url_check$error)
      errors <- c(errors, error_msg)
      cat(sprintf("    ❌ %s\n", error_msg))
      next
    } else {
      cat(sprintf("    ✓ DOI URL is valid (status %d)\n", url_check$status_code))
    }
    
    # Check 3: Metadata matches (if enabled)
    if (verify_metadata) {
      cat("    Fetching DOI metadata...\n")
      metadata <- get_doi_metadata(doi)
      
      if (!is.null(metadata)) {
        comparison <- compare_metadata(entry, metadata)
        if (length(comparison$warnings) > 0) {
          for (warning in comparison$warnings) {
            cat(sprintf("    ⚠️  %s\n", warning))
          }
        } else {
          cat("    ✓ Metadata appears consistent\n")
        }
      } else {
        cat("    ⚠️  Could not fetch metadata from CrossRef API\n")
      }
      
      # Small delay to be nice to the API
      Sys.sleep(0.5)
    }
  }
  
  return(list(
    checked_count = checked_count,
    errors_count = length(errors),
    errors = errors,
    warnings = resolver_warnings
  ))
}

# Main execution
run_doi_validation <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  # Parse arguments
  no_metadata_check <- "--no-metadata-check" %in% args
  files_raw <- args[!grepl("^--", args)]
  # Handle the case where all file paths are passed as a single space-separated
  # argument (e.g., via "$BIB_FILES" in a shell script). Only split on
  # whitespace when the single argument is not itself an existing file path,
  # so that valid quoted paths containing spaces are preserved.
  if (length(files_raw) == 1 && !file.exists(files_raw)) {
    files <- unlist(strsplit(files_raw, "\\s+"))
    files <- files[nchar(trimws(files)) > 0]
  } else {
    files <- files_raw
  }

  if (length(files) == 0) {
    cat("Usage: check-bibliography-dois.R [--no-metadata-check] <file1.bib> [file2.bib ...]\n")
    quit(status = 1)
  }
  
  total_checked <- 0
  total_errors <- 0
  all_errors <- c()
  all_warnings <- c()

  for (filepath in files) {
    if (!file.exists(filepath)) {
      cat(sprintf("Error: File %s does not exist\n", filepath))
      quit(status = 1)
    }

    result <- check_bibliography_file(filepath, verify_metadata = !no_metadata_check)
    total_checked <- total_checked + result$checked_count
    total_errors <- total_errors + result$errors_count
    all_errors <- c(all_errors, result$errors)
    all_warnings <- c(all_warnings, result$warnings)
  }

  # Print summary
  cat("\n")
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat("SUMMARY\n")
  cat(paste(rep("=", 70), collapse = ""), "\n")
  cat(sprintf("Total entries checked: %d\n", total_checked))
  cat(sprintf("Errors found: %d\n", total_errors))
  cat(sprintf("Transient resolver warnings: %d\n", length(all_warnings)))

  if (length(all_warnings) > 0) {
    cat("\nWARNINGS (resolver unavailable; not failing the check):\n")
    for (w in all_warnings) {
      cat(sprintf("  • %s\n", w))
    }
  }

  if (total_errors > 0) {
    cat("\nERRORS:\n")
    for (error in all_errors) {
      cat(sprintf("  • %s\n", error))
    }
    quit(status = 1)
  } else {
    cat("\n✓ All checks passed!\n")
    quit(status = 0)
  }
}

# Run main function
run_doi_validation()
