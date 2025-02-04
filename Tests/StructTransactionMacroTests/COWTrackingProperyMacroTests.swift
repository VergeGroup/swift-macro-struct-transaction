import MacroTesting
import StructTransactionMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class COWTrackingProperyMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: false,
      macros: [
        "COWTrackingProperty": COWTrackingPropertyMacro.self,
        "TrackingIgnored": TrackingIgnoredMacro.self,
      ]
    ) {
      super.invokeTest()
    }
  }

  func test_macro() {

    assertMacro {
      """
      struct MyState {
      
        @COWTrackingProperty  
        private var stored_0: Int = 18
      
        func compute() {
        }
      }
      """
    } expansion: {
      """
      struct MyState {

        
        private var stored_0: Int = 18 {
          get {
            _backing_stored_0.value
          }
          set {
            if !isKnownUniquelyReferenced(&_backing_stored_0) {
              _backing_stored_0 = .init(_backing_stored_0.value)
            } else {
              _backing_stored_0.value = newValue
            }
          }
          _modify {
            if !isKnownUniquelyReferenced(&_backing_stored_0) {
              _backing_stored_0 = .init(_backing_stored_0.value)
            }
            yield &_backing_stored_0.value
          }
        }
          private var _backing_stored_0: _Backing_COW_Storage<Int> = .init(18)

        func compute() {
        }
      }
      """
    }

  }
}
