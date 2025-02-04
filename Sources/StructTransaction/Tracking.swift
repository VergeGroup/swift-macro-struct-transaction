import Foundation

public struct Storage: Equatable {
  
  public struct Identifier: Hashable {
    public let keyPath: AnyKeyPath
    
    public init(keyPath: AnyKeyPath) {
      self.keyPath = keyPath
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
  fileprivate var currentKeyPathStack: Tracking.KeyPathStack? {
    get {
      self[ThreadDictionaryKey.currentKeyPathStack] as? Tracking.KeyPathStack
    }
    set {
      self[ThreadDictionaryKey.currentKeyPathStack] = newValue
    }  
  }
  
  fileprivate var tracking: Storage? {
    get {
      self[ThreadDictionaryKey.tracking] as? Storage
    }
    set {
      self[ThreadDictionaryKey.tracking] = newValue
    }
  }
}

public enum Tracking {
  
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
  
  public static func _tracking_modifyStorage(_ modifier: (inout Storage) -> Void) {
    guard Thread.current.threadDictionary.tracking != nil else {
      return
    }
    modifier(&Thread.current.threadDictionary.tracking!)
  }
}

public func withTracking(_ perform: () -> Void) -> Storage {
  let current = Thread.current.threadDictionary.tracking
  defer {
    Thread.current.threadDictionary.tracking = current
  }
  
  Thread.current.threadDictionary.tracking = Storage()  
  perform()  
  let result = Thread.current.threadDictionary.tracking!
  return result
}
