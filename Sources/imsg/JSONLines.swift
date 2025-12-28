import Foundation

enum JSONLines {
  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    return encoder
  }()

  static func print<T: Encodable>(_ value: T) throws {
    let data = try encoder.encode(value)
    if let line = String(data: data, encoding: .utf8) {
      Swift.print(line)
    }
  }
}
