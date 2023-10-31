
/**
 Available only for structs
 */
@attached(
  extension,
  conformances: DetectingType,
  names: named(Accessing),
  named(modify(source:modifier:)),
  named(read(source:reader:)),
  named(AccessingTarget)
)
public macro Detecting() = #externalMacro(module: "StructTransactionMacros", type: "WriterMacro")

/**
 Available only for member functions.
 Marker Macro that indicates if the function will be exported into Accessing struct.
 */
@attached(peer)
public macro Exporting() = #externalMacro(module: "StructTransactionMacros", type: "MarkerMacro")

/**
 Use ``Detecting()`` macro to adapt struct
 */
public protocol DetectingType {

  associatedtype Accessing

  @discardableResult
  static func modify(source: inout Self, modifier: (inout Accessing) throws -> Void) rethrows -> AccessingResult

  @discardableResult
  static func read(source: Self, reader: (inout Accessing) throws -> Void) rethrows -> AccessingResult
}

extension DetectingType {

  @discardableResult
  public mutating func modify(modifier: (inout Accessing) throws -> Void) rethrows -> AccessingResult {
    try Self.modify(source: &self, modifier: modifier)
  }

  @discardableResult
  public borrowing func read(reader: (inout Accessing) throws -> Void) rethrows -> AccessingResult {
    try Self.read(source: self, reader: reader)
  }
}

public struct AccessingResult {

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

