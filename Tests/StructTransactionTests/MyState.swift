import StructTransaction

@Tracking
struct MyState {

  var height: Int = 0
    
  var age: Int = 18
  var name: String

  var edge: Int = 0

  var computedName: String {
    get {
      "Mr. " + name
    }
  }

  var computedAge: Int {
    let age = age
    return age
  }

  var computed_setter: String {
    get {
      name
    }
    set {
      name = newValue
    }
  }

  var nested: Nested = .init(name: "hello")
  var nestedAttached: NestedAttached = .init(name: "")

  struct Nested {
    var name = ""
  }

  struct NestedAttached {
    var name: String = ""
  }

  mutating func updateName() {
    self.name = "Hiroshi"
  }

}
