import INotesCore

/// Shared account filtering logic used across commands.
///
/// Priority:
/// 1. `--account <name>` — filter by specific account name
/// 2. `--all-accounts` — include all accounts
/// 3. Default — iCloud only
enum AccountFilter {
  static func apply(
    runtime: RuntimeOptions,
    store: NotesStore,
    notes: [NoteItem]
  ) async throws -> [NoteItem] {
    var result: [NoteItem]
    if let accountName = runtime.accountName {
      let accounts = try await store.accounts()
      result = AccountMatching.filterNotes(notes, byAccountName: accountName, accounts: accounts)
      if result.isEmpty && !notes.isEmpty {
        let hasMatch = accounts.contains { $0.name.lowercased().contains(accountName.lowercased()) }
        if !hasMatch {
          throw INotesError.accountNotFound(accountName)
        }
      }
    } else if runtime.allAccounts {
      result = notes
    } else {
      result = notes.filter(\.isICloud)
    }
    return result.filter { !$0.isDeleted }
  }

  static func apply(
    runtime: RuntimeOptions,
    store: NotesStore,
    folders: [NoteFolder]
  ) async throws -> [NoteFolder] {
    var result: [NoteFolder]
    if let accountName = runtime.accountName {
      let accounts = try await store.accounts()
      result = AccountMatching.filterFolders(folders, byAccountName: accountName, accounts: accounts)
      if result.isEmpty && !folders.isEmpty {
        let hasMatch = accounts.contains { $0.name.lowercased().contains(accountName.lowercased()) }
        if !hasMatch {
          throw INotesError.accountNotFound(accountName)
        }
      }
    } else if runtime.allAccounts {
      result = folders
    } else {
      result = folders.filter(\.isICloud)
    }
    return result.filter { !TrashFolder.isTrashName($0.name) }
  }
}
