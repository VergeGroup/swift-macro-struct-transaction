
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

extension PropertyNode {
  
  public mutating func shakeAsWrite() {
    shake(where: { $0 == .write })
  }
  
  public mutating func shakeAsRead() {
    shake(where: { $0 == .read })
  }
  
  public mutating func shake(where predicate: (Status) -> Bool) { 
    nodes.removeAll {
      predicate($0.status) || $0.nodes.isEmpty
    }    
    nodes.modify { $0.shake(where: predicate) }
  }

}
