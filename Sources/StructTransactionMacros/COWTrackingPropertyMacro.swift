import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

public struct COWTrackingPropertyMacro {

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
        return .init(value: "_Backing_COW_Storage.init(\(initializer.value))" as ExprSyntax)        
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
    
    let readAccessor = AccessorDeclSyntax(
      """
      _read {
        _Tracking._tracking_modifyStorage {
          $0.accessorRead(path: _tracking_context.path?.pushed(.init("\(raw: propertyName)")))
        }
        yield \(raw: backingName).value    
      }
      """
    )

    let setAccessor = AccessorDeclSyntax(
      """
      set {                                 
        _Tracking._tracking_modifyStorage {
          $0.accessorSet(path: _tracking_context.path?.pushed(.init("\(raw: propertyName)")))
        }
        if !isKnownUniquelyReferenced(&\(raw: backingName)) {
          \(raw: backingName) = .init(newValue)
        } else {
          \(raw: backingName).value = newValue
        }
      
      }
      """
    )

    let modifyAccessor = AccessorDeclSyntax(
      """
      _modify {
        _Tracking._tracking_modifyStorage {
          $0.accessorModify(path: _tracking_context.path?.pushed(.init("\(raw: propertyName)")))
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
        readAccessor,
        setAccessor,
        modifyAccessor,
      ]
    } else {
      return [
        readAccessor,
        setAccessor,
        modifyAccessor,
      ]
    }

  }

}

