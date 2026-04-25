#!/bin/bash
# convert content to Kindle-compatible EPUB using pandoc
set -euo pipefail

# usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <source> <output>

Convert content to Kindle-compatible EPUB format.

Arguments:
  source    Source file (HTML, markdown, or man page reference like 'man:bash')
  output    Output EPUB filename

Options:
  -t, --title TITLE      Set document title
  -a, --author AUTHOR    Set document author
  -h, --help            Show this help message

Examples:
  $0 -t "Bash Manual" -a "GNU Project" man:bash bash_manual.epub
  $0 -t "Article" page.html article.epub
EOF
    exit 1
}

# defaults
TITLE=""
AUTHOR=""
SOURCE=""
OUTPUT=""

# parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--title)
            TITLE="$2"
            shift 2
            ;;
        -a|--author)
            AUTHOR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [[ -z "$SOURCE" ]]; then
                SOURCE="$1"
            elif [[ -z "$OUTPUT" ]]; then
                OUTPUT="$1"
            else
                echo "Error: Too many arguments" >&2
                usage
            fi
            shift
            ;;
    esac
done

# validate required arguments
if [[ -z "$SOURCE" ]] || [[ -z "$OUTPUT" ]]; then
    echo "Error: source and output are required" >&2
    usage
fi

# check for pandoc
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc not installed" >&2
    echo "Install with: nix-env -iA nixpkgs.pandoc" >&2
    exit 1
fi

# prepare temporary file for processing
TMP_HTML=$(mktemp /tmp/epub-converter-XXXXXX.html)
trap "rm -f $TMP_HTML" EXIT

# handle different source types
if [[ "$SOURCE" =~ ^man: ]]; then
    # man page reference like "man:bash"
    COMMAND="${SOURCE#man:}"
    echo "Converting man page: $COMMAND" >&2

    if ! man -Thtml "$COMMAND" > "$TMP_HTML" 2>/dev/null; then
        echo "Error: man page '$COMMAND' not found" >&2
        exit 1
    fi

    # set defaults if not provided
    if [[ -z "$TITLE" ]]; then
        TITLE="$(echo "${COMMAND:0:1}" | tr '[:lower:]' '[:upper:]')$(echo "${COMMAND:1}") Reference Manual"
    fi
    [[ -z "$AUTHOR" ]] && AUTHOR="GNU Project"

elif [[ "$SOURCE" =~ ^https?:// ]]; then
    # web URL
    echo "Downloading: $SOURCE" >&2

    if ! curl -sf "$SOURCE" -o "$TMP_HTML"; then
        echo "Error: failed to download $SOURCE" >&2
        exit 1
    fi

    [[ -z "$TITLE" ]] && TITLE="Web Article"
    [[ -z "$AUTHOR" ]] && AUTHOR="Unknown"

elif [[ -f "$SOURCE" ]]; then
    # local file
    echo "Converting file: $SOURCE" >&2
    cp "$SOURCE" "$TMP_HTML"

    # infer title from filename if not provided
    if [[ -z "$TITLE" ]]; then
        TITLE=$(basename "$SOURCE" | sed 's/\.[^.]*$//' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    fi
    [[ -z "$AUTHOR" ]] && AUTHOR="Unknown"

else
    echo "Error: source '$SOURCE' not found or invalid" >&2
    exit 1
fi

# convert to EPUB using pandoc
echo "Converting to EPUB..." >&2

pandoc "$TMP_HTML" -o "$OUTPUT" \
    --metadata title="$TITLE" \
    --metadata author="$AUTHOR" \
    --split-level=2

# validate the EPUB
if unzip -t "$OUTPUT" >/dev/null 2>&1; then
    echo "✓ EPUB created successfully: $OUTPUT" >&2
    ls -lh "$OUTPUT" >&2
else
    echo "✗ Error: EPUB validation failed" >&2
    exit 1
fi
