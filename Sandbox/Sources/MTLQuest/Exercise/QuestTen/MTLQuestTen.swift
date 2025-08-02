//
//  MTLQuestTen.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/26/25.
//

import SwiftUI
import MetalKit
import ModelIO
import PLTMetal
import PLTMath

/// Displaying multiple objects in a single scene.
/// Working with gestures (scale, pitch, yaw), studying spherical coordinates.
/// Displaying gizmo.
/// 'head' now represents roll angle around Z axis, not a distance.
struct MTLQuestTen: UIViewRepresentable {
  let exercise: MTLQuestExercise
  var yaw: Float = 0
  var pitch: Float = 0
  var head: Float = 80 // Roll angle in radians (used as rotation around Z axis)
  
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
      
      let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
      $0.addGestureRecognizer(pinch)
      
      let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
      pan.maximumNumberOfTouches = 1
      $0.addGestureRecognizer(pan)
      
      let rotate = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleRotate(_:)))
      rotate.minimumNumberOfTouches = 2
      rotate.maximumNumberOfTouches = 2
      $0.addGestureRecognizer(rotate)
    }
  }
  
  func updateUIView(_ view: MTKView, context: Context) {
    context.coordinator.updateFromParent(yaw: yaw, pitch: pitch, head: head)
  }
}

