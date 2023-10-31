
@propertyWrapper
struct JustWrapper<Value> {

  var wrappedValue: Value

}

@propertyWrapper
struct Clamped<Value: Comparable> {
  private var value: Value
  let min: Value
  let max: Value

  init(wrappedValue: Value, min: Value, max: Value) {
    self.min = min
    self.max = max
    self.value = Swift.min(Swift.max(wrappedValue, min), max)
  }

  var wrappedValue: Value {
    get { return value }
    set { value = Swift.min(Swift.max(newValue, min), max) }
  }
}
