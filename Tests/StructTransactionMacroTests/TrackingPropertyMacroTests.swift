import MacroTesting
import StructTransactionMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class TrackingProperyMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: false,
      macros: [
        "TrackingProperty": TrackingPropertyMacro.self,
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
      
        @TrackingProperty      
        private var stored_0: Int = 18
      
        @TrackingProperty      
        var stored_1: String
      
        @TrackingProperty      
        let stored_2: Int = 0
      
        var age: Int { 0 }
      
        var age2: Int {
          get { 0 }
          set { }
        }
      
        @TrackingProperty
        var height: Int
      
        func compute() {
        }
      }
      """
    } expansion: {
      """
      struct MyState {

        
        private var stored_0: Int = 18 {
          get {
            _backing_stored_0
          }
          set {
            _backing_stored_0 = newValue
          }
          _modify {
              yield &_backing_stored_0
          }
        }
          private var _backing_stored_0: Int = 18

        
        var stored_1: String {
          @storageRestrictions(initializes: _backing_stored_1)
          init(initialValue) {
              _backing_stored_1 = initialValue
          }
          get {
            _backing_stored_1
          }
          set {
            _backing_stored_1 = newValue
          }
          _modify {
              yield &_backing_stored_1
          }
        }

        private
          var _backing_stored_1: String

        
        let stored_2: Int = 0 {
          get {
            _backing_stored_2
          }
          set {
            _backing_stored_2 = newValue
          }
          _modify {
              yield &_backing_stored_2
          }
        }

        private
          let _backing_stored_2: Int = 0

        var age: Int { 0 }

        var age2: Int {
          get { 0 }
          set { }
        }
        var height: Int {
          @storageRestrictions(initializes: _backing_height)
          init(initialValue) {
              _backing_height = initialValue
          }
          get {
            _backing_height
          }
          set {
            _backing_height = newValue
          }
          _modify {
              yield &_backing_height
          }
        }

        private
          var _backing_height: Int

        func compute() {
        }
      }
      """
    }

  }
}
