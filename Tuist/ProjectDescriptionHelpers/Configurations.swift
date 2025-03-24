import ProjectDescription

let developmentTeam = Environment.developmentTeam.getString(default: "")
let bundleIdPrefix = Environment.bundleIdPrefix.getString(default: "")

public extension TargetReference {
  static let mainApplication = TargetReference.target("Timely")
}

// MARK: - Configurations

public let configurationDevelopment: Configuration = .debug(
  name: .debug,
  settings: [
    "PROJECT_BUNDLE_ID": "$(BUNDLE_ID_PREFIX).palette",
    "APP_BUNDLE_ID": "$(PROJECT_BUNDLE_ID).sandbox.dev"
  ],
  xcconfig: .relativeToRoot("Sandbox/Configurations/Debug/sandbox.xcconfig")
)

public let configurationProduction: Configuration = .release(
  name: .release,
  settings: [
    "PROJECT_BUNDLE_ID": "$(BUNDLE_ID_PREFIX).palette",
    "APP_BUNDLE_ID": "$(PROJECT_BUNDLE_ID).sandbox"
  ],
  xcconfig: .relativeToRoot("Sandbox/Configurations/Release/sandbox.xcconfig")
)

public let settings: Settings = .settings(
  base: [
    "DEVELOPMENT_TEAM": .string(developmentTeam),
    "BUNDLE_ID_PREFIX": .string(bundleIdPrefix)
  ],
  configurations: [
    configurationDevelopment,
    configurationProduction
  ]
)
