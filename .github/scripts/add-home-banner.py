#!/usr/bin/env python3
"""
Script to add a banner to the home page linking to changed chapters.
"""

import os
import sys
import json
import re
from pathlib import Path

def add_home_page_banner(index_html_path, changed_chapters):
    """Add a banner to the home page with links to changed chapters."""
    if not changed_chapters:
        return
    
    with open(index_html_path, 'r', encoding='utf-8') as f:
        html = f.read()
    
    # Create the banner HTML
    chapter_links = []
    for chapter_id in changed_chapters:
        # Convert chapter ID to readable title
        # E.g., "01-culture-and-conduct" -> "Culture and conduct"
        # First try to extract the title from the actual HTML file
        chapter_html = index_html_path.parent / f"{chapter_id}.html"
        title = chapter_id
        if chapter_html.exists():
            with open(chapter_html, 'r', encoding='utf-8') as cf:
                content = cf.read()
                # Look for the h1 heading
                h1_match = re.search(r'<h1[^>]*>.*?<span class="chapter-number">(\d+)</span>\s*(.*?)</h1>', content, re.DOTALL)
                if h1_match:
                    title = h1_match.group(2).strip()
                    chapter_num = h1_match.group(1)
                    title = f"{chapter_num}. {title}"
        
        chapter_links.append(f'<a href="{chapter_id}.html">{title}</a>')
    
    links_html = ', '.join(chapter_links)
    
    banner = f'''
<div class="preview-home-changes-banner">
    <p style="margin: 0;">
        <strong>📋 Changes in this PR:</strong> The following chapters have been modified: {links_html}
    </p>
</div>
'''
    
    # Find insertion point (after <main> tag)
    main_match = re.search(r'(<main[^>]*>)', html)
    if main_match:
        insertion_point = main_match.end()
        html = html[:insertion_point] + banner + html[insertion_point:]
        
        # Write back
        with open(index_html_path, 'w', encoding='utf-8') as f:
            f.write(html)
        
        print(f"Added home page banner with {len(changed_chapters)} changed chapter(s)")
    else:
        print("Could not find insertion point for home page banner", file=sys.stderr)

def main():
    # Get the HTML directory
    html_dir = Path(os.getenv('HTML_DIR', './docs'))
    index_html = html_dir / 'index.html'
    
    if not index_html.exists():
        print("index.html does not exist")
        return
    
    # Read changed chapters from JSON file
    changed_chapters_file = html_dir / 'changed-chapters.json'
    if not changed_chapters_file.exists():
        print("No changed chapters file found")
        return
    
    with open(changed_chapters_file, 'r') as f:
        data = json.load(f)
        changed_chapters = data.get('changed_chapters', [])
    
    if changed_chapters:
        add_home_page_banner(index_html, changed_chapters)
    else:
        print("No changed chapters to display on home page")

if __name__ == '__main__':
    main()
