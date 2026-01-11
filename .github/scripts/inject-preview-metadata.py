#!/usr/bin/env python3
"""
Script to inject preview metadata into changed .qmd files
"""

import os
import sys
import re

def inject_preview_metadata(filepath):
    """Add preview-changed: true to the YAML front matter of a file"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if file has YAML front matter
    # Valid YAML front matter must start with --- at the very beginning
    if content.startswith('---\n'):
        # Find the closing --- (must be on its own line)
        # Search for the second occurrence of \n---\n
        match = re.search(r'\n---\n', content[4:])  # Skip first ---\n
        
        if match:
            # Found valid front matter
            end_pos = match.start() + 4  # Position relative to start of content
            front_matter = content[4:end_pos]  # Extract front matter (without delimiters)
            rest = content[end_pos + 4:]  # Rest of content after closing ---
            
            # Add our metadata if not already there
            if 'preview-changed:' not in front_matter:
                front_matter = front_matter.rstrip() + '\npreview-changed: true\n'
            
            new_content = f'---\n{front_matter}---{rest}'
        else:
            # Has opening --- but no closing ---, treat as no front matter
            new_content = f'---\npreview-changed: true\n---\n{content}'
    else:
        # No front matter, add it
        new_content = f'---\npreview-changed: true\n---\n{content}'
    
    # Write back
    with open(filepath, 'w') as f:
        f.write(new_content)
    
    print(f"Injected preview metadata into {filepath}")

def main():
    # Get changed files from environment
    changed_files = os.getenv('PREVIEW_CHANGED_FILES', '').strip()
    
    if not changed_files:
        print("No changed files to process")
        return
    
    # Process each file
    for filepath in changed_files.split('\n'):
        filepath = filepath.strip()
        if filepath and os.path.exists(filepath):
            inject_preview_metadata(filepath)
        elif filepath:
            print(f"Warning: File not found: {filepath}", file=sys.stderr)

if __name__ == '__main__':
    main()
