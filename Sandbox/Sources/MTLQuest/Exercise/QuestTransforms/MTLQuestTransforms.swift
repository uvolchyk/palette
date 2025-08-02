//
//  MTLQuestTransforms.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/31/25.
//
//  Updated to support two-way binding for yaw, pitch, and head angles,
//  and to optionally use quaternion or Euler angle rotation modes.

import SwiftUI
import MetalKit
import ModelIO
import PLTMetal
import PLTMath

/// Displaying multiple objects in a single scene.
/// Working with gestures (scale, pitch, yaw), studying spherical coordinates.
/// Displaying gizmo.
/// 'head' now represents roll angle around Z axis, not a distance.
/// Supports two modes for rotation:
/// - Quaternion mode (default): rotations are applied using quaternions.
/// - Euler mode: rotations are applied by composing Euler angle rotation matrices in Z (head), X (pitch), Y (yaw) order.
struct MTLQuestTransforms: UIViewRepresentable {
  let exercise: MTLQuestExercise
  @Binding var yaw0: Float
  @Binding var pitch0: Float
  @Binding var head0: Float
  @Binding var yaw1: Float
  @Binding var pitch1: Float
  @Binding var head1: Float
  @Binding var position: Int
  @Binding var useQuaternion: Bool
  var animationDuration: Double = 2.0
  
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
    context.coordinator.updateFromParent(
      yaw0: yaw0, pitch0: pitch0, head0: head0,
      yaw1: yaw1, pitch1: pitch1, head1: head1,
      position: position,
      useQuaternion: useQuaternion
    )
  }
}

extension MTLQuestTransforms {
  @MainActor
  func makeCoordinator() -> Coordinator {
    Coordinator(
      exercise: exercise,
      yaw0: $yaw0,
      pitch0: $pitch0,
      head0: $head0,
      yaw1: $yaw1,
      pitch1: $pitch1,
      head1: $head1,
      position: $position,
      useQuaternion: $useQuaternion,
      animationDuration: animationDuration
    )
  }
  
  final class Coordinator {
    private var rotationAngle: Float = 0
    private var displayLink: CADisplayLink?
    private var cameraDistance: Float = 80.0
    private var cameraX: Float = 0.0
    private var cameraY: Float = 0.0
    
    private var _yaw0: () -> Float
    private var _pitch0: () -> Float
    private var _head0: () -> Float

    private var yaw0: Float { _yaw0() }
    private var pitch0: Float { _pitch0() }
    private var head0: Float { _head0() }

    private var _yaw1: () -> Float
    private var _pitch1: () -> Float
    private var _head1: () -> Float

    private var yaw1: Float { _yaw1() }
    private var pitch1: Float { _pitch1() }
    private var head1: Float { _head1() }

    private var position: Binding<Int>
    private var useQuaternion: Binding<Bool>

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
      simd_quatf(angle: 0.0, axis: SIMD3<Float>(0, 0, 1)) *
      simd_quatf(angle: -1.0, axis: SIMD3<Float>(1, 0, 0)) *
      simd_quatf(angle: 2.0, axis: SIMD3<Float>(0, 1, 0))
    }()

    private var rotQuat2Static: simd_quatf = {
      simd_quatf(angle: 2.0, axis: SIMD3<Float>(0, 0, 1)) *
      simd_quatf(angle: 1.0, axis: SIMD3<Float>(1, 0, 0)) *
      simd_quatf(angle: -2.0, axis: SIMD3<Float>(0, 1, 0))
    }()
    
    let mdlObjects: [MDLObjectParser]

    private var animationDuration: Double

    private var animationStartTime: CFTimeInterval?

    private var lastKnownPosition: Int
    private var lastKnownUseQuaternion: Bool

    /// generalized

