
final class ReferenceEdgeStorage<Value>: @unchecked Sendable {
  
  var value: Value
  
  init(_ value: consuming Value) {
    self.value = value
  }
  
  func read<T>(_ thunk: (borrowing Value) -> T) -> T {
    thunk(value)
  }
  
}

#if DEBUG
private struct Before {
  
  var value: Int
  
}

private struct After {
  
  var value: Int {
    get {
      _cow_value.value
    }
    set {
      if !isKnownUniquelyReferenced(&_cow_value) {
        _cow_value = .init(_cow_value.value)
      } else {
        _cow_value.value = newValue
      }      
    }
    _modify {
      if !isKnownUniquelyReferenced(&_cow_value) {
        _cow_value = .init(_cow_value.value)
      }
      yield &_cow_value.value
    }
  }
  
  private var _cow_value: ReferenceEdgeStorage<Int>
  
}

#endif
