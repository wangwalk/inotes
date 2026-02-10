import Foundation

/// Represents a note in Apple Notes
public struct NoteItem: Codable, Sendable, Equatable, Identifiable {
  public let id: String
  public let title: String
  public let body: String
  public let folder: String
  public let creationDate: Date
  public let modificationDate: Date

  public init(
    id: String,
    title: String,
    body: String,
    folder: String,
    creationDate: Date,
    modificationDate: Date
  ) {
    self.id = id
    self.title = title
    self.body = body
    self.folder = folder
    self.creationDate = creationDate
    self.modificationDate = modificationDate
  }

  /// Whether this note belongs to the local iCloud account (vs IMAP/Exchange)
  public var isICloud: Bool { id.contains("/ICNote/") }

  /// Whether this note is in the "Recently Deleted" trash folder
  public var isDeleted: Bool { TrashFolder.isTrashName(folder) }

  /// The account UUID prefix extracted from the note ID
  public var accountUUID: String? { AccountMatching.extractUUID(from: id) }
}

/// Represents a folder in Apple Notes
public struct NoteFolder: Codable, Sendable, Equatable, Identifiable {
  public let id: String
  public let name: String
  public let noteCount: Int

  public init(id: String, name: String, noteCount: Int) {
    self.id = id
    self.name = name
    self.noteCount = noteCount
  }

  /// Whether this folder belongs to the local iCloud account (vs IMAP/Exchange)
  public var isICloud: Bool { id.contains("/ICFolder/") }

  /// The account UUID prefix extracted from the folder ID
  public var accountUUID: String? { AccountMatching.extractUUID(from: id) }
}

/// Represents an account in Apple Notes (iCloud, Exchange, IMAP, etc.)
public struct NoteAccount: Codable, Sendable, Equatable, Identifiable {
  public let id: String
  public let name: String

  public init(id: String, name: String) {
    self.id = id
    self.name = name
  }
}

/// Draft for creating a new note
public struct NoteDraft: Sendable {
  public let title: String
  public let body: String
  public let folderName: String?

  public init(title: String, body: String, folderName: String? = nil) {
    self.title = title
    self.body = body
    self.folderName = folderName
  }
}

/// Update object for editing an existing note
public struct NoteUpdate: Sendable {
  public let title: String?
  public let body: String?
  public let folderName: String?

  public init(
    title: String? = nil,
    body: String? = nil,
    folderName: String? = nil
  ) {
    self.title = title
    self.body = body
    self.folderName = folderName
  }
}
