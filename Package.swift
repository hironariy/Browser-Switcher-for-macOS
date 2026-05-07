// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DefaultBrowserSwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "BrowserSwitcherCore", targets: ["BrowserSwitcherCore"]),
        .executable(name: "BrowserSwitcher", targets: ["BrowserSwitcher"])
    ],
    targets: [
        .target(name: "BrowserSwitcherCore"),
        .executableTarget(
            name: "BrowserSwitcher",
            dependencies: ["BrowserSwitcherCore"]
        )
    ]
)
