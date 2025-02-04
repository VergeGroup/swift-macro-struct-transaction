import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct COWTrackingPropertyMacro {

  public enum Error: Swift.Error {

  }
}

extension COWTrackingPropertyMacro: PeerMacro {
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
      .modifyingTypeAnnotation({ type in
        return "_Backing_COW_Storage<\(type.trimmed)>"
      })
      .modifyingInit({ initializer in                
        return .init(value: ".init(\(initializer.value))" as ExprSyntax)        
      })
    
    _variableDecl.leadingTrivia = .spaces(2)

    newMembers.append(_variableDecl.trimmed.formatted(using: .init(indentationWidth: .spaces(2), initialIndentation: [])).as(DeclSyntax.self)!)

    return newMembers
  }
}

extension COWTrackingPropertyMacro: AccessorMacro {
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
        \(raw: backingName) = .init(initialValue)
      }
      """
    )

    let getAccessor = AccessorDeclSyntax(
      """
      get {
        _tracking_modifyStorage {
          $0.read(identifier: .init(name: "\(raw: propertyName)"))
        }
        return \(raw: backingName).value 
      }
      """
    )

    let setAccessor = AccessorDeclSyntax(
      """
      set {    
        _tracking_modifyStorage {
          $0.write(identifier: .init(name: "\(raw: propertyName)"))
        }
        if !isKnownUniquelyReferenced(&\(raw: backingName)) {
          \(raw: backingName) = .init(\(raw: backingName).value)
        } else {
          \(raw: backingName).value = newValue
        }
      }
      """
    )

    let modifyAccessor = AccessorDeclSyntax(
      """
      _modify {
        _tracking_modifyStorage {
          $0.write(identifier: .init(name: "\(raw: propertyName)"))
        }
        if !isKnownUniquelyReferenced(&\(raw: backingName)) {
          \(raw: backingName) = .init(\(raw: backingName).value)
        }
        yield &\(raw: backingName).value
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

