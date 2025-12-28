import Commander
import Foundation

struct HelpPrinter {
  static func printRoot(version: String, rootName: String, commands: [CommandSpec]) {
    Swift.print("\(rootName) \(version)")
    Swift.print("Send and read iMessage / SMS from the terminal")
    Swift.print("")
    Swift.print("Usage:")
    Swift.print("  \(rootName) <command> [options]")
    Swift.print("")
    Swift.print("Commands:")
    for command in commands {
      Swift.print("  \(command.name)\t\(command.abstract)")
    }
    Swift.print("")
    Swift.print("Run '\(rootName) <command> --help' for details.")
  }

  static func printCommand(rootName: String, spec: CommandSpec) {
    Swift.print("\(rootName) \(spec.name)")
    Swift.print(spec.abstract)
    if let discussion = spec.discussion, !discussion.isEmpty {
      Swift.print("\n\(discussion)")
    }
    Swift.print("")
    Swift.print("Usage:")
    Swift.print("  \(rootName) \(spec.name) \(usageFragment(for: spec.signature))")
    Swift.print("")

    if !spec.signature.arguments.isEmpty {
      Swift.print("Arguments:")
      for arg in spec.signature.arguments {
        let optionalMark = arg.isOptional ? "?" : ""
        Swift.print("  \(arg.label)\(optionalMark)\t\(arg.help ?? "")")
      }
      Swift.print("")
    }

    let options = spec.signature.options
    let flags = spec.signature.flags
    if !options.isEmpty || !flags.isEmpty {
      Swift.print("Options:")
      for option in options {
        let names = formatNames(option.names, expectsValue: true)
        Swift.print("  \(names)\t\(option.help ?? "")")
      }
      for flag in flags {
        let names = formatNames(flag.names, expectsValue: false)
        Swift.print("  \(names)\t\(flag.help ?? "")")
      }
      Swift.print("")
    }

    if !spec.usageExamples.isEmpty {
      Swift.print("Examples:")
      for example in spec.usageExamples {
        Swift.print("  \(example)")
      }
    }
  }

  private static func usageFragment(for signature: CommandSignature) -> String {
    var parts: [String] = []
    for argument in signature.arguments {
      let token = argument.isOptional ? "[\(argument.label)]" : "<\(argument.label)>"
      parts.append(token)
    }
    if !signature.options.isEmpty || !signature.flags.isEmpty {
      parts.append("[options]")
    }
    return parts.joined(separator: " ")
  }

  private static func formatNames(_ names: [CommanderName], expectsValue: Bool) -> String {
    let parts = names.map { name -> String in
      switch name {
      case .short(let char):
        return "-\(char)"
      case .long(let value):
        return "--\(value)"
      case .aliasShort(let char):
        return "-\(char)"
      case .aliasLong(let value):
        return "--\(value)"
      }
    }
    let suffix = expectsValue ? " <value>" : ""
    return parts.joined(separator: ", ") + suffix
  }
}
