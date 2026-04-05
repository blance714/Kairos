// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KairosKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "KairosKit", targets: ["KairosKit"]),
    ],
    targets: [
        .target(name: "KairosKit"),
    ]
)
