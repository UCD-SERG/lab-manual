#!/bin/bash
# Script to detect changed .qmd files in a PR and prepare for highlighting

set -e

# Get the base branch (default to main)
BASE_BRANCH="${1:-origin/main}"

# Fetch the base branch
git fetch origin main:refs/remotes/origin/main || true

# Get list of changed .qmd files
CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD | grep -E '\.qmd$' || true)

if [ -z "$CHANGED_FILES" ]; then
  echo "No .qmd files changed"
  echo "PREVIEW_CHANGED_FILES=" >> "$GITHUB_ENV"
  exit 0
fi

echo "Changed .qmd files:"
echo "$CHANGED_FILES"

# Export as environment variable for use in other steps
echo "PREVIEW_CHANGED_FILES<<EOF" >> "$GITHUB_ENV"
echo "$CHANGED_FILES" >> "$GITHUB_ENV"
echo "EOF" >> "$GITHUB_ENV"

# Also export a flag indicating we should show highlights
echo "PREVIEW_SHOW_HIGHLIGHTS=true" >> "$GITHUB_ENV"
