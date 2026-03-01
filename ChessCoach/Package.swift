// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChessCoach",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ChessCoach",
            targets: ["ChessCoach"]
        )
    ],
    targets: [
        .target(
            name: "ChessCoach",
            path: "Sources/ChessCoach",
            exclude: ["Resources"],
            swiftSettings: [
                .define("SPM_BUILD")
            ]
        ),
        .testTarget(
            name: "ChessCoachTests",
            dependencies: ["ChessCoach"],
            path: "Tests/ChessCoachTests"
        )
    ]
)
