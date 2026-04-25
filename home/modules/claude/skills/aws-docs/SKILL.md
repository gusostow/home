---
name: aws-docs
description: Convert AWS documentation guides to comprehensive Kindle-compatible EPUB files with multi-page discovery and embedded images
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# AWS Documentation to EPUB Converter

Convert entire AWS documentation guides to comprehensive, offline-readable EPUB files optimized for Kindle and e-readers.

## What This Skill Does

This skill converts complete AWS documentation guides (not just single pages) into professional EPUB books with:

- **Multi-page discovery**: Automatically finds all pages in a guide via table of contents or intelligent crawling
- **Image embedding**: Downloads and embeds all AWS diagrams, architecture charts, and screenshots
- **AWS-specific parsing**: Understands AWS documentation structure and removes navigation chrome
- **Complete books**: Creates guides typically 50-200+ pages with proper chapter structure
- **Offline reading**: Fully self-contained EPUBs work without internet connection

## When to Use

Use this skill for AWS documentation URLs from `docs.aws.amazon.com`, such as:
- User Guides (VPC, EC2, Lambda, etc.)
- Developer Guides
- Administration Guides
- Transit Gateway documentation
- Service-specific documentation

**Not for**: Single web pages (use epub-converter instead), API references, or non-AWS documentation.

## Usage Examples

The skill can be invoked automatically by asking:
- "Convert the AWS Lambda Developer Guide to EPUB"
- "Make an EPUB of the VPC User Guide"
- "Turn the Transit Gateway documentation into a Kindle book"

Or provide a URL directly:
- "Convert https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html to EPUB"

## How It Works

When you request an AWS documentation conversion, this skill will:

1. **Validate URL**: Ensure it's from docs.aws.amazon.com
2. **Discover pages**: Extract table of contents or crawl to find all related pages
3. **Download content**: Fetch each page with respectful rate limiting (0.5s between requests)
4. **Extract content**: Parse AWS-specific HTML structure and remove UI chrome
5. **Download images**: Fetch and embed all images (diagrams, screenshots, charts)
6. **Build EPUB**: Create multi-chapter book with:
   - Proper metadata (title, author, identifier)
   - Custom CSS for code blocks, tables, and notes
   - Table of contents with chapter navigation
   - Navigation files for e-reader compatibility
7. **Save to ~/Downloads**: Output ready for Kindle email conversion

## Instructions for Claude

When user requests AWS documentation conversion:

1. **Verify URL pattern**: Must match `docs.aws.amazon.com`
2. **Run converter**:
   ```bash
   cd ~/.claude/skills/aws-docs
   uv run --with requests --with beautifulsoup4 --with ebooklib --with lxml \
       -- python3 aws_docs_to_epub.py "<url>"
   ```
3. **Monitor progress**: Script will output page-by-page progress
4. **Report results**: Show output file path, size, and page count

Example execution:
```bash
cd ~/.claude/skills/aws-docs
uv run --with requests --with beautifulsoup4 --with ebooklib --with lxml \
    -- python3 aws_docs_to_epub.py \
    "https://docs.aws.amazon.com/lambda/latest/dg/welcome.html"
```

Output will be saved to ~/Downloads/ automatically.

## Expected Output

Typical AWS documentation EPUBs:
- **Size**: 200-800 KB (depending on images and page count)
- **Pages**: 50-200+ individual pages
- **Time**: 2-5 minutes (depending on guide size)
- **Format**: EPUB3 compatible with Kindle conversion

Example outputs:
- `~/Downloads/AWS_Lambda_Developer_Guide.epub` - 450 KB
- `~/Downloads/Amazon_VPC_User_Guide.epub` - 340 KB
- `~/Downloads/AWS_Transit_Gateway.epub` - 213 KB

## Dependencies

Uses `uv run --with` for ad-hoc Python dependencies (no global installation required):

- **requests**: HTTP fetching with browser-like headers
- **beautifulsoup4**: HTML parsing and DOM manipulation
- **ebooklib**: EPUB file generation
- **lxml**: XML processing backend for BeautifulSoup

Dependencies are automatically installed per-execution by uv.

## Success Criteria

