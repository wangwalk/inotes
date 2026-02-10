import Commander
import Foundation
import INotesCore

enum StatusCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "status",
      abstract: "Check Notes automation permission",
      discussion: "Reports the current Notes.app automation permission state.",
      signature: CommandSignatures.withRuntimeFlags(CommandSignature()),
      usageExamples: [
        "inotes status",
        "inotes status --json",
      ]
    ) { _, runtime in
      let hasPermission = await checkNotesAutomationPermission()

      switch runtime.outputFormat {
      case .standard:
        if hasPermission {
          Swift.print("Notes automation permission: Granted")
        } else {
          Swift.print("Notes automation permission: Denied or not determined")
          Swift.print("")
          Swift.print("To grant permission:")
          Swift.print("  1. Open System Settings > Privacy & Security > Automation")
          Swift.print("  2. Find 'inotes' or your terminal app")
          Swift.print("  3. Enable access to Notes.app")
        }
      case .plain:
        Swift.print(hasPermission ? "granted" : "denied")
      case .json:
        struct StatusPayload: Codable {
          let automationPermission: String
          let authorized: Bool
        }
        let payload = StatusPayload(
          automationPermission: hasPermission ? "granted" : "denied",
          authorized: hasPermission
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        if let data = try? encoder.encode(payload),
          let json = String(data: data, encoding: .utf8)
        {
          Swift.print(json)
        }
      case .quiet:
        Swift.print(hasPermission ? "1" : "0")
      }
    }
  }

  private static func checkNotesAutomationPermission() async -> Bool {
    let runner = ScriptRunner()
    do {
      _ = try await runner.run("""
        tell application "Notes"
          return count of folders
        end tell
        """)
      return true
    } catch {
      return false
    }
  }
}
