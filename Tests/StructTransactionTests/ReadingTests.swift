import XCTest
import StructTransaction

final class ReadingStateTests: XCTestCase {

  func test_read_stored_property() {

    let myState = MyState(name: "")

    let r = myState.read {
      _ = $0.name
    }

    XCTAssertEqual(r.readIdentifiers, ["name"])

  }

  func test_read_computed_property() {

    let myState = MyState(name: "")

    let r = myState.read {
      _ = $0.computedAge
    }

    XCTAssertEqual(r.readIdentifiers, ["age"])

  }

}
