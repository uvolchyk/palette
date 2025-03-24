import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "PLTMetal",
  targets: [
    .target(
      name: "PLTMetal",
      destinations: .iOS,
      product: .framework,
      bundleId: "$(PROJECT_BUNDLE_ID).pltmetal",
      infoPlist: .default,
      sources: [
        "Sources/**"
      ],
      resources: [],
      settings: settings
    )
  ]
)
