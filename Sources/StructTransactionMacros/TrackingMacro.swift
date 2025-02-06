import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TrackingMacro: Macro {

  public enum Error: Swift.Error {
    case needsTypeAnnotation
    case notFoundPropertyName
  }

  public static var formatMode: FormatMode {
    .auto
  }

}

extension TrackingMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    
    return [
      """
      let _tracking_context: _TrackingContext = .init()
      """ as DeclSyntax
    ]
  }
}

extension TrackingMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {

    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      fatalError()
    }

    let members = declaration.memberBlock.members.compactMap { member -> String? in
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else {
        return nil
      }
      
      guard let binding = variableDecl.bindings.first,
            let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self)
      else {
        return nil
      }

      // 計算プロパティはスキップ
      if binding.accessorBlock != nil {
        return nil
      }

      return identifierPattern.identifier.text
    }
    
    let operation = members.map { member in
      """
      (\(member) as? TrackingObject)?._tracking_propagate(
        path: path.pushed(.init("\(member)"))
      )
      """
    }.joined(separator: "\n")
    
    return [
      ("""
      extension \(structDecl.name.trimmed): TrackingObject {      
      }
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self),
//      ("""
//      extension \(structDecl.name.trimmed) {
//      
//        func _tracking_propagate(path: PropertyPath) {
//          _tracking_context.path = path
//          \(raw: operation)
//        }
//      }
//      """ as DeclSyntax).formatted().cast(ExtensionDeclSyntax.self)
    ]
  }
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

    if variableDecl.bindingSpecifier.tokenKind == .keyword(.let)
      || variableDecl.bindingSpecifier.tokenKind == .keyword(.var)
    {
      let macroAttribute = "@COWTrackingProperty"
      let attributeSyntax = AttributeSyntax.init(stringLiteral: macroAttribute)

      return [attributeSyntax]
    }

    return []
  }

}
