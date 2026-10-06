// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SSGBerk",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Publish.git", exact: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/Ink.git", exact: "0.6.0")
    ],
    targets: [
        .executableTarget(
            name: "SSGBerk",
            dependencies: [
                .product(name: "Publish", package: "Publish"),
                .product(name: "Ink", package: "Ink")
            ]
        )
    ]
)
