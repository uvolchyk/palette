import ProjectDescription

let developmentTeam = Environment.developmentTeam.getString(default: "")
let bundleIdPrefix = Environment.bundleIdPrefix.getString(default: "")

// MARK: - Configurations

public let configurationDevelopment: Configuration = .debug(
  name: .debug,
  settings: [
    "PROJECT_BUNDLE_ID": "$(BUNDLE_ID_PREFIX).palette",
    "APP_BUNDLE_ID": "$(PROJECT_BUNDLE_ID).sandbox.dev",
    "MTL_HEADER_SEARCH_PATHS": "\"$(SRCROOT)/Sources/ShaderExam/Include\"/**",
    "HEADER_SEARCH_PATHS": "\"$(SRCROOT)/Sources/ShaderExam/Include\"/**",
  ],
  xcconfig: .relativeToRoot("Sandbox/Configurations/Debug/sandbox.xcconfig")
)

public let configurationProduction: Configuration = .release(
  name: .release,
  settings: [
    "PROJECT_BUNDLE_ID": "$(BUNDLE_ID_PREFIX).palette",
    "APP_BUNDLE_ID": "$(PROJECT_BUNDLE_ID).sandbox",
    "MTL_HEADER_SEARCH_PATHS": "\"$(SRCROOT)/Sources/ShaderExam/Include\"/**",
    "HEADER_SEARCH_PATHS": "\"$(SRCROOT)/Sources/ShaderExam/Include\"/**",
  ],
  xcconfig: .relativeToRoot("Sandbox/Configurations/Release/sandbox.xcconfig")
)

public extension Settings {
  static let project: Settings = .settings(
    base: [
      "DEVELOPMENT_TEAM": .string(developmentTeam),
      "BUNDLE_ID_PREFIX": .string(bundleIdPrefix),
    ],
    configurations: [
      configurationDevelopment,
      configurationProduction
    ]
  )
}

public extension String {
  static let appBundleId = "$(APP_BUNDLE_ID)"

  func dotAppend(_ string: String) -> String {
    self + "." + string
  }
}
