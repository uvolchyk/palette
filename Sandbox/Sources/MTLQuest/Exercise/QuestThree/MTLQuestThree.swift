//
//  MTLQuestThree.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/14/25.
//

import SwiftUI
import MetalKit
import PLTMetal

/// https://tchayen.github.io/posts/wireframes-with-barycentric-coordinates
/// Wireframe overlay (no geometry shader)
/// Use step() on barycentric coords (passed as separate attribute) to darken edges. Sharpens thinking about fragments vs. vertices.
struct MTLQuestThree: UIViewRepresentable {
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
      
      // Store MTKView reference in coordinator and start display link for animation
      coordinator.mtkView = $0
      coordinator.startDisplayLink()
    }
  }

  func updateUIView(
    _ view: MTKView,
    context: Context
  ) {}
}

extension MTLQuestThree {
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise)
  }

  final class Coordinator {
    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!
    
    // MARK: - Added properties for animation timing and display link
    var displayLink: CADisplayLink?
    var time: Float = 0
    weak var mtkView: MTKView?

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
            $0.vertexFunction = try! library.function(named: "funVertex")
            $0.fragmentFunction = try! library.function(named: "funFragment")
            $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          }

        let pipeline = try! device.makeRenderPipelineState(descriptor: trianglePassDescriptor)

        // 2. Creating some data for the brush (paints)

        let vertices: [Float] = [
    //     x     y    z    w    A    B    C
          -0.8, -0.8, 0.0, 1.0, 1.0, 0.0, 0.0, // bottom left
          -0.8,  0.8, 0.0, 1.0, 0.0, 1.0, 0.0, // top left
           0.8, -0.8, 0.0, 1.0, 0.0, 0.0, 1.0, // bottom right
           0.8,  0.8, 0.0, 1.0, 1.0, 0.0, 0.0, // top left
        ]

        let vertexBuffer = device.makeBuffer(
          bytes: vertices,
          length: MemoryLayout<Float>.size * vertices.count
        )

        // 3. Describing how to put the brush into the paints

        var uniforms = view.drawableSize.aspectMatrix
        
        // Pass the current time to the fragment shader as a uniform
        var time = self.time

        buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
          .configure { encoder in
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<float4x4>.size, index: 1)
            encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 1) // Time uniform for fragment shader
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
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
        namespace: String(describing: MTLQuestThree.self)
      )
    }
    
    // MARK: - Methods for display link and timing
    
    /// Starts the CADisplayLink to update frames continuously
    func startDisplayLink() {
      displayLink = CADisplayLink(target: self, selector: #selector(updateFrame(link:)))
      displayLink?.add(to: .main, forMode: .default)
    }

    /// Updates the time and triggers a redraw of the MTKView
    @objc func updateFrame(link: CADisplayLink) {
      time = Float(link.timestamp)
      mtkView?.setNeedsDisplay()
    }
    
    deinit {
      displayLink?.invalidate()
    }
  }
}

