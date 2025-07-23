//
//  MTLQuestSix.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/17/25.
//

import SwiftUI
import MetalKit
import PLTMetal

/// https://www.opengl-tutorial.org/beginners-tutorials/tutorial-3-matrices/
/// This quest studies the model-view-projection (MVP) matrix.
struct MTLQuestSix: UIViewRepresentable {
  let exercise: MTLQuestExercise

  func makeUIView(context: Context) -> MTKView {
    let coordinator = context.coordinator
    return MTKView(
      frame: .zero,
      device: coordinator.renderer.device
    ).configure { [unowned coordinator] in
      $0.clearColor = MTLClearColorMake(0, 0, 0, 1)
      $0.colorPixelFormat = .rgba8Unorm
      $0.delegate = coordinator.renderer
    }
  }

  func updateUIView(
    _ view: MTKView,
    context: Context
  ) {}
}

extension MTLQuestSix {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise)
  }

  final class Coordinator {
    struct SceneUniforms {
        var mvp        : float4x4
    }

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

        let vDesc = MTLVertexDescriptor()
          .configure {
            // attribute(0) – pos
            $0.attributes[0].format       = .float4
            $0.attributes[0].offset       = 0
            $0.attributes[0].bufferIndex  = 0
            // attribute(1) – color
            $0.attributes[1].format       = .float3
            $0.attributes[1].offset       = MemoryLayout<Float>.size * 4
            $0.attributes[1].bufferIndex  = 0

            $0.layouts[0].stride          = MemoryLayout<Float>.size * 7
          }

        let trianglePassDescriptor = MTLRenderPipelineDescriptor()
          .configure {
            $0.vertexDescriptor = vDesc
            $0.vertexFunction = try! library.function(named: "funVertex")
            $0.fragmentFunction = try! library.function(named: "funFragment")
            $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          }

        let pipeline = try! device.makeRenderPipelineState(descriptor: trianglePassDescriptor)

        // 2. Creating some data for the brush (paints)

        // Convert sprite size from pixels to Normalized-Device Coordinates (-1 … +1)
        let viewSize = view.drawableSize

        // Half-extent in NDC
        let hx = Float(1.0)
        let hy = Float(1.0)

        // x y z w r g b
        let quad: [Float] = [
          -1,  -1, 0, 1, 1, 0, 0,   // BL
          -1,   1, 0, 1, 0, 1, 0,   // TL
           1,  -1, 0, 1, 0, 0, 1,   // BR
           1,   1, 0, 1, 1, 0, 1,    // TR
        ]
        
        let vertexBuffer = device.makeBuffer(
          bytes: quad,
          length: MemoryLayout<Float>.size * quad.count
        )

        // 3. Describing how to put the brush into the paints

        let m_perspective = perspectiveMatrix(
          fovyRadians: .pi / 4,
          aspect: Float(view.drawableSize.width / view.drawableSize.height),
          nearZ: 0.1,
          farZ: 100.0
        )
//        let m_perspective = matrix_identity_float4x4

        let m_view = lookAt(
          eye: SIMD3<Float>(0, 0, 4),
          center: SIMD3<Float>(0, 0, 0),
          up: SIMD3<Float>(0, -1, 0)
        )
//        let m_view = matrix_identity_float4x4

//        let m_model = float4x4(1.0)
//        let m_model = float4x4(diagonal: SIMD4<Float>(repeating: 1))
        let m_model = matrix_identity_float4x4

        let mvp = m_perspective * m_view * m_model

        var uniforms = SceneUniforms(
          mvp: mvp
        )

        buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
          .configure { [unowned self] encoder in
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(
              &uniforms,
              length: MemoryLayout.stride(ofValue: uniforms),
              index: 1
            )

            encoder.drawPrimitives(
              type: .triangleStrip,
              vertexStart: 0,
              vertexCount: 4
            )
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
        namespace: String(describing: MTLQuestSix.self)
      )
    }

    func perspectiveMatrix(
      fovyRadians: Float,
      aspect: Float,
      nearZ: Float,
      farZ: Float
    ) -> simd_float4x4 {
      let yScale = 1 / tan(fovyRadians * 0.5)
      let xScale = yScale / aspect
      let zRange = farZ - nearZ
      let zScale = farZ / zRange
      let wz = -nearZ * zScale
      
      return simd_float4x4(
        SIMD4<Float>( xScale,   0,      0,   0 ),
        SIMD4<Float>(      0, yScale,   0,   0 ),
        SIMD4<Float>(      0,      0, zScale, 1 ),
        SIMD4<Float>(      0,      0,   wz,   0 )
      )
    }

    func lookAt(
      eye: SIMD3<Float>,
      center: SIMD3<Float>,
      up: SIMD3<Float>
    ) -> simd_float4x4 {
      let zAxis = normalize(center - eye)         // Forward
      let xAxis = normalize(cross(up, zAxis))     // Right
      let yAxis = cross(zAxis, xAxis)             // Up
      
      let translation = SIMD3<Float>(
        -dot(xAxis, eye),
        -dot(yAxis, eye),
        -dot(zAxis, eye)
      )
      
      return simd_float4x4(
        SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0),
        SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0),
        SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0),
        SIMD4<Float>(translation.x, translation.y, translation.z, 1)
      )
    }
  }
}
