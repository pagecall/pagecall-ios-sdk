// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pagecall",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PagecallCore",
            targets: ["PagecallCore", "AmazonChimeSDK", "AmazonChimeSDKMedia", "Mediasoup", "WebRTC"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PagecallCore",
            path: "Sources/PagecallSDK",
            resources: [
                .process("PagecallNative.js")
            ]),
        .binaryTarget(
            name: "AmazonChimeSDK",
            path: "Binaries/AmazonChimeSDK.xcframework"
        ),
        .binaryTarget(
            name: "AmazonChimeSDKMedia",
            path: "Binaries/AmazonChimeSDKMedia.xcframework"
        ),
        .binaryTarget(
            name: "Mediasoup",
            path: "Binaries/Mediasoup.xcframework"
        ),
        .binaryTarget(
            name: "WebRTC",
            path: "Binaries/WebRTC.xcframework"
        ),
        .testTarget(
            name: "PagecallSDKTests",
            dependencies: ["PagecallCore"])
    ])
