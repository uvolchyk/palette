// swift-tools-version: 5.9
@preconcurrency import PackageDescription

#if TUIST
    @preconcurrency import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

// https://community.tuist.dev/t/workspace-and-local-spm-packages/111
let package = Package(
    name: "Sandbox",
    dependencies: [
    ]
)
