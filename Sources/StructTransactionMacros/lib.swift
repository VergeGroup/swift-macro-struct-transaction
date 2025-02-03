import SwiftSyntax

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
