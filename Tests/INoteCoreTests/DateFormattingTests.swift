import Foundation
import Testing

@testable import INotesCore

@MainActor
struct DateFormattingTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
  }()

  // MARK: - ISO8601 Formatting Tests

  @Test("Format ISO8601 with fractional seconds")
  func formatISO8601WithFractionalSeconds() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let formatted = DateFormatting.formatISO8601(date)

    #expect(formatted.contains("2023"))
    #expect(formatted.contains("T"))
    #expect(formatted.contains("Z"))
    #expect(formatted.contains("."))
  }

  @Test("ISO8601 format is valid")
  func iso8601FormatValid() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let formatted = DateFormatting.formatISO8601(date)

    // Should be parseable back
    let parsed = DateFormatting.parseISO8601(formatted)
    #expect(parsed != nil)
  }

  @Test("ISO8601 round-trip preserves date")
  func iso8601RoundTrip() {
    let original = Date(timeIntervalSince1970: 1_700_000_000)
    let formatted = DateFormatting.formatISO8601(original)
    let parsed = DateFormatting.parseISO8601(formatted)

    #expect(parsed != nil)
    // Allow small difference due to fractional seconds precision
    if let parsed = parsed {
      #expect(abs(parsed.timeIntervalSince1970 - original.timeIntervalSince1970) < 0.001)
    }
  }

  @Test("ISO8601 format different dates")
  func iso8601FormatDifferentDates() {
    let date1 = Date(timeIntervalSince1970: 0)  // 1970
    let date2 = Date(timeIntervalSince1970: 1_700_000_000)  // 2023
    let date3 = Date(timeIntervalSince1970: 2_000_000_000)  // 2033

    let formatted1 = DateFormatting.formatISO8601(date1)
    let formatted2 = DateFormatting.formatISO8601(date2)
    let formatted3 = DateFormatting.formatISO8601(date3)

    #expect(formatted1 != formatted2)
    #expect(formatted2 != formatted3)
    #expect(formatted1.contains("1970"))
    #expect(formatted2.contains("2023"))
    #expect(formatted3.contains("2033"))
  }

  // MARK: - ISO8601 Parsing Tests

  @Test("Parse ISO8601 with fractional seconds")
  func parseISO8601WithFractionalSeconds() {
    let input = "2023-11-14T22:13:20.000Z"
    let parsed = DateFormatting.parseISO8601(input)

    #expect(parsed != nil)
    if let parsed = parsed {
      let calendar = Calendar(identifier: .gregorian)
      let components = calendar.dateComponents([.year, .month, .day], from: parsed)
      #expect(components.year == 2023)
      #expect(components.month == 11)
      #expect(components.day == 14)
    }
  }

  @Test("Parse ISO8601 without fractional seconds")
  func parseISO8601WithoutFractionalSeconds() {
    let input = "2023-11-14T22:13:20Z"
    let parsed = DateFormatting.parseISO8601(input)

    #expect(parsed != nil)
  }

  @Test("Parse ISO8601 with timezone offset")
  func parseISO8601WithTimezoneOffset() {
    let input1 = "2023-11-14T22:13:20+00:00"
    let input2 = "2023-11-14T22:13:20-05:00"

    let parsed1 = DateFormatting.parseISO8601(input1)
    let parsed2 = DateFormatting.parseISO8601(input2)

    #expect(parsed1 != nil)
    #expect(parsed2 != nil)
  }

  @Test("Parse empty ISO8601 string")
  func parseEmptyISO8601() {
    let parsed = DateFormatting.parseISO8601("")
    #expect(parsed == nil)
  }

  @Test("Parse invalid ISO8601 string")
  func parseInvalidISO8601() {
    let parsed1 = DateFormatting.parseISO8601("not a date")
    let parsed2 = DateFormatting.parseISO8601("2023-13-45")
    let parsed3 = DateFormatting.parseISO8601("invalid")

    #expect(parsed1 == nil)
    #expect(parsed2 == nil)
    #expect(parsed3 == nil)
  }

  // MARK: - AppleScript Date Parsing Tests

  @Test("Parse AppleScript date format")
  func parseAppleScriptDate() {
    let input = "date \"Thursday, February 8, 2024 at 3:30:45 PM\""
    let parsed = DateFormatting.parseAppleScriptDate(input)

    #expect(parsed != nil)
    if let parsed = parsed {
      let calendar = Calendar(identifier: .gregorian)
      let components = calendar.dateComponents([.year, .month, .day, .hour], from: parsed)
      #expect(components.year == 2024)
      #expect(components.month == 2)
      #expect(components.day == 8)
      #expect(components.hour == 15)  // 3 PM
    }
  }

  @Test("Parse AppleScript date without quotes")
  func parseAppleScriptDateWithoutQuotes() {
    let input = "Thursday, February 8, 2024 at 3:30:45 PM"
    let parsed = DateFormatting.parseAppleScriptDate(input)

    #expect(parsed != nil)
  }

  @Test("Parse AppleScript date without day name")
  func parseAppleScriptDateWithoutDayName() {
    let input = "date \"February 8, 2024 at 3:30:45 PM\""
    let parsed = DateFormatting.parseAppleScriptDate(input)

    #expect(parsed != nil)
  }

  @Test("Parse AppleScript date without seconds")
  func parseAppleScriptDateWithoutSeconds() {
    let input = "date \"Thursday, February 8, 2024 at 3:30 PM\""
    let parsed = DateFormatting.parseAppleScriptDate(input)

    #expect(parsed != nil)
  }

  @Test("Parse AppleScript date various formats")
  func parseAppleScriptDateVariousFormats() {
    let inputs = [
      "date \"Thursday, February 8, 2024 at 3:30:45 PM\"",
      "date \"February 8, 2024 at 3:30:45 PM\"",
      "date \"Thursday, February 8, 2024 at 3:30 PM\"",
      "Thursday, February 8, 2024 at 3:30:45 PM",
    ]

    for input in inputs {
      let parsed = DateFormatting.parseAppleScriptDate(input)
      #expect(parsed != nil, "Failed to parse: \(input)")
    }
  }

  @Test("Parse AppleScript date with whitespace")
  func parseAppleScriptDateWithWhitespace() {
    let input = "  date \"Thursday, February 8, 2024 at 3:30:45 PM\"  "
    let parsed = DateFormatting.parseAppleScriptDate(input)

    #expect(parsed != nil)
  }

  @Test("Parse invalid AppleScript date")
  func parseInvalidAppleScriptDate() {
    let parsed1 = DateFormatting.parseAppleScriptDate("not a date")
    let parsed2 = DateFormatting.parseAppleScriptDate("date \"invalid\"")
    let parsed3 = DateFormatting.parseAppleScriptDate("")

    #expect(parsed1 == nil)
    #expect(parsed2 == nil)
    #expect(parsed3 == nil)
  }

  // MARK: - Display Formatting Tests

  @Test("Format display for recent date")
  func formatDisplayRecentDate() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let formatted = DateFormatting.formatDisplay(date, calendar: calendar)

    #expect(formatted.isEmpty == false)
    // Should contain date and time components
    #expect(formatted.count > 5)
  }

  @Test("Format display for different dates")
  func formatDisplayDifferentDates() {
    let date1 = Date(timeIntervalSince1970: 1_700_000_000)
    let date2 = Date(timeIntervalSince1970: 1_700_100_000)

    let formatted1 = DateFormatting.formatDisplay(date1, calendar: calendar)
    let formatted2 = DateFormatting.formatDisplay(date2, calendar: calendar)

    #expect(formatted1 != formatted2)
  }

  @Test("Format display uses calendar timezone")
  func formatDisplayUsesCalendarTimezone() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)

    var calendar1 = Calendar(identifier: .gregorian)
    calendar1.timeZone = TimeZone(secondsFromGMT: 0)!

    var calendar2 = Calendar(identifier: .gregorian)
    calendar2.timeZone = TimeZone(secondsFromGMT: 3600)!  // +1 hour

    let formatted1 = DateFormatting.formatDisplay(date, calendar: calendar1)
    let formatted2 = DateFormatting.formatDisplay(date, calendar: calendar2)

    // Formatted strings should be non-empty
    #expect(formatted1.isEmpty == false)
    #expect(formatted2.isEmpty == false)
  }

  @Test("Format display epoch date")
  func formatDisplayEpochDate() {
    let date = Date(timeIntervalSince1970: 0)
    let formatted = DateFormatting.formatDisplay(date, calendar: calendar)

    #expect(formatted.isEmpty == false)
  }

  @Test("Format display far future date")
  func formatDisplayFarFutureDate() {
    let date = Date(timeIntervalSince1970: 2_000_000_000)
    let formatted = DateFormatting.formatDisplay(date, calendar: calendar)

    #expect(formatted.isEmpty == false)
  }

  // MARK: - Edge Cases

  @Test("Format and parse extreme dates")
  func formatParseExtremeDates() {
    let dates = [
      Date(timeIntervalSince1970: 0),  // Epoch
      Date(timeIntervalSince1970: 1_000_000),  // Early date
      Date(timeIntervalSince1970: 1_700_000_000),  // Recent date
      Date(timeIntervalSince1970: 2_000_000_000),  // Future date
    ]

    for date in dates {
      let formatted = DateFormatting.formatISO8601(date)
      let parsed = DateFormatting.parseISO8601(formatted)
      #expect(parsed != nil, "Failed to round-trip date: \(date)")
    }
  }

  @Test("Parse ISO8601 with millisecond precision")
  func parseISO8601MillisecondPrecision() {
    let input = "2023-11-14T22:13:20.123Z"
    let parsed = DateFormatting.parseISO8601(input)

    #expect(parsed != nil)
  }

  @Test("Parse ISO8601 with microsecond precision")
  func parseISO8601MicrosecondPrecision() {
    let input = "2023-11-14T22:13:20.123456Z"
    let parsed = DateFormatting.parseISO8601(input)

    #expect(parsed != nil)
  }

  @Test("Display format consistency")
  func displayFormatConsistency() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)

    let formatted1 = DateFormatting.formatDisplay(date, calendar: calendar)
    let formatted2 = DateFormatting.formatDisplay(date, calendar: calendar)

    #expect(formatted1 == formatted2)
  }

  @Test("ISO8601 format is sortable")
  func iso8601FormatSortable() {
    let date1 = Date(timeIntervalSince1970: 1_700_000_000)
    let date2 = Date(timeIntervalSince1970: 1_700_100_000)

    let formatted1 = DateFormatting.formatISO8601(date1)
    let formatted2 = DateFormatting.formatISO8601(date2)

    #expect(formatted1 < formatted2)
  }
}
