import Commander
import Foundation
import INotesCore

enum SearchCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "search",
      abstract: "Search notes by title or content",
      discussion: "Searches both note titles and body text.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(label: "query", help: "Search query", isOptional: false)
          ],
          options: [
            .make(
              label: "folder",
              names: [.short("f"), .long("folder")],
              help: "Restrict to folder",
              parsing: .singleValue
            ),
            .make(
              label: "limit",
              names: [.short("l"), .long("limit")],
              help: "Maximum number of results",
              parsing: .singleValue
            ),
          ]
        )
      ),
      usageExamples: [
        "inotes search \"meeting\"",
        "inotes search \"project ideas\" --folder Work",
        "inotes search \"TODO\" --limit 10",
      ]
    ) { values, runtime in
      guard let query = values.argument(0), !query.isEmpty else {
        throw ParsedValuesError.missingArgument("query")
      }

      let folderName = values.option("folder")
      let limitString = values.option("limit")

      let limit: Int
      if let limitString {
        guard let parsed = Int(limitString), parsed > 0 else {
          throw INotesError.operationFailed("Invalid limit value")
        }
        limit = parsed
      } else {
        limit = 20
      }

      let store = NotesStore()
      var notes = try await store.search(query: query, in: folderName)
      notes = try await AccountFilter.apply(runtime: runtime, store: store, notes: notes)
      let limited = Array(notes.prefix(limit))
      OutputRenderer.printNotes(limited, format: runtime.outputFormat)
    }
  }
}
