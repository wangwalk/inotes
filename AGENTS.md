# AGENTS.md

Guidelines for AI agents contributing to this codebase.

## Build commands

```bash
make build          # release build → bin/inotes (universal binary, arm64 + x86_64)
make test           # run tests with code coverage
make lint           # swift-format lint + swiftlint
make format         # auto-format sources with swift-format
make check          # lint + test
make inotes ARGS="show"   # clean build + run with arguments
make clean          # remove build artifacts
```

## Project structure

```
Sources/
  INotesCore/           # Reusable library (no CLI dependencies)
    Models.swift          # NoteItem, NoteFolder, NoteDraft, NoteUpdate
    NotesStore.swift      # Actor wrapping AppleScript calls to Notes.app
    NoteFilter.swift      # Date-based filtering (all, today, week, recent)
    IDResolver.swift      # Resolve index or ID prefix to NoteItem
    ScriptRunner.swift    # Actor that runs osascript processes
    DateFormatting.swift  # ISO 8601 and AppleScript date parsing
    Errors.swift          # INotesError enum
  inotes/               # CLI target
    INotesMain.swift      # @main entry point
    CommandRouter.swift   # Dispatches subcommands, implicit show rewriting
    CommandSpec.swift     # Command descriptor type
    CommandSignatures.swift # Shared runtime flags (--json, --plain, etc.)
    RuntimeOptions.swift  # Parsed runtime flag values
    OutputFormatting.swift # Renderers: standard, plain, JSON, quiet
    Console.swift         # TTY detection, prompts, stderr
    HelpPrinter.swift     # Usage/help text rendering
    ParsedValues+Decode.swift # Convenience extensions on Commander values
    Version.swift         # Auto-generated version string
    Commands/
      ShowCommand.swift     # List notes with date filters
      FoldersCommand.swift  # List folders
      ReadCommand.swift     # Show full note content
      AddCommand.swift      # Create a note
      EditCommand.swift     # Modify a note
      DeleteCommand.swift   # Delete a note (with confirmation)
      SearchCommand.swift   # Search by title or content
      StatusCommand.swift   # Check automation permission
Tests/
  INoteCoreTests/       # Unit tests for the core library
  inotesTests/          # Unit tests for the CLI layer
```

## Coding style

- **Swift 6** language mode with strict concurrency checking.
- All public API types conform to `Sendable`.
- `NotesStore` and `ScriptRunner` are both `actor` types.
- Use `async/await` -- no completion handlers.
- Line length: 120 warning, 140 error (SwiftLint).
- Format with `swift format` before committing.
- Lint with `swiftlint` -- see `.swiftlint.yml` for enabled rules.
- No force casts or force tries in production code (warnings).
- Prefer `guard let` for early exits, `if let` for conditional branches.
- Use `enum` with static members for stateless namespaces (e.g., `enum ShowCommand`).

## Adding a new command

1. Create `Sources/inotes/Commands/YourCommand.swift`.
2. Define an `enum YourCommand` with a `static var spec: CommandSpec`.
3. Use `CommandSignatures.withRuntimeFlags(...)` to include global flags.
4. Register the spec in `CommandRouter.init()` by adding it to the `specs` array.
5. Add tests in `Tests/inotesTests/`.

## Testing

- Test framework: Swift Testing (`import Testing`, `@Test`, `#expect`).
- Run with `make test` (enables code coverage).
- Core library tests go in `Tests/INoteCoreTests/`.
- CLI tests go in `Tests/inotesTests/`.
- Tests must not depend on Notes.app or real AppleScript execution.
- Use deterministic dates and mock data for unit tests.

## Versioning

- Version is stored in `version.env` (`MARKETING_VERSION=x.y.z`).
- `scripts/generate-version.sh` writes `Sources/inotes/Version.swift`.
- Both `make build` and `make test` regenerate the version file automatically.
- Override at runtime via the `INOTES_VERSION` environment variable.

## Commit messages

Use conventional-style prefixes:

```
feat: add folder rename support
fix: handle empty search results
test: add IDResolver edge cases
refactor: extract output rendering
docs: update README examples
chore: bump swift-tools-version
```

Keep the first line under 72 characters. Add a blank line before any extended description.
