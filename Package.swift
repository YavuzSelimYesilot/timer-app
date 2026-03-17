// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusTimer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FocusTimer", targets: ["FocusTimer"])
    ],
    targets: [
        .target(
            name: "TimerCore",
            path: "Sources/TimerCore"
        ),
        .executableTarget(
            name: "FocusTimer",
            dependencies: ["TimerCore"],
            path: "Sources/FocusTimer"
        )
    ]
)
