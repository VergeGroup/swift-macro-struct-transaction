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

  func test_copying_functions() {

    assertMacro {
      """
      @Detecting
      struct MyState {
        func hello() {
        }

        @Exporting
        func hello2() {
        }
      }
      """
    } expansion: {
      """
      struct MyState {
        func hello() {
        }

        @Exporting
        func hello2() {
        }
      }

      extension MyState: DetectingType {

        // MARK: - Accessing
        typealias AccessingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Accessing(pointer: pointer)
            try modifier(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: consuming Self, reader: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          // TODO: check copying costs
          var tmp = source

          return try withUnsafeMutablePointer(to: &tmp) { pointer in
            var modifying = Accessing(pointer: pointer)
            try reader(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        public struct Accessing /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<AccessingTarget>

          init(pointer: UnsafeMutablePointer<AccessingTarget>) {
            self.pointer = pointer
          }

          // MARK: - Properties



          // MARK: - Functions



          @Exporting
          func hello2() {
          }
        }

      }
      """
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

        // MARK: - Accessing
        typealias AccessingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Accessing(pointer: pointer)
            try modifier(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: consuming Self, reader: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          // TODO: check copying costs
          var tmp = source

          return try withUnsafeMutablePointer(to: &tmp) { pointer in
            var modifying = Accessing(pointer: pointer)
            try reader(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        public struct Accessing /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<AccessingTarget>

          init(pointer: UnsafeMutablePointer<AccessingTarget>) {
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

        // MARK: - Accessing
        typealias AccessingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Accessing(pointer: pointer)
            try modifier(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: consuming Self, reader: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          // TODO: check copying costs
          var tmp = source

          return try withUnsafeMutablePointer(to: &tmp) { pointer in
            var modifying = Accessing(pointer: pointer)
            try reader(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        public struct Accessing /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<AccessingTarget>

          init(pointer: UnsafeMutablePointer<AccessingTarget>) {
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

        // MARK: - Accessing
        typealias AccessingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Accessing(pointer: pointer)
            try modifier(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        @discardableResult
        public static func read(source: consuming Self, reader: (inout Accessing) throws -> Void) rethrows -> AccessingResult {

          // TODO: check copying costs
          var tmp = source

          return try withUnsafeMutablePointer(to: &tmp) { pointer in
            var modifying = Accessing(pointer: pointer)
            try reader(&modifying)
            return AccessingResult(
              readIdentifiers: modifying.$_readIdentifiers,
              modifiedIdentifiers: modifying.$_modifiedIdentifiers
            )
          }
        }

        public struct Accessing /* want to be ~Copyable */ {

          public private (set) var $_readIdentifiers: Set<String> = .init()
          public private (set) var $_modifiedIdentifiers: Set<String> = .init()

          private let pointer: UnsafeMutablePointer<AccessingTarget>

          init(pointer: UnsafeMutablePointer<AccessingTarget>) {
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

