import Testing
import Commander

@testable import inotes

@MainActor
struct HelpPrinterTests {
  // MARK: - Root Help Tests

  @Test("Root help contains tool name")
  func rootHelpContainsToolName() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "0.0.0", rootName: "inotes", commands: specs)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("inotes"))
  }

  @Test("Root help contains version")
  func rootHelpContainsVersion() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "1.2.3", rootName: "inotes", commands: specs)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("1.2.3"))
  }

  @Test("Root help contains description")
  func rootHelpContainsDescription() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "0.0.0", rootName: "inotes", commands: specs)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Apple Notes"))
  }

  @Test("Root help lists all commands")
  func rootHelpListsAllCommands() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "0.0.0", rootName: "inotes", commands: specs)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("show"))
    #expect(joined.contains("read"))
    #expect(joined.contains("add"))
    #expect(joined.contains("edit"))
    #expect(joined.contains("delete"))
    #expect(joined.contains("search"))
    #expect(joined.contains("folders"))
    #expect(joined.contains("status"))
  }

  @Test("Root help includes usage section")
  func rootHelpIncludesUsage() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "0.0.0", rootName: "inotes", commands: specs)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Usage:"))
    #expect(joined.contains("[command]"))
    #expect(joined.contains("[options]"))
  }

  @Test("Root help includes help hint")
  func rootHelpIncludesHelpHint() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "0.0.0", rootName: "inotes", commands: specs)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("--help"))
  }

  @Test("Root help has non-empty output")
  func rootHelpNonEmpty() {
    let specs = allCommandSpecs()
    let lines = HelpPrinter.renderRoot(version: "0.0.0", rootName: "inotes", commands: specs)

    #expect(lines.isEmpty == false)
    #expect(lines.count > 5)
  }

  @Test("Root help with empty commands list")
  func rootHelpEmptyCommands() {
    let lines = HelpPrinter.renderRoot(version: "1.0.0", rootName: "test", commands: [])

    #expect(lines.isEmpty == false)
    #expect(lines.joined(separator: "\n").contains("test"))
    #expect(lines.joined(separator: "\n").contains("1.0.0"))
  }

  // MARK: - Command Help Tests

  @Test("Command help contains command name")
  func commandHelpContainsName() {
    let spec = mockCommandSpec()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("test-command"))
  }

  @Test("Command help contains abstract")
  func commandHelpContainsAbstract() {
    let spec = mockCommandSpec()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Test command description"))
  }

  @Test("Command help contains discussion when present")
  func commandHelpContainsDiscussion() {
    let spec = mockCommandSpec(discussion: "This is a longer discussion about the command.")
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("longer discussion"))
  }

  @Test("Command help skips empty discussion")
  func commandHelpSkipsEmptyDiscussion() {
    let spec = mockCommandSpec(discussion: "")
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)

    // Should not have extra blank lines for discussion
    let nonEmptyLines = lines.filter { !$0.isEmpty }
    #expect(nonEmptyLines.count > 0)
  }

  @Test("Command help includes usage section")
  func commandHelpIncludesUsage() {
    let spec = mockCommandSpec()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Usage:"))
    #expect(joined.contains("inotes test-command"))
  }

  @Test("Command help lists arguments when present")
  func commandHelpListsArguments() {
    let spec = mockCommandSpecWithArguments()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Arguments:"))
    #expect(joined.contains("test-arg"))
  }

  @Test("Command help lists options when present")
  func commandHelpListsOptions() {
    let spec = mockCommandSpecWithOptions()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Options:"))
  }

  @Test("Command help lists flags when present")
  func commandHelpListsFlags() {
    let spec = mockCommandSpecWithFlags()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Options:"))
  }

  @Test("Command help includes examples when present")
  func commandHelpIncludesExamples() {
    let spec = mockCommandSpecWithExamples()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)
    let joined = lines.joined(separator: "\n")

    #expect(joined.contains("Examples:"))
    #expect(joined.contains("example command 1"))
    #expect(joined.contains("example command 2"))
  }

  @Test("Command help has non-empty output")
  func commandHelpNonEmpty() {
    let spec = mockCommandSpec()
    let lines = HelpPrinter.renderCommand(rootName: "inotes", spec: spec)

    #expect(lines.isEmpty == false)
  }

  // MARK: - Helper Methods

  private func allCommandSpecs() -> [CommandSpec] {
    [
      mockCommandSpec(name: "show"),
      mockCommandSpec(name: "read"),
      mockCommandSpec(name: "add"),
      mockCommandSpec(name: "edit"),
      mockCommandSpec(name: "delete"),
      mockCommandSpec(name: "search"),
      mockCommandSpec(name: "folders"),
      mockCommandSpec(name: "status"),
    ]
  }

  private func mockCommandSpec(
    name: String = "test-command",
    discussion: String? = nil
  ) -> CommandSpec {
    CommandSpec(
      name: name,
      abstract: "Test command description",
      discussion: discussion,
      signature: CommandSignature(arguments: [], options: [], flags: [], optionGroups: []),
      usageExamples: [],
      run: { _, _ in }
    )
  }

  private func mockCommandSpecWithArguments() -> CommandSpec {
    CommandSpec(
      name: "test-command",
      abstract: "Test command",
      discussion: nil,
      signature: CommandSignature(
        arguments: [
          .make(label: "test-arg", help: "Test argument", isOptional: false)
        ],
        options: [],
        flags: [],
        optionGroups: []
      ),
      usageExamples: [],
      run: { _, _ in }
    )
  }

  private func mockCommandSpecWithOptions() -> CommandSpec {
    CommandSpec(
      name: "test-command",
      abstract: "Test command",
      discussion: nil,
      signature: CommandSignature(
        arguments: [],
        options: [
          .make(label: "test-option", names: [.long("test")], help: "Test option", parsing: .singleValue)
        ],
        flags: [],
        optionGroups: []
      ),
      usageExamples: [],
      run: { _, _ in }
    )
  }

  private func mockCommandSpecWithFlags() -> CommandSpec {
    CommandSpec(
      name: "test-command",
      abstract: "Test command",
      discussion: nil,
      signature: CommandSignature(
        arguments: [],
        options: [],
        flags: [
          .make(label: "test-flag", names: [.short("t"), .long("test")], help: "Test flag")
        ],
        optionGroups: []
      ),
      usageExamples: [],
      run: { _, _ in }
    )
  }

  private func mockCommandSpecWithExamples() -> CommandSpec {
    CommandSpec(
      name: "test-command",
      abstract: "Test command",
      discussion: nil,
      signature: CommandSignature(arguments: [], options: [], flags: [], optionGroups: []),
      usageExamples: [
        "inotes test-command example command 1",
        "inotes test-command example command 2",
      ],
      run: { _, _ in }
    )
  }
}
