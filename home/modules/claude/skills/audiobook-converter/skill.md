---
name: audiobook-converter
description: Merge directories of MP3 or M4B files into unified audiobooks with chapters for iPhone Books app
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Write
---

# Audiobook Converter Skill

Merge directories of MP3 or M4B audiobook files into single unified files with chapter markers, optimized for the iPhone Books app.

## What This Skill Does

This skill automates the merging of multi-file audiobooks (downloaded as numbered MP3s or M4Bs) into a single, chapter-marked file that works perfectly with Apple Books on iPhone/iPad. It handles:

- **MP3 collections**: Merges multiple MP3 files into M4A with AAC encoding
- **M4B collections**: Merges multiple M4B files into unified M4B preserving quality
- **Chapter creation**: Each source file becomes a numbered chapter
- **Cover art embedding**: Automatically finds and embeds JPG/PNG cover images
- **Metadata tagging**: Sets title, artist, and audiobook-specific metadata
- **Books app optimization**: Uses proper format flags for iOS compatibility

## Usage Examples

The skill can be invoked automatically by asking questions like:
- "Convert this audiobook directory to M4A: /path/to/book"
- "Turn these MP3s into an audiobook for iPhone"
- "Merge these M4B files into a single audiobook"
- "Make an audiobook from /Downloads/BookName with artist 'Author Name'"

Or invoke directly with: `/audiobook-converter <directory> [artist]`

## How It Works

When you request an audiobook merge, this skill will:

1. **Find all audio files** in the specified directory (MP3 or M4B, excluding .part files)
2. **Sort them naturally** by filename to maintain chapter order
3. **Extract durations** to calculate precise chapter timestamps
4. **Find cover art** (any .jpg or .png in the directory)
5. **Create chapter metadata** with proper timecodes
6. **Merge files** into a single output:
   - **MP3 → M4A**: AAC audio at 64kbps (optimized for size)
   - **M4B → M4B**: Copy audio streams (preserves original quality ~125kbps)
   - Embedded cover art
   - Chapter markers for navigation
   - Audiobook-specific metadata tags
7. **Validate the output** and report file details

## Technical Details

### Conversion Script

The skill uses the script at `~/.claude/skills/audiobook-converter/convert.sh` which:

```bash
~/.claude/skills/audiobook-converter/convert.sh <book_directory> [output_directory] [artist_name]
```

**Parameters**:
- `book_directory`: Directory containing MP3 or M4B files (required)
- `output_directory`: Where to save the output file (default: parent directory)
- `artist_name`: Author/narrator name (default: "Unknown Artist")

### FFmpeg Command Structure

The script builds an ffmpeg command that:

1. Concatenates all audio files in order using a concat demuxer
2. Applies chapter metadata from a generated FFMETADATA1 file
3. Embeds cover art as an attached picture
4. Encodes audio:
   - **MP3 input**: Encodes to AAC at 64kbps for optimal size
   - **M4B input**: Copies audio stream (preserves original quality)
5. Adds audiobook-specific tags:
   - `media_type=2` (audiobook)
   - `stik=2` (audiobook category)
   - `movflags +faststart` (streaming optimization)

### Chapter Metadata Format

Chapters are created automatically:
- One chapter per source file (MP3 or M4B)
- Named sequentially: "Chapter 1", "Chapter 2", etc.
- Timestamps calculated from cumulative duration
- FFMETADATA1 format with 1ms timebase

## Instructions for Claude

When a user requests audiobook conversion:

1. **Identify the source directory**:
   - Ask for the directory path if not provided
   - Verify it exists using `ls` or Bash
   - Check that it contains MP3 or M4B files
   - Determine file type (all files should be same format)

2. **Determine the artist/author**:
   - Ask the user for the author/narrator name
   - Default to "Unknown Artist" if not provided
   - Common for audiobooks: use actual author name (e.g., "Lemony Snicket")

3. **Determine the output directory**:
   - Default: parent directory of source (one level up)
   - Or ask user if they want a specific output location
   - Output filename: "{book_name} - MERGED.{m4a|m4b}"

4. **For MP3 files, use the conversion script**:
   ```bash
   ~/.claude/skills/audiobook-converter/convert.sh \
     "/path/to/book/directory" \
     "/path/to/output" \
     "Author Name"
   ```

   **For M4B files, use ffmpeg directly**:
   - Create concat list with absolute paths
   - Extract durations and generate chapter metadata
   - Use ffmpeg concat demuxer with `-c:a copy` to preserve quality
   - Embed cover art and metadata

5. **Monitor the output**:
   - The script will report:
     - Number of chapters found
     - Whether cover art was found
     - Final file size and duration
     - Success/failure status

6. **Report to the user**:
   - Show the output file path
   - Confirm file size and duration
   - Number of chapters created
   - Remind them it's ready for AirDrop to iPhone

