import Commander
import Foundation
import Testing

@testable import IMsgCore
@testable import imsg

@Test
func chatsCommandRunsWithJsonOutput() async throws {
  let path = try CommandTestDatabase.makePath()
  let values = ParsedValues(
    positional: [],
    options: ["db": [path], "limit": ["5"]],
    flags: ["jsonOutput"]
  )
  let runtime = RuntimeOptions(parsedValues: values)
  _ = try await StdoutCapture.capture {
    try await ChatsCommand.spec.run(values, runtime)
  }
}

@Test
func historyCommandRunsWithChatID() async throws {
  let path = try CommandTestDatabase.makePath()
  let values = ParsedValues(
    positional: [],
    options: ["db": [path], "chatID": ["1"], "limit": ["5"]],
    flags: ["jsonOutput"]
  )
  let runtime = RuntimeOptions(parsedValues: values)
  let (output, _) = try await StdoutCapture.capture {
    try await HistoryCommand.spec.run(values, runtime)
  }
  let payload = try jsonObject(from: output)
  #expect(payload["is_group"] as? Bool == true)
  #expect(payload["chat_identifier"] as? String == "+123")
  #expect(payload["chat_guid"] as? String == "iMessage;+;chat123")
  #expect(payload["chat_name"] as? String == "Test Chat")
  #expect(payload["participants"] as? [String] == ["+123"])
}

@Test
func historyCommandJsonReportsDirectChatMetadata() async throws {
  let path = try CommandTestDatabase.makePathDirectChat()
  let values = ParsedValues(
    positional: [],
    options: ["db": [path], "chatID": ["1"], "limit": ["5"]],
    flags: ["jsonOutput"]
  )
  let runtime = RuntimeOptions(parsedValues: values)
  let (output, _) = try await StdoutCapture.capture {
    try await HistoryCommand.spec.run(values, runtime)
  }
  let payload = try jsonObject(from: output)
  #expect(payload["is_group"] as? Bool == false)
  #expect(payload["chat_identifier"] as? String == "+123")
  #expect(payload["chat_guid"] as? String == "iMessage;-;+123")
  #expect(payload["chat_name"] as? String == "Direct Chat")
  #expect(payload["participants"] as? [String] == ["+123"])
}

@Test
func historyCommandRunsWithAttachmentsNonJson() async throws {
  let path = try CommandTestDatabase.makePathWithAttachment()
  let values = ParsedValues(
    positional: [],
    options: ["db": [path], "chatID": ["1"], "limit": ["5"]],
    flags: ["attachments"]
  )
  let runtime = RuntimeOptions(parsedValues: values)
  _ = try await StdoutCapture.capture {
    try await HistoryCommand.spec.run(values, runtime)
  }
}

@Test
func chatsCommandRunsWithPlainOutput() async throws {
  let path = try CommandTestDatabase.makePath()
  let values = ParsedValues(
    positional: [],
    options: ["db": [path], "limit": ["5"]],
    flags: []
  )
  let runtime = RuntimeOptions(parsedValues: values)
  _ = try await StdoutCapture.capture {
    try await ChatsCommand.spec.run(values, runtime)
  }
}

@Test
func sendCommandRejectsMissingRecipient() async {
  let values = ParsedValues(
    positional: [],
    options: ["text": ["hi"]],
    flags: []
  )
  let runtime = RuntimeOptions(parsedValues: values)
  do {
    try await SendCommand.spec.run(values, runtime)
    #expect(Bool(false))
  } catch let error as ParsedValuesError {
    #expect(error.description.contains("Missing required option"))
  } catch {
    #expect(Bool(false))
  }
}

@Test
func sendCommandRunsWithStubSender() async throws {
  let values = ParsedValues(
    positional: [],
    options: ["to": ["+15551234567"], "text": ["hi"]],
    flags: []
  )
  let runtime = RuntimeOptions(parsedValues: values)
  var captured: MessageSendOptions?
  try await SendCommand.run(
    values: values,
    runtime: runtime,
    sendMessage: { options in
      captured = options
    }
  )
  #expect(captured?.recipient == "+15551234567")
  #expect(captured?.text == "hi")
}

@Test
func sendCommandResolvesChatID() async throws {
  let path = try CommandTestDatabase.makePath()
  let values = ParsedValues(
    positional: [],
    options: ["db": [path], "chatID": ["1"], "text": ["hi"]],
    flags: []
  )
  let runtime = RuntimeOptions(parsedValues: values)
  var captured: MessageSendOptions?
  try await SendCommand.run(
    values: values,
    runtime: runtime,
    sendMessage: { options in
      captured = options
    }
  )
  #expect(captured?.chatIdentifier == "+123")
  #expect(captured?.chatGUID == "iMessage;+;chat123")
  #expect(captured?.recipient.isEmpty == true)
}

private func jsonObject(from output: String) throws -> [String: Any] {
  let line = output.split(separator: "\n").first.map(String.init) ?? ""
  let data = Data(line.utf8)
  return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}
