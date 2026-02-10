---
name: managing-apple-notes
description: "Manage Apple Notes from the terminal using the inotes CLI. Use when asked to list, read, create, edit, delete, or search notes in Notes.app on macOS."
compatibility: "macOS 14+ (Sonoma or later). Requires Automation permission for Notes.app."
---

# Managing Apple Notes with inotes

`inotes` is a macOS CLI for Apple Notes. It communicates with Notes.app via AppleScript and supports all CRUD operations plus search. Output defaults to a human-readable table; use `--json` for machine-readable output.

## Prerequisites

Install via Homebrew:

```bash
brew install wangwalk/tap/inotes
```

Check permission:

```bash
inotes status
```

If permission is denied, the user must enable Automation access for their terminal in **System Settings > Privacy & Security > Automation > Notes**.

## Commands

### List notes

```bash
inotes                            # recent iCloud notes (default)
inotes today                      # modified today
inotes show week                  # modified this week
inotes show all                   # all notes
inotes show --folder Work         # notes in a specific folder
inotes show recent --limit 10    # limit results
```

### List folders

```bash
inotes folders
```

### List accounts

```bash
inotes accounts
```

### Read a note

```bash
inotes read 1        # by index from last show output
inotes read A3F2     # by ID prefix (4+ characters)
```

### Create a note

```bash
inotes add --title "Meeting Notes" --body "Action items" --folder Work
```

### Edit a note

```bash
inotes edit 1 --title "Updated Title"
inotes edit 2 --body "New content" --folder Projects
```

### Delete a note

```bash
inotes delete 1              # with confirmation
inotes delete 1 --force      # skip confirmation
```

### Search notes

```bash
inotes search "quarterly review"
inotes search "TODO" --folder Work --limit 10
```

## Multi-account support

By default only iCloud notes are shown. Use `--account <name>` or `--all-accounts` to access other accounts.

```bash
inotes accounts                    # list available accounts
inotes show all --account Exchange
inotes show all --all-accounts
```

## Output formats

| Flag | Description |
|------|-------------|
| *(default)* | Human-readable table |
| `--json` / `-j` | JSON |
| `--plain` | Tab-separated |
| `--quiet` / `-q` | Count only |

## Agent usage guidelines

- Always use `--json` when you need to parse output programmatically.
- Use `--no-input` to disable interactive prompts in non-interactive contexts.
- Use `--no-color` when capturing output to avoid ANSI escape sequences.
- Identify notes by **index** (from the last `show` output) or by **ID prefix** (first 4+ hex characters of the note ID).
- Run `inotes status` first to verify automation permission before attempting other commands.
