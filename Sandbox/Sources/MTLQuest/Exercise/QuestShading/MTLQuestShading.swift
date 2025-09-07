//
//  MTLQuestShading.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/9/25.
//

import SwiftUI
import MetalKit
import ModelIO
import PLTMetal
import PLTMath

struct MTLQuestShading: UIViewRepresentable {
  let exercise: MTLQuestExercise
  @Binding var automaticRotation: Bool
  let aggregation: MTLQuestShadingAggregation
  
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
  
  func updateUIView(_ view: MTKView, context: Context) {}
  
  /// Displaying multiple objects in a single scene.
  /// Working with gestures (scale, pitch, yaw), studying spherical coordinates.
  /// Displaying gizmo.
  /// 'head' now represents roll angle around Z axis, not a distance.
  /// Supports rotation using quaternions only.
  struct Transform {
    var translation: SIMD3<Float> = .zero
    var rotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0,0,1))
    var scale: SIMD3<Float> = SIMD3<Float>(repeating: 1)
    
    /// Model matrix used for instancing.
    var modelMatrix: float4x4 {
      float4x4(translate: translation) * float4x4(rotation) * float4x4(scale: scale)
    }
    
    init(
      translation: SIMD3<Float> = .zero,
      rotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0,0,1)),
      scale: SIMD3<Float> = SIMD3<Float>(repeating: 1)
    ) {
      self.translation = translation
      self.rotation = rotation
      self.scale = scale
    }
    
    /// Creates a rotation quaternion from Euler angles (head, pitch, yaw).
    /// Rotation order: head (roll around Z) -> pitch (rotation around X) -> yaw (rotation around Y)
    /// This matches the multiplication order: qHead * qPitch * qYaw.
    static func makeRotationQuaternion(yaw: Float, pitch: Float, head: Float) -> simd_quatf {
      let qHead = simd_quatf(angle: head, axis: SIMD3<Float>(0, 0, 1))
      let qPitch = simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
      let qYaw = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
      return qHead * qPitch * qYaw
    }
    
    mutating func applyQuaternion(yaw: Float, pitch: Float, head: Float) {
      let qHead = simd_quatf(angle: head, axis: SIMD3<Float>(0, 0, 1))
      let qPitch = simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
      let qYaw = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
      
      rotation = qHead * qPitch * qYaw
    }
    
    /// Backward compatibility initializer from yaw, pitch, head angles.
    init(yaw: Float, pitch: Float, head: Float) {
      self.translation = .zero
      self.scale = SIMD3<Float>(repeating: 1)
      self.rotation = Transform.makeRotationQuaternion(yaw: yaw, pitch: pitch, head: head)
    }
  }
}

