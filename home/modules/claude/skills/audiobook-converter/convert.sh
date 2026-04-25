#!/bin/bash

# convert a single audiobook directory to M4A with chapters for iPhone Books app
# usage: convert_single_audiobook.sh <book_directory> [output_directory] [artist_name]

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <book_directory> [output_directory] [artist_name]"
    echo ""
    echo "  book_directory:   Directory containing MP3 files"
    echo "  output_directory: Where to save the M4A file (default: same as book_directory)"
    echo "  artist_name:      Author name (default: Unknown Artist)"
    exit 1
fi

BOOK_DIR="$1"
OUTPUT_DIR="${2:-$BOOK_DIR}"
ARTIST="${3:-Unknown Artist}"

if [ ! -d "$BOOK_DIR" ]; then
    echo "Error: Directory '$BOOK_DIR' does not exist"
    exit 1
fi

# create output directory if needed
mkdir -p "$OUTPUT_DIR"

# get book name from directory
BOOK_NAME=$(basename "$BOOK_DIR")

echo "Converting: $BOOK_NAME"
echo "Artist: $ARTIST"

# find all mp3 files (not .part files) and sort them
mp3_files=()
while IFS= read -r -d '' file; do
    mp3_files+=("$file")
done < <(find "$BOOK_DIR" -maxdepth 1 -name "*.mp3" -not -name "*.part" -type f -print0 | sort -z)

if [ ${#mp3_files[@]} -eq 0 ]; then
    echo "Error: No MP3 files found in $BOOK_DIR"
    exit 1
fi

echo "Found ${#mp3_files[@]} chapters"

# create temp files
CONCAT_FILE=$(mktemp /tmp/audiobook_concat.XXXXXX.txt)
METADATA_FILE=$(mktemp /tmp/audiobook_metadata.XXXXXX.txt)

# cleanup on exit
trap "rm -f '$CONCAT_FILE' '$METADATA_FILE'" EXIT

# create concat file for ffmpeg
> "$CONCAT_FILE"
for mp3 in "${mp3_files[@]}"; do
    echo "file '$mp3'" >> "$CONCAT_FILE"
done

# find cover image if it exists
COVER_IMAGE=$(find "$BOOK_DIR" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" \) -type f | head -1)

# create metadata file with chapters
echo ";FFMETADATA1" > "$METADATA_FILE"

# calculate chapter timestamps
cumulative_ms=0
chapter_num=1

for mp3 in "${mp3_files[@]}"; do
    # get duration in milliseconds
    duration_ms=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$mp3" | awk '{print int($1 * 1000)}')

    # write chapter metadata
    echo "" >> "$METADATA_FILE"
    echo "[CHAPTER]" >> "$METADATA_FILE"
    echo "TIMEBASE=1/1000" >> "$METADATA_FILE"
    echo "START=$cumulative_ms" >> "$METADATA_FILE"

    cumulative_ms=$((cumulative_ms + duration_ms))

    echo "END=$cumulative_ms" >> "$METADATA_FILE"
    echo "title=Chapter $chapter_num" >> "$METADATA_FILE"

    chapter_num=$((chapter_num + 1))
done

# output file
OUTPUT_FILE="$OUTPUT_DIR/${BOOK_NAME}.m4a"

# build ffmpeg command
if [ -n "$COVER_IMAGE" ]; then
    echo "Using cover art: $(basename "$COVER_IMAGE")"
    # with cover art
    ffmpeg -y \
        -f concat -safe 0 -i "$CONCAT_FILE" \
        -i "$METADATA_FILE" \
        -i "$COVER_IMAGE" \
        -map_metadata 1 \
        -map 0:a -map 2:v \
        -c:a aac -b:a 64k \
        -c:v copy \
        -disposition:v:0 attached_pic \
        -f mp4 \
        -movflags +faststart \
        -metadata title="$BOOK_NAME" \
        -metadata album="$BOOK_NAME" \
        -metadata album_artist="$ARTIST" \
        -metadata artist="$ARTIST" \
        -metadata media_type=2 \
        -metadata genre="Audiobook" \
        -metadata stik=2 \
        "$OUTPUT_FILE" 2>&1 | grep -v "^  configuration:" | grep -v "^  lib" | grep -v "^  built with" || true
else
    echo "No cover art found"
    # without cover art
    ffmpeg -y \
        -f concat -safe 0 -i "$CONCAT_FILE" \
        -i "$METADATA_FILE" \
        -map_metadata 1 \
        -map 0:a \
        -c:a aac -b:a 64k \
        -f mp4 \
        -movflags +faststart \
        -metadata title="$BOOK_NAME" \
        -metadata album="$BOOK_NAME" \
        -metadata album_artist="$ARTIST" \
        -metadata artist="$ARTIST" \
        -metadata media_type=2 \
        -metadata genre="Audiobook" \
        -metadata stik=2 \
        "$OUTPUT_FILE" 2>&1 | grep -v "^  configuration:" | grep -v "^  lib" | grep -v "^  built with" || true
fi

if [ -f "$OUTPUT_FILE" ]; then
    file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_FILE" | awk '{printf "%d:%02d:%02d", $1/3600, ($1%3600)/60, $1%60}')
    echo ""
    echo "✓ Success!"
    echo "  Output: $OUTPUT_FILE"
    echo "  Size: $file_size"
    echo "  Duration: $duration"
    echo "  Chapters: ${#mp3_files[@]}"
else
    echo ""
    echo "✗ Error: Failed to create audiobook file"
    exit 1
fi
