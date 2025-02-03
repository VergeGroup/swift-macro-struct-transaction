import MacroTesting
import StructTransactionMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class TracingMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: false,
      macros: ["Tracing": TracingMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func test_macro() {

    assertMacro {
      """
      @Tracing
      struct MyState {

        var name: String

        var age: Int { 0 }

        @Clamp
        var height: Int

        func compute() {
        }
      }
      """
    } expansion: {
      """
      struct MyState {

        var name: String

        var age: Int { 0 }

        @Clamp
        var height: Int

        func compute() {
        }
      }
      """
    }

  }
}
