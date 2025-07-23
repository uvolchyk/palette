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
    MTLQuestSeven(exercise: .checkerboard)
//    MTLQuestSix(exercise: .checkerboard)
//    MTLQuestFive(exercise: .checkerboard)
//    MTLQuestFour(exercise: .checkerboard)
//    MTLQuestThree(exercise: .wireframe)
//    MTLQuestTwo(exercise: .rectangle)
//    MTLQuestOne(exercise: .triangle)
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
