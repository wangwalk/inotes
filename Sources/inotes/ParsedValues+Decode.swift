import Commander
import Foundation

enum ParsedValuesError: LocalizedError, CustomStringConvertible {
  case missingOption(String)
  case invalidOption(String)
  case missingArgument(String)

  var description: String {
    switch self {
    case .missingOption(let name):
      return "Missing required option: --\(name)"
    case .invalidOption(let name):
      return "Invalid value for option: --\(name)"
    case .missingArgument(let name):
      return "Missing required argument: \(name)"
    }
  }

  var errorDescription: String? {
    description
  }
}

extension ParsedValues {
  func flag(_ label: String) -> Bool {
    flags.contains(label)
  }

  func option(_ label: String) -> String? {
    options[label]?.last
  }

  func optionValues(_ label: String) -> [String] {
    options[label] ?? []
  }

  func optionRequired(_ label: String) throws -> String {
    guard let value = option(label), !value.isEmpty else {
      throw ParsedValuesError.missingOption(label)
    }
    return value
  }

  func argument(_ index: Int) -> String? {
    guard positional.indices.contains(index) else { return nil }
    return positional[index]
  }
}