    private var currentRotation: float4x4 = matrix_identity_float4x4
    private var animationFrom: float4x4 = matrix_identity_float4x4
    private var animationTo: float4x4? = nil

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
        // Compute eye using camera pitch and yaw for the view
        let cx = cos(pitch0) * sin(yaw0)
        let cy = sin(pitch0)
        let cz = cos(pitch0) * cos(yaw0)

        let eye = SIMD3<Float>(cx, cy, cz) * radius
        let center = SIMD3<Float>(cameraX, cameraY, 0)

        // Determine current target rotation based on animation state or position
        var targetRotationMatrix: simd_float4x4 = matrix_identity_float4x4

        if useQuaternion.wrappedValue {
          // Quaternion mode behavior

          if
            let toQuat = animationTo,
            let start = animationStartTime
          {
            let elapsed = CACurrentMediaTime() - start
            let t = min(1.0, elapsed / animationDuration)

            if t >= 1.0 {
              currentRotation = toQuat
              animationTo = nil
              animationStartTime = nil
              targetRotationMatrix = toQuat
            } else {
              currentRotation = float4x4(simd_slerp(simd_quatf(animationFrom), simd_quatf(toQuat), Float(t)))
              targetRotationMatrix = currentRotation
            }
          } else {
            // No animation, just use quaternion from active set
            let pos = position.wrappedValue
            currentRotation = pos == 0 ?
            float4x4(quaternionFromYaw: yaw0, pitch: pitch0, head: head0) :
            float4x4(quaternionFromYaw: yaw1, pitch: pitch1, head: head1)
        
            targetRotationMatrix = currentRotation
          }

        } else {
          // Euler mode behavior

          // Current yaw/pitch/head values for both sets
//          let currentYaw0 = yaw0.wrappedValue
//          let currentPitch0 = pitch0.wrappedValue
//          let currentHead0 = head0.wrappedValue
//
//          let currentYaw1 = yaw1.wrappedValue
//          let currentPitch1 = pitch1.wrappedValue
//          let currentHead1 = head1.wrappedValue

          let pos = position.wrappedValue

          if let start = animationStartTime {
            let elapsed = CACurrentMediaTime() - start
            let t = min(1.0, elapsed / animationDuration)

            if t >= 1.0 {
              animationStartTime = nil

              if pos == 0 {
                targetRotationMatrix = .init(eulerFromYaw: yaw0, pitch: pitch0, head: head0)
              } else {
                targetRotationMatrix = .init(eulerFromYaw: yaw1, pitch: pitch1, head: head1)
              }
            } else {
              let fromYaw = pos == 0 ? yaw1 : yaw0
              let toYaw = pos == 1 ? yaw1 : yaw0

              let fromHead = pos == 0 ? head1 : head0
              let toHead = pos == 1 ? head1 : head0

              let fromPitch = pos == 0 ? pitch1 : pitch0
              let toPitch = pos == 1 ? pitch1 : pitch0

              let interpYaw: Float = .lerp(fromYaw, toYaw, Float(t))
              let interpPitch: Float = .lerp(fromPitch, toPitch, Float(t))
              let interpHead: Float = .lerp(fromHead, toHead, Float(t))
              targetRotationMatrix = .init(eulerFromYaw: interpYaw, pitch: interpPitch, head: interpHead)
            }
          } else {
            // No animation; use current yaw/pitch/head of active position
            if pos == 0 {
              targetRotationMatrix = .init(eulerFromYaw: yaw0, pitch: pitch0, head: head0)
            } else {
              targetRotationMatrix = .init(eulerFromYaw: yaw1, pitch: pitch1, head: head1)
            }
          }

          currentRotation = targetRotationMatrix
        }

        // -------- Render --------
        let rotationMatrix = targetRotationMatrix

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

