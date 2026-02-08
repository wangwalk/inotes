import Foundation
import Testing

@testable import INotesCore

@MainActor
struct ModelsTests {
  // MARK: - NoteItem Tests

  @Test("NoteItem Codable round-trip")
  func noteItemCodableRoundTrip() throws {
    let creationDate = Date(timeIntervalSince1970: 1_700_000_000)
    let modificationDate = Date(timeIntervalSince1970: 1_700_100_000)

    let original = NoteItem(
      id: "abcd1234-5678-90ef-ghij-klmnopqrstuv",
      title: "Meeting Notes",
      body: "Discuss Q1 goals\n- Revenue targets\n- Product roadmap",
      folder: "Work",
      creationDate: creationDate,
      modificationDate: modificationDate
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(NoteItem.self, from: data)

    #expect(decoded == original)
    #expect(decoded.id == "abcd1234-5678-90ef-ghij-klmnopqrstuv")
    #expect(decoded.title == "Meeting Notes")
    #expect(decoded.body == "Discuss Q1 goals\n- Revenue targets\n- Product roadmap")
    #expect(decoded.folder == "Work")
    #expect(decoded.creationDate == creationDate)
    #expect(decoded.modificationDate == modificationDate)
  }

  @Test("NoteItem JSON serialization format")
  func noteItemJSONFormat() throws {
    let creationDate = Date(timeIntervalSince1970: 1_700_000_000)
    let modificationDate = Date(timeIntervalSince1970: 1_700_100_000)

    let note = NoteItem(
      id: "test-id",
      title: "Test Note",
      body: "Test body",
      folder: "Notes",
      creationDate: creationDate,
      modificationDate: modificationDate
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    let data = try encoder.encode(note)
    let json = String(data: data, encoding: .utf8) ?? ""

    #expect(json.contains("\"id\""))
    #expect(json.contains("\"title\""))
    #expect(json.contains("\"body\""))
    #expect(json.contains("\"folder\""))
    #expect(json.contains("\"creationDate\""))
    #expect(json.contains("\"modificationDate\""))
  }

  // MARK: - NoteFolder Tests

  @Test("NoteFolder Codable round-trip")
  func noteFolderCodableRoundTrip() throws {
    let original = NoteFolder(
      id: "folder-123",
      name: "Personal",
      noteCount: 42
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(NoteFolder.self, from: data)

    #expect(decoded == original)
    #expect(decoded.id == "folder-123")
    #expect(decoded.name == "Personal")
    #expect(decoded.noteCount == 42)
  }

  @Test("NoteFolder with zero notes")
  func noteFolderZeroNotes() throws {
    let folder = NoteFolder(id: "empty", name: "Empty Folder", noteCount: 0)

    let encoder = JSONEncoder()
    let data = try encoder.encode(folder)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(NoteFolder.self, from: data)

    #expect(decoded.noteCount == 0)
  }

  // MARK: - NoteDraft Tests

  @Test("NoteDraft with all fields")
  func noteDraftAllFields() {
    let draft = NoteDraft(
      title: "Shopping List",
      body: "- Milk\n- Eggs\n- Bread",
      folderName: "Errands"
    )

    #expect(draft.title == "Shopping List")
    #expect(draft.body == "- Milk\n- Eggs\n- Bread")
    #expect(draft.folderName == "Errands")
  }

  @Test("NoteDraft default folder")
  func noteDraftDefaultFolder() {
    let draft = NoteDraft(
      title: "Quick Note",
      body: "Something important"
    )

    #expect(draft.title == "Quick Note")
    #expect(draft.body == "Something important")
    #expect(draft.folderName == nil)
  }

  @Test("NoteDraft with explicit nil folder")
  func noteDraftExplicitNilFolder() {
    let draft = NoteDraft(
      title: "Note",
      body: "Content",
      folderName: nil
    )

    #expect(draft.folderName == nil)
  }

  // MARK: - NoteUpdate Tests

  @Test("NoteUpdate with all fields")
  func noteUpdateAllFields() {
    let update = NoteUpdate(
      title: "Updated Title",
      body: "Updated body",
      folderName: "New Folder"
    )

    #expect(update.title == "Updated Title")
    #expect(update.body == "Updated body")
    #expect(update.folderName == "New Folder")
  }

  @Test("NoteUpdate with only title")
  func noteUpdateOnlyTitle() {
    let update = NoteUpdate(title: "New Title")

    #expect(update.title == "New Title")
    #expect(update.body == nil)
    #expect(update.folderName == nil)
  }

  @Test("NoteUpdate with only body")
  func noteUpdateOnlyBody() {
    let update = NoteUpdate(body: "New content")

    #expect(update.title == nil)
    #expect(update.body == "New content")
    #expect(update.folderName == nil)
  }

  @Test("NoteUpdate with only folder")
  func noteUpdateOnlyFolder() {
    let update = NoteUpdate(folderName: "Archive")

    #expect(update.title == nil)
    #expect(update.body == nil)
    #expect(update.folderName == "Archive")
  }

  @Test("NoteUpdate default values")
  func noteUpdateDefaults() {
    let update = NoteUpdate()

    #expect(update.title == nil)
    #expect(update.body == nil)
    #expect(update.folderName == nil)
  }
}
