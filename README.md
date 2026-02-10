# inotes

Your notes, your terminal.

A macOS CLI for Apple Notes — list, read, create, edit, delete, and search notes without leaving the command line. Built for humans and AI agents alike.

## Requirements

- macOS 14+ (Sonoma or later)
- Automation permission for Notes.app (System Settings > Privacy & Security > Automation)

## Install

### Homebrew

```bash
brew install wangwalk/tap/inotes
```

### From source

```bash
make build
# binary at ./bin/inotes
```

Or with SwiftPM directly:

```bash
swift build -c release
```

## Quick start

```bash
inotes                    # show recent iCloud notes
inotes accounts           # list all accounts
inotes show all           # all iCloud notes
inotes folders            # list folders with note counts
inotes mkfolder Projects  # create a folder
inotes read 1             # read full note by index
inotes search "meeting"   # search by title or content
```

## Commands

### show — List notes

```bash
inotes                                # recent notes (default)
inotes today                          # notes modified today
inotes show week                      # notes modified this week
inotes show all                       # all notes
inotes show --folder Work             # notes in a specific folder
inotes show recent --limit 10         # limit results
```

Notes in the system “Recently Deleted” folder are excluded.

### folders — List folders

```bash
inotes folders                        # all folders with note counts
inotes folders --json                 # JSON output
```

The system “Recently Deleted” folder is excluded.

### mkfolder — Create a folder

```bash
inotes mkfolder Projects
inotes mkfolder Work --account Exchange
inotes mkfolder Ideas --json
```

### accounts — List accounts

```bash
inotes accounts                       # list all accounts (iCloud, Exchange, IMAP, etc.)
inotes accounts --json                # JSON output
```

### read — Read full note

```bash
inotes read 1                         # read by index
inotes read A3F2                      # read by ID prefix
```

### add — Create a note

```bash
inotes add --title "Meeting Notes"
inotes add -t "Ideas" -b "Draft outline" -f Projects
inotes add --title "Shopping list" --body "Milk, bread, eggs"
```

When run interactively (without `--no-input`), missing title/body/folder will be prompted.

### edit — Modify a note

```bash
inotes edit 1 --title "Updated Title"
inotes edit 2 --body "New content" --folder Projects
inotes edit 5 -t "Title" -b "Body" -f Work
```

### delete — Delete a note

```bash
inotes delete 1                       # delete with confirmation
inotes delete 1 --force               # skip confirmation
inotes delete 2 --dry-run             # preview without deleting
```

### search — Search notes

```bash
inotes search "quarterly review"
inotes search "TODO" --folder Work --limit 10
```

Notes in the system “Recently Deleted” folder are excluded.

### status — Check permission

```bash
inotes status                         # check automation permission
```

```bash
inotes status --json
```

```json
{
  "authorized" : true,
  "automationPermission" : "granted"
}
```

## Multi-account support

By default, inotes only shows notes from your **iCloud** account. Use `--account` or `--all-accounts` to access other accounts.

```bash
# List available accounts
inotes accounts

# Filter by account name (case-insensitive substring match)
inotes show all --account Exchange
inotes show all -a gmail
inotes folders --account iCloud
inotes search "draft" -a Exchange

# Show notes from all accounts
inotes show all --all-accounts
inotes folders --all-accounts
```

The `-a`/`--account` option is accepted on all commands. It affects commands that fetch notes/folders (e.g. `show`,
`folders`, `read`, `add`, `edit`, `delete`, `search`, `mkfolder`); for `accounts` and `status` it is currently
ignored.

## Note identification

Notes are identified by **index** or **ID prefix**:

- **Index** — a 1-based position from the most recent `show` output (e.g., `1`, `2`, `3`).
- **ID prefix** — the first 4+ characters of a note's internal ID (e.g., `A3F2`).

## Output formats

| Flag | Short | Description |
|------|-------|-------------|
| *(default)* | | Human-readable table with indices |
| `--json` | `-j` | Machine-readable JSON |
| `--plain` | | Tab-separated lines for scripting |
| `--quiet` | `-q` | Count only |

### JSON examples

```bash
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
inotes accounts --json
```

```json
[
  {
    "id" : "x-coredata://0D80089A-.../ICAccount/p3",
    "name" : "iCloud"
  },
  {
    "id" : "x-coredata://76BBD5A1-.../EWSAccount/p3",
    "name" : "Exchange"
  }
]
```

## Global options

These options are available on all commands:

| Option | Short | Description |
|--------|-------|-------------|
| `--account <name>` | `-a` | Filter by account name |
| `--all-accounts` | | Include notes from all accounts (default: iCloud only) |
| `--json` | `-j` | Emit machine-readable JSON output |
| `--plain` | | Emit stable tab-separated output |
| `--quiet` | `-q` | Only emit count output |
| `--no-color` | | Disable colored output |
| `--no-input` | | Disable interactive prompts (for scripts and agents) |
| `--version` | `-V` | Print version |
| `--help` | `-h` | Print help |

## Permissions

inotes uses AppleScript (`osascript`) to communicate with Notes.app. On first run, macOS will prompt you to allow Automation access.

## Privacy

inotes runs locally and does not send your notes to any server. It uses `osascript` to query Notes.app and prints results to stdout.

If you see "Permission denied" errors:

1. Open **System Settings > Privacy & Security > Automation**.
2. Find your terminal application (Terminal.app, iTerm, etc.).
3. Enable access to **Notes**.
4. Restart your terminal.
5. Run `inotes status` to verify.

## Core library

The reusable Swift core lives in `Sources/INotesCore` and can be consumed as a library dependency:

```swift
// Package.swift
.package(url: "https://github.com/wangwalk/inotes.git", from: "0.1.1")

// target dependency
.product(name: "INotesCore", package: "inotes")
```

## License

MIT
