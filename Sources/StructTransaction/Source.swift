
@attached(extension, conformances: StateModifyingType, names: named(Modifying), named(modify(source:modifier:)), named(ModifyingTarget))
public macro Writing() = #externalMacro(module: "StructTransactionMacros", type: "WriterMacro")

public protocol StateModifyingType {

  associatedtype Modifying

  @discardableResult
  static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult
}

extension StateModifyingType {

  @discardableResult
  public mutating func modify(modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {
    try Self.modify(source: &self, modifier: modifier)
  }

}

public struct ModifyingResult {

  public let modifiedIdentifiers: Set<String>

  public init(modifiedIdentifiers: Set<String>) {
    self.modifiedIdentifiers = modifiedIdentifiers
  }
}

