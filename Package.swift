// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-macro-struct-transaction",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "StructTransaction",
      targets: ["StructTransaction"]
    ),
    .executable(
      name: "StructTransactionClient",
      targets: ["StructTransactionClient"]
    ),
  ],
  dependencies: [
    // Depend on the Swift 5.9 release of SwiftSyntax
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.2.1")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    // Macro implementation that performs the source transformation of a macro.
    .macro(
      name: "StructTransactionMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),

    // Library that exposes a macro as part of its API, which is used in client programs.
    .target(
      name: "StructTransaction",
      dependencies: ["StructTransactionMacros"]
    ),

    // A client of the library, which is able to use the macro in its own code.
    .executableTarget(
      name: "StructTransactionClient",
      dependencies: ["StructTransaction"]
    ),

    // A test target used to develop the macro implementation.
    .testTarget(
      name: "StructTransactionMacroTests",
      dependencies: [
        "StructTransactionMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),

    .testTarget(
      name: "StructTransactionTests",
      dependencies: [
        "StructTransaction"
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
