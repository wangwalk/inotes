import Foundation
import Testing

@testable import INotesCore

@MainActor
struct IDResolverTests {
  private func sampleNotes() -> [NoteItem] {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let yesterday = Date(timeIntervalSince1970: 1_700_000_000 - 86400)
    let twoDaysAgo = Date(timeIntervalSince1970: 1_700_000_000 - 172800)

    return [
      NoteItem(
        id: "abcd1234-5678-90ab-cdef-ghijklmnopqr",
        title: "First Note",
        body: "Content 1",
        folder: "Work",
        creationDate: twoDaysAgo,
        modificationDate: now
      ),
      NoteItem(
        id: "abce5678-9012-3456-7890-abcdefghijkl",
        title: "Second Note",
        body: "Content 2",
        folder: "Work",
        creationDate: yesterday,
        modificationDate: yesterday
      ),
      NoteItem(
        id: "xyz9876-5432-10ab-cdef-fedcba987654",
        title: "Third Note",
        body: "Content 3",
        folder: "Personal",
        creationDate: twoDaysAgo,
        modificationDate: twoDaysAgo
      ),
    ]
  }

  // MARK: - Index Resolution Tests

  @Test("Resolve by index 1")
  func resolveByIndexOne() throws {
    let resolved = try IDResolver.resolve(["1"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "First Note")
  }

  @Test("Resolve by index 2")
  func resolveByIndexTwo() throws {
    let resolved = try IDResolver.resolve(["2"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "Second Note")
  }

  @Test("Resolve by index 3")
  func resolveByIndexThree() throws {
    let resolved = try IDResolver.resolve(["3"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "Third Note")
  }

  @Test("Resolve multiple indices")
  func resolveMultipleIndices() throws {
    let resolved = try IDResolver.resolve(["1", "3"], from: sampleNotes())
    #expect(resolved.count == 2)
    #expect(resolved[0].title == "First Note")
    #expect(resolved[1].title == "Third Note")
  }

  @Test("Invalid index out of range")
  func invalidIndexOutOfRange() {
    #expect(throws: INotesError.invalidIdentifier("0")) {
      _ = try IDResolver.resolve(["0"], from: sampleNotes())
    }
    #expect(throws: INotesError.invalidIdentifier("4")) {
      _ = try IDResolver.resolve(["4"], from: sampleNotes())
    }
    #expect(throws: INotesError.invalidIdentifier("999")) {
      _ = try IDResolver.resolve(["999"], from: sampleNotes())
    }
  }

