# Changelog

## 0.1.1 — 2026-02-10

### Added
- `mkfolder` command to create new folders in Notes.app
- Multi-language support for detecting "Recently Deleted" folder (15 languages)

### Fixed
- Filter out deleted notes from `show` and `search` results
- Filter out "Recently Deleted" folder from `folders` output
- Handle inaccessible folders gracefully during iteration
- `status` command now performs actual permission check via AppleScript

### Changed
- `NoteFilter.matches` accepts explicit `now` parameter for better testability

## 0.1.0 — 2026-02-08

Initial release.

- List, read, create, edit, delete notes via Apple Notes
- Search notes by title or content
- Folder management
- Multiple output formats (standard, JSON, plain, quiet)
- Note filtering (today, week, recent, all)
- ID resolution by index or prefix
- AppleScript bridge for Notes.app automation
