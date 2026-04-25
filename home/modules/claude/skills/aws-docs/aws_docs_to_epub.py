#!/usr/bin/env python3
"""
AWS Documentation to EPUB Converter
Converts any AWS documentation guide to an EPUB file.

Usage:
    python aws_docs_to_epub.py <url>

Example:
    python aws_docs_to_epub.py https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
    python aws_docs_to_epub.py https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html
"""

import argparse
import os
import requests
from bs4 import BeautifulSoup
from ebooklib import epub
from urllib.parse import urljoin, urlparse, urlunparse
import re
import time
import sys
import hashlib
from io import BytesIO

# Headers to mimic a browser request
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
}


def parse_url(url):
    """Parse the URL to extract base URL and start page."""
    parsed = urlparse(url)
    path_parts = parsed.path.rsplit('/', 1)

    if len(path_parts) == 2:
        base_path = path_parts[0] + '/'
        start_page = path_parts[1]
    else:
        base_path = parsed.path
        start_page = ''

    base_url = urlunparse((parsed.scheme, parsed.netloc, base_path, '', '', ''))
    return base_url, start_page


def fetch_page(url):
    """Fetch a page and return BeautifulSoup object."""
    print(f"  Fetching: {url}")
    try:
        response = requests.get(url, headers=HEADERS, timeout=30)
        response.raise_for_status()
        return BeautifulSoup(response.text, 'lxml')
    except Exception as e:
        print(f"  Error fetching {url}: {e}")
        return None


def extract_title(soup):
    """Extract the documentation title from the page."""
    # Try various title selectors
    title_selectors = [
        'h1',
        '.title',
        '#main-content h1',
        'title',
    ]

    for selector in title_selectors:
        elem = soup.select_one(selector)
        if elem:
            title = elem.get_text(strip=True)
            # Clean up title
            title = re.sub(r'\s*-\s*Amazon Web Services.*$', '', title)
            title = re.sub(r'\s*\|.*$', '', title)
            if title and len(title) > 3:
                return title

    return "AWS Documentation"


def extract_guide_title(soup, base_url):
    """Extract the guide title (e.g., 'Amazon VPC User Guide')."""
    # Try to extract from the page title first
    title_elem = soup.select_one('title')
    if title_elem:
        title = title_elem.get_text(strip=True)
        # Pattern like "What is X? - Amazon VPC User Guide"
        if ' - ' in title:
            parts = title.split(' - ')
            for part in parts[1:]:  # Skip the first part (page title)
                part = part.strip()
                # Prefer parts with "Guide" in them
                if 'guide' in part.lower():
                    return part
            # Second pass: look for service names in later parts
            for part in parts[1:]:
                part = part.strip()
                # Check for service names (prefer longer/more specific names)
                if any(x in part.lower() for x in ['transit gateway', 'cloudformation', 'lambda']):
                    return part

            # Check the first part for specific service names like "Transit Gateway"
            first_part = parts[0].strip()
            if 'transit gateway' in first_part.lower():
                return 'AWS Transit Gateway Guide'
            if 'lambda' in first_part.lower():
                return 'AWS Lambda Guide'

            for part in parts[1:]:
                part = part.strip()
                if any(x in part.lower() for x in ['aws', 'amazon', 'ec2', 'vpc', 's3']):
                    return part

    # Look for breadcrumb or guide title
    breadcrumb_selectors = [
        '.breadcrumb a',
        '#breadcrumb a',
        'nav a',
    ]

    for selector in breadcrumb_selectors:
        elems = soup.select(selector)
        for elem in elems:
            text = elem.get_text(strip=True)
            # Look for "User Guide" or "Developer Guide" etc.
            if 'guide' in text.lower() and len(text) > 5:
                return text

    # Fallback: derive from URL
    path = urlparse(base_url).path
    # Extract meaningful parts from path like /vpc/latest/userguide/ -> VPC User Guide
    parts = [p for p in path.split('/') if p and p not in ['latest', 'docs.aws.amazon.com', 'docs']]
    if parts:
        # Map common path names to proper titles
        name_map = {
            'userguide': 'User Guide',
            'dg': 'Developer Guide',
            'ag': 'Admin Guide',
            'tgw': 'Transit Gateway',
            'vpc': 'VPC',
            'ec2': 'EC2',
            'lambda': 'Lambda',
            's3': 'S3',
            'iam': 'IAM',
            'cloudformation': 'CloudFormation',
        }

        title_parts = []
        for p in parts:
            if p in name_map:
                title_parts.append(name_map[p])
            else:
                title_parts.append(p.replace('-', ' ').replace('_', ' ').title())

        return f"AWS {' '.join(title_parts)}"

    return "AWS Documentation"


