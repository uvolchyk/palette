//
//  Target-PLTMath.swift
//  Manifests
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import ProjectDescription

public extension Target {
  static let paletteMath: Target = .target(
    name: "PLTMath",
    destinations: .iOS,
    product: .framework,
    bundleId: .appBundleId.dotAppend("math"),
    infoPlist: .default,
    sources: [
      "Modules/PLTMath/Sources/**",
    ],
    dependencies: [
    ],
    settings: .project
  )
}

public extension TargetDependency {
  static let paletteMath: TargetDependency = .target(name: "PLTMath")
}
