import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TrackingMacro: Macro {
    
  public enum Error: Swift.Error {
    case needsTypeAnnotation
    case notFoundPropertyName
  }
  
  public static var formatMode: FormatMode = .disabled
  
}

extension TrackingMacro: MemberAttributeMacro {
  
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    
    guard let variableDecl = member.as(VariableDeclSyntax.self) else {
      return []
    }
    
    // to ignore computed properties
    for binding in variableDecl.bindings {
      if binding.accessorBlock != nil {
        return []
      }
    }
    
    if variableDecl.bindingSpecifier.tokenKind == .keyword(.let) ||
        variableDecl.bindingSpecifier.tokenKind == .keyword(.var) {
      let macroAttribute = "@COWTrackingProperty"
      let attributeSyntax = AttributeSyntax.init(stringLiteral: macroAttribute)
      
      return [attributeSyntax]
    }
    
    return []
  }

}
