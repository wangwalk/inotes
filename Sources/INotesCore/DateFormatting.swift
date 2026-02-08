import Foundation

enum DateFormatting {
  /// Formats a date as ISO8601 with fractional seconds
  static func formatISO8601(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }

  /// Parses an ISO8601 date string
  static func parseISO8601(_ value: String) -> Date? {
    if value.isEmpty { return nil }

    // Try with fractional seconds
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: value) {
      return date
    }

    // Try without fractional seconds
    let standard = ISO8601DateFormatter()
    standard.formatOptions = [.withInternetDateTime]
    return standard.date(from: value)
  }

  /// Parses AppleScript date format: "date \"Thursday, February 8, 2024 at 3:30:45 PM\""
  static func parseAppleScriptDate(_ value: String) -> Date? {
    // AppleScript returns dates in the format: "date \"Thursday, February 8, 2024 at 3:30:45 PM\""
    // Extract the date string from quotes
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    var dateString = trimmed

    if dateString.hasPrefix("date \"") {
      dateString = String(dateString.dropFirst(6))
    }
    if dateString.hasSuffix("\"") {
      dateString = String(dateString.dropLast())
    }

    // Try various formatters
    let formatters = appleScriptDateFormatters()
    for formatter in formatters {
      if let date = formatter.date(from: dateString) {
        return date
      }
    }

    return nil
  }

  /// Creates date formatters for AppleScript date parsing
  private static func appleScriptDateFormatters() -> [DateFormatter] {
    let formats = [
      "EEEE, MMMM d, yyyy 'at' h:mm:ss a",  // "Thursday, February 8, 2024 at 3:30:45 PM"
      "EEEE, MMMM d, yyyy 'at' h:mm a",
      "MMMM d, yyyy 'at' h:mm:ss a",
      "MMMM d, yyyy 'at' h:mm a",
      "yyyy-MM-dd HH:mm:ss",
    ]

    return formats.map { format in
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone.current
      formatter.dateFormat = format
      return formatter
    }
  }

  /// Formats a date for display (medium date, short time)
  static func formatDisplay(_ date: Date, calendar: Calendar = .current) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = calendar.timeZone
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
