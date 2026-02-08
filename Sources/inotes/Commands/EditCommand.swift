import Commander
import Foundation
import INotesCore

enum EditCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "edit",
      abstract: "Modify a note",
      discussion: "Use an index or ID prefix from the show output.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(label: "id", help: "Index or ID prefix", isOptional: false)
          ],
          options: [
            .make(
              label: "title",
              names: [.short("t"), .long("title")],
              help: "New title",
              parsing: .singleValue
            ),
            .make(
              label: "body",
              names: [.short("b"), .long("body")],
              help: "New body content",
              parsing: .singleValue
            ),
            .make(
              label: "folder",
              names: [.short("f"), .long("folder")],
              help: "Move to folder",
              parsing: .singleValue
            ),
          ]
        )
      ),
      usageExamples: [
        "inotes edit 1 --title \"Updated title\"",
        "inotes edit A3F2 --body \"New content here\"",
        "inotes edit 2 --folder Projects",
        "inotes edit 5 -t \"Title\" -b \"Body\" -f Work",
      ]
    ) { values, runtime in
      guard let input = values.argument(0) else {
        throw ParsedValuesError.missingArgument("id")
      }

      let title = values.option("title")
      let body = values.option("body")
      let folderName = values.option("folder")

      if title == nil && body == nil && folderName == nil {
        throw INotesError.operationFailed("No changes specified")
      }

      let store = NotesStore()
      let notes = try await store.notes(in: nil, limit: 100)
      let resolved = try IDResolver.resolve([input], from: notes)

      guard let note = resolved.first else {
        throw INotesError.noteNotFound(input)
      }

      let update = NoteUpdate(
        title: title,
        body: body,
        folderName: folderName
      )

      let updated = try await store.updateNote(id: note.id, update)
      OutputRenderer.printNote(updated, format: runtime.outputFormat)
    }
  }
}
