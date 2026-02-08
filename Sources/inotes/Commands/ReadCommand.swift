import Commander
import Foundation
import INotesCore

enum ReadCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "read",
      abstract: "Show full note content",
      discussion: "Use an index (1, 2, 3) or ID prefix from the show output.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(label: "id", help: "Index or ID prefix", isOptional: false)
          ]
        )
      ),
      usageExamples: [
        "inotes read 1",
        "inotes read A3F2",
        "inotes read 5 --json",
      ]
    ) { values, runtime in
      guard let input = values.argument(0) else {
        throw ParsedValuesError.missingArgument("id")
      }

      let store = NotesStore()
      var notes = try await store.notes(in: nil, limit: 100)
      if !runtime.allAccounts { notes = notes.filter(\.isICloud) }
      let resolved = try IDResolver.resolve([input], from: notes)

      guard let note = resolved.first else {
        throw INotesError.noteNotFound(input)
      }

      OutputRenderer.printNote(note, format: runtime.outputFormat, fullContent: true)
    }
  }
}
