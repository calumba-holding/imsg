import Foundation

enum TypedStreamParser {
  static func parseAttributedBody(_ data: Data) -> String {
    guard !data.isEmpty else { return "" }
    var bytes = [UInt8](data)
    let start = [UInt8(0x01), UInt8(0x2b)]
    let end = [UInt8(0x86), UInt8(0x84)]

    if let startIndex = bytes.firstIndex(of: start[0]) {
      if startIndex + 1 < bytes.count, bytes[startIndex + 1] == start[1] {
        bytes = Array(bytes[(startIndex + 2)...])
      }
    }
    if let endIndex = bytes.firstIndex(of: end[0]) {
      if endIndex + 1 < bytes.count, bytes[endIndex + 1] == end[1] {
        bytes = Array(bytes[..<endIndex])
      }
    }

    let text = String(decoding: bytes, as: UTF8.self)
    return text.trimmingLeadingControlCharacters()
  }
}

extension String {
  fileprivate func trimmingLeadingControlCharacters() -> String {
    var scalars = unicodeScalars
    while let first = scalars.first,
      CharacterSet.controlCharacters.contains(first) || first == "\n" || first == "\r"
    {
      scalars.removeFirst()
    }
    return String(String.UnicodeScalarView(scalars))
  }
}
