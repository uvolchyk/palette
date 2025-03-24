import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Sandbox",
  packages: [
    .package(path: "../Packages/PLTMath"),
//    .package(path: "../Packages/PLTMetal"),
  ],
  targets: [
    .target(
      name: "Sandbox",
      destinations: .iOS,
      product: .app,
      bundleId: "$(APP_BUNDLE_ID)",
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [
          "UIColorName": "",
          "UIImageName": "",
        ],
      ]),
      sources: [
        "Sources/**"
      ],
      resources: [],
      dependencies: [
        .package(product: "PLTMath"),
        .project(
          target: "PLTMetal",
          path: "../Frameworks/PLTMetal"
        )
//        .package(product: "PLTMetal"), // https://developer.apple.com/forums/thread/649579 - it doesn't work :(
      ],
      settings: settings
    ),
    .target(
      name: "PLTMathSandbox",
      destinations: .iOS,
      product: .framework,
      bundleId: "$(PROJECT_BUNDLE_ID).pltmathsandbox",
      infoPlist: .extendingDefault(with: [:]),
      sources: [],
      resources: [],
      dependencies: [
        .package(product: "PLTMath")
      ],
      settings: settings
    ),
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
