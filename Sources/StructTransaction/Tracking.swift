import Foundation
import os.lock

extension Array {
  mutating func modify(_ modifier: (inout Element) -> Void) {
    for index in indices {
      modifier(&self[index])
    }
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

  public var graph: PropertyNode = .root
  public var readGraph: PropertyNode = .root
  public var writeGraph: PropertyNode = .root

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
