import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Sandbox",
  packages: [],
  targets: [
    .sandbox,
//    .target(
//      name: "PLTMathSandbox",
//      destinations: .iOS,
//      product: .framework,
//      bundleId: "$(PROJECT_BUNDLE_ID).pltmathsandbox",
//      infoPlist: .extendingDefault(with: [:]),
//      sources: [],
//      resources: [],
//      dependencies: [
//        .paletteMetal
//      ],
//      settings: .project
//    ),
    .paletteMetal,
    .paletteMath,

//    .target( // https://developer.apple.com/forums/thread/649579 - it doesn't work :(
//      name: "PLTMetalSandbox",
//      destinations: .iOS,
//      product: .framework,
//      bundleId: "$(PROJECT_BUNDLE_ID).pltmetalsandbox",
//      infoPlist: .extendingDefault(with: [:]),
//      sources: [],
//      resources: [],
//      dependencies: [
//        .package(product: "PLTMetal")
//      ],
//      settings: settings
//    )
  ]
)
