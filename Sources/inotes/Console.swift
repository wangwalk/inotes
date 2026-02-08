import Foundation

struct Console {
  static var isTTY: Bool {
    isatty(STDIN_FILENO) != 0
  }

  static func readLine(prompt: String) -> String? {
    Swift.print(prompt, terminator: " ")
    return Swift.readLine()
  }

  static func confirm(_ prompt: String, defaultValue: Bool = false) -> Bool {
    let suffix = defaultValue ? "[Y/n]" : "[y/N]"
    guard let input = readLine(prompt: "\(prompt) \(suffix)")?.trimmingCharacters(in: .whitespacesAndNewlines),
      !input.isEmpty
    else {
      return defaultValue
    }
    switch input.lowercased() {
    case "y", "yes":
      return true
    case "n", "no":
      return false
    default:
      return defaultValue
    }
  }

  static func printError(_ message: String) {
    var stderr = StandardErrorOutputStream()
    Swift.print(message, to: &stderr)
  }
}

struct StandardErrorOutputStream: TextOutputStream {
  mutating func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    FileHandle.standardError.write(data)
  }
}
