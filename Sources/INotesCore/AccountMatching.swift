import Foundation

/// Helpers for matching notes/folders to accounts via shared UUID prefixes in x-coredata IDs.
///
/// Apple Notes IDs follow the pattern:
///   x-coredata://<UUID>/<type>/<id>
///
/// The UUID portion is shared across accounts, folders, and notes that belong to the same account.
public enum AccountMatching {

  /// Extracts the UUID prefix from an x-coredata:// style ID.
  /// Returns nil if the ID doesn't match the expected format.
  public static func extractUUID(from id: String) -> String? {
    // Format: x-coredata://UUID/Type/...
    guard id.hasPrefix("x-coredata://") else { return nil }
    let afterPrefix = id.dropFirst("x-coredata://".count)
    guard let slashIndex = afterPrefix.firstIndex(of: "/") else { return nil }
    let uuid = String(afterPrefix[afterPrefix.startIndex..<slashIndex])
    return uuid.isEmpty ? nil : uuid
  }

  /// Filters notes by matching their account UUID to the given accounts.
  public static func filterNotes(
    _ notes: [NoteItem],
    byAccountName name: String,
    accounts: [NoteAccount]
  ) -> [NoteItem] {
    let uuids = matchingUUIDs(for: name, in: accounts)
    guard !uuids.isEmpty else { return [] }
    return notes.filter { note in
      guard let noteUUID = note.accountUUID else { return false }
      return uuids.contains(noteUUID)
    }
  }

  /// Filters folders by matching their account UUID to the given accounts.
  public static func filterFolders(
    _ folders: [NoteFolder],
    byAccountName name: String,
    accounts: [NoteAccount]
  ) -> [NoteFolder] {
    let uuids = matchingUUIDs(for: name, in: accounts)
    guard !uuids.isEmpty else { return [] }
    return folders.filter { folder in
      guard let folderUUID = folder.accountUUID else { return false }
      return uuids.contains(folderUUID)
    }
  }

  /// Finds the account UUIDs that match the given name (case-insensitive substring match).
  private static func matchingUUIDs(for name: String, in accounts: [NoteAccount]) -> Set<String> {
    let lowered = name.lowercased()
    var uuids = Set<String>()
    for account in accounts {
      if account.name.lowercased().contains(lowered) {
        if let uuid = extractUUID(from: account.id) {
          uuids.insert(uuid)
        }
      }
    }
    return uuids
  }
}