def get_toc_links(soup, base_url):
    """Extract table of contents links from the navigation sidebar."""
    toc_links = []
    seen_urls = set()

    # Parse base URL
    base_parsed = urlparse(base_url)
    base_path = base_parsed.path.rstrip('/')

    # AWS docs use various navigation structures - try to find the TOC
    nav_selectors = [
        '#left-column',
        '.awsdocs-nav-tree',
        '[data-testid="nav-tree"]',
        '.nav-tree',
        '#sidebar',
        'nav',
    ]

    nav = None
    for selector in nav_selectors:
        nav = soup.select_one(selector)
        if nav:
            break

    if nav:
        # Find all links in the navigation
        for link in nav.find_all('a', href=True):
            href = link.get('href', '')
            title = link.get_text(strip=True)

            # Skip anchors and empty titles
            if not href or href.startswith('#'):
                continue
            if not title or len(title) < 2:
                continue

            # Build full URL
            if not href.startswith('http'):
                full_url = urljoin(base_url, href)
            else:
                full_url = href

            # Parse link URL
            link_parsed = urlparse(full_url)

            # Must be on docs.aws.amazon.com
            if link_parsed.netloc and link_parsed.netloc != 'docs.aws.amazon.com':
                continue

            # Must be in the same guide directory
            if not link_parsed.path.startswith(base_path):
                continue

            # Remove anchor part for deduplication
            clean_url = full_url.split('#')[0]
            if clean_url.endswith('.html') and clean_url not in seen_urls:
                seen_urls.add(clean_url)
                toc_links.append((title, clean_url))

    return toc_links


def crawl_for_links(soup, base_url, visited=None):
    """Crawl the page for documentation links when navigation is not found."""
    if visited is None:
        visited = set()

    links = []

    # Parse base URL to get the guide path
    base_parsed = urlparse(base_url)
    base_path = base_parsed.path.rstrip('/')

    # Find all internal links on the page
    for link in soup.find_all('a', href=True):
        href = link.get('href', '')
        title = link.get_text(strip=True)

        # Skip anchors, empty titles
        if not href or href.startswith('#'):
            continue
        if not title or len(title) < 3:
            continue

        # Build full URL
        if not href.startswith('http'):
            full_url = urljoin(base_url, href)
        else:
            full_url = href

        # Parse the link URL
        link_parsed = urlparse(full_url)

        # Must be on docs.aws.amazon.com
        if link_parsed.netloc and link_parsed.netloc != 'docs.aws.amazon.com':
            continue

        # Must be in the same guide directory
        link_path = link_parsed.path
        if not link_path.startswith(base_path):
            continue

        # Must be an HTML file
        clean_url = full_url.split('#')[0]
        if not clean_url.endswith('.html'):
            continue

        if clean_url not in visited:
            visited.add(clean_url)
            links.append((title, clean_url))

    return links


def download_image(url, image_cache):
    """Download an image and return its content and content type."""
    # check cache first
    if url in image_cache:
        return image_cache[url]

    try:
        print(f"    Downloading image: {url}")
        response = requests.get(url, headers=HEADERS, timeout=30)
        response.raise_for_status()

        # get content type
        content_type = response.headers.get('content-type', 'image/jpeg')

        # store in cache
        image_cache[url] = (response.content, content_type)
        return response.content, content_type
    except Exception as e:
        print(f"    Error downloading image {url}: {e}")
        return None, None


