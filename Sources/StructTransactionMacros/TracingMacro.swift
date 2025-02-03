import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TracingMacro {
  public enum Error: Swift.Error {
    case foundNotStructType
  }
}

extension TracingMacro: MemberAttributeMacro {

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AttributeSyntax] {

    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.addDiagnostics(from: TracingMacro.Error.foundNotStructType, node: node)
      return []
    }

//    let collector = PropertyCollector(viewMode: .all)
//    collector.onError = { syntax, error in
//
//    }
//    collector.walk(structDecl.memberBlock)

    print(member)

    return [""]
  }

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {

    return []
  }

}
