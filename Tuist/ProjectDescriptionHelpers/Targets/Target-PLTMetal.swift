//
//  Target-PLTMetal.swift
//  Manifests
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import ProjectDescription

public extension Target {
  static let paletteMetal: Target = .target(
    name: "PLTMetal",
    destinations: .iOS,
    product: .framework,
    bundleId: .appBundleId.dotAppend("metal"),
    infoPlist: .default,
    sources: [
      "Modules/PLTMetal/Sources/**",
    ],
    dependencies: [
    ],
    settings: .project
  )
}

public extension TargetDependency {
  static let paletteMetal: TargetDependency = .target(name: "PLTMetal")
}