extension MTLQuestShading {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(
      exercise: exercise,
      automaticRotation: $automaticRotation,
      aggregation: aggregation
    )
  }
  
  final class Coordinator {
    private var rotationAngle: Float = 0
    private var displayLink: CADisplayLink?
    private var cameraDistance: Float = 10.0
    private var cameraX: Float = 0.0
    private var cameraY: Float = 0.0
    
    private var automaticRotation: Binding<Bool>
    
    private var automaticAngle: Float = 0

    private lazy var oxzPlaneWireBuffer: MTLBuffer = {
      let divs = 16
      let size: Float = 16
      let step = (2 * size) / Float(divs)
      var verts: [Float] = []

      /**
         x ->
        z
        |
       \_/

       +---+---+
       |   |   |
       +---+---+
       |   |   |
       +---+---+

       (x,z)

       (-size, -size) (-size + 1 * step, -size) .... (-size + step * divs, -size)
       (-size, -size + step * 1) ...
       ...
       (-size, size) ... (size, size)
       */
      for i in 0...divs {
        let x = -size + Float(i) * step
        verts += [x, 0, -size, x, 0, size]
      }

      for i in 0...divs {
        let z = -size + Float(i) * step
        verts += [-size, 0, z, size, 0, z]
      }
      return device.makeBuffer(bytes: verts, length: verts.count * MemoryLayout<Float>.size, options: [])!
    }()
    
    weak var mtkView: MTKView?
    
    struct SceneUniforms {
      var mvp: float4x4
      var model: float4x4
    }
    
    let exercise: MTLQuestExercise
    let library: PLTMetal.ShaderLibrary
    let device = MTLCreateSystemDefaultDevice()!
    let vertexDescriptor: MTLVertexDescriptor
    
    private var rotQuat1Static: simd_quatf = {
      Transform.makeRotationQuaternion(
        yaw: 2.0,
        pitch: -1.0,
        head: 0.0
      )
    }()
    
    private var rotQuat2Static: simd_quatf = {
      Transform.makeRotationQuaternion(
        yaw: -2.0,
        pitch: 1.0,
        head: 2.0
      )
    }()
    
    let mdlObject: MDLObjectParser
    let mdlLightObject: MDLObjectParser
    let mdlGizmoArrow: MDLObjectParser

    private var lightTransform: Transform
    
    private var instanceTransforms: [Transform] = []
    private var instanceBuffer: MTLBuffer?
    private let instanceCount: Int = 1

    private let gridColumns = 1
    private let gridRows = 1
    private let gridSpacing: Float = 0
    
    private var aggregation: MTLQuestShadingAggregation

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
          farZ: 1000.0
        )

        let radius = cameraDistance
        let eye: SIMD3<Float> = aggregation.cameraEye * radius
        let center: SIMD3<Float> = aggregation.center
        let up: SIMD3<Float> = aggregation.up

        let m_view: simd_float4x4 = .lookAt(
          eye: eye,
          center: center,
          up: up
        )

        /// -------- Start model --------

        let activeYaw: Float
        let activePitch: Float
        let activeHead: Float
        
        if automaticRotation.wrappedValue {
          activeYaw = automaticAngle
          activePitch = automaticAngle
          activeHead = automaticAngle
        } else {
          activeYaw = aggregation.rotationData.x
          activePitch = aggregation.rotationData.y
          activeHead = aggregation.rotationData.z
        }
        
        for i in 0..<instanceTransforms.count {
          var t = instanceTransforms[i]

          t.translation = aggregation.translationData
          t.scale = aggregation.scaleData
          t.applyQuaternion(
            yaw: activeYaw + Float(i) * (.pi * 2 / Float(instanceTransforms.count)),
            pitch: activePitch + Float(i) * (.pi * 2 / Float(instanceTransforms.count)),
            head: activeHead + Float(i) * (.pi * 2 / Float(instanceTransforms.count))
          )
          
          instanceTransforms[i] = t
        }
        
        // Upload instance model matrices to GPU buffer
        let transforms = instanceTransforms.map { $0.modelMatrix }
        if let instanceBuffer = instanceBuffer {
          let ptr = instanceBuffer.contents().bindMemory(to: float4x4.self, capacity: transforms.count)
          for i in 0..<transforms.count {
            ptr[i] = transforms[i]
          }
        }
        
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

        renderEncoder?.setTriangleFillMode(aggregation.wireframeEnabled ? .lines : .fill)
        
        let m_model: float4x4 = matrix_identity_float4x4
        
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

            // Pass shading model to the fragment shader as an Int (the rawValue)
            // This can be used in the shader to select shading logic.
            var shadingModelRawValue = aggregation.shadingModel.rawValue
            encoder.setFragmentBytes(&shadingModelRawValue, length: MemoryLayout<Int>.stride, index: 1)

            var lightingModelRawValue = aggregation.index
            encoder.setFragmentBytes(&lightingModelRawValue, length: MemoryLayout<Int>.stride, index: 2)

            var pointLights: [MTLQuestShadingPointLight] = []
            var spotLights: [MTLQuestShadingSpotLight] = []
            var dirLights: [MTLQuestShadingDirLight] = []

            for source in aggregation.lightingSources {
              switch source.lightingModelType {
              case .point:
                pointLights.append(source.pointData.metalCompatible)
              case .spotlight:
                spotLights.append(source.spotlightData.metalCompatible)
              case .directional:
                dirLights.append(source.directionalData.metalCompatible)
              }
            }

            var lightingCounts = MTLQuestShadingLightingCounts(
              pointCount: UInt32(pointLights.count),
              spotCount: UInt32(spotLights.count),
              dirCount: UInt32(dirLights.count),
              _pad: .zero
            )

            if pointLights.isEmpty { pointLights.append(.init()) }
            if spotLights.isEmpty { spotLights.append(.init()) }
            if dirLights.isEmpty { dirLights.append(.init()) }

            encoder.setFragmentBytes(
              &lightingCounts,
              length: MemoryLayout<MTLQuestShadingLightingCounts>.stride,
              index: 2
            )

            pointLights.withUnsafeBytes { pointer in
              encoder.setFragmentBytes(
                pointer.baseAddress!,
                length: pointer.count,
                index: 3
              )
            }

            spotLights.withUnsafeBytes { pointer in
              encoder.setFragmentBytes(
                pointer.baseAddress!,
                length: pointer.count,
                index: 4
              )
            }

            dirLights.withUnsafeBytes { pointer in
              encoder.setFragmentBytes(
                pointer.baseAddress!,
                length: pointer.count,
                index: 5
              )
            }
