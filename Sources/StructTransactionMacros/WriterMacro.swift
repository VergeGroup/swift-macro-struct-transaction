import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum WriterMacroError: Error {
  case foundMultiBindingsStoredProperty
  case propertyNeed
  case foundNotStructType
}

public struct WriterMacro {

}

extension WriterMacro: ExtensionMacro {

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

    let accessingDecl = try Self.makeModifying(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )

    let extensionDecl = """
      extension \(type.trimmed): DetectingType {

      // MARK: - Accessing
      \(accessingDecl)

      }
      """ as DeclSyntax

    return [
      extensionDecl
        .formatted(
          using: .init(
            indentationWidth: .spaces(2),
            initialIndentation: [],
            viewMode: .fixedUp
          )
        )
        .cast(ExtensionDeclSyntax.self)
    ]

  }

  private static func makeModifying(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> CodeBlockItemListSyntax {
    // Decode the expansion arguments.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.addDiagnostics(from: WriterMacroError.foundNotStructType, node: node)
      return ""
    }

    let functions = declaration
      .memberBlock
      .members
      .compactMap {
        $0.as(MemberBlockItemSyntax.self)?.decl.as(FunctionDeclSyntax.self)
      }
      .filter {
        $0.attributes.contains { $0.trimmed.description == "@Exporting" }
      }

    let c = PropertyCollector(viewMode: .all)
    c.onError = { node, error in
      context.addDiagnostics(from: error, node: node)
    }
    c.walk(structDecl.memberBlock)

    let decls = c.properties.map { prop in

      switch prop {
      case .storedConstant(let b):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type) {
          mutating _read {
            $_readIdentifiers.insert("\(b.pattern)")
            yield pointer.pointee.\(b.pattern)
          }
        }
        """
      case .storedVaraiable(let b):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type) {
          mutating _read {
            $_readIdentifiers.insert("\(b.pattern)")
            yield pointer.pointee.\(b.pattern)
          }
          _modify {
            $_modifiedIdentifiers.insert("\(b.pattern)")
            yield &pointer.pointee.\(b.pattern)
          }
        }
        """
      case .computedGetOnly(let b, let accessorBlock):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type)
        \(makeMutatingGetter(accessorBlock))
        """
      case .computed(let b, let accessorBlock):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type)
        \(makeMutatingGetter(accessorBlock))
        """
      }

    }

    let modifyingStructDecl = """
      public struct Accessing /* want to be ~Copyable */ {

        public private(set) var $_readIdentifiers: Set<String> = .init()
        public private(set) var $_modifiedIdentifiers: Set<String> = .init()

        private let pointer: UnsafeMutablePointer<AccessingTarget>

        init(pointer: UnsafeMutablePointer<AccessingTarget>) {
          self.pointer = pointer
        }

        // MARK: - Properties

        \(raw: decls.joined(separator: "\n\n"))

        // MARK: - Functions

        \(raw: functions.map(\.description).joined(separator: "\n\n"))
      }
      """ as DeclSyntax

    let modifyingDecl =
      ("""
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

      \(modifyingStructDecl)

      """ as CodeBlockItemListSyntax)

    return modifyingDecl
  }

}

private func makeMutatingGetter(_ block: AccessorBlockSyntax) -> AccessorBlockSyntax {

  switch block.accessors {
  case .accessors(let list):

    let decl = MutatingGetterConverter().visit(list)

    return """
      {
        \(decl)
      }
      """ as AccessorBlockSyntax

  case .getter(let getter):
    return """
      {
        mutating get { \(getter) }
      }
      """ as AccessorBlockSyntax
  }

}

/// convert get-accessor into mutating-get-accessor
final class MutatingGetterConverter: SyntaxRewriter {

  override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {

    if node.accessorSpecifier.text == "get" || node.accessorSpecifier.text == "_read" {
      var _node = node
      _node.modifier = DeclModifierSyntax(name: "mutating")
      return super.visit(_node)
    }

    return super.visit(node)
  }

}

final class PropertyCollector: SyntaxVisitor {

  enum Property {
    case storedConstant(PatternBindingListSyntax.Element)
    case storedVaraiable(PatternBindingListSyntax.Element)
    case computedGetOnly(PatternBindingListSyntax.Element, AccessorBlockSyntax)
    case computed(PatternBindingListSyntax.Element, AccessorBlockSyntax)
  }

  var properties: [Property] = []

  var onError: (any SyntaxProtocol, Error) -> Void = { _, _ in }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    // walk only toplevel variables
    return .skipChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    return .skipChildren
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {

    guard node.bindings.count == 1 else {
      // let a,b,c = 0
      // it's stored
      onError(node, WriterMacroError.foundMultiBindingsStoredProperty)
      return .skipChildren
    }

    guard let binding: PatternBindingListSyntax.Element = node.bindings.first else {
      fatalError()
    }

    guard let _ = binding.typeAnnotation else {
      onError(node, MacroError(message: "Requires a type annotation, such as `identifier: Type`"))
      return .skipChildren
    }

    let isConstant = node.bindingSpecifier == "let"

    if isConstant {
      properties.append(.storedConstant(binding))
      return .skipChildren
    }

    guard let accessorBlock = binding.accessorBlock else {
      properties.append(.storedVaraiable(binding))
      return .skipChildren
    }

    // computed property

    switch accessorBlock.accessors {
    case .accessors(let x):
      let hasSetter = x.contains {
        $0.accessorSpecifier == "set" || $0.accessorSpecifier == "_modify"
      }
      if hasSetter {
        properties.append(.computed(binding, accessorBlock))
      } else {
        properties.append(.computedGetOnly(binding, accessorBlock))
      }
    case .getter:
      properties.append(.computedGetOnly(binding, accessorBlock))
      return .skipChildren
    }

    return .skipChildren
  }

}
