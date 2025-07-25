//
//  MTLQuestEight.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/24/25.
//

import SwiftUI
import MetalKit
import PLTMetal

/// https://www.opengl-tutorial.org/beginners-tutorials/tutorial-5-a-textured-cube/
/// https://ilkinulas.github.io/development/unity/2016/05/06/uv-mapping.html
///
/// Continue working with 3D, this time applying a texture on a cube.
/// Study UV mapping
struct MTLQuestEight: UIViewRepresentable {
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

extension MTLQuestEight {
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

    let atlas       : MTLTexture
    let sampler     : MTLSamplerState

    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!

    private static func loadTexture(
      device: MTLDevice
    ) throws -> MTLTexture {
      let loader = MTKTextureLoader(device: device)
      let url    = Bundle.main.url(forResource: "cube1", withExtension: "png")!
      return try loader.newTexture(URL: url, options: [
        .SRGB                         : false,
        .textureUsage                 : MTLTextureUsage.shaderRead.rawValue,
        .textureStorageMode           : MTLStorageMode.private.rawValue,
        .origin                       : MTKTextureLoader.Origin.bottomLeft.rawValue,
        .generateMipmaps              : true
      ])
    }

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
            $0.attributes[1].format       = .float2
            $0.attributes[1].offset       = MemoryLayout<Float>.size * 4
            $0.attributes[1].bufferIndex  = 0

            $0.layouts[0].stride          = MemoryLayout<Float>.size * 6
          }

        let trianglePassDescriptor = MTLRenderPipelineDescriptor()
          .configure {
            $0.vertexDescriptor = vDesc
            $0.vertexFunction = try! library.function(named: "funVertex")
            $0.fragmentFunction = try! library.function(named: "funFragment")
            $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
            $0.depthAttachmentPixelFormat = .depth32Float
          }

        let pipeline = try! device.makeRenderPipelineState(descriptor: trianglePassDescriptor)

        // 2. Creating some data for the brush (paints)

        let viewSize = view.drawableSize

        // Half-extent in NDC
        let hx = Float(1.0)
        let hy = Float(1.0)

        // x y z w r g b
        let quad: [Float] = [
            // Front (+Z), Face 1
            -1, -1,  1, 1,  0.0, 0.25,
             1, -1,  1, 1,  0.25, 0.25,
             1,  1,  1, 1,  0.25, 0.5,
            -1, -1,  1, 1,  0.0, 0.25,
             1,  1,  1, 1,  0.25, 0.5,
            -1,  1,  1, 1,  0.0, 0.5,

            // Back (-Z)1,, Face 2
             1, -1, -1, 1,  0.5, 0.25,
            -1, -1, -1, 1,  0.25, 0.25,
            -1,  1, -1, 1,  0.25, 0.5,
             1, -1, -1, 1,  0.5, 0.25,
            -1,  1, -1, 1,  0.25, 0.5,
             1,  1, -1, 1,  0.5, 0.5,

            // Left (-X)1,, Face 3
            -1, -1, -1, 1,  0.5, 0.25,
            -1, -1,  1, 1,  0.75, 0.25,
            -1,  1,  1, 1,  0.75, 0.5,
            -1, -1, -1, 1,  0.5, 0.25,
            -1,  1,  1, 1,  0.75, 0.5,
            -1,  1, -1, 1,  0.5, 0.5,

            // Right (+X1,), Face 4
             1, -1,  1, 1,  0.75, 0.25,
             1, -1, -1, 1,  1.0, 0.25,
             1,  1, -1, 1,  1.0, 0.5,
             1, -1,  1, 1,  0.75, 0.25,
             1,  1, -1, 1,  1.0, 0.5,
             1,  1,  1, 1,  0.75, 0.5,

            // Top (+Y),1, Face 5
            -1,  1,  1, 1,  0.5, 0.5,
             1,  1,  1, 1,  0.75, 0.5,
             1,  1, -1, 1,  0.75, 0.75,
            -1,  1,  1, 1,  0.5, 0.5,
             1,  1, -1, 1,  0.75, 0.75,
            -1,  1, -1, 1,  0.5, 0.75,

            // Bottom (-1,Y), Face 6
            -1, -1, -1, 1,  0.5, 0.0,
             1, -1, -1, 1,  0.75, 0.0,
             1, -1,  1, 1,  0.75, 0.25,
            -1, -1, -1, 1,  0.5, 0.0,
             1, -1,  1, 1,  0.75, 0.25,
            -1, -1,  1, 1,  0.5, 0.25,
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

        let m_view = lookAt(
          eye: SIMD3<Float>(0, 8, 8),
          center: SIMD3<Float>(0, 0, 0),
          up: SIMD3<Float>(0, 3, 0)
        )
        let m_model = rotationMatrixY(angleRadians: rotationAngle)

        let mvp = m_perspective * m_view * m_model

        var uniforms = SceneUniforms(
          mvp: mvp
        )
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
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

            encoder.setFragmentTexture(self.atlas, index: 0)
            encoder.setFragmentSamplerState(self.sampler, index: 0)

            encoder.drawPrimitives(
              type: .triangle,
              vertexStart: 0,
              vertexCount: quad.count / 6
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
        namespace: String(describing: MTLQuestEight.self)
      )
      self.atlas    = try! Self.loadTexture(device: device)
      let sampDesc  = MTLSamplerDescriptor()
      sampDesc.minFilter   = .nearest        // prevent inter-frame bleeding
      sampDesc.magFilter   = .nearest
      sampDesc.sAddressMode = .clampToEdge
      sampDesc.tAddressMode = .clampToEdge
      self.sampler = device.makeSamplerState(descriptor: sampDesc)!

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

