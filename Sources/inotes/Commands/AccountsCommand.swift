import Commander
import Foundation
import INotesCore

enum AccountsCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "accounts",
      abstract: "List all note accounts",
      discussion: "Shows available accounts (iCloud, Exchange, IMAP, etc.).",
      signature: CommandSignatures.withRuntimeFlags(CommandSignature()),
      usageExamples: [
        "inotes accounts",
        "inotes accounts --json",
      ]
    ) { _, runtime in
      let store = NotesStore()
      let accounts = try await store.accounts()
      OutputRenderer.printAccounts(accounts, format: runtime.outputFormat)
    }
  }
}
