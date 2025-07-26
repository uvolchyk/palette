//
//  MTLQuestFive.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/15/25.
//

import SwiftUI
import MetalKit
import PLTMetal
import PLTMath

/// https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator
/// Flipbook animation
/// Animate through sprite sheet frames by offsetting UVs with floor(time * fps). Explores integer math and UV wrapping.
struct MTLQuestFive: UIViewRepresentable {
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

extension MTLQuestFive {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise)
  }

  final class Coordinator {
    struct FlipbookUniforms {
        var time:     Float    = 0          // seconds since start
        var columns:  UInt32   = 13          // atlas grid X
        var rows:     UInt32   = 54          // atlas grid Y
        var fps:      Float    = 32         // playback speed
    }

    private static func loadAtlas(
      device: MTLDevice,
      named name: String
    ) throws -> MTLTexture {
      let loader = MTKTextureLoader(device: device)
      let url    = Bundle.main.url(forResource: name, withExtension: "png")!
      return try loader.newTexture(URL: url, options: [
        .SRGB                         : false,
        .textureUsage                 : MTLTextureUsage.shaderRead.rawValue,
        .textureStorageMode           : MTLStorageMode.private.rawValue,
        .origin                       : MTKTextureLoader.Origin.topLeft.rawValue
      ])
    }

    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!
    
    var timer: Timer?
    var currentIndex = 0
    let assetCount = 9
    
    let atlas       : MTLTexture
    let sampler     : MTLSamplerState
    let startTime   = CACurrentMediaTime()

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
            // attribute(0) – pos (float4)
            $0.attributes[0].format       = .float4
            $0.attributes[0].offset       = 0
            $0.attributes[0].bufferIndex  = 0
            // attribute(1) – uv  (float2)
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
          }

        let pipeline = try! device.makeRenderPipelineState(descriptor: trianglePassDescriptor)

        // 2. Creating some data for the brush (paints)

        // Convert sprite size from pixels to Normalized-Device Coordinates (-1 … +1)
        let viewSize = view.drawableSize

        // Half-extent in NDC
        let hx = Float(1.0)
        let hy = Float(1.0)

        // sliding window over the texture
        // y == animation type
        // x == animation frame
        let regionOrigin = SIMD2<Float>(Float(currentIndex) * 64.0, 8.0 * 64.0)
        let regionSize = SIMD2<Float>(64.0, 64.0)
        let textureSize = SIMD2<Float>(832.0, 3456.0)

        // Calculate UVs (normalized 0-1)
        let uvMin = regionOrigin / textureSize
        let uvMax = (regionOrigin + regionSize) / textureSize

        // need to better understand the difference between texels and pixels, because for now it's a bit vague
        let quad: [Float] = [
      //   x,   y, z, w,   u, v
          -hx,  -hy, 0, 1,   uvMin.x, uvMax.y,   // BL
          -hx,   hy, 0, 1,   uvMin.x, uvMin.y,   // TL
           hx,  -hy, 0, 1,   uvMax.x, uvMax.y,   // BR
           hx,   hy, 0, 1,   uvMax.x, uvMin.y    // TR
        ]
        
        let vertexBuffer = device.makeBuffer(
          bytes: quad,
          length: MemoryLayout<Float>.size * quad.count
        )

        // 3. Describing how to put the brush into the paints

        var uniforms = view.drawableSize.aspectMatrix

        var fbUniforms = FlipbookUniforms(
            time:    floor(Float(CACurrentMediaTime() - startTime)),
            columns: 13,
            rows:    54,
            fps:     32
        )

        buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
          .configure { [unowned self] encoder in
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(
              &uniforms,    // your MVP matrix
              length: MemoryLayout<float4x4>.size,
              index: 1
            )

            encoder.setFragmentBytes(
              &fbUniforms,
              length: MemoryLayout<FlipbookUniforms>.size,
              index: 2
            )

            encoder.setFragmentTexture(self.atlas, index: 0)
            encoder.setFragmentSamplerState(self.sampler, index: 0)
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
        namespace: String(describing: MTLQuestFive.self)
      )

      self.atlas    = try! Self.loadAtlas(device: device, named: "wizard")
      let sampDesc  = MTLSamplerDescriptor()
      sampDesc.minFilter   = .nearest        // prevent inter-frame bleeding
      sampDesc.magFilter   = .nearest
      sampDesc.sAddressMode = .clampToEdge
      sampDesc.tAddressMode = .clampToEdge
      self.sampler = device.makeSamplerState(descriptor: sampDesc)!

      // Call this once to start the timer
      Timer.scheduledTimer(withTimeInterval: 0.24, repeats: true) { [unowned self] _ in
          currentIndex = (currentIndex + 1) % assetCount
      }
    }
  }
}
