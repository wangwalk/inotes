import Foundation
import Testing
import INotesCore

@testable import inotes

@MainActor
struct OutputFormattingTests {
  @Test("FolderSummary stores properties")
  func folderSummaryProperties() {
    let summary = FolderSummary(id: "test-id", name: "Work", noteCount: 5)
    #expect(summary.id == "test-id")
    #expect(summary.name == "Work")
    #expect(summary.noteCount == 5)
  }

  @Test("FolderSummary equality")
  func folderSummaryEquality() {
    let a = FolderSummary(id: "1", name: "Work", noteCount: 5)
    let b = FolderSummary(id: "1", name: "Work", noteCount: 5)
    let c = FolderSummary(id: "2", name: "Personal", noteCount: 3)
    #expect(a == b)
    #expect(a != c)
  }

  @Test("FolderSummary is Codable")
  func folderSummaryCodable() throws {
    let summary = FolderSummary(id: "test-id", name: "Work", noteCount: 5)
    let encoder = JSONEncoder()
    let data = try encoder.encode(summary)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(FolderSummary.self, from: data)
    #expect(decoded == summary)
  }

  @Test("OutputFormat has all expected cases")
  func outputFormatCases() {
    let formats: [OutputFormat] = [.standard, .plain, .json, .quiet]
    #expect(formats.count == 4)
  }
}
