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
    dependencies: [
        .package(url: "https://github.com/chesskit-app/chesskit-engine.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "ChessCoach",
            dependencies: [
                .product(name: "ChessKitEngine", package: "chesskit-engine")
            ],
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
