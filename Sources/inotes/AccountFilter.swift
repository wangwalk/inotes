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
    if let accountName = runtime.accountName {
      let accounts = try await store.accounts()
      let filtered = AccountMatching.filterNotes(notes, byAccountName: accountName, accounts: accounts)
      if filtered.isEmpty && !notes.isEmpty {
        // Check if the account name matches any account at all
        let hasMatch = accounts.contains { $0.name.lowercased().contains(accountName.lowercased()) }
        if !hasMatch {
          throw INotesError.accountNotFound(accountName)
        }
      }
      return filtered
    } else if runtime.allAccounts {
      return notes
    } else {
      return notes.filter(\.isICloud)
    }
  }

  static func apply(
    runtime: RuntimeOptions,
    store: NotesStore,
    folders: [NoteFolder]
  ) async throws -> [NoteFolder] {
    if let accountName = runtime.accountName {
      let accounts = try await store.accounts()
      let filtered = AccountMatching.filterFolders(folders, byAccountName: accountName, accounts: accounts)
      if filtered.isEmpty && !folders.isEmpty {
        let hasMatch = accounts.contains { $0.name.lowercased().contains(accountName.lowercased()) }
        if !hasMatch {
          throw INotesError.accountNotFound(accountName)
        }
      }
      return filtered
    } else if runtime.allAccounts {
      return folders
    } else {
      return folders.filter(\.isICloud)
    }
  }
}
