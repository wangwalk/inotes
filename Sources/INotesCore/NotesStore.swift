import Foundation

// Separators used between AppleScript output fields and records.
// Body text may contain newlines and tabs, so we use unique delimiters.
private let fieldSep = "<<F>>"
private let recordSep = "<<R>>"
private let newlinePlaceholder = "<<NL>>"


/// Helper AppleScript snippet that sanitizes a note's plaintext body.
/// Replaces newlines with a placeholder so they don't break record parsing.
private let sanitizeBody = """
  set noteBody to my replaceText(noteBody, linefeed, "\(newlinePlaceholder)")
  set noteBody to my replaceText(noteBody, return, "\(newlinePlaceholder)")
  """

/// AppleScript text replacement subroutine.
private let replaceTextHandler = """
  on replaceText(theText, old, new)
    set {TID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, old}
    set parts to text items of theText
    set AppleScript's text item delimiters to new
    set theText to parts as text
    set AppleScript's text item delimiters to TID
    return theText
  end replaceText
  """

/// Main interface to Apple Notes via AppleScript
public actor NotesStore {
  private let scriptRunner: ScriptRunner

  public init() {
    self.scriptRunner = ScriptRunner()
  }

  // MARK: - Accounts

  /// Lists all accounts in Notes
  public func accounts() async throws -> [NoteAccount] {
    let script = """
      tell application "Notes"
        set output to ""
        repeat with a in accounts
          set output to output & (id of a) & "\(fieldSep)" & (name of a) & "\(recordSep)"
        end repeat
        return output
      end tell
      """

    let result = try await scriptRunner.run(script)
    guard !result.isEmpty else { return [] }

    return result.components(separatedBy: recordSep).compactMap { record in
      let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      let parts = trimmed.components(separatedBy: fieldSep)
      guard parts.count >= 2 else { return nil }
      return NoteAccount(id: parts[0], name: parts[1])
    }
  }

  // MARK: - Folders

  /// Lists all folders in Notes
  public func folders() async throws -> [NoteFolder] {
    let script = """
      tell application "Notes"
        set output to ""
        repeat with f in folders
          set folderID to id of f
          set folderName to name of f
          set folderCount to count of notes in f
          set output to output & folderID & "\(fieldSep)" & folderName & "\(fieldSep)" & folderCount & "\(recordSep)"
        end repeat
        return output
      end tell
      """

    let result = try await scriptRunner.run(script)
    return parseFolders(result)
  }

  /// Creates a new folder in Notes
  public func createFolder(name: String, in accountName: String? = nil) async throws -> NoteFolder {
    let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
    let script: String

    if let accountName = accountName {
      let escapedAccount = accountName.replacingOccurrences(of: "\"", with: "\\\"")
      script = """
        tell application "Notes"
          try
            set targetAccount to account "\(escapedAccount)"
          on error
            error "Account not found: \(escapedAccount)"
          end try
          set newFolder to make new folder at targetAccount with properties {name:"\(escapedName)"}
          set folderID to id of newFolder
          set folderName to name of newFolder
          set folderCount to count of notes in newFolder
          return folderID & "\(fieldSep)" & folderName & "\(fieldSep)" & folderCount
        end tell
        """
    } else {
      script = """
        tell application "Notes"
          set newFolder to make new folder with properties {name:"\(escapedName)"}
          set folderID to id of newFolder
          set folderName to name of newFolder
          set folderCount to count of notes in newFolder
          return folderID & "\(fieldSep)" & folderName & "\(fieldSep)" & folderCount
        end tell
        """
    }

    let result = try await scriptRunner.run(script)
    let folders = parseFolders(result)
    guard let folder = folders.first else {
      throw INotesError.operationFailed("Failed to create folder")
    }
    return folder
  }

  // MARK: - Notes

  /// Lists notes in a folder (or all notes if folder is nil)
  public func notes(in folder: String? = nil, limit: Int = 100) async throws -> [NoteItem] {
    let script: String

    if let folder = folder {
      let escapedFolder = folder.replacingOccurrences(of: "\"", with: "\\\"")
      script = """
        tell application "Notes"
          try
            set targetFolder to folder "\(escapedFolder)"
          on error
            error "Folder not found: \(escapedFolder)"
          end try
          set folderLabel to name of targetFolder
          set output to ""
          set counter to 0
          repeat with n in notes of targetFolder
            if counter \u{2265} \(limit) then exit repeat
            try
              set noteID to id of n
              set noteName to name of n
              set noteBody to plaintext of n
              \(sanitizeBody)
              set createdDate to creation date of n
              set modifiedDate to modification date of n
              set output to output & noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderLabel & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate & "\(recordSep)"
              set counter to counter + 1
            end try
          end repeat
          return output
        end tell
        \(replaceTextHandler)
        """
    } else {
      script = """
        tell application "Notes"
          set output to ""
          set counter to 0
          repeat with f in folders
            try
              set folderName to name of f
              repeat with n in notes of f
                if counter \u{2265} \(limit) then exit repeat
                try
                  set noteID to id of n
                  set noteName to name of n
                  set noteBody to plaintext of n
                  \(sanitizeBody)
                  set createdDate to creation date of n
                  set modifiedDate to modification date of n
                  set output to output & noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderName & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate & "\(recordSep)"
                  set counter to counter + 1
                end try
              end repeat
            end try
            if counter \u{2265} \(limit) then exit repeat
          end repeat
          return output
        end tell
        \(replaceTextHandler)
        """
    }

    let result = try await scriptRunner.run(script)
    return parseNotes(result)
  }

  /// Gets a single note by ID
  public func note(id: String) async throws -> NoteItem {
    let escapedID = id.replacingOccurrences(of: "\"", with: "\\\"")
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
        \(sanitizeBody)
        set folderName to "Notes"
        try
          set folderName to name of container of targetNote
        end try
        set createdDate to creation date of targetNote
        set modifiedDate to modification date of targetNote
        return noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderName & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate
      end tell
      \(replaceTextHandler)
      """

    let result = try await scriptRunner.run(script)
    let notes = parseNotes(result)
    guard let note = notes.first else {
      throw INotesError.noteNotFound(id)
    }
    return note
  }

  // MARK: - Create / Update / Delete

  /// Creates a new note
  public func createNote(_ draft: NoteDraft) async throws -> NoteItem {
    let targetFolder = draft.folderName ?? "Notes"
    let escapedFolder = targetFolder.replacingOccurrences(of: "\"", with: "\\\"")
    let escapedTitle = draft.title.replacingOccurrences(of: "\"", with: "\\\"")

    let htmlBody = "<html><body>\(escapeHTML(draft.body))</body></html>"
    let escapedHTML = htmlBody.replacingOccurrences(of: "\"", with: "\\\"")

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
        \(sanitizeBody)
        set folderName to "\(escapedFolder)"
        try
          set folderName to name of container of newNote
        end try
        set createdDate to creation date of newNote
        set modifiedDate to modification date of newNote
        return noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderName & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate
      end tell
      \(replaceTextHandler)
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
    let escapedID = id.replacingOccurrences(of: "\"", with: "\\\"")

    var updateStatements: [String] = []

    if let title = update.title {
      let escaped = title.replacingOccurrences(of: "\"", with: "\\\"")
      updateStatements.append("set name of targetNote to \"\(escaped)\"")
    }

    if let body = update.body {
      let htmlBody = "<html><body>\(escapeHTML(body))</body></html>"
      let escaped = htmlBody.replacingOccurrences(of: "\"", with: "\\\"")
      updateStatements.append("set body of targetNote to \"\(escaped)\"")
    }

    if let folderName = update.folderName {
      let escaped = folderName.replacingOccurrences(of: "\"", with: "\\\"")
      updateStatements.append("""
        try
          set newFolder to folder "\(escaped)"
          move targetNote to newFolder
        on error
          error "Folder not found: \(escaped)"
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
        \(sanitizeBody)
        set folderName to "Notes"
        try
          set folderName to name of container of targetNote
        end try
        set createdDate to creation date of targetNote
        set modifiedDate to modification date of targetNote
        return noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderName & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate
      end tell
      \(replaceTextHandler)
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
    let escapedID = id.replacingOccurrences(of: "\"", with: "\\\"")
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

  // MARK: - Search

  /// Searches for notes by query
  public func search(query: String, in folder: String? = nil) async throws -> [NoteItem] {
    let escapedQuery = query.replacingOccurrences(of: "\"", with: "\\\"")
    let script: String

    if let folder = folder {
      let escapedFolder = folder.replacingOccurrences(of: "\"", with: "\\\"")
      script = """
        tell application "Notes"
          try
            set targetFolder to folder "\(escapedFolder)"
          on error
            error "Folder not found: \(escapedFolder)"
          end try
          set folderLabel to name of targetFolder
          set searchResults to (every note of targetFolder whose name contains "\(escapedQuery)" or plaintext contains "\(escapedQuery)")
          set output to ""
          repeat with n in searchResults
            try
              set noteID to id of n
              set noteName to name of n
              set noteBody to plaintext of n
              \(sanitizeBody)
              set createdDate to creation date of n
              set modifiedDate to modification date of n
              set output to output & noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderLabel & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate & "\(recordSep)"
            end try
          end repeat
          return output
        end tell
        \(replaceTextHandler)
        """
    } else {
      script = """
        tell application "Notes"
          set output to ""
          repeat with f in folders
            try
              set folderLabel to name of f
              set searchResults to (every note of f whose name contains "\(escapedQuery)" or plaintext contains "\(escapedQuery)")
              repeat with n in searchResults
                try
                  set noteID to id of n
                  set noteName to name of n
                  set noteBody to plaintext of n
                  \(sanitizeBody)
                  set createdDate to creation date of n
                  set modifiedDate to modification date of n
                  set output to output & noteID & "\(fieldSep)" & noteName & "\(fieldSep)" & noteBody & "\(fieldSep)" & folderLabel & "\(fieldSep)" & createdDate & "\(fieldSep)" & modifiedDate & "\(recordSep)"
                end try
              end repeat
            end try
          end repeat
          return output
        end tell
        \(replaceTextHandler)
        """
    }

    let result = try await scriptRunner.run(script)
    return parseNotes(result)
  }

  // MARK: - Private Helpers

  private func parseFolders(_ output: String) -> [NoteFolder] {
    guard !output.isEmpty else { return [] }

    return output.components(separatedBy: recordSep).compactMap { record in
      let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }

      let parts = trimmed.components(separatedBy: fieldSep)
      guard parts.count >= 3 else { return nil }

      return NoteFolder(id: parts[0], name: parts[1], noteCount: Int(parts[2]) ?? 0)
    }
  }

  private func parseNotes(_ output: String) -> [NoteItem] {
    guard !output.isEmpty else { return [] }

    return output.components(separatedBy: recordSep).compactMap { record in
      let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }

      let parts = trimmed.components(separatedBy: fieldSep)
      guard parts.count >= 6 else { return nil }

      let id = parts[0]
      let title = parts[1]
      let body = parts[2].replacingOccurrences(of: newlinePlaceholder, with: "\n")
      let folder = parts[3]
      let createdDateStr = parts[4]
      let modifiedDateStr = parts[5]

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

  private func escapeHTML(_ text: String) -> String {
    return text
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "\n", with: "<br>")
  }
}