extension MTLQuestTen {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(exercise: exercise, yaw: yaw, pitch: pitch, head: head)
  }
  
  final class Coordinator {
    private var rotationAngle: Float = 0
    private var displayLink: CADisplayLink?
    private var cameraDistance: Float = 80.0
    private var cameraX: Float = 0.0
    private var cameraY: Float = 0.0
    
    private var externalYaw: () -> Float
    private var externalPitch: () -> Float
    private var externalHead: () -> Float
    
    weak var mtkView: MTKView?
    
    struct SceneUniforms {
      var mvp: float4x4
      var model: float4x4
    }
    
    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!
    let vertexDescriptor: MTLVertexDescriptor
    
    let mdlObjects: [MDLObjectParser]
    
    lazy var renderer: MTLQuestRenderer = {
      MTLQuestRenderer(
        device: device
      ) { [unowned self] buffer, view in
        guard
          let viewRenderDescriptor = view.currentRenderPassDescriptor,
          let drawable = view.currentDrawable
        else { return }
        
        // Per-cycle globals
        
        let m_perspective: simd_float4x4 = .perspective(
          fovYRadians: .pi / 4,
          aspect: Float(view.drawableSize.width / view.drawableSize.height),
          nearZ: 0.1,
          farZ: 100.0
        )
        let radius = cameraDistance

        /// https://en.wikipedia.org/wiki/Spherical_coordinate_system
        /// https://math.libretexts.org/Courses/Mount_Royal_University/Calculus_for_Scientists_II/7%3A_Vector_Spaces/5.7%3A_Cylindrical_and_Spherical_Coordinates
        let cx = cos(externalPitch()) * sin(externalYaw())
        let cy = sin(externalPitch())
        let cz = cos(externalPitch()) * cos(externalYaw())

        let eye = SIMD3<Float>(cx, cy, cz) * radius
        let center = SIMD3<Float>(cameraX, cameraY, 0)

        /// https://en.wikipedia.org/wiki/Euler_angles
//        let rotationMatrix =
//          simd_float4x4.rotationZ(angleRadians: externalHead()) *
//          simd_float4x4.rotationX(angleRadians: externalPitch()) *
//          simd_float4x4.rotationY(angleRadians: externalYaw())

        /// https://mrelusive.com/publications/papers/SIMD-From-Quaternion-to-Matrix-and-Back.pdf
        let qYaw = simd_quatf(angle: externalYaw(), axis: SIMD3<Float>(0, 1, 0))
        let qPitch = simd_quatf(angle: externalPitch(), axis: SIMD3<Float>(1, 0, 0))
        let qRoll = simd_quatf(angle: externalHead(), axis: SIMD3<Float>(0, 0, 1))
        let rotationMatrix = simd_float4x4(qRoll * qPitch * qYaw)
        
        let m_view: simd_float4x4 = .lookAt(
          eye: eye,
          center: center,
          up: SIMD3<Float>(0, 3, 0)
        ) * rotationMatrix
        
        let renderPD_objects = MTLRenderPipelineDescriptor().configure {
          $0.vertexDescriptor = vertexDescriptor
          $0.vertexFunction = try! library.funVertex
          $0.fragmentFunction = try! library.funFragment
          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          $0.depthAttachmentPixelFormat = .depth32Float
        }
        let renderPipeline_objects = try! device.makeRenderPipelineState(descriptor: renderPD_objects)
        
        let renderEncoder = buffer
          .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)
        
        for (i, mdlObject) in mdlObjects.enumerated() {
          let m_model: simd_float4x4 =  .init(
            translate: SIMD3<Float>(x: Float(i) * -12.0 + 12.0, y: 0, z: 0)
          ) * .rotationY(angleRadians: rotationAngle)
          
          let mvp = m_perspective * m_view * m_model
          var uniforms = SceneUniforms(
            mvp: mvp,
            model: m_model
          )
          
          renderEncoder?
            .configure { encoder in
              encoder.setRenderPipelineState(renderPipeline_objects)
              encoder.setDepthStencilState(
                device.makeDepthStencilState(
                  descriptor: MTLDepthStencilDescriptor().configure {
                    $0.depthCompareFunction = .less
                    $0.isDepthWriteEnabled = true
                  }
                )!
              )
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
        }
        
        let renderPD_gizmo = MTLRenderPipelineDescriptor().configure {
          $0.vertexDescriptor = vertexDescriptor
          $0.vertexFunction = try! library.gizmo_vertex
          $0.fragmentFunction = try! library.gizmo_fragment
          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          $0.depthAttachmentPixelFormat = .depth32Float
        }
        let renderPipeline_gizmo = try! device.makeRenderPipelineState(descriptor: renderPD_objects)
        
        let vertex_gizmo: [Float] = [
          0, 0, 0, 1, 0, 0,
          1, 0, 0, 1, 0, 0,
          0, 0, 0, 0, 1, 0,
          0, 1, 0, 0, 1, 0,
          0, 0, 0, 0, 0, 1,
          0, 0, 1, 0, 0, 1,
        ]
        
        let vertexBuffer_gizmo = device.makeBuffer(
          bytes: vertex_gizmo,
          length: MemoryLayout<Float>.size * vertex_gizmo.count
        )
        
        let mvp = m_perspective * m_view * matrix_identity_float4x4
        var uniforms = SceneUniforms(
          mvp: mvp,
          model: matrix_identity_float4x4
        )
        
        renderEncoder?
          .configure { encoder in
            encoder.setRenderPipelineState(renderPipeline_gizmo)
            encoder.setVertexBuffer(vertexBuffer_gizmo, offset: 0, index: 0)
            encoder.setVertexBytes(
              &uniforms,
              length: MemoryLayout<SceneUniforms>.stride,
              index: 1
            )
            
            encoder.drawPrimitives(
              type: .line,
              vertexStart: 0,
              vertexCount: 6
            )
          }
        
        renderEncoder?.endEncoding()
        buffer.present(drawable)
        buffer.commit()
      }
    }()
    
    init(exercise: MTLQuestExercise, yaw: Float, pitch: Float, head: Float) {
      self.exercise = exercise
      self.library = .init(
        library: try! device.makeDefaultLibrary(bundle: .main),
        namespace: String(describing: MTLQuestTen.self)
      )
      
      self.externalYaw = { yaw }
      self.externalPitch = { pitch }
      self.externalHead = { head }
      
      let modelURL = Bundle.main.url(forResource: "pikachu", withExtension: "obj")!
      self.mdlObjects = [
        MDLObjectParser(
          modelURL: modelURL,
          device: device
        ),
        MDLObjectParser(
          modelURL: modelURL,
          device: device
        ),
        MDLObjectParser(
          modelURL: modelURL,
          device: device
        ),
      ]
      
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
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
      guard
        let view = mtkView
      else { return }
      
      switch gesture.state {
      case .changed, .ended:
        let minDistance: Float = 2
        let maxDistance: Float = 200
        cameraDistance /= Float(gesture.scale)
        cameraDistance = cameraDistance.clamp(
          minValue: minDistance,
          maxValue: maxDistance
        )
        gesture.scale = 1.0
        view.setNeedsDisplay()
      default: break
      }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
      guard
        let view = mtkView
      else { return }
      
      let translation = gesture.translation(in: view)
      // Sensitivity can be adjusted
      let sensitivity: Float = 0.08
      
      cameraX += Float(translation.x) * sensitivity
      cameraY -= -Float(translation.y) * sensitivity // Y is typically inverted
      
      gesture.setTranslation(.zero, in: view)
      view.setNeedsDisplay()
    }
    
    @objc func handleRotate(_ gesture: UIPanGestureRecognizer) {
      guard
        let view = mtkView
      else { return }
      
      let translation = gesture.translation(in: view)
      let yawSensitivity: Float = 0.008
      let pitchSensitivity: Float = 0.008
      
      var yaw = externalYaw()
      var pitch = externalPitch()
      
      yaw += Float(translation.x) * yawSensitivity
      pitch += Float(translation.y) * pitchSensitivity
      pitch = pitch.clamp(
        minValue: -.pi/2,
        maxValue: .pi/2
      ) // in order to avoid flipping
      
      gesture.setTranslation(.zero, in: view)
      
      externalYaw = { yaw }
      externalPitch = { pitch }
      
      view.setNeedsDisplay()
    }
    
    func updateFromParent(yaw: Float, pitch: Float, head: Float) {
      // Update closures to point to new parent values
      externalYaw = { yaw }
      externalPitch = { pitch }
      externalHead = { head } // head is now roll angle, no longer distance
    }
  }
}
