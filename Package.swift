// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UtubeKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UtubeKit",
            targets: ["UtubeKit"]),
    ],
    dependencies: [
        .package(
          url: "https://github.com/google/GoogleSignIn-iOS",
          from: "9.0.0"),
    ],
    targets: [
        .target(
            name: "UtubeKit",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ]),
        .testTarget(
            name: "UtubeKitTests",
            dependencies: ["UtubeKit"]),
    ],
)
