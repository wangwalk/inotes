import Foundation

/// Executes AppleScript safely using osascript
public actor ScriptRunner {
  public init() {}

  /// Runs an AppleScript and returns the output
  public func run(_ script: String) async throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if process.terminationStatus != 0 {
      // Check for permission errors
      if stderr.lowercased().contains("not allowed") || stderr.lowercased().contains("not authorized") {
        throw INotesError.permissionDenied
      }
      throw INotesError.scriptError(stderr.isEmpty ? "Unknown error" : stderr)
    }

    let output = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return output
  }
}
