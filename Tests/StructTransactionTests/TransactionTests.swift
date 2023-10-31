import XCTest
import StructTransaction

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

final class WritingStateTests: XCTestCase {

  @Detecting
  struct MyState {

    @Clamped(min: 0, max: 300) var height: Int = 0

    var age: Int = 18
    var name: String

    @JustWrapper var edge: Int = 0

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

    @Detecting
    struct NestedAttached {
      var name: String = ""
    }

  }

  func testPropertyWrapper() {

    var myState = MyState(name: "")

    let r = MyState.modify(source: &myState) {
      // should be clamped
      $0.height = 400
    }

    XCTAssertEqual(myState.height, 300)

  }

  func testObserve() {

    var myState = MyState(name: "")

    let r = MyState.modify(source: &myState) {
      $0.name = "Hello"
    }

    XCTAssert(r.modifiedIdentifiers.contains("name"))

  }

  func testModifyNested() {

    var myState = MyState(name: "")

    let r = myState.modify {
      $0.nested.name = "hey"
    }

    XCTAssertEqual(r.modifiedIdentifiers, .init(["nested"]))
    XCTAssertEqual(myState.nested.name, "hey")
  }

  func testModifyOverComputedProperty() {

    var myState = MyState(name: "")

    let r = myState.modify {
      $0.computed_setter = "A"
    }

    XCTAssertEqual(r.modifiedIdentifiers, .init(["name"]))
    XCTAssertEqual(myState.name, "A")
  }

  func testModifyNestedAttached() {

    var myState = MyState(name: "")

    myState.nestedAttached.modify {
      $0.name = "A"
    }

    XCTAssertEqual(myState.nestedAttached.name, "A")

    myState.modify {

      $0.name = "A"

      $0.nestedAttached.modify {
        $0.name = "B"
      }
    }

    XCTAssertEqual(myState.name, "A")
    XCTAssertEqual(myState.nestedAttached.name, "B")

  }

}
