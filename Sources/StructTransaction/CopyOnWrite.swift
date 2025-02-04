
public final class _Backing_COW_Storage<Value>: @unchecked Sendable {
  
  public var value: Value
  
  public init(_ value: consuming Value) {
    self.value = value
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
  
  private var _cow_value: _Backing_COW_Storage<Int>
  
}

#endif
