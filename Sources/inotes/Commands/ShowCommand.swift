import Commander
import Foundation
import INotesCore

enum ShowCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "show",
      abstract: "Show notes",
      discussion: "Filters: all, today, week, recent.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(
              label: "filter",
              help: "all|today|week|recent",
              isOptional: true
            )
          ],
          options: [
            .make(
              label: "folder",
              names: [.short("f"), .long("folder")],
              help: "Limit to a specific folder",
              parsing: .singleValue
            ),
            .make(
              label: "limit",
              names: [.short("l"), .long("limit")],
              help: "Maximum number of notes to show",
              parsing: .singleValue
            ),
          ]
        )
      ),
      usageExamples: [
        "inotes",
        "inotes today",
        "inotes show all",
        "inotes show --folder Work",
        "inotes show recent --limit 10",
      ]
    ) { values, runtime in
      let folderName = values.option("folder")
      let filterToken = values.argument(0)
      let limitString = values.option("limit")

      let filter: NoteFilter
      if let token = filterToken {
        guard let parsed = NoteFiltering.parse(token) else {
          throw INotesError.operationFailed("Unknown filter: \"\(token)\"")
        }
        filter = parsed
      } else {
        filter = .recent
      }

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
      var notes = try await store.notes(in: folderName, limit: limit)
      notes = try await AccountFilter.apply(runtime: runtime, store: store, notes: notes)
      let filtered = filter.apply(to: notes)
      OutputRenderer.printNotes(filtered, format: runtime.outputFormat)
    }
  }
}
