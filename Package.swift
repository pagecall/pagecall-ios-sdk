// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PagecallSDK",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PagecallSDK",
            targets: ["PagecallSDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/alexpiezo/WebRTC.git", .upToNextMajor(from: "95.4638.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PagecallSDK",
            dependencies: ["WebRTC"],
            resources: [
                .copy("WKWebViewRTC/Js/jsWKWebViewRTC.js")
            ]),
        .testTarget(
            name: "PagecallSDKTests",
            dependencies: ["PagecallSDK"])
    ])
