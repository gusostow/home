---
name: audiobook-converter
description: Convert directories of MP3 files into M4A audiobooks with chapters for iPhone Books app
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Write
---

# Audiobook Converter Skill

Convert directories of MP3 audiobook files into single M4A files with chapter markers, optimized for the iPhone Books app.

## What This Skill Does

This skill automates the conversion of multi-file audiobooks (typically downloaded as numbered MP3s) into a single, chapter-marked M4A file that works perfectly with Apple Books on iPhone/iPad. It handles:

- **MP3 collections**: Merges multiple MP3 files in order
- **Chapter creation**: Each MP3 becomes a numbered chapter
- **Cover art embedding**: Automatically finds and embeds JPG/PNG cover images
- **Metadata tagging**: Sets title, artist, and audiobook-specific metadata
- **Books app optimization**: Uses proper format flags for iOS compatibility

## Usage Examples

The skill can be invoked automatically by asking questions like:
- "Convert this audiobook directory to M4A: /path/to/book"
- "Turn these MP3s into an audiobook for iPhone"
- "Make an M4A audiobook from /Downloads/BookName with artist 'Author Name'"

Or invoke directly with: `/audiobook-converter <directory> [artist]`

## How It Works

When you request an audiobook conversion, this skill will:

1. **Find all MP3 files** in the specified directory (excluding .part files)
2. **Sort them naturally** by filename to maintain chapter order
3. **Extract durations** to calculate precise chapter timestamps
4. **Find cover art** (any .jpg or .png in the directory)
5. **Create chapter metadata** with proper timecodes
6. **Merge and encode** all files into a single M4A with:
   - AAC audio at 64kbps (good quality, reasonable size)
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
- `book_directory`: Directory containing MP3 files (required)
- `output_directory`: Where to save the M4A file (default: same as book_directory)
- `artist_name`: Author/narrator name (default: "Unknown Artist")

### FFmpeg Command Structure

The script builds an ffmpeg command that:

1. Concatenates all MP3s in order using a concat demuxer
2. Applies chapter metadata from a generated FFMETADATA1 file
3. Embeds cover art as an attached picture
4. Encodes to AAC at 64kbps
5. Adds audiobook-specific tags:
   - `media_type=2` (audiobook)
   - `stik=2` (audiobook category)
   - `movflags +faststart` (streaming optimization)

### Chapter Metadata Format

Chapters are created automatically:
- One chapter per MP3 file
- Named sequentially: "Chapter 1", "Chapter 2", etc.
- Timestamps calculated from cumulative duration
- FFMETADATA1 format with 1ms timebase

## Instructions for Claude

When a user requests audiobook conversion:

1. **Identify the source directory**:
   - Ask for the directory path if not provided
   - Verify it exists using `ls` or Bash
   - Check that it contains MP3 files

2. **Determine the artist/author**:
   - Ask the user for the author/narrator name
   - Default to "Unknown Artist" if not provided
   - Common for audiobooks: use actual author name (e.g., "Lemony Snicket")

3. **Determine the output directory**:
   - Default: same as source directory
   - Or ask user if they want a specific output location
   - Common: create a "converted" subdirectory

4. **Run the conversion script**:
   ```bash
   ~/.claude/skills/audiobook-converter/convert.sh \
     "/path/to/book/directory" \
     "/path/to/output" \
     "Author Name"
   ```

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
- **MP3 files**: Named in order (e.g., "01.mp3", "02.mp3" or "Book Name 01.mp3")
- **Cover art (optional)**: Any .jpg or .png file
- **No .part files**: Incomplete downloads are automatically skipped

### Output

Creates a single `.m4a` file named after the directory:
- If directory is "The Reptile Room", output is "The Reptile Room.m4a"
- Number prefixes are stripped (e.g., "02 - The Reptile Room" → "The Reptile Room")

## Metadata Tags Applied

The output M4A file includes:
- `title`: Book name (from directory)
- `album`: Book name (same as title)
- `artist`: Author/narrator name
- `album_artist`: Author/narrator name
- `genre`: "Audiobook"
- `media_type`: 2 (audiobook identifier)
- `stik`: 2 (iTunes audiobook category)

## Common Issues and Solutions

### Issue: No MP3 files found
**Solution**: Check that files are actually .mp3 (not .m4a, .part, etc.)

### Issue: Files out of order
**Solution**: Ensure filenames sort correctly (use leading zeros: 01, 02, not 1, 2)

### Issue: iPhone won't open in Books app
**Solution**:
- Verify file extension is .m4a (not .m4b)
- Check that media_type=2 is set
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

By default, saves M4A files to:
- Same directory as source (if no output specified)
- Or user-specified output directory
- Recommended: create a "converted" subdirectory

## Success Criteria

A successful conversion should:
1. Create a valid M4A file (playable in Books app)
2. Include all MP3s merged in correct order
3. Have chapter markers (one per MP3)
4. Include embedded cover art (if available)
5. Use ~64kbps AAC encoding for efficiency
6. Be under 100MB per hour of audio
7. Display correct title and artist in Books app

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

## Typical Workflow

1. User downloads audiobook as directory of MP3s
2. User asks: "Convert this audiobook: /path/to/book"
3. Claude asks: "Who is the author/narrator?"
4. User provides: "Author Name"
5. Claude runs conversion script
6. Claude reports: "Created Book.m4a (85MB, 3h 11m, 13 chapters)"
7. User AirDrops to iPhone and opens in Books app

## Notes

- The script strips number prefixes from directory names for cleaner titles
- Cover art is automatically detected (first .jpg or .png found)
- Output is highly compressed (64kbps AAC) but maintains good quality for spoken word
- Chapter titles are generic ("Chapter 1", "Chapter 2") - not extracted from MP3 metadata
- Files work with AirDrop, iCloud Drive, or any file transfer method
