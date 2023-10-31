import XCTest
import StructTransaction

final class ModifyingStateTests: XCTestCase {

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
