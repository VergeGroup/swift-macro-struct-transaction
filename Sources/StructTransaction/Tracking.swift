import Foundation
import os.lock

public final class _TrackingContext: @unchecked Sendable {
  
  public weak var parent: _TrackingContext?
      
  public var path: PropertyPath? {
    get {
      storage.withLockUnchecked {
        $0[Unmanaged.passUnretained(Thread.current).toOpaque()]
      }
    }
    set {
      storage.withLockUnchecked {
        $0[Unmanaged.passUnretained(Thread.current).toOpaque()] = newValue
      }
    }
  }
    
  @usableFromInline
  let storage: OSAllocatedUnfairLock<[UnsafeMutableRawPointer : PropertyPath]> = .init(
    uncheckedState: [:]
  )
  
  public func makePath(endpoint: PropertyPath) -> String {
    sequence(first: self, next: { $0?.parent })
      .reversed()
      .map { $0?.path?.value ?? "" }
      .joined(separator: ".") + "." + endpoint.value
  }
    
  public init() {    
  }
}

public struct PropertyPath {
  
  public let value: String
  
  public init(_ value: String) {
    self.value = value
  }
  
}

public protocol TrackingObject {
  var _tracking_context: _TrackingContext { get }
  func _tracking_propagate(parentContext: _TrackingContext?, path: PropertyPath)
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
    self._tracking_propagate(parentContext: nil, path: .init(_typeName(type(of: self))))
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
  
  public private(set) var readIdentifiers: Set<Identifier> = []
  public private(set) var writeIdentifiers: Set<Identifier> = []
  
  public mutating func read(identifier: Identifier) {
    readIdentifiers.insert(identifier)
  }
  
  public mutating func write(identifier: Identifier) {
    writeIdentifiers.insert(identifier)
  }
}

private enum ThreadDictionaryKey {
  case tracking
  case currentKeyPathStack
}

extension NSMutableDictionary {
  fileprivate var currentKeyPathStack: _Tracking.KeyPathStack? {
    get {
      self[ThreadDictionaryKey.currentKeyPathStack] as? _Tracking.KeyPathStack
    }
    set {
      self[ThreadDictionaryKey.currentKeyPathStack] = newValue
    }  
  }
  
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
  
  public static func _pushKeyPath(_ keyPath: AnyKeyPath) {
    if Thread.current.threadDictionary.currentKeyPathStack == nil {
      Thread.current.threadDictionary.currentKeyPathStack = KeyPathStack()
    }
    
    Thread.current.threadDictionary.currentKeyPathStack?.push(
      keyPath
    )
  }
  
  public static func _currentKeyPath(_ keyPath: AnyKeyPath) -> AnyKeyPath? {
    guard let current = Thread.current.threadDictionary.currentKeyPathStack else {
      return keyPath
    }
    return current.currentKeyPath()?.appending(path: keyPath)
  }
  
  public static func _popKeyPath() {
    Thread.current.threadDictionary.currentKeyPathStack?.pop()
  }
  
  fileprivate struct KeyPathStack: Equatable {
    
    var stack: [AnyKeyPath]
    
    init() {
      stack = []
    }
    
    mutating func push(_ keyPath: AnyKeyPath) {
      stack.append(keyPath)
    }
    
    mutating func pop() {
      stack.removeLast()
    }
    
    func currentKeyPath() -> AnyKeyPath? {
      
      guard var keyPath = stack.first else {
        return nil
      }
      
      for component in stack.dropFirst() {
        guard let appended = keyPath.appending(path: component) else {
          return nil          
        }
        
        keyPath = appended
      }
      
      return keyPath
    }
      
        
  }
  
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
