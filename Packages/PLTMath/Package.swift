// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PLTMath",
  products: [
    .library(
      name: "PLTMath",
      targets: [
        "PLTMath"
      ]
    )
  ],
  targets: [
    .target(
      name: "PLTMath"
    )
  ]
)
