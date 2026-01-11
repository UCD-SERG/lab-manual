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
    if content.startswith('---'):
        # Find the end of the front matter
        parts = content.split('---', 2)
        if len(parts) >= 3:
            # Already has front matter
            front_matter = parts[1]
            rest = parts[2]
            
            # Add our metadata if not already there
            if 'preview-changed:' not in front_matter:
                front_matter = front_matter.rstrip() + '\npreview-changed: true\n'
            
            new_content = f'---{front_matter}---{rest}'
        else:
            # Malformed, just prepend
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
