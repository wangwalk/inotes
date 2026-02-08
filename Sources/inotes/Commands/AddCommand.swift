import Commander
import Foundation
import INotesCore

enum AddCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "add",
      abstract: "Create a new note",
      discussion: "Provide a title and optional body. Defaults to the default Notes folder.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          options: [
            .make(
              label: "title",
              names: [.short("t"), .long("title")],
              help: "Note title",
              parsing: .singleValue
            ),
            .make(
              label: "body",
              names: [.short("b"), .long("body")],
              help: "Note body content",
              parsing: .singleValue
            ),
            .make(
              label: "folder",
              names: [.short("f"), .long("folder")],
              help: "Folder name",
              parsing: .singleValue
            ),
          ]
        )
      ),
      usageExamples: [
        "inotes add --title \"Meeting notes\"",
        "inotes add -t \"Ideas\" -b \"Draft outline\" -f Projects",
        "inotes add --title \"Shopping list\" --body \"Milk, bread, eggs\"",
      ]
    ) { values, runtime in
      var title = values.option("title")
      if title == nil {
        if runtime.noInput || !Console.isTTY {
          throw INotesError.operationFailed("Missing title. Provide it via --title.")
        }
        title = Console.readLine(prompt: "Title:")?.trimmingCharacters(in: .whitespacesAndNewlines)
        if title?.isEmpty == true { title = nil }
      }

      guard let title, !title.isEmpty else {
        throw INotesError.operationFailed("Missing title.")
      }

      var body = values.option("body")
      if body == nil && !runtime.noInput && Console.isTTY {
        body = Console.readLine(prompt: "Body (optional):")?.trimmingCharacters(in: .whitespacesAndNewlines)
        if body?.isEmpty == true { body = nil }
      }

      var folderName = values.option("folder")
      if folderName == nil && !runtime.noInput && Console.isTTY {
        folderName = Console.readLine(prompt: "Folder (optional):")?.trimmingCharacters(in: .whitespacesAndNewlines)
        if folderName?.isEmpty == true { folderName = nil }
      }

      let draft = NoteDraft(
        title: title,
        body: body ?? "",
        folderName: folderName
      )

      let store = NotesStore()
      let note = try await store.createNote(draft)
      OutputRenderer.printNote(note, format: runtime.outputFormat)
    }
  }
}
