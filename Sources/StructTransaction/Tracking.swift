import Foundation

public struct Storage: Equatable {
  
  public struct Identifier: Hashable {
    public let name: String
    
    public init(name: String) {
      self.name = name
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

public func _tracking_modifyStorage(_ modifier: (inout Storage) -> Void) {
  guard Thread.current.threadDictionary["tracking"] != nil else {
    return
  }
  var storage = Thread.current.threadDictionary["tracking"] as! Storage
  modifier(&storage)
  Thread.current.threadDictionary["tracking"] = storage      
}

public func withTracking(_ perform: () -> Void) -> Storage {
  let current = Thread.current.threadDictionary["tracking"] as? Storage
  defer {
    Thread.current.threadDictionary["tracking"] = current
  }
  
  Thread.current.threadDictionary["tracking"] = Storage()  
  perform()  
  let result = Thread.current.threadDictionary["tracking"] as! Storage
  return result
}
