import Commander
import Foundation
import INotesCore

enum MkfolderCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "mkfolder",
      abstract: "Create a new folder",
      discussion: "Creates a new folder in Notes.app.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(
              label: "name",
              help: "Name for the new folder"
            )
          ]
        )
      ),
      usageExamples: [
        "inotes mkfolder Projects",
        "inotes mkfolder Work --account Exchange",
        "inotes mkfolder Ideas --json",
      ]
    ) { values, runtime in
      guard let name = values.argument(0) else {
        throw INotesError.operationFailed("Folder name is required")
      }

      let store = NotesStore()
      let folder = try await store.createFolder(name: name, in: runtime.accountName)
      let summary = FolderSummary(id: folder.id, name: folder.name, noteCount: folder.noteCount)
      OutputRenderer.printFolders([summary], format: runtime.outputFormat)
    }
  }
}
