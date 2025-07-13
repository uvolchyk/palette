//
//  Target-Sandbox.swift
//  Manifests
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import ProjectDescription

public extension Target {
  static let sandbox: Target = .target(
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
      "Sources/**",
    ],
    resources: [
      "Resources/**",
      "Sources/**/*.h",
    ],
    dependencies: [
      .paletteMetal,
      .paletteMath,
//        .package(product: "PLTMetal"), // https://developer.apple.com/forums/thread/649579 - it doesn't work :(
    ],
    settings: .project
  )
}

public extension TargetDependency {
  static let sandbox: TargetDependency = .target(name: "Sandbox")
}
