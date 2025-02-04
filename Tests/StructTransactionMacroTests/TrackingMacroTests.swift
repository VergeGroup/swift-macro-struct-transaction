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
            
        @TrackingProperty

            
        var name: String

            
        var age: Int { 0 }

            
        var age2: Int {
            
          get { 0 }
            
          set { }
            
        }

            
        @Clamp
            
        @TrackingProperty
            
        var height: Int

            
        func compute() {
            
        }
            
      }
            
      """
    }

  }
}