        for mdlObject in mdlObjects {
          let m_model: simd_float4x4 =  .init(
            translate: SIMD3<Float>(0, 0, 0)
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

        /// -------- gizmo --------
//        let renderPD_gizmo = MTLRenderPipelineDescriptor().configure {
//          $0.vertexDescriptor = vertexDescriptor
//          $0.vertexFunction = try! library.gizmo_vertex
//          $0.fragmentFunction = try! library.gizmo_fragment
//          $0.colorAttachments[0].pixelFormat = view.colorPixelFormat
//          $0.depthAttachmentPixelFormat = .depth32Float
//        }
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

    init(
      exercise: MTLQuestExercise,
      yaw0: Binding<Float>,
      pitch0: Binding<Float>,
      head0: Binding<Float>,
      yaw1: Binding<Float>,
      pitch1: Binding<Float>,
      head1: Binding<Float>,
      position: Binding<Int>,
      useQuaternion: Binding<Bool>,
      animationDuration: Double = 2.0
    ) {
      self.exercise = exercise
      self.library = .init(
        library: try! device.makeDefaultLibrary(bundle: .main),
        namespace: String(describing: MTLQuestTransforms.self)
      )

      self._yaw0 = { yaw0.wrappedValue }
      self._pitch0 = { pitch0.wrappedValue }
      self._head0 = { head0.wrappedValue }

      self._yaw1 = { yaw1.wrappedValue }
      self._pitch1 = { pitch1.wrappedValue }
      self._head1 = { head1.wrappedValue }

      self.position = position
      self.useQuaternion = useQuaternion

      self.animationDuration = animationDuration

      self.lastKnownPosition = position.wrappedValue
      self.lastKnownUseQuaternion = useQuaternion.wrappedValue

      self.animationTo = nil
      self.animationStartTime = nil

      let modelURL = Bundle.main.url(forResource: "pikachu", withExtension: "obj")!
      self.mdlObjects = [
        MDLObjectParser(
          modelURL: modelURL,
          device: device
        )
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
        selector: #selector(modelAnimation)
      )
      self.displayLink?.add(to: .main, forMode: .default)
    }

    deinit {
      displayLink?.invalidate()
    }

    /// Handles model's individual transforms
    @objc private func modelAnimation() {
//      rotationAngle += 0.012
//      if rotationAngle > 2 * .pi {
//        rotationAngle -= 2 * .pi
//      }
//
//      mtkView?.setNeedsDisplay()
    }

    func startRotationAnimation(to targetQuat: simd_float4x4) {
      animationFrom = currentRotation
      animationTo = targetQuat
      animationStartTime = CACurrentMediaTime()
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

    func updateFromParent(
      yaw0: Float, pitch0: Float, head0: Float,
      yaw1: Float, pitch1: Float, head1: Float,
      position: Int,
      useQuaternion: Bool
    ) {
      var didUpdateAnimation = false
      
      if position != lastKnownPosition {
        lastKnownPosition = position

        animationStartTime = nil
        animationTo = nil
        animationFrom = currentRotation

        if useQuaternion {
          let targetRotation: simd_float4x4 = position == 0
            ? .init(quaternionFromYaw: yaw0, pitch: pitch0, head: head0)
            : .init(quaternionFromYaw: yaw1, pitch: pitch1, head: head1)

          startRotationAnimation(to: targetRotation)
          didUpdateAnimation = true
        } else {
          startRotationAnimation(to: matrix_identity_float4x4)
          didUpdateAnimation = true
        }
      }
      
      // If not position or useQuaternion change, do not update animation; only redraw.
      if !didUpdateAnimation {
        mtkView?.setNeedsDisplay()
      }
    }
  }
}

// Note: When using MTLQuestTransforms, pass bindings for yaw0, pitch0, head0, yaw1, pitch1, head1,
// position, and the new `useQuaternion` binding to enable two-way synchronization with the parent SwiftUI view
// for both transform sets and rotation mode selection.
// When `useQuaternion` is true, rotations use quaternion math.
// When false, rotations use Euler angle matrices with Z (head), X (pitch), Y (yaw) order.
