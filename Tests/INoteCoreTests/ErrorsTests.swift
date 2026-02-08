import Testing

@testable import INotesCore

@MainActor
struct ErrorsTests {
  // MARK: - Error Description Tests

  @Test("All errors have non-nil descriptions")
  func allErrorsHaveDescriptions() {
    let errors: [INotesError] = [
      .permissionDenied,
      .noteNotFound("test-id"),
      .folderNotFound("Work"),
      .ambiguousIdentifier("abc", matches: ["abc1", "abc2"]),
      .invalidIdentifier("x"),
      .scriptError("script failed"),
      .operationFailed("operation failed"),
    ]

    for error in errors {
      #expect(error.errorDescription != nil)
      #expect(error.errorDescription?.isEmpty == false)
    }
  }

  @Test("Permission denied includes guidance text")
  func permissionDeniedGuidance() {
    let error = INotesError.permissionDenied
    let description = error.errorDescription ?? ""

    #expect(description.contains("Permission denied"))
    #expect(description.contains("Notes.app"))
    #expect(description.contains("System Settings"))
    #expect(description.contains("Privacy & Security"))
    #expect(description.contains("Automation"))
  }

  @Test("Note not found includes ID")
  func noteNotFoundIncludesID() {
    let error = INotesError.noteNotFound("abcd1234")
    let description = error.errorDescription ?? ""

    #expect(description.contains("Note not found"))
    #expect(description.contains("abcd1234"))
  }

  @Test("Note not found with different IDs")
  func noteNotFoundDifferentIDs() {
    let error1 = INotesError.noteNotFound("test-id-1")
    let error2 = INotesError.noteNotFound("test-id-2")

    #expect(error1.errorDescription?.contains("test-id-1") == true)
    #expect(error2.errorDescription?.contains("test-id-2") == true)
  }

  @Test("Folder not found includes folder name")
  func folderNotFoundIncludesName() {
    let error = INotesError.folderNotFound("Work")
    let description = error.errorDescription ?? ""

    #expect(description.contains("Folder not found"))
    #expect(description.contains("Work"))
  }

  @Test("Folder not found with different names")
  func folderNotFoundDifferentNames() {
    let error1 = INotesError.folderNotFound("Personal")
    let error2 = INotesError.folderNotFound("Archive")

    #expect(error1.errorDescription?.contains("Personal") == true)
    #expect(error2.errorDescription?.contains("Archive") == true)
  }

  @Test("Ambiguous identifier includes matches")
  func ambiguousIdentifierIncludesMatches() {
    let matches = ["abcd1234", "abcd5678", "abcd9012"]
    let error = INotesError.ambiguousIdentifier("abcd", matches: matches)
    let description = error.errorDescription ?? ""

    #expect(description.contains("Identifier"))
    #expect(description.contains("abcd"))
    #expect(description.contains("matches"))
    #expect(description.contains("abcd1234"))
    #expect(description.contains("abcd5678"))
    #expect(description.contains("abcd9012"))
  }

  @Test("Ambiguous identifier with two matches")
  func ambiguousIdentifierTwoMatches() {
    let error = INotesError.ambiguousIdentifier("abc", matches: ["abc1", "abc2"])
    let description = error.errorDescription ?? ""

    #expect(description.contains("abc1"))
    #expect(description.contains("abc2"))
  }

  @Test("Invalid identifier includes input")
  func invalidIdentifierIncludesInput() {
    let error = INotesError.invalidIdentifier("x")
    let description = error.errorDescription ?? ""

    #expect(description.contains("Invalid identifier"))
    #expect(description.contains("x"))
  }

  @Test("Script error includes message")
  func scriptErrorIncludesMessage() {
    let error = INotesError.scriptError("AppleScript execution failed")
    let description = error.errorDescription ?? ""

    #expect(description.contains("AppleScript error"))
    #expect(description.contains("AppleScript execution failed"))
  }

