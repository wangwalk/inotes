import Commander

struct RuntimeOptions: Sendable {
  let jsonOutput: Bool
  let plainOutput: Bool
  let quiet: Bool
  let noColor: Bool
  let noInput: Bool
  let allAccounts: Bool
  let accountName: String?

  init(parsedValues: ParsedValues) {
    self.jsonOutput = parsedValues.flags.contains("jsonOutput")
    self.plainOutput = parsedValues.flags.contains("plainOutput")
    self.quiet = parsedValues.flags.contains("quiet")
    self.noColor = parsedValues.flags.contains("noColor")
    self.noInput = parsedValues.flags.contains("noInput")
    self.allAccounts = parsedValues.flags.contains("allAccounts")
    self.accountName = parsedValues.option("account")
  }

  var outputFormat: OutputFormat {
    if jsonOutput { return .json }
    if plainOutput { return .plain }
    if quiet { return .quiet }
    return .standard
  }
}
