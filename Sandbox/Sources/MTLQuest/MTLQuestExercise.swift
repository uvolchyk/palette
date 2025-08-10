//
//  MTLQuestExercise.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import SwiftUI

struct MTLQuestExerciseScreen: View {
  @State private var exercise: MTLQuestExercise = .wireframe
  
  var body: some View {
    MTLQuestShadingContainer(exercise: .checkerboard)
//    MTLQuestInstancedRotationsContainer(exercise: .checkerboard)
//    MTLQuestBasicRotationsContainer(exercise: .checkerboard)
//    MTLQuestCameraRotationContainer(exercise: .checkerboard)
//    MTLQuestModelLoading(exercise: .checkerboard)
//    MTLQuestUVMapping(exercise: .checkerboard)
//    MTLQuestBasic3D(exercise: .checkerboard)
//    MTLQuestBasicMVP(exercise: .checkerboard)
//    MTLQuestFlipBook(exercise: .checkerboard)
//    MTLQuestCheckerboard(exercise: .checkerboard)
//    MTLQuestBasicWireframe(exercise: .wireframe)
//    MTLQuestBasicRectangle(exercise: .rectangle)
//    MTLQuestBasicTriangle(exercise: .triangle)
  }
}

enum MTLQuestExercise: Identifiable, CustomStringConvertible, CaseIterable {
  case triangle
  case rectangle
  case wireframe
  case checkerboard
  
  var id: Self { self }
  
  var description: String {
    switch self {
    case .triangle: "Triangle"
    case .rectangle: "Rectangle"
    case .wireframe: "Wireframe"
    case .checkerboard: "Checkerboard"
    }
  }

  var shaderFunctionName: String {
    switch self {
    case .triangle: "transform_triangle"
    case .rectangle: "transform_rectangle"
    case .wireframe: "transform_wireframe"
    case .checkerboard: "transform_checkerboard"
    }
  }
}
