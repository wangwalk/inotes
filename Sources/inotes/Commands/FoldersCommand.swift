import Commander
import Foundation
import INotesCore

enum FoldersCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "folders",
      abstract: "List all note folders",
      discussion: "Shows all folders with their note counts.",
      signature: CommandSignatures.withRuntimeFlags(CommandSignature()),
      usageExamples: [
        "inotes folders",
        "inotes folders --json",
      ]
    ) { _, runtime in
      let store = NotesStore()
      var folders = try await store.folders()
      folders = try await AccountFilter.apply(runtime: runtime, store: store, folders: folders)

      let summaries = folders.map { folder in
        FolderSummary(
          id: folder.id,
          name: folder.name,
          noteCount: folder.noteCount
        )
      }

      OutputRenderer.printFolders(summaries, format: runtime.outputFormat)
    }
  }
}