  @Test("Script error with different messages")
  func scriptErrorDifferentMessages() {
    let error1 = INotesError.scriptError("timeout")
    let error2 = INotesError.scriptError("syntax error")

    #expect(error1.errorDescription?.contains("timeout") == true)
    #expect(error2.errorDescription?.contains("syntax error") == true)
  }

  @Test("Operation failed includes message")
  func operationFailedIncludesMessage() {
    let error = INotesError.operationFailed("Could not create note")
    let description = error.errorDescription ?? ""

    #expect(description.contains("Operation failed"))
    #expect(description.contains("Could not create note"))
  }

  @Test("Operation failed with different messages")
  func operationFailedDifferentMessages() {
    let error1 = INotesError.operationFailed("network error")
    let error2 = INotesError.operationFailed("disk full")

    #expect(error1.errorDescription?.contains("network error") == true)
    #expect(error2.errorDescription?.contains("disk full") == true)
  }

  // MARK: - Equatable Tests

  @Test("Same error types are equal")
  func sameErrorTypesEqual() {
    #expect(INotesError.permissionDenied == INotesError.permissionDenied)
    #expect(
      INotesError.noteNotFound("abc") == INotesError.noteNotFound("abc")
    )
    #expect(
      INotesError.folderNotFound("Work") == INotesError.folderNotFound("Work")
    )
  }

  @Test("Different error types are not equal")
  func differentErrorTypesNotEqual() {
    #expect(INotesError.permissionDenied != INotesError.noteNotFound("abc"))
    #expect(
      INotesError.noteNotFound("abc") != INotesError.folderNotFound("abc")
    )
  }

  @Test("Same error type with different values not equal")
  func sameTypesDifferentValuesNotEqual() {
    #expect(
      INotesError.noteNotFound("abc") != INotesError.noteNotFound("xyz")
    )
    #expect(
      INotesError.folderNotFound("Work") != INotesError.folderNotFound("Personal")
    )
  }

  @Test("Ambiguous identifier equality")
  func ambiguousIdentifierEquality() {
    let error1 = INotesError.ambiguousIdentifier("abc", matches: ["abc1", "abc2"])
    let error2 = INotesError.ambiguousIdentifier("abc", matches: ["abc1", "abc2"])
    let error3 = INotesError.ambiguousIdentifier("abc", matches: ["abc1", "abc3"])

    #expect(error1 == error2)
    #expect(error1 != error3)
  }

  // MARK: - LocalizedError Protocol Tests

  @Test("Error conforms to LocalizedError")
  func errorConformsToLocalizedError() {
    let error: LocalizedError = INotesError.permissionDenied
    #expect(error.errorDescription != nil)
  }

  @Test("Error can be thrown and caught")
  func errorThrowable() throws {
    func throwError() throws {
      throw INotesError.noteNotFound("test")
    }

    var didCatch = false
    do {
      try throwError()
    } catch INotesError.noteNotFound(let id) {
      didCatch = true
      #expect(id == "test")
    }

    #expect(didCatch)
  }

  // MARK: - Edge Cases

  @Test("Empty string inputs")
  func emptyStringInputs() {
    let error1 = INotesError.noteNotFound("")
    let error2 = INotesError.folderNotFound("")
    let error3 = INotesError.invalidIdentifier("")

    #expect(error1.errorDescription?.isEmpty == false)
    #expect(error2.errorDescription?.isEmpty == false)
    #expect(error3.errorDescription?.isEmpty == false)
  }

  @Test("Ambiguous identifier with empty matches")
  func ambiguousIdentifierEmptyMatches() {
    let error = INotesError.ambiguousIdentifier("abc", matches: [])
    let description = error.errorDescription ?? ""

    #expect(description.contains("abc"))
  }

  @Test("Special characters in error messages")
  func specialCharactersInMessages() {
    let error1 = INotesError.noteNotFound("test\nid")
    let error2 = INotesError.folderNotFound("Work/Personal")
    let error3 = INotesError.scriptError("Error: \"quoted\"")

    #expect(error1.errorDescription != nil)
    #expect(error2.errorDescription != nil)
    #expect(error3.errorDescription != nil)
  }
}
