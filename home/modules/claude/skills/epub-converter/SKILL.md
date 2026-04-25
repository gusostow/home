---
name: epub-converter
description: Convert web pages, man pages, and markdown documents to Kindle-compatible EPUB files using pandoc
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - WebFetch
  - Write
---

# EPUB Converter Skill

Convert various content formats to Kindle-compatible EPUB files optimized for Amazon's email conversion service.

## What This Skill Does

This skill automates the process of creating properly formatted EPUB files that work reliably with Kindle's email conversion service. It handles:

- **Web pages**: Downloads and converts HTML articles
- **Man pages**: Converts Unix/Linux manual pages (bash, ls, grep, etc.)
- **Markdown files**: Converts local markdown documents
- **HTML files**: Converts local HTML files

All outputs are tested and validated for Kindle compatibility.

## Usage Examples

The skill can be invoked automatically by asking questions like:
- "Convert the bash man page to EPUB for my Kindle"
- "Turn this web page into a Kindle book: https://example.com/article"
- "Make an EPUB from /path/to/document.md"

Or invoke directly with: `/epub-converter <source>`

### Supported Source Types

1. **Web URLs**: `https://example.com/article.html`
2. **Man pages**: `man:bash` or `man:grep`
3. **Local files**: `/path/to/file.md` or `/path/to/file.html`

## How It Works

When you request an EPUB conversion, this skill will:

1. **Detect the source type** (URL, man page, or file)
2. **Extract content** in the appropriate format:
   - Web pages: Use `curl` to download HTML
   - Man pages: Use `man -Thtml` to generate clean HTML
   - Files: Read directly from filesystem
3. **Convert to EPUB** using pandoc with these Kindle-optimized settings:
   - EPUB3 format
   - Chapter splitting at heading level 2
   - Proper metadata (title, author)
   - Clean HTML structure
4. **Validate the output** using `unzip -t` to check for errors
5. **Save to current directory** with a descriptive filename

## Technical Details

### Pandoc Command Structure

```bash
pandoc <input-file> -o <output.epub> \
  --metadata title="Title Here" \
  --metadata author="Author Name" \
  --split-level=2
```

### For Man Pages

```bash
man -Thtml <command> > /tmp/content.html
pandoc /tmp/content.html -o output.epub \
  --metadata title="Command Reference Manual" \
  --metadata author="GNU Project" \
  --split-level=2
```

### For Web Pages

```bash
curl -s "<url>" -o /tmp/page.html
pandoc /tmp/page.html -o output.epub \
  --metadata title="Article Title" \
  --metadata author="Author" \
  --split-level=2
```

## Instructions for Claude

When a user requests EPUB conversion:

1. **Identify the source type** from the user's request
2. **Extract or download content**:
   - For URLs: Use `curl -s "<url>" -o /tmp/source.html`
   - For man pages: Use `man -Thtml <command> > /tmp/source.html`
   - For local files: Use the Read tool or copy to /tmp
3. **Determine appropriate metadata**:
   - Man pages: Title should be "<Command> Reference Manual", author "GNU Project" or "Free Software Foundation"
   - Web pages: Extract title from HTML or ask user, set author if known
   - Files: Ask user for title/author or infer from filename
4. **Run pandoc conversion**:
   ```bash
   # Save to ~/Downloads directory
   pandoc /tmp/source.html -o ~/Downloads/<descriptive-name>.epub \
     --metadata title="<title>" \
     --metadata author="<author>" \
     --split-level=2
   ```
5. **Validate the EPUB**:
   ```bash
   unzip -t ~/Downloads/<output.epub> | tail -2
   ```
   - Should see "No errors detected"
6. **Inform the user**:
   - Show output filename (in ~/Downloads) and size
   - Confirm it's ready for Kindle email conversion
   - Optionally show number of chapters created

## Common Issues and Solutions

### Issue: "Document is empty" error
**Solution**: Ensure input HTML has actual content, not just headers

### Issue: Pandoc warnings about deprecated options
**Solution**: Use `--split-level=2` instead of `--epub-chapter-level=2`

### Issue: EPUB fails Kindle conversion (E999 error)
**Solution**:
- Use pandoc (not Python ebooklib)
- Validate with `unzip -t output.epub`
- Ensure proper HTML structure in input

### Issue: Man page has formatting characters
**Solution**: Use `man -Thtml` instead of `man | col -b`

## File Naming Convention

Use descriptive names based on content:
- Man pages: `<command>_manual.epub` (e.g., `bash_manual.epub`)
- Web pages: `<article-slug>.epub` (e.g., `kerberos_dialogue.epub`)
- Files: `<original-name>.epub`

## Output Location

Save EPUBs to `~/Downloads` directory by default. Ensure the directory exists before saving.

## Dependencies

Required tools (should be available on most systems):
- `pandoc` - Document converter
- `curl` - Web page fetcher
- `man` - Manual page viewer
- `unzip` - EPUB validator

Check for pandoc availability before conversion:
```bash
command -v pandoc >/dev/null 2>&1 || echo "pandoc not found"
```

## Success Criteria

A successful conversion should:
1. Create a valid EPUB file (passes `unzip -t` check)
2. Include proper metadata (title, author)
3. Be under 50MB in size
4. Have chapters split logically at h2 headings
5. Work when emailed to Kindle address

## Examples of Successful Conversions

```bash
# Man page example:
man -Thtml bash > /tmp/bash.html
pandoc /tmp/bash.html -o ~/Downloads/bash_manual.epub \
  --metadata title="Bash Reference Manual" \
  --metadata author="Free Software Foundation" \
  --split-level=2

# Web page example:
curl -s "https://web.mit.edu/kerberos/dialogue.html" -o /tmp/kerberos.html
pandoc /tmp/kerberos.html -o ~/Downloads/kerberos_dialogue.epub \
  --metadata title="Designing an Authentication System" \
  --metadata author="Bill Bryant" \
  --split-level=2
```

Both examples have been tested and confirmed to work with Kindle email conversion.
