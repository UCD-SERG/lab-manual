#!/usr/bin/env python3
"""
Script to compare rendered HTML files and highlight changed sections.
This compares the PR's rendered HTML with the published version from gh-pages.
"""

import os
import sys
import re
import difflib
import subprocess
from pathlib import Path
from html.parser import HTMLParser
from html import escape, unescape

class HTMLDiffer:
    """Compare HTML files and inject highlighting for changed sections."""
    
    def __init__(self, local_html_dir, base_html_dir=None):
        self.local_html_dir = Path(local_html_dir)
        self.base_html_dir = Path(base_html_dir) if base_html_dir else None
        
    def fetch_base_html(self, filepath):
        """Get the base (published) HTML for comparison."""
        if not self.base_html_dir:
            return None
            
        # Get the relative path and construct base path
        relative_path = filepath.relative_to(self.local_html_dir)
        base_path = self.base_html_dir / relative_path
        
        if not base_path.exists():
            print(f"  Base file not found: {base_path}", file=sys.stderr)
            return None
        
        try:
            with open(base_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            print(f"  Could not read {base_path}: {e}", file=sys.stderr)
            return None
    
    def extract_main_content(self, html):
        """Extract the main content section from HTML, ignoring navigation and metadata."""
        # Find the main content area (typically in <main> or specific div)
        main_match = re.search(r'<main[^>]*>(.*?)</main>', html, re.DOTALL)
        if main_match:
            return main_match.group(1)
        
        # Fallback: look for common content containers
        content_match = re.search(r'<div[^>]*class="[^"]*content[^"]*"[^>]*>(.*?)</div>', html, re.DOTALL)
        if content_match:
            return content_match.group(1)
        
        return html
    
    def normalize_html(self, html):
        """Normalize HTML for better comparison (remove extra whitespace, etc.)."""
        # Remove extra whitespace
        html = re.sub(r'\s+', ' ', html)
        # Remove comments
        html = re.sub(r'<!--.*?-->', '', html, flags=re.DOTALL)
        return html.strip()
    
    def highlight_text_diff(self, old_text, new_text):
        """Highlight differences between old and new text at word/phrase level."""
        # Split into words while preserving spaces
        old_words = re.findall(r'\S+|\s+', old_text)
        new_words = re.findall(r'\S+|\s+', new_text)
        
        # Use SequenceMatcher to find differences
        matcher = difflib.SequenceMatcher(None, old_words, new_words)
        
        result = []
        for tag, i1, i2, j1, j2 in matcher.get_opcodes():
            if tag == 'equal':
                # No change, keep as is
                result.extend(new_words[j1:j2])
            elif tag == 'replace':
                # Text was changed - highlight the new text
                changed_text = ''.join(new_words[j1:j2])
                result.append(f'<mark class="preview-text-changed" title="Modified from: {escape("".join(old_words[i1:i2]))}">{changed_text}</mark>')
            elif tag == 'insert':
                # Text was added - highlight as insertion
                added_text = ''.join(new_words[j1:j2])
                result.append(f'<mark class="preview-text-added">{added_text}</mark>')
            elif tag == 'delete':
                # Text was deleted - we don't show deletions in the new version
                pass
        
        return ''.join(result)
    
    def extract_text_from_element(self, element_html):
        """Extract plain text from an HTML element, preserving basic structure."""
        # Remove inner HTML tags but keep the text
        text = re.sub(r'<[^>]+>', '', element_html)
        return unescape(text).strip()
    
    def highlight_changed_elements(self, old_html, new_html):
        """Find and highlight changed paragraphs and sections in the HTML."""
        if not old_html:
            return new_html, 0
        
        # Constants for similarity matching
        SIMILARITY_THRESHOLD_MIN = 0.5  # Minimum similarity to consider elements related
        SIMILARITY_THRESHOLD_MAX = 0.99  # Maximum similarity to still highlight differences
        
        # Extract main content for both versions
        old_content = self.extract_main_content(old_html)
        new_content = self.extract_main_content(new_html)
        
        # Define element types to compare
        COMPARABLE_ELEMENTS = 'p|h[1-6]|li|blockquote'
        element_pattern = f'(<(?:{COMPARABLE_ELEMENTS})[^>]*>.*?</(?:{COMPARABLE_ELEMENTS})>)'
        
        old_elements = re.findall(element_pattern, old_content, re.DOTALL)
        new_elements = re.findall(element_pattern, new_content, re.DOTALL)
        
        # Create a list of (text, element) tuples to handle duplicates
        old_elem_list = []
        for elem in old_elements:
            text = self.extract_text_from_element(elem)
            if text:  # Only store non-empty elements
                old_elem_list.append((text, elem))
        
        # Track which old elements have been matched to avoid reuse
        used_old_indices = set()
        
        # Process each new element and check if it changed
        highlighted_new_html = new_html
        changes_made = 0
        
        for new_elem in new_elements:
            new_text = self.extract_text_from_element(new_elem)
            if not new_text:
                continue
            
            # Try to find a matching old element
            best_match_idx = None
            best_ratio = 0.0
            
            for idx, (old_text, old_elem) in enumerate(old_elem_list):
                if idx in used_old_indices:
                    continue  # Already matched this element
                    
                ratio = difflib.SequenceMatcher(None, old_text, new_text).ratio()
                if ratio > best_ratio:
                    best_ratio = ratio
                    best_match_idx = idx
            
            # If we found a similar element and it's not identical, highlight the differences
            if best_match_idx is not None and best_ratio > SIMILARITY_THRESHOLD_MIN and best_ratio < SIMILARITY_THRESHOLD_MAX:
                used_old_indices.add(best_match_idx)
                old_text, old_elem = old_elem_list[best_match_idx]
                
                # Extract the inner text from the new element
                tag_match = re.match(r'(<[^>]+>)(.*)(</[^>]+>)', new_elem, re.DOTALL)
                if tag_match:
                    open_tag, inner_content, close_tag = tag_match.groups()
                    
                    # Get the old and new text for comparison
                    new_inner = self.extract_text_from_element(new_elem)
                    
                    # Highlight the differences
                    highlighted_inner = self.highlight_text_diff(old_text, new_inner)
                    
                    # Reconstruct the element with highlighting
                    highlighted_elem = f'{open_tag}{highlighted_inner}{close_tag}'
                    
                    # Replace in the HTML - use a unique marker to ensure we replace the right instance
                    # We escape the element for regex safety
                    escaped_elem = re.escape(new_elem)
                    highlighted_new_html = re.sub(escaped_elem, highlighted_elem, highlighted_new_html, count=1)
                    changes_made += 1
            
            elif best_match_idx is None and new_text:
                # This is a completely new element - highlight the whole thing
                tag_match = re.match(r'(<[^>]+>)(.*)(</[^>]+>)', new_elem, re.DOTALL)
                if tag_match:
                    open_tag, inner_content, close_tag = tag_match.groups()
                    new_inner = self.extract_text_from_element(new_elem)
                    
                    # Mark the entire element as new
                    highlighted_elem = f'{open_tag}<mark class="preview-element-added">{new_inner}</mark>{close_tag}'
                    
                    # Replace in the HTML using regex with escaping
                    escaped_elem = re.escape(new_elem)
                    highlighted_new_html = re.sub(escaped_elem, highlighted_elem, highlighted_new_html, count=1)
                    changes_made += 1
        
        return highlighted_new_html, changes_made
    
    def find_changed_sections(self, old_html, new_html):
        """Find sections that changed between old and new HTML."""
        if not old_html:
            return None, 0
        
        old_content = self.normalize_html(self.extract_main_content(old_html))
        new_content = self.normalize_html(self.extract_main_content(new_html))
        
        # Calculate similarity ratio
        similarity = difflib.SequenceMatcher(None, old_content, new_content).ratio()
        
        # If content is nearly identical, no need to highlight
        if similarity > 0.95:
            return None, similarity
        
        # Use unified diff to find changed lines
        old_lines = old_content.split('\n')
        new_lines = new_content.split('\n')
        
        differ = difflib.unified_diff(old_lines, new_lines, lineterm='')
        diff_lines = list(differ)
        
        # Count changes
        changes = sum(1 for line in diff_lines if line.startswith('+') or line.startswith('-'))
        
        return diff_lines if changes > 0 else None, similarity
    
    def inject_change_notice(self, html, num_changes, similarity):
        """Add a notice about content changes to the HTML."""
        # Calculate change percentage
        change_pct = int((1 - similarity) * 100)
        
        # Create notice HTML - using CSS class defined in styles.css
        notice = f'''
<div class="preview-content-changed-notice">
    <p style="margin: 0;"><strong>🔍 Content Changes:</strong> This page has been modified in this pull request (~{change_pct}% of content changed).</p>
</div>
'''
        
        # Find insertion point (after the page changed banner if it exists, or at start of main)
        # Look for existing preview-changed-banner
        banner_match = re.search(r'(<div class="preview-changed-banner"[^>]*>.*?</div>)', html, re.DOTALL)
        if banner_match:
            # Insert after the preview-changed-banner
            insertion_point = banner_match.end()
        else:
            # Insert at the start of main content
            main_match = re.search(r'(<main[^>]*>)', html)
            if main_match:
                insertion_point = main_match.end()
            else:
                # Can't find insertion point, skip
                return html
        
        html = html[:insertion_point] + notice + html[insertion_point:]
        
        return html
    
    def highlight_toc_entries(self, html, changed_files):
        """Highlight table of contents entries for changed files."""
        if not changed_files:
            return html
        
        # Convert .qmd files to their corresponding HTML fragment IDs
        # For example, "01-culture-and-conduct.qmd" maps to link containing "01-culture-and-conduct.html"
        changed_html_files = set()
        for qmd_file in changed_files:
            html_file = qmd_file.replace('.qmd', '.html')
            changed_html_files.add(html_file)
        
        # Find all TOC links and add highlighting class to those that point to changed files
        # TOC links are typically in the sidebar navigation
        for html_file in changed_html_files:
            # Pattern to match TOC links - look for links in the sidebar navigation
            # that point to the changed file
            pattern = rf'(<a[^>]*href="[^"]*{re.escape(html_file)}[^"]*"[^>]*class="[^"]*")([^"]*"[^>]*>)'
            
            def add_toc_highlight_class(match):
                prefix = match.group(1)
                suffix = match.group(2)
                # Add our highlighting class
                return f'{prefix} preview-toc-changed{suffix}'
            
            html = re.sub(pattern, add_toc_highlight_class, html)
        
        return html
    
    def process_file(self, local_filepath):
        """Process a single HTML file: fetch old version, compare, and highlight."""
        print(f"Processing {local_filepath}...")
        
        # Read the new (PR) version
        with open(local_filepath, 'r', encoding='utf-8') as f:
            new_html = f.read()
        
        # Fetch the published (main) version
        old_html = self.fetch_base_html(local_filepath)
        
        if old_html:
            # Find what changed
            diff_lines, similarity = self.find_changed_sections(old_html, new_html)
            
            if diff_lines:
                num_changes = len([l for l in diff_lines if l.startswith('+') or l.startswith('-')])
                print(f"  Found content changes (similarity: {similarity:.2%})")
                
                # Apply inline highlighting to changed elements
                highlighted_html, inline_changes = self.highlight_changed_elements(old_html, new_html)
                
                if inline_changes > 0:
                    print(f"  Highlighted {inline_changes} changed element(s) inline")
                    new_html = highlighted_html
                
                # Add change notice banner
                new_html = self.inject_change_notice(new_html, num_changes, similarity)
                
                # Write back
                with open(local_filepath, 'w', encoding='utf-8') as f:
                    f.write(new_html)
                
                print(f"  Added content change notice and inline highlights to {local_filepath}")
            else:
                print(f"  No significant content changes detected (similarity: {similarity:.2%})")
        else:
            print(f"  Could not fetch base version (file may be new)")

def checkout_base_html(base_ref='origin/gh-pages', target_dir='/tmp/base-html'):
    """Check out the base HTML files from gh-pages for comparison."""
    target_path = Path(target_dir)
    
    # Create target directory
    target_path.mkdir(parents=True, exist_ok=True)
    
    try:
        # Try to fetch the gh-pages branch
        subprocess.run(['git', 'fetch', 'origin', 'gh-pages:gh-pages'], 
                      check=False, capture_output=True)
        
        # Check out just the docs or root directory from gh-pages
        result = subprocess.run(
            ['git', 'show', f'{base_ref}:docs/'],
            capture_output=True,
            check=False
        )
        
        if result.returncode != 0:
            # Try root directory instead
            result = subprocess.run(
                ['git', 'ls-tree', '-r', '--name-only', base_ref],
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.returncode == 0:
                files = [f for f in result.stdout.split('\n') if f.endswith('.html')]
                
                # Extract each HTML file
                for file in files:
                    output_path = target_path / file
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    
                    with open(output_path, 'wb') as f:
                        subprocess.run(
                            ['git', 'show', f'{base_ref}:{file}'],
                            stdout=f,
                            check=False
                        )
                
                return target_path if files else None
        
        return None
    except Exception as e:
        print(f"Could not check out base HTML: {e}", file=sys.stderr)
        return None

def main():
    # Get the local HTML directory
    html_dir = os.getenv('HTML_DIR', './docs')
    
    # Get list of changed HTML files (derived from changed .qmd files)
    changed_files = os.getenv('PREVIEW_CHANGED_FILES', '').strip()
    
    if not changed_files:
        print("No changed files to process")
        return
    
    # Try to check out base HTML from gh-pages
    print("Checking out base HTML from gh-pages...")
    base_html_dir = checkout_base_html()
    
    if not base_html_dir:
        print("Warning: Could not check out base HTML, will skip content comparison")
        print("(This is normal for new files or if gh-pages doesn't exist yet)")
    else:
        print(f"Base HTML checked out to {base_html_dir}")
    
    # Convert .qmd files to .html files
    html_files = []
    changed_qmd_files = []
    for qmd_file in changed_files.split('\n'):
        qmd_file = qmd_file.strip()
        if qmd_file:
            changed_qmd_files.append(qmd_file)
            # Convert .qmd to .html
            html_file = qmd_file.replace('.qmd', '.html')
            html_path = Path(html_dir) / html_file
            if html_path.exists():
                html_files.append(html_path)
    
    if not html_files:
        print("No HTML files to process")
        return
    
    # Create differ and process files
    differ = HTMLDiffer(html_dir, base_html_dir)
    
    for html_file in html_files:
        differ.process_file(html_file)
    
    # Highlight TOC entries in all HTML files (not just changed ones)
    print("\nHighlighting table of contents entries for changed chapters...")
    all_html_files = list(Path(html_dir).glob("*.html"))
    
    for html_path in all_html_files:
        try:
            with open(html_path, 'r', encoding='utf-8') as f:
                html = f.read()
            
            # Add TOC highlighting
            highlighted_html = differ.highlight_toc_entries(html, changed_qmd_files)
            
            # Only write back if something changed
            if highlighted_html != html:
                with open(html_path, 'w', encoding='utf-8') as f:
                    f.write(highlighted_html)
                print(f"  Added TOC highlighting to {html_path.name}")
        except Exception as e:
            print(f"  Error processing {html_path}: {e}", file=sys.stderr)

if __name__ == '__main__':
    main()
