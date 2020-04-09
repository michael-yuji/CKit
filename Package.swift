// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CKit",
    products: [ .library(name: "CKit", type: .dynamic, targets: ["CKit"]) ],
    platforms: [
      .macOS(.v10_10),
      .iOS(.v8)
    ],
    dependencies: [
        .package(url: "https://github.com/michael-yuji/xlibc", from: "0.0.3")
    ],
    targets: [
      .target(name: "CKit", dependencies: ["xlibc"])
    ]
)
