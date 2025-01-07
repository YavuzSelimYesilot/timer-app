// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TimerApp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "TimerApp", targets: ["TimerApp"])
    ],
    targets: [
        .executableTarget(
            name: "TimerApp",
            path: "."
        )
    ]
) 