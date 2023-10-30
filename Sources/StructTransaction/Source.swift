
@attached(extension, conformances: DetectingType, names: named(Modifying), named(modify(source:modifier:)), named(read(source:reader:)), named(ModifyingTarget))
public macro Detecting() = #externalMacro(module: "StructTransactionMacros", type: "WriterMacro")

public protocol DetectingType {

  associatedtype Modifying

  @discardableResult
  static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult

  @discardableResult
  static func read(source: Self, reader: (Modifying) throws -> Void) rethrows -> ReadResult
}

extension DetectingType {

  @discardableResult
  public mutating func modify(modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {
    try Self.modify(source: &self, modifier: modifier)
  }

  @discardableResult
  public mutating func read(reader: (Modifying) throws -> Void) rethrows -> ReadResult {
    try Self.read(source: self, reader: reader)
  }
}

public struct ReadResult {

  public let readIdentifiers: Set<String>

  public init(
    readIdentifiers: Set<String>
  ) {
    self.readIdentifiers = readIdentifiers
  }
}


public struct ModifyingResult {

  public let readIdentifiers: Set<String>
  public let modifiedIdentifiers: Set<String>

  public init(
    readIdentifiers: Set<String>,
    modifiedIdentifiers: Set<String>
  ) {
    self.readIdentifiers = readIdentifiers
    self.modifiedIdentifiers = modifiedIdentifiers
  }
}

