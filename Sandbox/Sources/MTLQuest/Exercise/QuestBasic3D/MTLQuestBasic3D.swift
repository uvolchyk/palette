//
//  MTLQuestBasic3D.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/21/25.
//

import SwiftUI
import MetalKit
import PLTMetal

/// https://www.opengl-tutorial.org/beginners-tutorials/tutorial-4-a-colored-cube/
/// Working with 3D, displaying a coloured cube, animating it's rotation
struct MTLQuestBasic3D: UIViewRepresentable {
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
      $0.depthStencilPixelFormat = .depth32Float
      coordinator.mtkView = $0
    }
  }

  func updateUIView(
    _ view: MTKView,
    context: Context
  ) {}
}

extension MTLQuestBasic3D {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise)
  }

  final class Coordinator {
    private var rotationAngle: Float = 0
    private var displayLink: CADisplayLink?
    weak var mtkView: MTKView?

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
            $0.vertexFunction = try! library.funVertex
            $0.fragmentFunction = try! library.funFragment
            $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
            $0.depthAttachmentPixelFormat = .depth32Float
          }

        let pipeline = try! device.makeRenderPipelineState(descriptor: trianglePassDescriptor)

        // 2. Creating some data for the brush (paints)
        let viewSize = view.drawableSize

        let indices: [UInt16] = [
          0, 1, 3,
          2, 1, 3,
          0, 4, 3,
          7, 4, 3,
          0, 1, 4,
          5, 1, 4,
          3, 2, 7,
          6, 2, 7,
          1, 5, 2,
          6, 5, 2,
          4, 5, 7,
          6, 5, 7,
        ]

        let indexBuffer = device.makeBuffer(
          bytes: indices,
          length: MemoryLayout<UInt16>.stride * indices.count,
          options: []
        )!

        // x y z w r g b
        let quad: [Float] = [
          -1, -1, -1, 1, 1, 0, 0, // bln
          -1,  1, -1, 1, 0, 1, 0, // tln
           1,  1, -1, 1, 0, 0, 1, // trn
           1, -1, -1, 1, 1, 0, 1, // brn
          -1, -1,  1, 1, 0, 1, 1, // blf
          -1,  1,  1, 1, 1, 1, 0, // tlf
           1,  1,  1, 1, 1, 1, 1, // trf
           1, -1,  1, 1, 1, 1, 1, // brf
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
          eye: SIMD3<Float>(0, 8, 8),
          center: SIMD3<Float>(0, 0, 0),
          up: SIMD3<Float>(0, 3, 0)
        )
//        let m_view = matrix_identity_float4x4

//        let m_model = float4x4(1.0)
//        let m_model = float4x4(diagonal: SIMD4<Float>(repeating: 1))
        let m_model = rotationMatrixY(angleRadians: rotationAngle)

        let mvp = m_perspective * m_view * m_model

        var uniforms = SceneUniforms(
          mvp: mvp
        )
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less      // Like GL_LESS
        depthDescriptor.isDepthWriteEnabled = true

        let depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!

        buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
          .configure { [unowned self] encoder in
            encoder.setRenderPipelineState(pipeline)
            encoder.setDepthStencilState(depthState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(
              &uniforms,
              length: MemoryLayout.stride(ofValue: uniforms),
              index: 1
            )

            encoder.drawIndexedPrimitives(
              type: .triangle,
              indexCount: indices.count,
              indexType: .uint16,
              indexBuffer: indexBuffer,
              indexBufferOffset: 0
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
        namespace: String(describing: MTLQuestBasic3D.self)
      )
      self.displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
      self.displayLink?.add(to: .main, forMode: .default)
    }

    deinit {
      displayLink?.invalidate()
    }

    @objc private func updateRotation() {
        rotationAngle += 0.01 // Adjust rotation speed as desired
        if rotationAngle > 2 * .pi {
            rotationAngle -= 2 * .pi
        }
        mtkView?.setNeedsDisplay()
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
    
    func rotationMatrixY(angleRadians: Float) -> simd_float4x4 {
      let c = cos(angleRadians)
      let s = sin(angleRadians)
      return simd_float4x4(
        SIMD4<Float>( c, 0,  s, 0),
        SIMD4<Float>( 0, 1,  0, 0),
        SIMD4<Float>(-s, 0,  c, 0),
        SIMD4<Float>( 0, 0,  0, 1)
      )
    }
  }
}
