import Foundation

/// Filtering criteria for notes based on modification date
public enum NoteFilter: String, CaseIterable, Sendable {
  case all
  case today
  case week
  case recent

  /// Checks if a note matches the filter criteria
  public func matches(_ note: NoteItem, calendar: Calendar = .current) -> Bool {
    let now = Date()

    switch self {
    case .all:
      return true
    case .today:
      return calendar.isDate(note.modificationDate, inSameDayAs: now)
    case .week:
      guard let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else {
        return false
      }
      return note.modificationDate >= weekAgo
    case .recent:
      guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else {
        return false
      }
      return note.modificationDate >= thirtyDaysAgo
    }
  }

  /// Applies the filter to a collection of notes
  public func apply(to notes: [NoteItem], calendar: Calendar = .current) -> [NoteItem] {
    return notes.filter { matches($0, calendar: calendar) }
  }
}

public enum NoteFiltering {
  /// Parses a filter string into a NoteFilter
  public static func parse(_ input: String) -> NoteFilter? {
    let token = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return NoteFilter(rawValue: token)
  }

  /// Sorts notes by modification date (newest first)
  public static func sort(_ notes: [NoteItem]) -> [NoteItem] {
    return notes.sorted { $0.modificationDate > $1.modificationDate }
  }
}
