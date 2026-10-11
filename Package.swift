// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "SwiftSymbols",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .visionOS(.v1)],
    products: [.library(name: "SwiftSymbols", targets: ["SwiftSymbols"]),
               .library(name: "SwiftSymbolsIndex", targets: ["SwiftSymbolsIndex"])],
    targets: [
        .target(name: "SwiftSymbolsIndex", resources: [.process("Resources")]),
        .target(name: "SwiftSymbols", dependencies: ["SwiftSymbolsIndex"]),
        .testTarget(name: "SwiftSymbolsIndexTests", dependencies: ["SwiftSymbolsIndex"])
    ]
)