//            switch aggregation.lightingModelType {
//            case .point:
//              var _data = aggregation.pointData
//              encoder.setFragmentBytes(
//                &_data,
//                length: MemoryLayout<MTLQuestShadingAggregation.PointData>.stride,
//                index: 3
//              )
//            case .spotlight:
//              var _data = aggregation.spotlightData
//              encoder.setFragmentBytes(
//                &_data,
//                length: MemoryLayout<MTLQuestShadingAggregation.SpotlightData>.stride,
//                index: 3
//              )
//            case .directional:
//              var _data = aggregation.directionalData
//              encoder.setFragmentBytes(
//                &_data,
//                length: MemoryLayout<MTLQuestShadingAggregation.DirectionalData>.stride,
//                index: 3
//              )
//            }

            // Set per-instance model matrix buffer at index 2
            // Note: Since index 2 is used here for instance buffer, 
            // consider using a different buffer index for shading model if needed,
            // or use argument buffers in future for cleaner resource management.
            
            // For now, we keep instance buffer at index 2,
            // so shading model is sent via setFragmentBytes at index 2 (fragment shader)
            // This is valid as these indices are separate for vertex/fragment stages.
            
            encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
            
            // Draw instanced primitives
            encoder.drawIndexedPrimitives(
              type: mdlObject.submesh.primitiveType,
              indexCount: mdlObject.submesh.indexCount,
              indexType: mdlObject.submesh.indexType,
              indexBuffer: mdlObject.submesh.indexBuffer.buffer,
              indexBufferOffset: mdlObject.submesh.indexBuffer.offset,
              instanceCount: instanceTransforms.count
            )
          }
        
        let planePassDescriptor = MTLRenderPipelineDescriptor().configure {
          $0.vertexDescriptor = {
            let vd = MTLVertexDescriptor()
            vd.attributes[0].format = .float3
            vd.attributes[0].offset = 0
            vd.attributes[0].bufferIndex = 0
            vd.layouts[0].stride = MemoryLayout<Float>.size * 3
            return vd
          }()
          $0.vertexFunction = try! library.funPlaneVertex
          $0.fragmentFunction = try! library.funPlaneFragment
          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          $0.depthAttachmentPixelFormat = .depth32Float
        }
        let planePipeline = try! device.makeRenderPipelineState(descriptor: planePassDescriptor)
        renderEncoder?.configure { encoder in
          encoder.setRenderPipelineState(planePipeline)
          encoder.setVertexBuffer(oxzPlaneWireBuffer, offset: 0, index: 0)
          encoder.setVertexBytes(&uniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
          encoder.setDepthStencilState(
            device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor().configure { $0.depthCompareFunction = .less; $0.isDepthWriteEnabled = true })!
          )
          encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: (16+1)*4)
        }
        
        /// -------- Start gizmo --------

        // New gizmo arrows rendering
        let arrowScale: Float = 3.0
        let arrowTransforms: [(Transform, SIMD3<Float>)] = [
          // X axis arrow
          (
            Transform(
              translation: SIMD3<Float>(0.0, 0.0, 0.0),
              rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1)),
              scale: SIMD3<Float>(repeating: arrowScale)
            ),
            SIMD3<Float>(1, 0, 0)
          ),
          // Y axis arrow
          (
            Transform(
              translation: SIMD3<Float>(0.0, 0.0, 0.0),
              rotation: simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1)),
              scale: SIMD3<Float>(repeating: arrowScale)
            ),
            SIMD3<Float>(0, 1, 0)
          ),
          // Z axis arrow
          (
            Transform(
              translation: SIMD3<Float>(0.0, 0.0, 0.0),
              rotation: simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0)),
              scale: SIMD3<Float>(repeating: arrowScale)
            ),
            SIMD3<Float>(0, 0, 1)
          ),
        ]

        struct GizmoInstance {
          let model: float4x4
          let color: SIMD3<Float>
        }

        let arrowTransformsBuffer = device.makeBuffer(
          length: MemoryLayout<GizmoInstance>.stride * arrowTransforms.count,
          options: []
        )

        if let arrowTransformsBuffer {
          let ptr = arrowTransformsBuffer
            .contents()
            .bindMemory(
              to: GizmoInstance.self,
              capacity: arrowTransforms.count
            )

          for i in 0..<arrowTransforms.count {
            ptr[i] = GizmoInstance(
              model: arrowTransforms[i].0.modelMatrix,
              color: arrowTransforms[i].1
            )
          }
        }
        
        let renderPD_arrow = MTLRenderPipelineDescriptor().configure {
          $0.vertexDescriptor = vertexDescriptor
          $0.vertexFunction = try! library.funVertexGizmo
          $0.fragmentFunction = try! library.funFragmentGizmo
          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
          $0.depthAttachmentPixelFormat = .depth32Float
        }
        let renderPipeline_arrow = try! device.makeRenderPipelineState(descriptor: renderPD_arrow)
        
        let mvp_arrow = m_perspective * m_view * matrix_identity_float4x4
        var uniforms_arrow = SceneUniforms(
          mvp: mvp_arrow,
          model: matrix_identity_float4x4
        )
        
        renderEncoder?.configure { encoder in
          encoder.setRenderPipelineState(renderPipeline_arrow)
          encoder.setDepthStencilState(
            device.makeDepthStencilState(
              descriptor: MTLDepthStencilDescriptor().configure {
                $0.depthCompareFunction = .less
                $0.isDepthWriteEnabled = true
              }
            )!
          )
          encoder.setVertexBuffer(
            mdlGizmoArrow.mesh.vertexBuffers[0].buffer,
            offset: mdlGizmoArrow.mesh.vertexBuffers[0].offset,
            index: 0
          )
          encoder.setVertexBytes(
            &uniforms_arrow,
            length: MemoryLayout<SceneUniforms>.stride,
            index: 1
          )
          encoder.setVertexBuffer(
            arrowTransformsBuffer,
            offset: 0,
            index: 2
          )
          
          encoder.drawIndexedPrimitives(
            type: mdlGizmoArrow.submesh.primitiveType,
            indexCount: mdlGizmoArrow.submesh.indexCount,
            indexType: mdlGizmoArrow.submesh.indexType,
            indexBuffer: mdlGizmoArrow.submesh.indexBuffer.buffer,
            indexBufferOffset: mdlGizmoArrow.submesh.indexBuffer.offset,
            instanceCount: arrowTransforms.count
          )
        }
        
        /// -------- End gizmo --------
        
        /// -------- Light source visualization --------
        
