import PackageDescription

let package = Package(
    name: "CKit",
    dependencies: [
        .Package(url: "https://github.com/michael-yuji/xlibc.git", majorVersion: 0)
    ]
)