def extract_content(soup, title, base_url, book=None, image_cache=None):
    """Extract the main content from a documentation page."""
    if image_cache is None:
        image_cache = {}

    # Try various content selectors used by AWS docs
    content_selectors = [
        '#main-content',
        '#main-col-body',
        '.awsdocs-main-content',
        '[data-testid="main-content"]',
        'main',
        '#content',
        '.content',
        'article',
    ]

    content = None
    for selector in content_selectors:
        content = soup.select_one(selector)
        if content:
            break

    if not content:
        # Fallback: get the body
        content = soup.find('body')

    if content:
        # Remove navigation, headers, footers, scripts
        for tag in content.find_all(['script', 'style', 'nav', 'header', 'footer', 'aside']):
            tag.decompose()

        # Remove AWS-specific elements we don't need
        for selector in ['.awsdocs-nav', '.feedback', '.breadcrumb', '#left-column', '.sidebar',
                         '.doc-cookie-banner', '.awsdocs-filter', '.awsdocs-page-header']:
            for elem in content.select(selector):
                elem.decompose()

        # Convert relative links to absolute
        for a in content.find_all('a', href=True):
            href = a.get('href', '')
            if href and not href.startswith('http') and not href.startswith('#'):
                a['href'] = urljoin(base_url, href)

        # Download and embed images
        if book is not None:
            for img in content.find_all('img', src=True):
                src = img.get('src', '')
                if not src:
                    continue

                # convert relative URLs to absolute
                if not src.startswith('http'):
                    src = urljoin(base_url, src)

                # download the image
                image_data, content_type = download_image(src, image_cache)
                if image_data:
                    # create a unique filename using hash of URL
                    img_hash = hashlib.md5(src.encode()).hexdigest()

                    # determine file extension from content type
                    ext_map = {
                        'image/jpeg': 'jpg',
                        'image/jpg': 'jpg',
                        'image/png': 'png',
                        'image/gif': 'gif',
                        'image/svg+xml': 'svg',
                        'image/webp': 'webp',
                    }
                    ext = ext_map.get(content_type, 'jpg')
                    img_filename = f'images/{img_hash}.{ext}'

                    # create EPUB image item
                    epub_image = epub.EpubItem(
                        uid=f'img_{img_hash}',
                        file_name=img_filename,
                        media_type=content_type,
                        content=image_data
                    )

                    # add to book
                    book.add_item(epub_image)

                    # update img src to point to embedded image
                    img['src'] = f'../{img_filename}'
                else:
                    # if download failed, keep the absolute URL
                    img['src'] = src

        html_content = str(content)
        # Ensure we have actual content
        if html_content and len(html_content.strip()) > 50:
            return html_content

    # Return a minimal valid content with the title
    return f"<div><h1>{title}</h1><p>See the online documentation for this section.</p></div>"


def discover_pages(start_url, base_url):
    """Discover all pages in the documentation guide."""
    pages = []
    visited = set()

    print("\nDiscovering documentation pages...")

    # First, fetch the start page and try to get TOC
    soup = fetch_page(start_url)
    if not soup:
        print("Failed to fetch the starting page!")
        return pages

    # Try to get TOC links from navigation
    toc_links = get_toc_links(soup, base_url)

    if toc_links:
        print(f"  Found {len(toc_links)} pages in navigation")
        for title, url in toc_links:
            clean_url = url.split('#')[0]
            if clean_url not in visited:
                visited.add(clean_url)
                pages.append((title, clean_url))
    else:
        print("  Navigation not found, crawling for links...")
        # Crawl the start page and discovered pages
        start_title = extract_title(soup)
        clean_start = start_url.split('#')[0]
        visited.add(clean_start)
        pages.append((start_title, clean_start))

        # Get links from start page
        found_links = crawl_for_links(soup, base_url, visited)
        pages.extend(found_links)

        # Crawl discovered pages to find more links (breadth-first)
        pages_to_crawl = list(found_links)
        crawled_count = 0
        max_crawl = 50  # Limit to prevent infinite crawling

        while pages_to_crawl and crawled_count < max_crawl:
            _, url = pages_to_crawl.pop(0)
            crawled_count += 1

            sub_soup = fetch_page(url)
            if sub_soup:
                more_links = crawl_for_links(sub_soup, base_url, visited)
                pages.extend(more_links)
                pages_to_crawl.extend(more_links)
            time.sleep(0.3)

        print(f"  Crawled {crawled_count} pages, found {len(pages)} total")

    # Deduplicate while preserving order
    seen = set()
    unique_pages = []
    for title, url in pages:
        clean_url = url.split('#')[0]
        if clean_url not in seen:
            seen.add(clean_url)
            unique_pages.append((title, clean_url))

    return unique_pages


