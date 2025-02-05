import MacroTesting
import StructTransactionMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class COWTrackingProperyMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: true,
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
      #"""
      struct MyState {

        
        private var stored_0: Int = 18 {
          _read {
            let currentKeyPath = (_backing_stored_0 as? TrackingObject)?._tracking_context.parentKeyPath?.appending(path: \Self.stored_0) ?? \Self.stored_0
            Tracking._tracking_modifyStorage {
              $0.read(identifier: .init(keyPath: currentKeyPath))
            }
            yield _backing_stored_0.value
          }
          set {

            (newValue as? TrackingObject)?.propagateKeyPath(\Self.stored_0)

            let currentKeyPath = (_backing_stored_0 as? TrackingObject)?._tracking_context.parentKeyPath?.appending(path: \Self.stored_0) ?? \Self.stored_0
            Tracking._tracking_modifyStorage {
              $0.write(identifier: .init(keyPath: currentKeyPath))
            }
            if !isKnownUniquelyReferenced(&_backing_stored_0) {
              _backing_stored_0 = .init(newValue)
            } else {
              _backing_stored_0.value = newValue
            }

          }
          _modify {
            let currentKeyPath = (_backing_stored_0 as? TrackingObject)?._tracking_context.parentKeyPath?.appending(path: \Self.stored_0) ?? \Self.stored_0
            Tracking._tracking_modifyStorage {
              $0.write(identifier: .init(keyPath: currentKeyPath))
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
      """#
    }

  }
}