  @Test("Negative index")
  func negativeIndex() {
    #expect(throws: INotesError.invalidIdentifier("-1")) {
      _ = try IDResolver.resolve(["-1"], from: sampleNotes())
    }
  }

  // MARK: - Prefix Resolution Tests

  @Test("Resolve by prefix abcd")
  func resolveByPrefixAbcd() throws {
    let resolved = try IDResolver.resolve(["abcd"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "First Note")
  }

  @Test("Resolve by prefix abce")
  func resolveByPrefixAbce() throws {
    let resolved = try IDResolver.resolve(["abce"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "Second Note")
  }

  @Test("Resolve by prefix xyz9")
  func resolveByPrefixXyz() throws {
    let resolved = try IDResolver.resolve(["xyz9"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "Third Note")
  }

  @Test("Resolve by longer prefix")
  func resolveByLongerPrefix() throws {
    let resolved = try IDResolver.resolve(["abcd1234"], from: sampleNotes())
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "First Note")
  }

  @Test("Resolve by full ID")
  func resolveByFullID() throws {
    let resolved = try IDResolver.resolve(
      ["abcd1234-5678-90ab-cdef-ghijklmnopqr"],
      from: sampleNotes()
    )
    #expect(resolved.count == 1)
    #expect(resolved.first?.title == "First Note")
  }

  @Test("Case-insensitive prefix matching")
  func caseInsensitivePrefix() throws {
    let upperResolved = try IDResolver.resolve(["ABCD"], from: sampleNotes())
    let lowerResolved = try IDResolver.resolve(["abcd"], from: sampleNotes())
    let mixedResolved = try IDResolver.resolve(["AbCd"], from: sampleNotes())

    #expect(upperResolved.first?.id == lowerResolved.first?.id)
    #expect(lowerResolved.first?.id == mixedResolved.first?.id)
  }

  // MARK: - Error Cases Tests

  @Test("Reject short prefix")
  func rejectShortPrefix() {
    #expect(throws: INotesError.invalidIdentifier("abc")) {
      _ = try IDResolver.resolve(["abc"], from: sampleNotes())
    }
    #expect(throws: INotesError.invalidIdentifier("ab")) {
      _ = try IDResolver.resolve(["ab"], from: sampleNotes())
    }
    #expect(throws: INotesError.invalidIdentifier("a")) {
      _ = try IDResolver.resolve(["a"], from: sampleNotes())
    }
  }

  @Test("Ambiguous prefix multiple matches")
  func ambiguousPrefixMultipleMatches() {
    // Create notes that share a 4-char prefix to trigger ambiguity
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let ambiguousNotes = [
      NoteItem(
        id: "abcd1234-5678-90ab-cdef-ghijklmnopqr",
        title: "First Note",
        body: "Content 1",
        folder: "Work",
        creationDate: now,
        modificationDate: now
      ),
      NoteItem(
        id: "abcd5678-9012-3456-7890-abcdefghijkl",
        title: "Second Note",
        body: "Content 2",
        folder: "Work",
        creationDate: now,
        modificationDate: now
      ),
    ]
    let error = INotesError.ambiguousIdentifier(
      "abcd",
      matches: [
        "abcd1234-5678-90ab-cdef-ghijklmnopqr",
        "abcd5678-9012-3456-7890-abcdefghijkl",
      ]
    )
    #expect(throws: error) {
      _ = try IDResolver.resolve(["abcd"], from: ambiguousNotes)
    }
  }

  @Test("Ambiguous prefix with sufficient length")
  func ambiguousPrefixSufficientLength() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let notes = [
      NoteItem(
        id: "abcd1111-0000-0000-0000-000000000000", title: "Note A", body: "", folder: "Test",
        creationDate: now, modificationDate: now),
      NoteItem(
        id: "abcd2222-0000-0000-0000-000000000000", title: "Note B", body: "", folder: "Test",
        creationDate: now, modificationDate: now),
    ]
    #expect(
      throws: INotesError.ambiguousIdentifier(
        "abcd",
        matches: [
          "abcd1111-0000-0000-0000-000000000000",
          "abcd2222-0000-0000-0000-000000000000",
        ])
    ) {
      _ = try IDResolver.resolve(["abcd"], from: notes)
    }
  }

  @Test("Note not found with valid length prefix")
  func noteNotFoundValidLengthPrefix() {
    #expect(throws: INotesError.noteNotFound("zzzz")) {
      _ = try IDResolver.resolve(["zzzz"], from: sampleNotes())
    }
    #expect(throws: INotesError.noteNotFound("qqqq")) {
      _ = try IDResolver.resolve(["qqqq"], from: sampleNotes())
    }
  }

  @Test("Empty list returns error")
  func emptyListError() {
    let emptyList: [NoteItem] = []
    #expect(throws: INotesError.invalidIdentifier("1")) {
      _ = try IDResolver.resolve(["1"], from: emptyList)
    }
  }

  @Test("Empty input string")
  func emptyInputString() {
    #expect(throws: (any Error).self) {
      _ = try IDResolver.resolve([""], from: sampleNotes())
    }
  }

  @Test("Whitespace-only input")
  func whitespaceOnlyInput() {
    #expect(throws: (any Error).self) {
      _ = try IDResolver.resolve(["   "], from: sampleNotes())
    }
  }

  // MARK: - Mixed Resolution Tests

  @Test("Resolve mixed indices and prefixes")
  func resolveMixedIndicesAndPrefixes() throws {
    let resolved = try IDResolver.resolve(["1", "xyz9"], from: sampleNotes())
    #expect(resolved.count == 2)
    #expect(resolved[0].title == "First Note")
    #expect(resolved[1].title == "Third Note")
  }

  @Test("Whitespace trimming in input")
  func whitespaceTrimming() throws {
    let resolved = try IDResolver.resolve(["  1  ", "  abcd  "], from: sampleNotes())
    #expect(resolved.count == 2)
    #expect(resolved[0].title == "First Note")
    #expect(resolved[1].title == "First Note")
  }

  // MARK: - Sorting Tests

  @Test("Resolve uses sorted notes by modification date")
  func resolveUsesSortedNotes() throws {
    // Notes are sorted by modification date (newest first)
    // First Note has newest modificationDate
    let resolved = try IDResolver.resolve(["1"], from: sampleNotes())
    #expect(resolved.first?.title == "First Note")
  }

  @Test("Index resolution stable across same input")
  func indexResolutionStable() throws {
    let notes = sampleNotes()
    let resolved1 = try IDResolver.resolve(["1"], from: notes)
    let resolved2 = try IDResolver.resolve(["1"], from: notes)

    #expect(resolved1.first?.id == resolved2.first?.id)
  }

  // MARK: - Minimum Prefix Length Tests

  @Test("Minimum prefix length is 4")
  func minimumPrefixLength() {
    #expect(IDResolver.minimumPrefixLength == 4)
  }

  @Test("Exactly minimum prefix length accepted")
  func exactlyMinimumPrefixLength() throws {
    let resolved = try IDResolver.resolve(["abcd"], from: sampleNotes())
    #expect(resolved.count == 1)
  }

  @Test("One less than minimum rejected")
  func oneLessThanMinimumRejected() {
    let input = String(repeating: "a", count: IDResolver.minimumPrefixLength - 1)
    #expect(throws: INotesError.invalidIdentifier(input)) {
      _ = try IDResolver.resolve([input], from: sampleNotes())
    }
  }
}
