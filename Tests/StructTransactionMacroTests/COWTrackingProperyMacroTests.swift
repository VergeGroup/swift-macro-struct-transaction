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
          _read {
            _Tracking._tracking_modifyStorage {
              $0.accessorRead(path: _tracking_context.path?.pushed(.init("stored_0")))
            }
            yield _backing_stored_0.value
          }
          set {
            _Tracking._tracking_modifyStorage {
              $0.accessorSet(path: _tracking_context.path?.pushed(.init("stored_0")))
            }
            if !isKnownUniquelyReferenced(&_backing_stored_0) {
              _backing_stored_0 = .init(newValue)
            } else {
              _backing_stored_0.value = newValue
            }

          }
          _modify {
            _Tracking._tracking_modifyStorage {
              $0.accessorModify(path: _tracking_context.path?.pushed(.init("stored_0")))
            }
            if !isKnownUniquelyReferenced(&_backing_stored_0) {
              _backing_stored_0 = .init(_backing_stored_0.value)
            }
            yield &_backing_stored_0.value
          }
        }
          private var _backing_stored_0: _Backing_COW_Storage<Int> = _Backing_COW_Storage.init(18)

        func compute() {
        }
      }
      """
    }

  }
}