A successful conversion produces:
1. Valid EPUB file in ~/Downloads/
2. Multiple chapters (10+ pages typical)
3. Embedded images visible in e-reader
4. Functional table of contents
5. File size appropriate for content (not bloated)
6. Passes EPUB validation
7. Works with Kindle email conversion

## Common Issues and Solutions

### Issue: "No pages found"
**Cause**: Navigation structure not recognized or URL is API reference
**Solution**: Try a different starting page from the guide, or verify it's user/developer documentation

### Issue: Conversion takes too long
**Cause**: Large guide with 200+ pages
**Solution**: Normal for comprehensive guides. Wait 3-5 minutes. Script includes progress output.

### Issue: Images missing in EPUB
**Cause**: Image download failures (network issues, broken links)
**Solution**: Script logs download errors but continues. Most images should embed successfully.

### Issue: EPUB validation errors
**Cause**: Malformed HTML in source documentation
**Solution**: Script handles most cases. If persistent, report specific AWS doc URL.

## Technical Details

### Multi-Page Discovery Strategy

1. **Primary: TOC Extraction**
   - Targets AWS navigation selectors: `.awsdocs-nav-tree`, `#left-column`, etc.
   - Extracts all links from sidebar navigation
   - Filters to same guide directory (same URL path)

2. **Fallback: Intelligent Crawling**
   - Breadth-first search from starting page
   - Follows links within same documentation guide
   - Maximum 50 pages to prevent runaway crawling
   - Maintains visited set to avoid cycles

### Content Extraction

Removes AWS UI elements:
- `.awsdocs-nav` - Navigation sidebar
- `.feedback` - Feedback widgets
- `.breadcrumb` - Breadcrumb navigation
- `.doc-cookie-banner` - Cookie consent
- `.awsdocs-filter` - Filter controls

Preserves AWS content elements:
- Code blocks with syntax highlighting
- Tables and lists
- Note/warning callouts
- Diagrams and images

### Image Handling

- **Caching**: Downloads each unique image only once
- **Format detection**: Supports JPEG, PNG, GIF, SVG, WebP
- **Filename generation**: MD5 hash of URL for uniqueness
- **Embedding**: Creates `EpubItem` objects with proper MIME types
- **Path rewriting**: Updates `<img src>` to reference embedded images

### EPUB Structure

- **Metadata**: Title (auto-extracted), author (Amazon Web Services), identifier
- **CSS**: 100+ lines of styling for typography, code blocks, tables, notes
- **Chapters**: One XHTML file per documentation page
- **Navigation**: NCX (EPUB2) and Nav (EPUB3) files for compatibility
- **Spine**: Ordered chapter list for sequential reading

## Examples of Successful Conversions

```bash
# VPC User Guide (340 KB, 78 pages)
cd ~/.claude/skills/aws-docs
uv run --with requests --with beautifulsoup4 --with ebooklib --with lxml \
    -- python3 aws_docs_to_epub.py \
    "https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html"

# Lambda Developer Guide (450 KB, 143 pages)
cd ~/.claude/skills/aws-docs
uv run --with requests --with beautifulsoup4 --with ebooklib --with lxml \
    -- python3 aws_docs_to_epub.py \
    "https://docs.aws.amazon.com/lambda/latest/dg/welcome.html"

# Transit Gateway Guide (213 KB, 45 pages)
cd ~/.claude/skills/aws-docs
uv run --with requests --with beautifulsoup4 --with ebooklib --with lxml \
    -- python3 aws_docs_to_epub.py \
    "https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html"
```

All examples have been tested and confirmed to work with Kindle email conversion.

## Comparison to epub-converter Skill

| Feature | epub-converter | aws-docs |
|---------|----------------|----------|
| **Input** | Single page/file | Multi-page guide |
| **Discovery** | None | Auto TOC/crawling |
| **Images** | External refs | Embedded |
| **Time** | Seconds | 2-5 minutes |
| **Size** | 10-100 KB | 200-800 KB |
| **Pages** | 1 | 50-200+ |
| **AWS parsing** | No | Yes |
| **Use case** | Quick reference | Complete guides |

Use `epub-converter` for single pages or man pages. Use `aws-docs` for comprehensive AWS documentation guides.
