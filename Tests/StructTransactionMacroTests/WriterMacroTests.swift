import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting

import StructTransactionMacros

final class WriterMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: false,
      macros: ["Detecting": WriterMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func test_() {

    assertMacro {
      #"""
      @Detecting
      struct MyState {

        @MyPropertyWrapper
        var stored_property_wrapper: String = ""

      }
      """#
    } expansion: {
      """
      struct MyState {

        @MyPropertyWrapper
        var stored_property_wrapper: String = ""

      }

      extension MyState: DetectingType {

        typealias ModifyingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Modifying(pointer: pointer)
            try modifier(&modifying)
            return ModifyingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: Self, reader: (Modifying) throws -> Void) rethrows -> ReadResult {
          // FIXME: avoid copying
          var reading = source

          return try withUnsafeMutablePointer(to: &reading) { pointer in
            let modifying = Modifying(pointer: pointer)
            try reader(modifying)
            return ReadResult(
              readIdentifiers: modifying.$_readIdentifiers
            )
          }
        }

        public struct Modifying /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<ModifyingTarget>

          init(pointer: UnsafeMutablePointer<ModifyingTarget>) {
            self.pointer = pointer
          }

          public var stored_property_wrapper: String  {
          mutating _read {
            $_readIdentifiers.insert("stored_property_wrapper")
            yield pointer.pointee.stored_property_wrapper
          }
          _modify {
            $_modifiedIdentifiers.insert("stored_property_wrapper")
            yield &pointer.pointee.stored_property_wrapper
          }
        }
        }
      }
      """
    }

  }

  func test_1() {

    assertMacro {
      #"""
      @Detecting
      struct MyState {

        let constant_has_initial_value: Int = 0

      }
      """#
    } expansion: {
      """
      struct MyState {

        let constant_has_initial_value: Int = 0

      }

      extension MyState: DetectingType {

        typealias ModifyingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Modifying(pointer: pointer)
            try modifier(&modifying)
            return ModifyingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: Self, reader: (Modifying) throws -> Void) rethrows -> ReadResult {
          // FIXME: avoid copying
          var reading = source

          return try withUnsafeMutablePointer(to: &reading) { pointer in
            let modifying = Modifying(pointer: pointer)
            try reader(modifying)
            return ReadResult(
              readIdentifiers: modifying.$_readIdentifiers
            )
          }
        }

        public struct Modifying /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<ModifyingTarget>

          init(pointer: UnsafeMutablePointer<ModifyingTarget>) {
            self.pointer = pointer
          }

          public var constant_has_initial_value: Int  {
          mutating _read {
            $_readIdentifiers.insert("constant_has_initial_value")
            yield pointer.pointee.constant_has_initial_value
          }
          _modify {
            $_modifiedIdentifiers.insert("constant_has_initial_value")
            yield &pointer.pointee.constant_has_initial_value
          }
        }
        }
      }
      """
    }

  }
  func test_getter() {

    assertMacro {
      #"""
      @Detecting
      struct MyState {
      
        var computed_read_only: Int {
          constant_has_initial_value
        }
      
        var computed_read_only2: Int {
          get {
            constant_has_initial_value
          }
        }
      
        var computed_readwrite: String {
          get {
            variable_no_initial_value
          }
          set {
            variable_no_initial_value = newValue
          }
        }
      }
      """#
    } expansion: {
      """
      struct MyState {

        var computed_read_only: Int {
          constant_has_initial_value
        }

        var computed_read_only2: Int {
          get {
            constant_has_initial_value
          }
        }

        var computed_readwrite: String {
          get {
            variable_no_initial_value
          }
          set {
            variable_no_initial_value = newValue
          }
        }
      }

      extension MyState: DetectingType {

        typealias ModifyingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Modifying(pointer: pointer)
            try modifier(&modifying)
            return ModifyingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: Self, reader: (Modifying) throws -> Void) rethrows -> ReadResult {
          // FIXME: avoid copying
          var reading = source

          return try withUnsafeMutablePointer(to: &reading) { pointer in
            let modifying = Modifying(pointer: pointer)
            try reader(modifying)
            return ReadResult(
              readIdentifiers: modifying.$_readIdentifiers
            )
          }
        }

        public struct Modifying /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<ModifyingTarget>

          init(pointer: UnsafeMutablePointer<ModifyingTarget>) {
            self.pointer = pointer
          }

          public var computed_read_only: Int
        {
          mutating get {
            constant_has_initial_value
        }
        }

        public var computed_read_only2: Int
        {
          mutating
              get {
                constant_has_initial_value
              }
        }

        public var computed_readwrite: String
        {
          mutating
              get {
                variable_no_initial_value
              }
              set {
                variable_no_initial_value = newValue
              }
        }
        }
      }
      """
    }
  }
}

