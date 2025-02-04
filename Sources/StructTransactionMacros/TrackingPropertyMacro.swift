
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
    
    let renameRewriter = RenameIdentifierRewriter()
    let modifierRewriter = MakePrivateRewriter()
    
    var newMembers: [DeclSyntax] = []
    
    for binding in variableDecl.bindings {
      if binding.accessorBlock != nil {
        // skip computed properties
        continue
      }
      
      let backingStorageDecl = modifierRewriter.visit(
        renameRewriter.visit(variableDecl.trimmed)
      )
      
      newMembers.append(backingStorageDecl)
    }
    
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
    
    // `@TrackingProperty` は単一のプロパティにのみ適用可能
    guard let binding = variableDecl.bindings.first,
          let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
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
        modifyAccessor
      ]
    } else {
      return [
        getAccessor,
        setAccessor,
        modifyAccessor
      ]
    }
    
  }

  
}


final class RenameIdentifierRewriter: SyntaxRewriter {
  
  init() {}
  
  override func visit(_ node: IdentifierPatternSyntax) -> PatternSyntax {
    
    let propertyName = node.identifier.text
    let newIdentifier = IdentifierPatternSyntax.init(identifier: "_backing_\(raw: propertyName)")
    
    return super.visit(newIdentifier)
    
  }
}

final class MakePrivateRewriter: SyntaxRewriter {
  
  init() {}
  
  //  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
  //    return super.visit(node.trimmed(matching: { $0.isNewline }))
  //  }
  
  override func visit(_ node: DeclModifierListSyntax) -> DeclModifierListSyntax {
    if node.contains(where: { $0.name.tokenKind == .keyword(.private) }) {
      return super.visit(node)
    }
    
    var modified = node 
    modified.append(.init(name: .keyword(.private), trailingTrivia: .spaces(1)))    
    
    return super.visit(modified)
  }
}
