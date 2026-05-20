// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "WindowResizeHelper",
  platforms: [.macOS(.v12)],
  targets: [
    .executableTarget(
      name: "WindowResizeHelper",
      path: "Sources/WindowResizeHelper"
    )
  ]
)
