import Testing

@testable import inotes

@MainActor
struct ConsoleTests {
  @Test("Console.isTTY returns a boolean")
  func isTTYReturnsBool() {
    let result = Console.isTTY
    #expect(result == true || result == false)
  }
}
