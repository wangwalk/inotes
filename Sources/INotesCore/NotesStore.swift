import Foundation

/// Main interface to Apple Notes via AppleScript
public actor NotesStore {
  private let scriptRunner: ScriptRunner

  public init() {
    self.scriptRunner = ScriptRunner()
  }

  /// Lists all folders in Notes
  public func folders() async throws -> [NoteFolder] {
    let script = """
      tell application "Notes"
        set output to ""
        repeat with f in folders
          set folderID to id of f
          set folderName to name of f
          set folderCount to count of notes in f
          set output to output & folderID & tab & folderName & tab & folderCount & linefeed
        end repeat
        return output
      end tell
      """

    let result = try await scriptRunner.run(script)
    return parseFolders(result)
  }

  /// Lists notes in a folder (or all notes if folder is nil)
  public func notes(in folder: String? = nil, limit: Int = 100) async throws -> [NoteItem] {
    let script: String

    if let folder = folder {
      // Escape single quotes in folder name for AppleScript
      let escapedFolder = folder.replacingOccurrences(of: "'", with: "\\'")
      script = """
        tell application "Notes"
          try
            set targetFolder to folder "\(escapedFolder)"
          on error
            error "Folder not found: \(escapedFolder)"
          end try
          set notesList to notes of targetFolder
          set output to ""
          set counter to 0
          repeat with n in notesList
            if counter ≥ \(limit) then exit repeat
            set noteID to id of n
            set noteName to name of n
            set noteBody to plaintext of n
            set folderName to name of container of n
            set createdDate to creation date of n
            set modifiedDate to modification date of n
            set output to output & noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate & linefeed
            set counter to counter + 1
          end repeat
          return output
        end tell
        """
    } else {
      script = """
        tell application "Notes"
          set allNotes to notes
          set output to ""
          set counter to 0
          repeat with n in allNotes
            if counter ≥ \(limit) then exit repeat
            set noteID to id of n
            set noteName to name of n
            set noteBody to plaintext of n
            set folderName to name of container of n
            set createdDate to creation date of n
            set modifiedDate to modification date of n
            set output to output & noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate & linefeed
            set counter to counter + 1
          end repeat
          return output
        end tell
        """
    }

    let result = try await scriptRunner.run(script)
    return parseNotes(result)
  }

  /// Gets a single note by ID
  public func note(id: String) async throws -> NoteItem {
    // Escape single quotes in ID for AppleScript
    let escapedID = id.replacingOccurrences(of: "'", with: "\\'")
    let script = """
      tell application "Notes"
        try
          set targetNote to note id "\(escapedID)"
        on error
          error "Note not found: \(escapedID)"
        end try
        set noteID to id of targetNote
        set noteName to name of targetNote
        set noteBody to plaintext of targetNote
        set folderName to name of container of targetNote
        set createdDate to creation date of targetNote
        set modifiedDate to modification date of targetNote
        return noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate
      end tell
      """

    let result = try await scriptRunner.run(script)
    let notes = parseNotes(result)
    guard let note = notes.first else {
      throw INotesError.noteNotFound(id)
    }
    return note
  }

  /// Creates a new note
  public func createNote(_ draft: NoteDraft) async throws -> NoteItem {
    let targetFolder = draft.folderName ?? "Notes"
    let escapedFolder = targetFolder.replacingOccurrences(of: "'", with: "\\'")
    let escapedTitle = draft.title.replacingOccurrences(of: "'", with: "\\'")

    // Notes.app requires HTML body, convert plain text to simple HTML
    let htmlBody = "<html><body>\(escapeHTML(draft.body))</body></html>"
    let escapedHTML = htmlBody.replacingOccurrences(of: "'", with: "\\'")

    let script = """
      tell application "Notes"
        try
          set targetFolder to folder "\(escapedFolder)"
        on error
          error "Folder not found: \(escapedFolder)"
        end try
        set newNote to make new note at targetFolder with properties {name:"\(escapedTitle)", body:"\(escapedHTML)"}
        set noteID to id of newNote
        set noteName to name of newNote
        set noteBody to plaintext of newNote
        set folderName to name of container of newNote
        set createdDate to creation date of newNote
        set modifiedDate to modification date of newNote
        return noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate
      end tell
      """

    let result = try await scriptRunner.run(script)
    let notes = parseNotes(result)
    guard let note = notes.first else {
      throw INotesError.operationFailed("Failed to create note")
    }
    return note
  }

  /// Updates an existing note
  public func updateNote(id: String, _ update: NoteUpdate) async throws -> NoteItem {
    let escapedID = id.replacingOccurrences(of: "'", with: "\\'")

    // Build the update script based on what fields are provided
    var updateStatements: [String] = []

    if let title = update.title {
      let escapedTitle = title.replacingOccurrences(of: "'", with: "\\'")
      updateStatements.append("set name of targetNote to \"\(escapedTitle)\"")
    }

    if let body = update.body {
      let htmlBody = "<html><body>\(escapeHTML(body))</body></html>"
      let escapedHTML = htmlBody.replacingOccurrences(of: "'", with: "\\'")
      updateStatements.append("set body of targetNote to \"\(escapedHTML)\"")
    }

    if let folderName = update.folderName {
      let escapedFolder = folderName.replacingOccurrences(of: "'", with: "\\'")
      updateStatements.append("""
        try
          set newFolder to folder "\(escapedFolder)"
          move targetNote to newFolder
        on error
          error "Folder not found: \(escapedFolder)"
        end try
        """)
    }

    let updateBlock = updateStatements.joined(separator: "\n        ")

    let script = """
      tell application "Notes"
        try
          set targetNote to note id "\(escapedID)"
        on error
          error "Note not found: \(escapedID)"
        end try
        \(updateBlock)
        set noteID to id of targetNote
        set noteName to name of targetNote
        set noteBody to plaintext of targetNote
        set folderName to name of container of targetNote
        set createdDate to creation date of targetNote
        set modifiedDate to modification date of targetNote
        return noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate
      end tell
      """

    let result = try await scriptRunner.run(script)
    let notes = parseNotes(result)
    guard let note = notes.first else {
      throw INotesError.operationFailed("Failed to update note")
    }
    return note
  }

  /// Deletes a note by ID
  public func deleteNote(id: String) async throws {
    let escapedID = id.replacingOccurrences(of: "'", with: "\\'")
    let script = """
      tell application "Notes"
        try
          set targetNote to note id "\(escapedID)"
          delete targetNote
        on error
          error "Note not found: \(escapedID)"
        end try
      end tell
      """

    _ = try await scriptRunner.run(script)
  }

  /// Searches for notes by query
  public func search(query: String, in folder: String? = nil) async throws -> [NoteItem] {
    let escapedQuery = query.replacingOccurrences(of: "'", with: "\\'")
    let script: String

    if let folder = folder {
      let escapedFolder = folder.replacingOccurrences(of: "'", with: "\\'")
      script = """
        tell application "Notes"
          try
            set targetFolder to folder "\(escapedFolder)"
          on error
            error "Folder not found: \(escapedFolder)"
          end try
          set searchResults to (every note of targetFolder whose name contains "\(escapedQuery)" or plaintext contains "\(escapedQuery)")
          set output to ""
          repeat with n in searchResults
            set noteID to id of n
            set noteName to name of n
            set noteBody to plaintext of n
            set folderName to name of container of n
            set createdDate to creation date of n
            set modifiedDate to modification date of n
            set output to output & noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate & linefeed
          end repeat
          return output
        end tell
        """
    } else {
      script = """
        tell application "Notes"
          set searchResults to (every note whose name contains "\(escapedQuery)" or plaintext contains "\(escapedQuery)")
          set output to ""
          repeat with n in searchResults
            set noteID to id of n
            set noteName to name of n
            set noteBody to plaintext of n
            set folderName to name of container of n
            set createdDate to creation date of n
            set modifiedDate to modification date of n
            set output to output & noteID & tab & noteName & tab & noteBody & tab & folderName & tab & createdDate & tab & modifiedDate & linefeed
          end repeat
          return output
        end tell
        """
    }

    let result = try await scriptRunner.run(script)
    return parseNotes(result)
  }

  // MARK: - Private Helpers

  /// Parses tab-separated folder output from AppleScript
  private func parseFolders(_ output: String) -> [NoteFolder] {
    guard !output.isEmpty else { return [] }

    return output.split(separator: "\n").compactMap { line in
      let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
      guard parts.count >= 3 else { return nil }

      let id = String(parts[0])
      let name = String(parts[1])
      let count = Int(parts[2]) ?? 0

      return NoteFolder(id: id, name: name, noteCount: count)
    }
  }

  /// Parses tab-separated note output from AppleScript
  private func parseNotes(_ output: String) -> [NoteItem] {
    guard !output.isEmpty else { return [] }

    return output.split(separator: "\n").compactMap { line in
      let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
      guard parts.count >= 6 else { return nil }

      let id = String(parts[0])
      let title = String(parts[1])
      let body = String(parts[2])
      let folder = String(parts[3])
      let createdDateStr = String(parts[4])
      let modifiedDateStr = String(parts[5])

      // Parse dates from AppleScript format
      guard let createdDate = DateFormatting.parseAppleScriptDate(createdDateStr),
            let modifiedDate = DateFormatting.parseAppleScriptDate(modifiedDateStr)
      else {
        return nil
      }

      return NoteItem(
        id: id,
        title: title,
        body: body,
        folder: folder,
        creationDate: createdDate,
        modificationDate: modifiedDate
      )
    }
  }

  /// Escapes HTML special characters
  private func escapeHTML(_ text: String) -> String {
    return text
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "\n", with: "<br>")
  }
}
