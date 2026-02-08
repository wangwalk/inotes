import Foundation

public enum INotesError: LocalizedError, Sendable, Equatable {
  case permissionDenied
  case noteNotFound(String)
  case folderNotFound(String)
  case accountNotFound(String)
  case ambiguousIdentifier(String, matches: [String])
  case invalidIdentifier(String)
  case scriptError(String)
  case operationFailed(String)

  public var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return """
        Permission denied: Cannot access Notes.app

        To fix:
        1. Open System Settings > Privacy & Security > Automation
        2. Find your terminal application (Terminal.app, iTerm, etc.)
        3. Enable access to Notes
        4. Restart your terminal
        5. Try again

        Note: This is required for inotes to interact with Apple Notes.
        """
    case .noteNotFound(let id):
      return "Note not found: \"\(id)\"."
    case .folderNotFound(let name):
      return "Folder not found: \"\(name)\"."
    case .accountNotFound(let name):
      return "Account not found: \"\(name)\". Use 'inotes accounts' to list available accounts."
    case .ambiguousIdentifier(let input, let matches):
      return "Identifier \"\(input)\" matches multiple notes: \(matches.joined(separator: ", "))."
    case .invalidIdentifier(let input):
      return "Invalid identifier: \"\(input)\"."
    case .scriptError(let message):
      return "AppleScript error: \(message)"
    case .operationFailed(let message):
      return "Operation failed: \(message)"
    }
  }
}
