import Foundation
import INotesCore

enum OutputFormat {
  case standard
  case plain
  case json
  case quiet
}

struct FolderSummary: Codable, Sendable, Equatable {
  let id: String
  let name: String
  let noteCount: Int
}

enum OutputRenderer {
  static func printNotes(_ notes: [NoteItem], format: OutputFormat) {
    switch format {
    case .standard:
      printNotesStandard(notes)
    case .plain:
      printNotesPlain(notes)
    case .json:
      printJSON(notes)
    case .quiet:
      Swift.print(notes.count)
    }
  }

  static func printFolders(_ summaries: [FolderSummary], format: OutputFormat) {
    switch format {
    case .standard:
      printFoldersStandard(summaries)
    case .plain:
      printFoldersPlain(summaries)
    case .json:
      printJSON(summaries)
    case .quiet:
      Swift.print(summaries.count)
    }
  }

  static func printNote(_ note: NoteItem, format: OutputFormat, fullContent: Bool = false) {
    switch format {
    case .standard:
      printNoteStandard(note, fullContent: fullContent)
    case .plain:
      Swift.print(plainLine(for: note))
    case .json:
      printJSON(note)
    case .quiet:
      break
    }
  }

  static func printDeleteResult(_ count: Int, format: OutputFormat) {
    switch format {
    case .standard:
      Swift.print("Deleted \(count) note(s)")
    case .plain:
      Swift.print("\(count)")
    case .json:
      let payload = ["deleted": count]
      printJSON(payload)
    case .quiet:
      break
    }
  }

  private static func printNotesStandard(_ notes: [NoteItem]) {
    guard !notes.isEmpty else {
      Swift.print("No notes found")
      return
    }
    for (index, note) in notes.enumerated() {
      let date = formatDate(note.modificationDate)
      Swift.print("[\(index + 1)] \(note.title) — \(note.folder) — \(date)")
    }
  }

  private static func printNotesPlain(_ notes: [NoteItem]) {
    for note in notes {
      Swift.print(plainLine(for: note))
    }
  }

  private static func plainLine(for note: NoteItem) -> String {
    let created = isoFormatter().string(from: note.creationDate)
    let modified = isoFormatter().string(from: note.modificationDate)
    return [
      note.id,
      note.folder,
      created,
      modified,
      note.title,
    ].joined(separator: "\t")
  }

  private static func printNoteStandard(_ note: NoteItem, fullContent: Bool) {
    Swift.print("Title: \(note.title)")
    Swift.print("Folder: \(note.folder)")
    Swift.print("Created: \(formatDate(note.creationDate))")
    Swift.print("Modified: \(formatDate(note.modificationDate))")
    Swift.print("")
    if fullContent {
      Swift.print(note.body)
    }
  }

  private static func printFoldersStandard(_ summaries: [FolderSummary]) {
    guard !summaries.isEmpty else {
      Swift.print("No folders found")
      return
    }
    for (index, folder) in summaries.enumerated() {
      let plural = folder.noteCount == 1 ? "note" : "notes"
      Swift.print("[\(index + 1)] \(folder.name) (\(folder.noteCount) \(plural))")
    }
  }

  private static func printFoldersPlain(_ summaries: [FolderSummary]) {
    for folder in summaries {
      Swift.print("\(folder.name)\t\(folder.noteCount)")
    }
  }

  private static func printJSON<T: Encodable>(_ payload: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(payload)
      if let json = String(data: data, encoding: .utf8) {
        Swift.print(json)
      }
    } catch {
      Swift.print("Failed to encode JSON: \(error)")
    }
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  private static func isoFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }
}
