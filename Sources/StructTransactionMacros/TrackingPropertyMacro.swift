import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TrackingPropertyMacro {

  public enum Error: Swift.Error {

  }
}

extension TrackingPropertyMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {

    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      return []
    }

    var newMembers: [DeclSyntax] = []

    let ignoreMacroAttached = variableDecl.attributes.contains {
      switch $0 {
      case .attribute(let attribute):
        return attribute.attributeName.description == "TrackingIgnored"
      case .ifConfigDecl:
        return false
      }
    }

    guard !ignoreMacroAttached else {
      return []
    }

    for binding in variableDecl.bindings {
      if binding.accessorBlock != nil {
        // skip computed properties
        continue
      }
    }

    var _variableDecl = variableDecl
    _variableDecl.attributes = [.init(.init(stringLiteral: "@TrackingIgnored"))]

    _variableDecl = _variableDecl
      .renamingIdentifier(with: "_backing_")
      .withPrivateModifier()


    newMembers.append(_variableDecl.as(DeclSyntax.self)!)

    return newMembers
  }
}

extension TrackingPropertyMacro: AccessorMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AccessorDeclSyntax] {

    guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
      return []
    }

    guard let binding = variableDecl.bindings.first,
      let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self)
    else {
      return []
    }

    let propertyName = identifierPattern.identifier.text
    let backingName = "_backing_" + propertyName

    let initAccessor = AccessorDeclSyntax(
      """
      @storageRestrictions(initializes: \(raw: backingName))
      init(initialValue) {
          \(raw: backingName) = initialValue
      }
      """
    )

    let getAccessor = AccessorDeclSyntax(
      """
      get { \(raw: backingName) }
      """
    )

    let setAccessor = AccessorDeclSyntax(
      """
      set { \(raw: backingName) = newValue }
      """
    )

    let modifyAccessor = AccessorDeclSyntax(
      """
      _modify {
          yield &\(raw: backingName)
      }
      """
    )

    if binding.initializer == nil {
      return [
        initAccessor,
        getAccessor,
        setAccessor,
        modifyAccessor,
      ]
    } else {
      return [
        getAccessor,
        setAccessor,
        modifyAccessor,
      ]
    }

  }

}

extension VariableDeclSyntax {
  func renamingIdentifier(with newName: String) -> VariableDeclSyntax {
    let newBindings = self.bindings.map { binding -> PatternBindingSyntax in

      if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) {

        let propertyName = identifierPattern.identifier.text

        let newIdentifierPattern = identifierPattern.with(
          \.identifier, "\(raw: newName)\(raw: propertyName)")
        return binding.with(\.pattern, .init(newIdentifierPattern))
      }
      return binding
    }

    return self.with(\.bindings, .init(newBindings))
  }
}

extension VariableDeclSyntax {
  func withPrivateModifier() -> VariableDeclSyntax {

    let privateModifier = DeclModifierSyntax.init(
      name: .keyword(.private), trailingTrivia: .spaces(1))

    var modifiers = self.modifiers
    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.private) }) {
      return self
    }
    modifiers.append(privateModifier)
    return self.with(\.modifiers, modifiers)
  }
}

extension VariableDeclSyntax {
  
  func modifyingTypeAnnotation(_ modifier: (TypeSyntax) -> TypeSyntax) -> VariableDeclSyntax {
    let newBindings = self.bindings.map { binding -> PatternBindingSyntax in
      if let typeAnnotation = binding.typeAnnotation {
        let newType = modifier(typeAnnotation.type)
        let newTypeAnnotation = typeAnnotation.with(\.type, newType)
        return binding.with(\.typeAnnotation, newTypeAnnotation)
      }
      return binding
    }

    return self.with(\.bindings, .init(newBindings))
  }
    
  func modifyingInit(_ modifier: (InitializerClauseSyntax) -> InitializerClauseSyntax) -> VariableDeclSyntax {
        
    let newBindings = self.bindings.map { binding -> PatternBindingSyntax in      
      if let initializer = binding.initializer {
        let newInitializer = modifier(initializer)
        return binding.with(\.initializer, newInitializer)
      }
      return binding
    }

    return self.with(\.bindings, .init(newBindings))
  }
  
}
