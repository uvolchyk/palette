//
//  Exercise.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/12/25.
//

import SwiftUI

struct SEExerciseScreen: View {
  @State private var exercise: Exercise = .threshold
  
  var body: some View {
    MetalView(exercise: self.exercise)
      .toolbar {
        Picker("Exercise", selection: self.$exercise) {
          ForEach(Exercise.allCases) {
            Text($0.description)
          }
        }
      }
#if os(iOS)
      .ignoresSafeArea()
#endif
  }
}

enum Exercise: Identifiable, CustomStringConvertible, CaseIterable {
  case passthrough
  case mirror
  case symmetry
  case rotation
  case zoom
  case zoomDistortion
  case repetition
  case spiral
  case thunder

  case clamp
  case fold
  case pixelise
  case vague
  case colonne
  case crash
  case scanline
  case doubleFrequency

  case noir
  case black
  case threshold
  case chromaticAberration
  
  var id: Self { self }
  
  var description: String {
    switch self {
    case .passthrough: "Passthrough"
    case .mirror: "Mirror"
    case .symmetry: "Symmetry"
    case .rotation: "Rotation"
    case .zoom: "Zoom"
    case .zoomDistortion: "Zoom Distortion"
    case .repetition: "Repetition"
    case .spiral: "Spiral"
    case .thunder: "Thunder"

    case .clamp: "Clamp"
    case .fold: "Fold"
    case .pixelise: "Pixelise"
    case .vague: "Vague"
    case .colonne: "Colonne"
    case .crash: "Crash"
    case .scanline: "Scanline"
    case .doubleFrequency: "Double Frequency"

    case .noir: "Noir"
    case .black: "Black"
    case .threshold: "Threshold"
    case .chromaticAberration: "Chromatic Aberration"
    }
  }

  var shaderFunctionName: String {
    switch self {
    case .passthrough: "transform_passthrough"
    case .mirror: "transform_mirror"
    case .symmetry: "transform_symmetry"
    case .rotation: "transform_rotation"
    case .zoom: "transform_zoom"
    case .zoomDistortion: "transform_zoomDistortion"
    case .repetition: "transform_repetitions"
    case .spiral: "transform_spiral"
    case .thunder: "transform_thunder"

    case .clamp: "transform_clamp"
    case .fold: "transform_fold"
    case .pixelise: "transform_pixelise"
    case .vague: "transform_vague"
    case .colonne: "transform_colonne"
    case .crash: "transform_crash"
    case .scanline: "transform_scanline"
    case .doubleFrequency: "transform_double_frequency"

    case .noir: "filter_noir"
    case .black: "filter_black"
    case .threshold: "filter_threshold"
    case .chromaticAberration: "filter_chromatic_aberration"
    }
  }
}