## File Requirements

### Input Directory Structure

The directory should contain:
- **MP3 or M4B files**: Named in order (e.g., "01.mp3", "02.m4b" or "Book Name 01.m4b")
  - All files should be the same format (don't mix MP3 and M4B)
- **Cover art (optional)**: Any .jpg or .png file
- **No .part files**: Incomplete downloads are automatically skipped

### Output

Creates a single merged file named after the directory:
- **MP3 input**: Creates `.m4a` file (e.g., "The Reptile Room.m4a")
- **M4B input**: Creates `.m4b` file (e.g., "The Hunger of the Gods - MERGED.m4b")
- Number prefixes are stripped (e.g., "02 - The Reptile Room" → "The Reptile Room")
- Output saved to parent directory by default

## Metadata Tags Applied

The output file includes:
- `title`: Book name (from directory)
- `album`: Book name (same as title)
- `artist`: Author/narrator name
- `album_artist`: Author/narrator name
- `genre`: "Audiobook"
- `media_type`: 2 (audiobook identifier for M4B)
- `stik`: 2 (iTunes audiobook category for M4B)

## Common Issues and Solutions

### Issue: No audio files found
**Solution**: Check that files are .mp3 or .m4b (not .m4a, .part, etc.)

### Issue: Files out of order
**Solution**: Ensure filenames sort correctly (use leading zeros: 01, 02, not 1, 2)

### Issue: iPhone won't open in Books app
**Solution**:
- Both .m4a and .m4b extensions work with Books app
- Check that metadata is properly set
- Try deleting and re-AirDropping

### Issue: No chapters visible
**Solution**: Chapters are embedded - swipe or tap to see chapter navigation in Books app

### Issue: Cover art not showing
**Solution**: Ensure there's a .jpg or .png file in the source directory

## Dependencies

Required tools (available via Nix on this system):
- `ffmpeg` - Audio/video conversion (use: `nix run nixpkgs#ffmpeg`)
- `ffprobe` - Media file analysis (included with ffmpeg)
- `bash` - Shell script execution

The script checks for these automatically and will error if missing.

## Output Location

By default, saves merged files to:
- Parent directory of source (one level up from input directory)
- Or user-specified output directory
- Format: M4A for MP3 input, M4B for M4B input

## Success Criteria

A successful merge should:
1. Create a valid M4A or M4B file (playable in Books app)
2. Include all source files merged in correct order
3. Have chapter markers (one per source file)
4. Include embedded cover art (if available)
5. Audio quality:
   - MP3 → M4A: ~64kbps AAC (under 100MB per hour)
   - M4B → M4B: Original quality preserved (~125kbps, ~1GB per 20 hours)
6. Display correct title and artist in Books app

## Examples of Successful Conversions

```bash
# basic conversion (output to same directory)
~/.claude/skills/audiobook-converter/convert.sh \
  "/Users/aostow/Downloads/The Reptile Room" \
  "" \
  "Lemony Snicket"

# conversion with custom output directory
~/.claude/skills/audiobook-converter/convert.sh \
  "/Users/aostow/Downloads/The Wide Window" \
  "/Users/aostow/Downloads/Audiobooks/Converted" \
  "Lemony Snicket"

# batch conversion of multiple books
for book_dir in "/Users/aostow/Downloads/Books"/*; do
  ~/.claude/skills/audiobook-converter/convert.sh \
    "$book_dir" \
    "/Users/aostow/Downloads/Books/converted" \
    "Author Name"
done
```

## Typical Workflows

### MP3 Conversion
1. User downloads audiobook as directory of MP3s
2. User asks: "Convert this audiobook: /path/to/book"
3. Claude asks: "Who is the author/narrator?"
4. User provides: "Author Name"
5. Claude runs conversion script
6. Claude reports: "Created Book.m4a (85MB, 3h 11m, 13 chapters)"
7. User AirDrops to iPhone and opens in Books app

### M4B Merge
1. User has audiobook split into multiple M4B files
2. User asks: "Merge these M4B files: /path/to/book"
3. Claude identifies M4B files and extracts author from metadata
4. Claude uses ffmpeg to merge with chapter markers
5. Claude reports: "Created Book - MERGED.m4b (1.3GB, 23h, 81 chapters)"
6. User AirDrops to iPhone and opens in Books app

## Notes

- The script strips number prefixes from directory names for cleaner titles
- Cover art is automatically detected (first .jpg or .png found)
- **MP3 conversion**: Output is highly compressed (64kbps AAC) but maintains good quality for spoken word
- **M4B merge**: Output preserves original quality (~125kbps) using stream copy
- Chapter titles are generic ("Chapter 1", "Chapter 2") - not extracted from file metadata
- Files work with AirDrop, iCloud Drive, or any file transfer method
- Both M4A and M4B formats work perfectly with Apple Books app
