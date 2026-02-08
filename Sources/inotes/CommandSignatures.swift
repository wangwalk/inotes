import Commander

enum CommandSignatures {
  static func runtimeFlags() -> [FlagDefinition] {
    [
      .make(
        label: "jsonOutput",
        names: [.short("j"), .long("json"), .aliasLong("json-output"), .aliasLong("jsonOutput")],
        help: "Emit machine-readable JSON output"
      ),
      .make(
        label: "plainOutput",
        names: [.long("plain")],
        help: "Emit stable tab-separated output"
      ),
      .make(
        label: "quiet",
        names: [.short("q"), .long("quiet")],
        help: "Only emit count output"
      ),
      .make(
        label: "noColor",
        names: [.long("no-color")],
        help: "Disable colored output"
      ),
      .make(
        label: "noInput",
        names: [.long("no-input")],
        help: "Disable interactive prompts"
      ),
      .make(
        label: "allAccounts",
        names: [.long("all-accounts")],
        help: "Include notes from all accounts (default: iCloud only)"
      ),
    ]
  }

  static func runtimeOptions() -> [OptionDefinition] {
    [
      .make(
        label: "account",
        names: [.short("a"), .long("account")],
        help: "Filter by account name (e.g. iCloud, Exchange)",
        parsing: .singleValue
      ),
    ]
  }

  static func withRuntimeFlags(_ signature: CommandSignature) -> CommandSignature {
    CommandSignature(
      arguments: signature.arguments,
      options: signature.options + runtimeOptions(),
      flags: signature.flags + runtimeFlags(),
      optionGroups: signature.optionGroups
    )
  }
}
