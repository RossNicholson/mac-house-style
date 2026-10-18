// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HouseStyle",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HouseStyle", targets: ["HouseStyle"]),
    ],
    targets: [
        .target(
            name: "HouseStyle",
            resources: [.copy("Fonts"), .copy("Icons")]
        ),
        .testTarget(
            name: "HouseStyleTests",
            dependencies: ["HouseStyle"]
        ),
    ]
)
