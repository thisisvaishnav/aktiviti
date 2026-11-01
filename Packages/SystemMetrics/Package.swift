// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SystemMetrics",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SystemMetrics",
            targets: ["SystemMetrics"]
        ),
        .executable(
            name: "metrics-cli",
            targets: ["metrics-cli"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SystemMetrics",
            dependencies: []
        ),
        .executableTarget(
            name: "metrics-cli",
            dependencies: ["SystemMetrics"]
        ),
        .testTarget(
            name: "SystemMetricsTests",
            dependencies: ["SystemMetrics"]
        ),
    ]
)
