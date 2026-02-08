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
      let folders = try await store.folders()

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
