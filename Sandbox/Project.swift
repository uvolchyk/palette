import ProjectDescription

let developmentTeam = Environment.developmentTeam.getString(default: "")
let bundleIdPrefix = Environment.bundleIdPrefix.getString(default: "")

extension TargetReference {
  static let mainApplication = TargetReference.target("Timely")
}

// MARK: - Configurations

let configurationDevelopment: Configuration = .debug(
  name: .debug,
  settings: [
    "APP_BUNDLE_ID": "$(BUNDLE_ID_PREFIX).palette.sandbox.dev"
  ],
  xcconfig: .relativeToRoot("Sandbox/Configurations/Debug/sandbox.xcconfig")
)

let configurationProduction: Configuration = .release(
  name: .release,
  settings: [
    "APP_BUNDLE_ID": "$(BUNDLE_ID_PREFIX).palette.sandbox"
  ],
  xcconfig: .relativeToRoot("Sandbox/Configurations/Release/sandbox.xcconfig")
)

let settings: Settings = .settings(
  base: [
    "DEVELOPMENT_TEAM": .string(developmentTeam),
    "BUNDLE_ID_PREFIX": .string(bundleIdPrefix)
  ],
  configurations: [
    configurationDevelopment,
    configurationProduction
  ]
)

let project = Project(
  name: "Sandbox",
  packages: [
    .package(path: "../Packages/PLTMath")
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
        .package(product: "PLTMath")
      ],
      settings: settings
    ),
//    .target(
//      name: "PLTMathSandbox",
//      destinations: .iOS,
//      product: .framework,
//      bundleId: "com.uvolchyk.palette.pltmathsandbox",
//      infoPlist: .extendingDefault(with: [:]),
//      sources: [],
//      resources: [],
//      dependencies: [
//        .package(product: "PLTMath")
//      ],
//      settings: settings
//    )
  ]
)
