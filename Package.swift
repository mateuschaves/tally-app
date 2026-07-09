// swift-tools-version:5.9
import PackageDescription

// TallyCore is the platform-independent (Foundation-only) core of Tally.
// It has no AppKit/SwiftUI dependency, so `swift test` runs anywhere a Swift
// toolchain is available (macOS or Linux CI) and exercises the ported prototype
// logic: task engine, quick-entry parser, time formatting and the day report.
//
// The macOS app target lives in Sources/TallyApp and is built with Xcode via
// `project.yml` (XcodeGen) — see README.md.
let package = Package(
    name: "TallyCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TallyCore", targets: ["TallyCore"])
    ],
    targets: [
        .target(name: "TallyCore", path: "Sources/TallyCore"),
        .testTarget(
            name: "TallyCoreTests",
            dependencies: ["TallyCore"],
            path: "Tests/TallyCoreTests"
        )
    ]
)
