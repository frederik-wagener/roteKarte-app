// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RoteKarteCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "RoteKarteCore", targets: ["RoteKarteCore"]),
    ],
    targets: [
        .target(name: "RoteKarteCore"),
        .testTarget(name: "RoteKarteCoreTests", dependencies: ["RoteKarteCore"]),
    ]
)