//        var lightT = lightTransform
//        lightT.translation = aggregation.position
//        lightT.scale = SIMD3<Float>(repeating: 0.5)
//
//        let m_model_light = lightT.modelMatrix
//        let mvp_light = m_perspective * m_view * m_model_light
//        var uniforms_light = SceneUniforms(
//          mvp: mvp_light,
//          model: m_model_light
//        )
//
//        let renderPD_light = MTLRenderPipelineDescriptor().configure {
//          $0.vertexDescriptor = vertexDescriptor
//          $0.vertexFunction = try! library.funVertex
//          $0.fragmentFunction = try! library.funFragment
//          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
//          $0.depthAttachmentPixelFormat = .depth32Float
//        }
//        let renderPipeline_light = try! device.makeRenderPipelineState(descriptor: renderPD_light)
//
//        renderEncoder?.configure { encoder in
//          encoder.setRenderPipelineState(renderPipeline_light)
//          encoder.setDepthStencilState(
//            device.makeDepthStencilState(
//              descriptor: MTLDepthStencilDescriptor().configure {
//                $0.depthCompareFunction = .less
//                $0.isDepthWriteEnabled = true
//              }
//            )!
//          )
//          encoder.setVertexBuffer(
//            mdlLightObject.mesh.vertexBuffers[0].buffer,
//            offset: mdlLightObject.mesh.vertexBuffers[0].offset,
//            index: 0
//          )
//          encoder.setVertexBytes(
//            &uniforms_light,
//            length: MemoryLayout<SceneUniforms>.stride,
//            index: 1
//          )
//          var _lightPosition = aggregation.position
//          encoder.setFragmentBytes(&_lightPosition, length: MemoryLayout<SIMD3<Float>>.stride, index: 1)
//          encoder.drawIndexedPrimitives(
//            type: mdlLightObject.submesh.primitiveType,
//            indexCount: mdlLightObject.submesh.indexCount,
//            indexType: mdlLightObject.submesh.indexType,
//            indexBuffer: mdlLightObject.submesh.indexBuffer.buffer,
//            indexBufferOffset: mdlLightObject.submesh.indexBuffer.offset,
//            instanceCount: 1
//          )
//        }

        /// -------- End light source visualization --------
        
        renderEncoder?.endEncoding()
        
        buffer.present(drawable)
        buffer.commit()
      }
    }()
    
    init(
      exercise: MTLQuestExercise,
      automaticRotation: Binding<Bool>,
      aggregation: MTLQuestShadingAggregation
    ) {
      self.exercise = exercise
      self.library = .init(
        library: try! device.makeDefaultLibrary(bundle: .main),
        namespace: String(describing: MTLQuestShading.self)
      )

      self.automaticRotation = automaticRotation

      self.aggregation = aggregation
      
      let modelURL = Bundle.main.url(forResource: "pikachu", withExtension: "obj")!
      self.mdlObject = MDLObjectParser(
        modelURL: modelURL,
        device: device
      )
      
      // Load light sphere model
      let lightModelURL = Bundle.main.url(forResource: "sphere", withExtension: "obj")!
      self.mdlLightObject = MDLObjectParser(modelURL: lightModelURL, device: device)
      
      // Load arrow model for gizmo
      let arrowModelURL = Bundle.main.url(forResource: "arrow", withExtension: "obj")!
      self.mdlGizmoArrow = MDLObjectParser(modelURL: arrowModelURL, device: device)
      
      self.lightTransform = Transform(
        translation: aggregation.position,
        scale: SIMD3<Float>(repeating: 3.0)
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
      
      
      /// -------- build instances --------

      // used to move the origin to (0,0)
      let halfWidth = Float(gridColumns - 1) * gridSpacing * 0.5
      let halfHeight = Float(gridRows - 1) * gridSpacing * 0.5
      
      for row in 0..<gridRows {
        for col in 0..<gridColumns {
          if instanceTransforms.count >= instanceCount { break }
          
          let x = Float(col) * gridSpacing - halfWidth
          let y = Float(row) * gridSpacing - halfHeight

          instanceTransforms.append(Transform(translation: SIMD3<Float>(x, y, 0)))
        }
      }

      instanceBuffer = device.makeBuffer(
        length: MemoryLayout<float4x4>.stride * instanceTransforms.count,
        options: []
      )
      
      self.displayLink = CADisplayLink(
        target: self,
        selector: #selector(modelAnimation)
      )
      self.displayLink?.add(to: .main, forMode: .default)
    }
    
    deinit {
      displayLink?.invalidate()
    }
    
    /// Handles model's individual transforms
    @objc private func modelAnimation() {
      if automaticRotation.wrappedValue {
        automaticAngle += 0.012
        if automaticAngle > 2 * .pi {
          automaticAngle -= 2 * .pi
        }
        mtkView?.setNeedsDisplay()
      }
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
      //      guard
      //        let view = mtkView
      //      else { return }
      //
      //      let translation = gesture.translation(in: view)
      //      let yawSensitivity: Float = 0.008
      //      let pitchSensitivity: Float = 0.008
      //
      //      let pos = position.wrappedValue
      //
      //      switch pos {
      //      case 0:
      //        yaw0.wrappedValue += Float(translation.x) * yawSensitivity
      //        pitch0.wrappedValue += Float(translation.y) * pitchSensitivity
      //        pitch0.wrappedValue = pitch0.wrappedValue.clamp(minValue: -.pi/2, maxValue: .pi/2)
      //      case 1:
      //        yaw1.wrappedValue += Float(translation.x) * yawSensitivity
      //        pitch1.wrappedValue += Float(translation.y) * pitchSensitivity
      //        pitch1.wrappedValue = pitch1.wrappedValue.clamp(minValue: -.pi/2, maxValue: .pi/2)
      //      default:
      //        break
      //      }
      //
      //      gesture.setTranslation(.zero, in: view)
      //      view.setNeedsDisplay()
    }
  }
}

// Note: When using MTLQuestInstancedRotations, pass bindings for yaw0, pitch0, head0, yaw1, pitch1, head1,
// position, and the `automaticRotation` binding to enable automatic smooth rotation mode.
// The automatic rotation angle is managed internally by Coordinator and updates automatically on each frame.
// Rotations use quaternion math exclusively.

// TODO: Update Metal vertex shader to fetch the model matrix for each instance from buffer(2)
// using instance_id to properly transform each instance separately.

// Note on shadingModel:
// The selected shading model is passed as an Int to the fragment shader at buffer index 2.
// The Metal shader should read this value to branch or select appropriate shading computations.
// This is a simple approach; for more complex scenarios consider using argument buffers or more structured uniform buffers.

