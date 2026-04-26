---
name: project
description: Switch to a project directory, load context, and prepare for work
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Project Command

Switch to a project directory by name, load project context from log.md, and familiarize with the directory layout.

## Usage

`/project <name>`

Where `<name>` is the project name without the date suffix (e.g., `my-project` for `my-project.2026-04-25`).

## What This Command Does

When invoked:

1. **Find the project directory**: Searches `/Users/aostow/dev/journal/projects/` for directories matching the pattern `<name>.*` (where the suffix is typically a date in YYYY-MM-DD format created by the `mkproject` shell function)

2. **Change to the directory**: Switches the working directory to the found project directory

3. **Load project log**: Reads `log.md` in the project directory to understand the project context, goals, and current status

4. **Explore directory layout**: Lists directory contents and identifies key files to familiarize with the project structure

5. **Prepare for work**: Sets context so all subsequent file paths are relative to the project directory

## Instructions for Claude

When the user runs `/project <name>`:

1. **Locate the project**:
   ```bash
   cd /Users/aostow/dev/journal/projects && find . -maxdepth 1 -type d -name "<name>.*" | head -1
   ```
   - If no directory found, inform the user and list available projects
   - If multiple matches, use the most recent (last alphabetically since dates sort correctly)

2. **Change directory**:
   ```bash
   cd /Users/aostow/dev/journal/projects/<matched-directory>
   ```

3. **Read the project log**:
   - Use the Read tool on `log.md` (relative path from project directory)
   - If log.md doesn't exist, note this and continue

4. **Explore the layout**:
   - List directory contents with `ls -la`
   - Use Glob to find common file patterns (*.py, *.md, *.js, etc.)
   - Identify and describe the project structure

5. **Prepare context**:
   - Inform the user you're ready to work in this project
   - All subsequent file operations should use relative paths from the project directory
   - Summarize what you learned from log.md and the directory structure

## Example Session

```
User: /project nixos-backup

Claude:
1. Found project: /Users/aostow/dev/journal/projects/nixos-backup.2026-04-20
2. Read log.md - working on automated NixOS backup scripts
3. Directory contains:
   - backup.sh - main backup script
   - test.sh - test suite
   - README.md - documentation
   - configs/ - sample config files

Ready to work on nixos-backup. All paths will be relative to the project directory.
```

## Error Handling

- **Project not found**: List available projects in `/Users/aostow/dev/journal/projects/` to help the user
- **log.md missing**: Continue anyway, just note that no project log exists yet
- **Empty directory**: Note this and ask if the user wants to initialize the project

## Notes

- The date suffix is added automatically by the `mkproject` shell function using `$(ymd)` which outputs YYYY-MM-DD format
- Projects are organized in `/Users/aostow/dev/journal/projects/`
- After loading a project, maintain the working directory for the rest of the session unless explicitly changed
- Use relative paths for all file operations within the project
