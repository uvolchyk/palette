//
//  SEMetalView.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/12/25.
//

import SwiftUI
import MetalKit

struct SEMetalView: UIViewRepresentable {
  let exercise: SEExercise

  func makeUIView(context: Context) -> MTKView {
    let renderer = context.coordinator
    return MTKView(frame: .zero, device: renderer.device).configure {
      $0.clearColor = MTLClearColorMake(0, 0, 0, 1)
      $0.colorPixelFormat = .rgba8Unorm
      $0.isPaused = true
      $0.enableSetNeedsDisplay = true
      $0.delegate = renderer
    }
  }

  func updateUIView(_ view: MTKView, context: Context) {
    context.coordinator.setExercise(self.exercise, view: view)
  }
}

extension SEMetalView {
  @MainActor
  func makeCoordinator() -> Pikachu2dRenderer {
    let device = MTLCreateSystemDefaultDevice()!
    return Pikachu2dRenderer(device: device, exercise: self.exercise)
  }
}
