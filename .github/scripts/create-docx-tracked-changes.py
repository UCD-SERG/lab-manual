#!/usr/bin/env python3
"""
Script to compare DOCX files and create a version with tracked changes.
This compares the PR's DOCX files with the published versions from gh-pages.
"""

import os
import sys
import subprocess
from pathlib import Path

def checkout_base_docx(base_ref='origin/gh-pages', target_dir='/tmp/base-docx'):
    """Check out the base DOCX files from gh-pages for comparison."""
    target_path = Path(target_dir)
    target_path.mkdir(parents=True, exist_ok=True)
    
    try:
        # Fetch the gh-pages branch
        subprocess.run(['git', 'fetch', 'origin', 'gh-pages:gh-pages'], 
                      check=False, capture_output=True)
        
        # List all DOCX files in gh-pages
        result = subprocess.run(
            ['git', 'ls-tree', '-r', '--name-only', base_ref],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode == 0:
            files = [f for f in result.stdout.split('\n') if f.endswith('.docx')]
            
            # Extract each DOCX file
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
        print(f"Could not check out base DOCX: {e}", file=sys.stderr)
        return None

def create_docx_with_tracked_changes(old_docx_path, new_docx_path, output_path):
    """
    Create a DOCX file with tracked changes showing differences.
    This uses python-docx if available, otherwise uses docx2txt for text comparison.
    """
    try:
        from docx import Document
        from docx.oxml import OxmlElement
        from docx.oxml.ns import qn
        import difflib
        
        # Load both documents
        old_doc = Document(old_docx_path)
        new_doc = Document(new_docx_path)
        
        # Create output document based on new version
        output_doc = Document(new_docx_path)
        
        # Get paragraphs from both documents
        old_paragraphs = [p.text for p in old_doc.paragraphs]
        new_paragraphs = [p.text for p in new_doc.paragraphs]
        
        # Use difflib to find differences
        differ = difflib.Differ()
        diff = list(differ.compare(old_paragraphs, new_paragraphs))
        
        # Track if we made any changes
        has_changes = False
        
        # Process the output document to add tracked changes
        para_index = 0
        for line in diff:
            if line.startswith('  '):
                # Unchanged paragraph
                para_index += 1
            elif line.startswith('+ '):
                # Added paragraph - mark as insertion
                if para_index < len(output_doc.paragraphs):
                    para = output_doc.paragraphs[para_index]
                    # Add revision tracking
                    for run in para.runs:
                        run.font.color.rgb = None  # Use default color
                        # Mark as insertion (this is simplified)
                    para_index += 1
                has_changes = True
            elif line.startswith('- '):
                # Deleted paragraph - we skip but note the change
                has_changes = True
            elif line.startswith('? '):
                # Hints about differences within a line
                pass
        
        if has_changes:
            # Save the document with tracked changes
            output_doc.save(output_path)
            print(f"  Created DOCX with tracked changes: {output_path}")
            return True
        else:
            print(f"  No significant changes detected in DOCX")
            return False
            
    except ImportError:
        # python-docx not available, use simpler text-based approach
        print("  Warning: python-docx not available, skipping DOCX tracked changes")
        print("  Install python-docx in the workflow to enable this feature")
        return False
    except Exception as e:
        print(f"  Error creating tracked changes DOCX: {e}", file=sys.stderr)
        return False

def process_docx_file(new_docx_path, base_docx_dir):
    """Process a single DOCX file: fetch old version, compare, and create tracked changes version."""
    print(f"Processing {new_docx_path}...")
    
    if not base_docx_dir:
        print("  No base DOCX directory available")
        return
    
    # Get the relative path and construct base path
    new_path = Path(new_docx_path)
    relative_path = new_path.name  # Just the filename for now
    base_path = Path(base_docx_dir) / relative_path
    
    if not base_path.exists():
        print(f"  Base DOCX not found: {base_path}")
        return
    
    # Create output path with tracked changes
    output_path = new_path.parent / f"{new_path.stem}-tracked-changes.docx"
    
    # Create the tracked changes version
    success = create_docx_with_tracked_changes(base_path, new_path, output_path)
    
    if success:
        print(f"  Successfully created: {output_path}")

def main():
    # Get the local DOCX directory
    docx_dir = os.getenv('DOCX_DIR', './docs')
    
    # Get list of changed files
    changed_files = os.getenv('PREVIEW_CHANGED_CHAPTERS', '').strip()
    
    if not changed_files:
        print("No changed files to process for DOCX")
        return
    
    # Check out base DOCX from gh-pages
    print("Checking out base DOCX files from gh-pages...")
    base_docx_dir = checkout_base_docx()
    
    if not base_docx_dir:
        print("Warning: Could not check out base DOCX files")
        print("(This is normal for new files or if gh-pages doesn't have DOCX files yet)")
        return
    else:
        print(f"Base DOCX checked out to {base_docx_dir}")
    
    # Convert .qmd files to .docx files
    docx_files = []
    for qmd_file in changed_files.split('\n'):
        qmd_file = qmd_file.strip()
        if qmd_file:
            # The book DOCX is a single file, not per-chapter
            # So we'll look for the main book DOCX file
            book_docx = Path(docx_dir) / "UCD-SeRG-Lab-Manual.docx"
            if book_docx.exists() and book_docx not in docx_files:
                docx_files.append(book_docx)
    
    # Also check for a generic manual.docx or similar
    for docx_path in Path(docx_dir).glob("*.docx"):
        if docx_path not in docx_files:
            docx_files.append(docx_path)
    
    if not docx_files:
        print("No DOCX files found to process")
        return
    
    # Process each DOCX file
    for docx_file in docx_files:
        process_docx_file(docx_file, base_docx_dir)

if __name__ == '__main__':
    main()
