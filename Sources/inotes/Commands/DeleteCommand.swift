import Commander
import Foundation
import INotesCore

enum DeleteCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "delete",
      abstract: "Delete a note",
      discussion: "Use an index or ID prefix from show output.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(label: "id", help: "Index or ID prefix", isOptional: false)
          ],
          flags: [
            .make(
              label: "dryRun",
              names: [.short("n"), .long("dry-run")],
              help: "Preview without changes"
            ),
            .make(
              label: "force",
              names: [.short("f"), .long("force")],
              help: "Skip confirmation"
            ),
          ]
        )
      ),
      usageExamples: [
        "inotes delete 1",
        "inotes delete A3F2",
        "inotes delete 5 --force",
        "inotes delete 2 --dry-run",
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

      if values.flag("dryRun") {
        OutputRenderer.printNote(note, format: runtime.outputFormat)
        return
      }

      if !values.flag("force") && !runtime.noInput && Console.isTTY {
        let prompt = "Delete note \"\(note.title)\"?"
        if !Console.confirm(prompt, defaultValue: false) {
          return
        }
      }

      try await store.deleteNote(id: note.id)
      OutputRenderer.printDeleteResult(1, format: runtime.outputFormat)
    }
  }
}
