//
//  MTLQuestBasicTriangle.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import SwiftUI
import MetalKit
import PLTMetal
import PLTMath

/// Solid-color triangle
/// Set up the render pipeline, vertex buffer, and a fragment shader that returns a constant color. Confirms your tool-chain works.
///
/// Per-vertex colors
/// Pass a color attribute per vertex and interpolate it in the fragment shader. Teaches varying inputs and barycentric interpolation.
struct MTLQuestBasicTriangle: UIViewRepresentable {
  let exercise: MTLQuestExercise

  func makeUIView(context: Context) -> MTKView {
    let coordinator = context.coordinator
    return MTKView(
      frame: .zero,
      device: coordinator.renderer.device
    ).configure { [unowned coordinator] in
      $0.clearColor = MTLClearColorMake(0, 0, 0, 1)
      $0.colorPixelFormat = .rgba8Unorm
      $0.isPaused = true
      $0.enableSetNeedsDisplay = true
      $0.delegate = coordinator.renderer
    }
  }

  func updateUIView(
    _ view: MTKView,
    context: Context
  ) {}
}

extension MTLQuestBasicTriangle {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise)
  }

  final class Coordinator {
    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!

    lazy var renderer: MTLQuestRenderer = {
      MTLQuestRenderer(
        device: device
      ) { [unowned device, unowned self] buffer, view in
        guard
          let viewRenderDescriptor = view.currentRenderPassDescriptor,
          let drawable = view.currentDrawable
        else {
          return
        }
        
        // 1. Creating a brush

        let vDesc = MTLVertexDescriptor()
          .configure {
            // attribute(0) – position
            $0.attributes[0].format = .float4
            $0.attributes[0].offset = 0
            $0.attributes[0].bufferIndex = 0
            // attribute(1) – texCoord
            $0.attributes[1].format = .float3
            $0.attributes[1].offset = MemoryLayout<Float>.size * 4
            $0.attributes[1].bufferIndex = 0

            $0.layouts[0].stride = MemoryLayout<Float>.size * 7
          }

        let trianglePassDescriptor = MTLRenderPipelineDescriptor()
          .configure {
            $0.vertexDescriptor = vDesc
            $0.vertexFunction = try! library.function(named: "triVertex")
            $0.fragmentFunction = try! library.function(named: "triFragment")
            $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          }

        let pipeline = try! device.makeRenderPipelineState(descriptor: trianglePassDescriptor)

        // 2. Creating some data for the brush (paints)

        let vertices: [Float] = [
    //     x     y    z    w    r    g    b
          0.0,  0.5, 0.0, 1.0, 1.0, 0.0, 0.0, // top
         -0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 0.0, // left
          0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 1.0, // right
        ]

        let vertexBuffer = device.makeBuffer(
          bytes: vertices,
          length: MemoryLayout<Float>.size * vertices.count
        )

        // 3. Describing how to put the brush into the paints

        var uniforms = view.drawableSize.aspectMatrix

        buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
          .configure { encoder in
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
          }
          .endEncoding()

        buffer.present(drawable)
        buffer.commit()
      }
    }()

    init(
      exercise: MTLQuestExercise
    ) {
      self.exercise = exercise
      self.library = .init(
        library: try! device.makeDefaultLibrary(bundle: .main),
        namespace: String(describing: MTLQuestBasicTriangle.self)
      )
    }
  }
}
