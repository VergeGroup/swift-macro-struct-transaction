
final class ReferenceEdgeStorage<Value>: @unchecked Sendable {
  
  var value: Value
  
  init(_ value: consuming Value) {
    self.value = value
  }
  
  func read<T>(_ thunk: (borrowing Value) -> T) -> T {
    thunk(value)
  }
  
}
