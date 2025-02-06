import MacroTesting
import StructTransactionMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class TrackingMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: false,
      macros: ["Tracking": TrackingMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func test_macro() {

    assertMacro {
      """
      @Tracking
      struct MyState {
      
        private var stored_0: Int = 18

        var stored_1: String
      
        let stored_2: Int = 0

        var age: Int { 0 }

        var age2: Int {
          get { 0 }
          set { }
        }

        var height: Int

        func compute() {
        }
      }
      """
    } expansion: {
      """
      struct MyState {
        @COWTrackingProperty

        private var stored_0: Int = 18
        @COWTrackingProperty

        var stored_1: String
        @COWTrackingProperty

        let stored_2: Int = 0

        var age: Int { 0 }

        var age2: Int {
          get { 0 }
          set { }
        }
        @COWTrackingProperty

        var height: Int

        func compute() {
        }

        let _tracking_context: _TrackingContext = .init()
      }

      extension MyState: TrackingObject {
      }

      extension MyState {

        func _tracking_propagate(path: PropertyPath) {
          _tracking_context.path = path
          (stored_0 as? TrackingObject)?._tracking_propagate(
        path: path.pushed(.init("stored_0"))
          )
          (stored_1 as? TrackingObject)?._tracking_propagate(
            path: path.pushed(.init("stored_1"))
          )
          (stored_2 as? TrackingObject)?._tracking_propagate(
            path: path.pushed(.init("stored_2"))
          )
          (height as? TrackingObject)?._tracking_propagate(
            path: path.pushed(.init("height"))
          )
        }
      }
      """
    }

  }
}
