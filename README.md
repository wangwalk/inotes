# inotes

Your notes, your terminal.

A macOS CLI for Apple Notes -- list, read, create, edit, delete, and search notes without leaving the command line. Built for humans and AI agents alike.

## Requirements
- macOS 14+ (Sonoma or later)
- Automation permission for Notes.app (System Settings > Privacy & Security > Automation)

## Install

### From source
```bash
make build
# binary at ./bin/inotes
```

Or with SwiftPM directly:
```bash
swift build -c release
```

## Usage
```bash
inotes                                # show recent notes (default)
inotes today                          # notes modified today
inotes show week                      # notes modified this week
inotes show all                       # all notes
inotes show --folder Work             # notes in a specific folder
inotes show recent --limit 10         # limit results

inotes folders                        # list all folders with note counts

inotes read 1                         # read full note by index
inotes read A3F2                      # read full note by ID prefix

inotes add --title "Meeting Notes" --body "Discussed Q1 plans" --folder Work
inotes add -t "Shopping list" -b "Milk, bread, eggs"

inotes edit 1 --title "Updated Title"
inotes edit 2 --body "New content" --folder Projects

inotes delete 1                       # delete with confirmation
inotes delete 1 --force               # skip confirmation
inotes delete 2 --dry-run             # preview without deleting

inotes search "quarterly review"
inotes search "TODO" --folder Work --limit 10

inotes status                         # check automation permission
```

## Note identification

Notes are identified by index or ID prefix:
- **Index** -- a 1-based position from the most recent `show` output (e.g., `1`, `2`, `3`).
- **ID prefix** -- the first 4+ characters of a note's internal ID (e.g., `A3F2`).

## Output formats
- Default: human-readable table with indices.
- `--json` (`-j`): machine-readable JSON arrays/objects.
- `--plain`: stable tab-separated lines for scripting.
- `--quiet` (`-q`): counts only.

### JSON output examples

```bash
# notes list as JSON
inotes show --json
```
```json
[
  {
    "body" : "Discussed Q1 plans",
    "creationDate" : "2026-02-08T10:00:00Z",
    "folder" : "Work",
    "id" : "x-coredata://AB12CD34-...",
    "modificationDate" : "2026-02-08T14:30:00Z",
    "title" : "Meeting Notes"
  }
]
```

```bash
# folders as JSON
inotes folders --json
```
```json
[
  {
    "id" : "x-coredata://AB12CD34-...",
    "name" : "Notes",
    "noteCount" : 42
  }
]
```

```bash
# permission status as JSON
inotes status --json
```
```json
{
  "automation_permission" : "granted",
  "authorized" : true
}
```

## Global flags

| Flag | Short | Description |
|------|-------|-------------|
| `--json` | `-j` | Emit machine-readable JSON output |
| `--plain` | | Emit stable tab-separated output |
| `--quiet` | `-q` | Only emit count output |
| `--no-color` | | Disable colored output |
| `--no-input` | | Disable interactive prompts (for scripts and agents) |

## Permissions

inotes uses AppleScript (`osascript`) to communicate with Notes.app. On first run, macOS will prompt you to allow Automation access.

If you see "Permission denied" errors:
1. Open **System Settings > Privacy & Security > Automation**.
2. Find your terminal application (Terminal.app, iTerm, etc.).
3. Enable access to **Notes**.
4. Restart your terminal.
5. Try again.

Run `inotes status` to check the current permission state.

## Core library

The reusable Swift core lives in `Sources/INotesCore` and is consumed by the CLI target. Apps can depend on the `INotesCore` library target directly.

## License

MIT
