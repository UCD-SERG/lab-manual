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
        
        # Create notice HTML
        notice = f'''
<div class="preview-content-changed-notice" style="background-color: #e7f3ff; border-left: 4px solid #2196F3; padding: 12px 16px; margin-bottom: 20px; border-radius: 4px; font-size: 14px;">
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
                
                # Add change notice
                new_html = self.inject_change_notice(new_html, num_changes, similarity)
                
                # Write back
                with open(local_filepath, 'w', encoding='utf-8') as f:
                    f.write(new_html)
                
                print(f"  Added content change notice to {local_filepath}")
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
                    
                    subprocess.run(
                        ['git', 'show', f'{base_ref}:{file}'],
                        stdout=open(output_path, 'wb'),
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
    for qmd_file in changed_files.split('\n'):
        qmd_file = qmd_file.strip()
        if qmd_file:
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

if __name__ == '__main__':
    main()
