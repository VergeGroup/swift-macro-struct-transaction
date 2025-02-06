import Foundation
import os.lock

extension Array {
  mutating func modify(_ modifier: (inout Element) -> Void) {
    for index in indices {
      modifier(&self[index])
    }
  }
}

public struct PropertyNode: Equatable {

  public struct Status: OptionSet, Sendable {
    public let rawValue: Int8

    public init(rawValue: Int8) {
      self.rawValue = rawValue
    }

    public static let read = Status(rawValue: 1 << 0)
    public static let write = Status(rawValue: 1 << 1)
  }

  public static var root: PropertyNode {
    .init(name: "root")
  }

  public let name: String
  public var status: Status = []

  public init(name: String) {
    self.name = name
  }

  public var nodes: [PropertyNode] = []

  private mutating func mark(status: Status) {
    self.status.insert(status)
  }

  public mutating func applyAsRead(path: PropertyPath) {
    apply(components: path.components, status: .read)
  }

  public mutating func applyAsWrite(path: PropertyPath) {
    apply(components: path.components, status: .write)
  }

  public mutating func apply(path: PropertyPath) {
    apply(components: path.components, status: [])
  }

  private mutating func apply(
    components: some RandomAccessCollection<PropertyPath.Component>, status: Status
  ) {

    guard let component = components.first else {
      return
    }

    guard name == component.value else {
      return
    }

    let next = components.dropFirst()

    guard !next.isEmpty else {
      self.mark(status: status)
      return
    }

    let targetName = next.first!.value

    let foundIndex: Int? = nodes.withUnsafeMutableBufferPointer { bufferPointer in
      for index in bufferPointer.indices {
        if bufferPointer[index].name == targetName {
          bufferPointer[index].apply(components: next, status: status)
          return index
        }
      }
      return nil
    }

    if foundIndex == nil {
      var newNode = PropertyNode(name: targetName)

      newNode.apply(components: next, status: status)

      nodes.append(newNode)
    }

  }

  @discardableResult
  public func prettyPrint() -> String {
    let output = prettyPrint(indent: 0)
    print(output)
    return output
  }
  
  private func prettyPrint(indent: Int = 0) -> String {
    let indentation = String(repeating: "  ", count: indent)
    var statusDescription: String {
      var result = ""
      if status.contains(.read) {
        result += "-"
      }
      if status.contains(.write) {
        result += "+"
      }
      return result
    }
    var output = "\(indentation)\(name)\(statusDescription)"

    if !nodes.isEmpty {
      output += " {\n"
      output += nodes.map { $0.prettyPrint(indent: indent + 1) }.joined(separator: "\n")
      output += "\n\(indentation)}"
    }
 
    return output
  }

}

public final class _TrackingContext: @unchecked Sendable {

  public var path: PropertyPath? {
    get {
      pathBox.withLockUnchecked {
        $0[Unmanaged.passUnretained(Thread.current).toOpaque()]
      }
    }
    set {
      pathBox.withLockUnchecked {
        $0[Unmanaged.passUnretained(Thread.current).toOpaque()] = newValue
      }
    }
  }

  @usableFromInline
  let pathBox: OSAllocatedUnfairLock<[UnsafeMutableRawPointer: PropertyPath]> = .init(
    uncheckedState: [:]
  )

  public init() {
  }
}

public struct PropertyPath: Equatable {

  public struct Component: Equatable {

    public let value: String

    public init(_ value: String) {
      self.value = value
    }

  }

  public var components: [Component] = []

  public init() {

  }

  public static var root: PropertyPath {
    let path = PropertyPath().pushed(.init("root"))
    return path
  }

  public consuming func pushed(_ component: Component) -> PropertyPath {
    self.components.append(component)
    return self
  }

}

public protocol TrackingObject {
  var _tracking_context: _TrackingContext { get }
  //  func _tracking_propagate(path: PropertyPath)
}

extension TrackingObject {

  public func tracking(_ applier: () -> Void) -> TrackingResult {
    startTracking()
    defer {
      endTracking()
    }
    return withTracking {
      applier()
    }
  }

  private func startTracking() {
    _tracking_context.path = .root
  }

  private func endTracking() {
  }

}

public struct TrackingResult: Equatable {

  public struct Identifier: Hashable {
    public let pathString: String

    public init(_ value: String) {
      self.pathString = value
    }
  }

  public private(set) var graph: PropertyNode = .root
  public private(set) var readGraph: PropertyNode = .root
  public private(set) var writeGraph: PropertyNode = .root

  public mutating func accessorRead(path: PropertyPath?) {
    guard let path = path else {
      return
    }
    graph.applyAsRead(path: path)
    readGraph.apply(path: path)
  }

  public mutating func accessorSet(path: PropertyPath?) {
    guard let path = path else {
      return
    }
    graph.applyAsWrite(path: path)
    writeGraph.apply(path: path)
  }

  public mutating func accessorModify(path: PropertyPath?) {
    guard let path = path else {
      return
    }
    graph.applyAsWrite(path: path)
    writeGraph.apply(path: path)
  }
}

private enum ThreadDictionaryKey {
  case tracking
  case currentKeyPathStack
}

extension NSMutableDictionary {

  fileprivate var tracking: TrackingResult? {
    get {
      self[ThreadDictionaryKey.tracking] as? TrackingResult
    }
    set {
      self[ThreadDictionaryKey.tracking] = newValue
    }
  }
}

public enum _Tracking {

  public static func _tracking_modifyStorage(_ modifier: (inout TrackingResult) -> Void) {
    guard Thread.current.threadDictionary.tracking != nil else {
      return
    }
    modifier(&Thread.current.threadDictionary.tracking!)
  }
}

private func withTracking(_ perform: () -> Void) -> TrackingResult {
  let current = Thread.current.threadDictionary.tracking
  defer {
    Thread.current.threadDictionary.tracking = current
  }

  Thread.current.threadDictionary.tracking = TrackingResult()
  perform()
  let result = Thread.current.threadDictionary.tracking!
  return result
}
