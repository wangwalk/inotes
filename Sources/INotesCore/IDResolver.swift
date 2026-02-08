import Foundation

public enum IDResolver {
  public static let minimumPrefixLength = 4

  /// Resolves note identifiers (index or ID prefix) to actual notes
  public static func resolve(
    _ inputs: [String],
    from notes: [NoteItem]
  ) throws -> [NoteItem] {
    let sorted = NoteFiltering.sort(notes)
    var resolved: [NoteItem] = []

    for input in inputs {
      let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

      // Try to parse as index (1-based)
      if let index = Int(trimmed) {
        let idx = index - 1
        guard idx >= 0 && idx < sorted.count else {
          throw INotesError.invalidIdentifier(trimmed)
        }
        resolved.append(sorted[idx])
        continue
      }

      // Try to match as ID prefix (minimum 4 characters)
      if trimmed.count < minimumPrefixLength {
        throw INotesError.invalidIdentifier(trimmed)
      }

      let matches = sorted.filter { $0.id.lowercased().hasPrefix(trimmed.lowercased()) }
      if matches.isEmpty {
        throw INotesError.noteNotFound(trimmed)
      }
      if matches.count > 1 {
        throw INotesError.ambiguousIdentifier(trimmed, matches: matches.map { $0.id })
      }
      if let match = matches.first {
        resolved.append(match)
      }
    }

    return resolved
  }
}
