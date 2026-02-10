import Testing

@testable import inotes

@MainActor
struct CommandRouterTests {
  private let router = CommandRouter()

  @Test("Version flag returns success")
  func versionFlagReturnsSuccess() async {
    let code = await router.run(argv: ["inotes", "--version"])
    #expect(code == 0)
  }

  @Test("Short version flag returns success")
  func shortVersionFlagReturnsSuccess() async {
    let code = await router.run(argv: ["inotes", "-V"])
    #expect(code == 0)
  }

  @Test("Help flag returns success")
  func helpFlagReturnsSuccess() async {
    let code = await router.run(argv: ["inotes", "--help"])
    #expect(code == 0)
  }

  @Test("Short help flag returns success")
  func shortHelpFlagReturnsSuccess() async {
    let code = await router.run(argv: ["inotes", "-h"])
    #expect(code == 0)
  }

  @Test("Command help returns success")
  func commandHelpReturnsSuccess() async {
    let code = await router.run(argv: ["inotes", "show", "--help"])
    #expect(code == 0)
  }

  @Test("All command help returns success")
  func allCommandHelpReturnsSuccess() async {
    let commands = ["show", "read", "add", "edit", "delete", "search", "folders", "accounts", "status", "mkfolder"]
    for cmd in commands {
      let code = await router.run(argv: ["inotes", cmd, "--help"])
      #expect(code == 0, "Help for '\(cmd)' should succeed")
    }
  }
}
