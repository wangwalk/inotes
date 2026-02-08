import Commander
import Foundation
import INotesCore

struct CommandRouter {
  let rootName = "inotes"
  let version: String
  let specs: [CommandSpec]
  let program: Program

  init() {
    self.version = CommandRouter.resolveVersion()
    self.specs = [
      ShowCommand.spec,
      FoldersCommand.spec,
      AccountsCommand.spec,
      ReadCommand.spec,
      AddCommand.spec,
      EditCommand.spec,
      DeleteCommand.spec,
      SearchCommand.spec,
      StatusCommand.spec,
    ]
    let descriptor = CommandDescriptor(
      name: rootName,
      abstract: "Manage Apple Notes from the terminal",
      discussion: nil,
      signature: CommandSignature(),
      subcommands: specs.map { $0.descriptor },
      defaultSubcommandName: "show"
    )
    self.program = Program(descriptors: [descriptor])
  }

  func run() async -> Int32 {
    await run(argv: CommandLine.arguments)
  }

  func run(argv: [String]) async -> Int32 {
    var argv = normalizeArguments(argv)

    if argv.contains("--version") || argv.contains("-V") {
      Swift.print(version)
      return 0
    }

    if argv.contains("--help") || argv.contains("-h") {
      printHelp(for: argv)
      return 0
    }

    argv = rewriteImplicitShow(argv)

    do {
      let invocation = try program.resolve(argv: argv)
      guard let commandName = invocation.path.last,
        let spec = specs.first(where: { $0.name == commandName })
      else {
        Console.printError("Unknown command")
        HelpPrinter.printRoot(version: version, rootName: rootName, commands: specs)
        return 1
      }
      let runtime = RuntimeOptions(parsedValues: invocation.parsedValues)
      do {
        try await spec.run(invocation.parsedValues, runtime)
        return 0
      } catch let error as INotesError {
        Console.printError(formatError(error))
        return errorCode(for: error)
      } catch {
        Console.printError(error.localizedDescription)
        return 1
      }
    } catch let error as CommanderProgramError {
      Console.printError(error.description)
      if case .missingSubcommand = error {
        HelpPrinter.printRoot(version: version, rootName: rootName, commands: specs)
      }
      return 1
    } catch {
      Console.printError(error.localizedDescription)
      return 1
    }
  }

  private func normalizeArguments(_ argv: [String]) -> [String] {
    guard !argv.isEmpty else { return argv }
    var copy = argv
    copy[0] = URL(fileURLWithPath: argv[0]).lastPathComponent
    return copy
  }

  private func rewriteImplicitShow(_ argv: [String]) -> [String] {
    guard argv.count >= 2 else { return argv }
    let token = argv[1]
    if token.hasPrefix("-") {
      return argv
    }

    let commandNames = Set(specs.map { $0.name })
    if commandNames.contains(token) {
      return argv
    }

    if NoteFiltering.parse(token) != nil {
      var copy = argv
      copy.insert("show", at: 1)
      return copy
    }

    return argv
  }

  private func printHelp(for argv: [String]) {
    let path = helpPath(from: argv)
    if path.count <= 1 {
      HelpPrinter.printRoot(version: version, rootName: rootName, commands: specs)
      return
    }
    if let spec = specs.first(where: { $0.name == path[1] }) {
      HelpPrinter.printCommand(rootName: rootName, spec: spec)
    } else {
      HelpPrinter.printRoot(version: version, rootName: rootName, commands: specs)
    }
  }

  private func helpPath(from argv: [String]) -> [String] {
    var path: [String] = []
    for token in argv {
      if token == "--help" || token == "-h" { continue }
      if token.hasPrefix("-") { break }
      path.append(token)
    }
    return path
  }

  private func formatError(_ error: INotesError) -> String {
    switch error {
    case .permissionDenied:
      return "Permission denied: Notes access not authorized"
    case .noteNotFound(let id):
      return "Note not found: \(id)"
    case .folderNotFound(let name):
      return "Folder not found: \(name)"
    case .accountNotFound(let name):
      return "Account not found: \(name). Use 'inotes accounts' to list available accounts."
    case .ambiguousIdentifier(let input, let matches):
      return "Identifier \"\(input)\" matches multiple notes: \(matches.joined(separator: ", "))"
    case .invalidIdentifier(let input):
      return "Invalid identifier: \(input)"
    case .scriptError(let message):
      return "AppleScript error: \(message)"
    case .operationFailed(let message):
      return message
    }
  }

  private func errorCode(for error: INotesError) -> Int32 {
    switch error {
    case .permissionDenied:
      return 2
    default:
      return 1
    }
  }

  private static func resolveVersion() -> String {
    if let envVersion = ProcessInfo.processInfo.environment["INOTES_VERSION"], !envVersion.isEmpty {
      return envVersion
    }
    return inotesVersion
  }
}
