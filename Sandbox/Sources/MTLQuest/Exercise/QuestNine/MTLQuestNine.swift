//  MTLQuestNine.swift
//  Sandbox
//
//  Created by Assistant on 7/25/25.
//

import SwiftUI
import MetalKit
import ModelIO
import PLTMetal
import PLTMath

/// https://www.opengl-tutorial.org/beginners-tutorials/tutorial-8-basic-shading/
/// Loads and displays Suzanne using MetalKit's MDLAsset+MTKMesh APIs.
/// Also studies the work with basic shading (Lambertian Reflection in this case, see the shaders code for more)
struct MTLQuestNine: UIViewRepresentable {
  let exercise: MTLQuestExercise
  
  func makeUIView(context: Context) -> MTKView {
    let coordinator = context.coordinator
    return MTKView(
      frame: .zero,
      device: coordinator.device
    ).configure { [unowned coordinator] in
      $0.clearColor = MTLClearColorMake(0, 0, 0, 1)
      $0.colorPixelFormat = .rgba8Unorm
      $0.depthStencilPixelFormat = .depth32Float
      $0.delegate = coordinator.renderer
      coordinator.mtkView = $0
    }
  }
  
  func updateUIView(_ view: MTKView, context: Context) {}
}

extension MTLQuestNine {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise)
  }
  
  final class Coordinator {
    private var rotationAngle: Float = 0
    private var displayLink: CADisplayLink?
    weak var mtkView: MTKView?
    
    struct SceneUniforms {
      var mvp: float4x4
      var model: float4x4
    }
    
    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!
    let vertexDescriptor: MTLVertexDescriptor

    let mdlObject: MDLObjectParser
    
    lazy var renderer: MTLQuestRenderer = {
      MTLQuestRenderer(
        device: device
      ) { [unowned self] buffer, view in
        guard
          let viewRenderDescriptor = view.currentRenderPassDescriptor,
          let drawable = view.currentDrawable
        else { return }
        
        let pipelineDesc = MTLRenderPipelineDescriptor().configure {
          $0.vertexDescriptor = vertexDescriptor
          $0.vertexFunction = try! library.funVertex
          $0.fragmentFunction = try! library.funFragment
          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          $0.depthAttachmentPixelFormat = .depth32Float
        }
        let pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
        
        let m_perspective: simd_float4x4 = .perspective(
          fovYRadians: .pi / 4,
          aspect: Float(view.drawableSize.width / view.drawableSize.height),
          nearZ: 0.1,
          farZ: 100.0
        )
        let m_view: simd_float4x4 = .lookAt(
          eye: SIMD3<Float>(0, 0, 16),
          center: SIMD3<Float>(0, 0, 0),
          up: SIMD3<Float>(0, 3, 0)
        )
        let m_model: simd_float4x4 = .rotationY(angleRadians: rotationAngle)
        let mvp = m_perspective * m_view * m_model
        var uniforms = SceneUniforms(
          mvp: mvp,
          model: m_model
        )
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        let depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!
        
        buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
          .configure { encoder in
            encoder.setRenderPipelineState(pipeline)
            encoder.setDepthStencilState(depthState)
            encoder.setVertexBuffer(
              mdlObject.mesh.vertexBuffers[0].buffer,
              offset: mdlObject.mesh.vertexBuffers[0].offset,
              index: 0
            )

            encoder.setVertexBytes(
              &uniforms,
              length: MemoryLayout<SceneUniforms>.stride,
              index: 1
            )

            encoder.drawIndexedPrimitives(
              type: mdlObject.submesh.primitiveType,
              indexCount: mdlObject.submesh.indexCount,
              indexType: mdlObject.submesh.indexType,
              indexBuffer: mdlObject.submesh.indexBuffer.buffer,
              indexBufferOffset: mdlObject.submesh.indexBuffer.offset
            )
          }
          .endEncoding()
        buffer.present(drawable)
        buffer.commit()
      }
    }()
    
    init(exercise: MTLQuestExercise) {
      self.exercise = exercise
      self.library = .init(
        library: try! device.makeDefaultLibrary(bundle: .main),
        namespace: String(describing: MTLQuestNine.self)
      )

      let url = Bundle.main.url(forResource: "suzanne", withExtension: "obj")!

      self.mdlObject = MDLObjectParser(
        modelURL: url,
        device: device
      )

      self.vertexDescriptor = MTLVertexDescriptor()
        .configure {
          // attribute(0): position (float3)
          $0.attributes[0].format = .float3
          $0.attributes[0].offset = 0
          $0.attributes[0].bufferIndex = 0

          // attribute(1): normal (float3)
          $0.attributes[1].format = .float3
          $0.attributes[1].offset = 12
          $0.attributes[1].bufferIndex = 0

          $0.layouts[0].stride = 24
        }

      self.displayLink = CADisplayLink(
        target: self,
        selector: #selector(updateRotation)
      )
      self.displayLink?.add(to: .main, forMode: .default)
    }

    deinit {
      displayLink?.invalidate()
    }
    
    @objc private func updateRotation() {
      rotationAngle += 0.012
      if rotationAngle > 2 * .pi {
        rotationAngle -= 2 * .pi
      }
      mtkView?.setNeedsDisplay()
    }
  }
}