def create_epub(pages, guide_title, base_url):
    """Create an EPUB book from the collected pages."""
    book = epub.EpubBook()

    # Generate identifier from guide title
    identifier = re.sub(r'[^\w]+', '-', guide_title.lower()).strip('-')

    # Set metadata
    book.set_identifier(f'{identifier}-2026')
    book.set_title(guide_title)
    book.set_language('en')
    book.add_author('Amazon Web Services')

    # Add CSS for better formatting
    css_content = '''
    body {
        font-family: Georgia, serif;
        line-height: 1.6;
        margin: 1em;
    }
    h1, h2, h3, h4, h5, h6 {
        font-family: Arial, sans-serif;
        margin-top: 1.5em;
        margin-bottom: 0.5em;
    }
    h1 { font-size: 1.8em; }
    h2 { font-size: 1.5em; }
    h3 { font-size: 1.3em; }
    pre, code {
        font-family: Consolas, Monaco, monospace;
        background-color: #f4f4f4;
        padding: 0.2em 0.4em;
        border-radius: 3px;
        font-size: 0.9em;
    }
    pre {
        padding: 1em;
        overflow-x: auto;
        white-space: pre-wrap;
    }
    table {
        border-collapse: collapse;
        width: 100%;
        margin: 1em 0;
    }
    th, td {
        border: 1px solid #ddd;
        padding: 0.5em;
        text-align: left;
    }
    th {
        background-color: #f2f2f2;
    }
    img {
        max-width: 100%;
        height: auto;
        display: block;
        margin: 1em 0;
    }
    .note, .important, .warning {
        padding: 1em;
        margin: 1em 0;
        border-left: 4px solid #0073bb;
        background-color: #f0f8ff;
    }
    .warning {
        border-left-color: #d13212;
        background-color: #fff5f5;
    }
    a {
        color: #0073bb;
    }
    '''

    css = epub.EpubItem(
        uid="style",
        file_name="style/main.css",
        media_type="text/css",
        content=css_content
    )
    book.add_item(css)

    chapters = []
    toc = []

    # image cache to avoid downloading the same image multiple times
    image_cache = {}

    print("\nCreating EPUB chapters...")

    for i, (title, url) in enumerate(pages):
        print(f"  Processing ({i+1}/{len(pages)}): {title}")

        soup = fetch_page(url)
        if not soup:
            continue

        content = extract_content(soup, title, base_url, book, image_cache)

        # Create a valid filename
        filename = re.sub(r'[^\w\-]', '_', title.lower())[:50] + '.xhtml'
        # Ensure unique filename
        if filename in [c.file_name for c in chapters]:
            filename = f"{i:03d}_{filename}"

        # Create chapter
        chapter = epub.EpubHtml(
            title=title,
            file_name=filename,
            lang='en'
        )

        # Clean the content for XHTML compatibility
        clean_content = content.replace('&nbsp;', '&#160;')

        chapter.set_content(f'''<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>{title}</title>
</head>
<body>
<h1>{title}</h1>
{clean_content}
</body>
</html>''')
        chapter.add_item(css)

        book.add_item(chapter)
        chapters.append(chapter)
        toc.append(epub.Link(filename, title, filename.replace('.xhtml', '')))

        # Be nice to AWS servers
        time.sleep(0.5)

    # Set table of contents
    book.toc = toc

    # Add navigation files
    book.add_item(epub.EpubNcx())
    book.add_item(epub.EpubNav())

    # Set spine
    book.spine = ['nav'] + chapters

    # generate output filename in ~/Downloads
    filename = re.sub(r'[^\w\-]+', '_', guide_title) + '.epub'
    output_file = os.path.join(os.path.expanduser('~/Downloads'), filename)

    print(f"\nWriting EPUB to {output_file}...")
    epub.write_epub(output_file, book)
    print(f"Done! Created {output_file}")

    return output_file


def main():
    parser = argparse.ArgumentParser(
        description='Convert AWS documentation to EPUB format',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
    %(prog)s https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
    %(prog)s https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html
    %(prog)s https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
        '''
    )
    parser.add_argument('url', help='URL of the AWS documentation landing page')
    parser.add_argument('--title', '-t', help='Override the guide title')

    args = parser.parse_args()

    print("=" * 60)
    print("AWS Documentation to EPUB Converter")
    print("=" * 60)

    # Parse the URL
    base_url, start_page = parse_url(args.url)
    print(f"\nBase URL: {base_url}")
    print(f"Start page: {start_page}")

    # Fetch start page to get guide title
    print("\nFetching documentation...")
    soup = fetch_page(args.url)
    if not soup:
        print("Failed to fetch the starting page!")
        sys.exit(1)

    # Get guide title
    if args.title:
        guide_title = args.title
    else:
        guide_title = extract_guide_title(soup, base_url)
    print(f"Guide title: {guide_title}")

    # Discover all pages
    pages = discover_pages(args.url, base_url)

    if not pages:
        print("No pages found. Exiting.")
        sys.exit(1)

    print(f"\nFound {len(pages)} pages to convert:")
    for title, url in pages:
        print(f"  - {title}")

    # Create EPUB
    print("\nCreating EPUB...")
    output_file = create_epub(pages, guide_title, base_url)

    print("\n" + "=" * 60)
    print(f"SUCCESS! EPUB created: {output_file}")
    print("=" * 60)
    print("\nTo send to Kindle:")
    print("1. Email the EPUB file to your Kindle email address")
    print("2. Or use Amazon's Send to Kindle app/website")
    print("   https://www.amazon.com/sendtokindle")


if __name__ == "__main__":
    main()
