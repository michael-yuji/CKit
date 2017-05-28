import PackageDescription

let package = Package(
    name: "CKit",
    dependencies: [
       // .Package(url: "https://github.com/michael-yuji/xlibc.git", Version(0,0,3))
       .Package(url: "../xlibc", Version(0,0,3))
    ]
)
