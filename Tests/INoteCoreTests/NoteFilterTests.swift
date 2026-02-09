import Foundation
import Testing

@testable import INotesCore

@MainActor
struct NoteFilterTests {
  private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
  }()

  private func makeNote(id: String, title: String, modificationDate: Date) -> NoteItem {
    NoteItem(
      id: id,
      title: title,
      body: "Test body",
      folder: "Test",
      creationDate: modificationDate,
      modificationDate: modificationDate
    )
  }

  private func sampleNotes(now: Date) -> [NoteItem] {
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
    let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now)!
    let monthAgo = calendar.date(byAdding: .day, value: -30, to: now)!
    let twoMonthsAgo = calendar.date(byAdding: .day, value: -60, to: now)!

    return [
      makeNote(id: "1", title: "Today's note", modificationDate: now),
      makeNote(id: "2", title: "Yesterday's note", modificationDate: yesterday),
      makeNote(id: "3", title: "Three days ago", modificationDate: threeDaysAgo),
      makeNote(id: "4", title: "Week ago", modificationDate: weekAgo),
      makeNote(id: "5", title: "Two weeks ago", modificationDate: twoWeeksAgo),
      makeNote(id: "6", title: "Month ago", modificationDate: monthAgo),
      makeNote(id: "7", title: "Two months ago", modificationDate: twoMonthsAgo),
    ]
  }

  // MARK: - .today Filter Tests

  @Test("Today filter matches notes modified today")
  func todayMatchesToday() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = sampleNotes(now: now)
    let result = NoteFilter.today.apply(to: notes, now: now, calendar: calendar)

    #expect(result.count == 1)
    #expect(result.first?.title == "Today's note")
  }

  @Test("Today filter rejects yesterday's notes")
  func todayRejectsYesterday() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
    let note = makeNote(id: "old", title: "Old note", modificationDate: yesterday)

    #expect(NoteFilter.today.matches(note, now: now, calendar: calendar) == false)
  }

  @Test("Today filter at midnight boundary")
  func todayAtMidnight() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let midnight = calendar.startOfDay(for: now)
    let note = makeNote(id: "midnight", title: "Midnight note", modificationDate: midnight)

    // Should match since it's the same day
    #expect(NoteFilter.today.matches(note, now: now, calendar: calendar) == true)
  }

  @Test("Today filter just before midnight")
  func todayJustBeforeMidnight() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
    let justBeforeMidnight = calendar.date(byAdding: .second, value: -1, to: nextDay)!
    let note = makeNote(id: "late", title: "Late note", modificationDate: justBeforeMidnight)

    // Should match since it's still the same day
    #expect(NoteFilter.today.matches(note, now: now, calendar: calendar) == true)
  }

  // MARK: - .week Filter Tests

  @Test("Week filter matches notes from past 7 days")
  func weekMatchesSevenDays() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = sampleNotes(now: now)
    let result = NoteFilter.week.apply(to: notes, now: now, calendar: calendar)

    // Should include: today, yesterday, 3 days ago, week ago
    #expect(result.count == 4)
  }

  @Test("Week filter rejects notes older than 7 days")
  func weekRejectsOlder() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: now)!
    let note = makeNote(id: "old", title: "Old note", modificationDate: eightDaysAgo)

    #expect(NoteFilter.week.matches(note, now: now, calendar: calendar) == false)
  }

  @Test("Week filter exactly 7 days ago")
  func weekExactlySevenDays() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let exactlyWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
    let note = makeNote(id: "week", title: "Week note", modificationDate: exactlyWeekAgo)

    #expect(NoteFilter.week.matches(note, now: now, calendar: calendar) == true)
  }

  // MARK: - .recent Filter Tests

  @Test("Recent filter matches notes from past 30 days")
  func recentMatchesThirtyDays() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = sampleNotes(now: now)
    let result = NoteFilter.recent.apply(to: notes, now: now, calendar: calendar)

    // Should include: today, yesterday, 3 days, week, 2 weeks, month
    #expect(result.count == 6)
  }

  @Test("Recent filter rejects notes older than 30 days")
  func recentRejectsOlder() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -31, to: now)!
    let note = makeNote(id: "old", title: "Old note", modificationDate: thirtyOneDaysAgo)

    #expect(NoteFilter.recent.matches(note, now: now, calendar: calendar) == false)
  }

  @Test("Recent filter exactly 30 days ago")
  func recentExactlyThirtyDays() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let exactlyThirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
    let note = makeNote(id: "month", title: "Month note", modificationDate: exactlyThirtyDaysAgo)

    #expect(NoteFilter.recent.matches(note, now: now, calendar: calendar) == true)
  }

  // MARK: - .all Filter Tests

  @Test("All filter matches everything")
  func allMatchesEverything() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = sampleNotes(now: now)
    let result = NoteFilter.all.apply(to: notes, now: now, calendar: calendar)

    #expect(result.count == notes.count)
    #expect(result.count == 7)
  }

  @Test("All filter matches very old notes")
  func allMatchesVeryOld() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let veryOld = calendar.date(byAdding: .year, value: -5, to: now)!
    let note = makeNote(id: "ancient", title: "Ancient note", modificationDate: veryOld)

    #expect(NoteFilter.all.matches(note, now: now, calendar: calendar) == true)
  }

  // MARK: - NoteFiltering Tests

  @Test("Parse valid filter strings")
  func parseValidFilters() {
    #expect(NoteFiltering.parse("all") == .all)
    #expect(NoteFiltering.parse("today") == .today)
    #expect(NoteFiltering.parse("week") == .week)
    #expect(NoteFiltering.parse("recent") == .recent)
  }

  @Test("Parse case-insensitive filter strings")
  func parseCaseInsensitive() {
    #expect(NoteFiltering.parse("ALL") == .all)
    #expect(NoteFiltering.parse("Today") == .today)
    #expect(NoteFiltering.parse("WEEK") == .week)
    #expect(NoteFiltering.parse("Recent") == .recent)
  }

  @Test("Parse filter strings with whitespace")
  func parseWithWhitespace() {
    #expect(NoteFiltering.parse("  today  ") == .today)
    #expect(NoteFiltering.parse("\tweek\n") == .week)
  }

  @Test("Parse invalid filter string")
  func parseInvalidFilter() {
    #expect(NoteFiltering.parse("invalid") == nil)
    #expect(NoteFiltering.parse("") == nil)
    #expect(NoteFiltering.parse("tomorrow") == nil)
  }

  @Test("Sort notes by modification date newest first")
  func sortByModificationDate() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = sampleNotes(now: now)

    let sorted = NoteFiltering.sort(notes)

    #expect(sorted.first?.title == "Today's note")
    #expect(sorted.last?.title == "Two months ago")
    #expect(sorted[0].modificationDate > sorted[1].modificationDate)
    #expect(sorted[1].modificationDate > sorted[2].modificationDate)
  }

  @Test("Sort preserves order for same modification date")
  func sortSameDate() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = [
      makeNote(id: "1", title: "First", modificationDate: now),
      makeNote(id: "2", title: "Second", modificationDate: now),
      makeNote(id: "3", title: "Third", modificationDate: now),
    ]

    let sorted = NoteFiltering.sort(notes)

    // Stable sort should preserve original order for equal dates
    #expect(sorted.count == 3)
  }
}
