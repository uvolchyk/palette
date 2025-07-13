//
//  Pikachu2dRenderer.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/12/25.
//

import Foundation
import MetalKit
import simd

// MARK: - Pikachu2dRenderer
final class Pikachu2dRenderer: NSObject, MTKViewDelegate {
  
  // MARK: Stored properties
  
  let device: any MTLDevice
  var exercise: Exercise
  
  let commandQueue: any MTLCommandQueue
  let library: any MTLLibrary
  let imageTexture: any MTLTexture
  
  let quadPassDescriptor: MTLRenderPipelineDescriptor
  var quadPassPipeline: any MTLRenderPipelineState
  
  private let vertexBuffer: MTLBuffer
  var colorTexture: (any MTLTexture)?

  // Quad vertices: clip-space XY + UV
  private static let vertices: [Float] = [
    //  X     Y       U   V
     -1,  +1,       0,  0,   // left-top
     +1,  +1,       1,  0,   // right-top
     -1,  -1,       0,  1,   // left-bottom
     +1,  -1,       1,  1    // right-bottom
  ]
  
  // MARK: Initialization
  
  required init(device: any MTLDevice, exercise: Exercise) {
    self.device = device
    self.exercise = exercise
    
    // Load image texture from bundle
    guard
      let url = Bundle.main.url(forResource: "pikachu2d", withExtension: "png")
    else {
      fatalError("Could not find pikachu2d.png in main bundle")
    }

    let textureLoader = MTKTextureLoader(device: device)
    let library = try! device.makeDefaultLibrary(bundle: .main)
    do {
      self.imageTexture = try textureLoader.newTexture(URL: url)
      self.library = library
    } catch {
      fatalError("Failed to load pikachu2d.png texture: \(error)")
    }

    self.vertexBuffer = device.makeBuffer(
      bytes: Self.vertices,
      length: MemoryLayout<Float>.size * Self.vertices.count
    )!

    // Global::QuadVertexIn
    let vDesc = MTLVertexDescriptor()
      .configure {
        // attribute(0) – position
        $0.attributes[0].format = .float2
        $0.attributes[0].offset = 0
        $0.attributes[0].bufferIndex = 0
        // attribute(1) – texCoord
        $0.attributes[1].format = .float2
        $0.attributes[1].offset = MemoryLayout<Float>.size * 2
        $0.attributes[1].bufferIndex = 0
        $0.layouts[0].stride = MemoryLayout<Float>.size * 4
      }

    // First pass pipeline descriptor
    quadPassDescriptor = MTLRenderPipelineDescriptor()
      .configure {
        $0.vertexDescriptor = vDesc
        $0.label = "Quad Pass Pipeline"
        $0.vertexFunction = library.makeFunction(name: "Global::quadVertex")
        $0.fragmentFunction = library.makeFunction(name: "Pikachu2d::\(exercise.shaderFunctionName)")
        $0.colorAttachments[0].pixelFormat = .rgba8Unorm
      }

    do {
      self.quadPassPipeline = try device.makeRenderPipelineState(descriptor: quadPassDescriptor)
    } catch {
      fatalError("Failed to create first pass pipeline state: \(error)")
    }

    guard let queue = device.makeCommandQueue() else {
      fatalError("Failed to create command queue")
    }
    self.commandQueue = queue
    
    super.init()
  }
  
  // MARK: MTKViewDelegate
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    guard size.width > 0 && size.height > 0 else {
      colorTexture = nil
      return
    }
    
    // Create or resize offscreen color texture for first pass
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .rgba8Unorm,
      width: Int(size.width),
      height: Int(size.height),
      mipmapped: false
    )
    descriptor.usage = [.renderTarget, .shaderRead]
    descriptor.storageMode = .private
    
    colorTexture = device.makeTexture(descriptor: descriptor)
    colorTexture?.label = "Offscreen Color Texture"
  }
  
  func draw(in view: MTKView) {
    guard
      let drawable = view.currentDrawable,
      let colorTexture,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let viewRenderDescriptor = view.currentRenderPassDescriptor
    else {
      return
    }
    commandBuffer.label = Self.id

    let firstPass = MTLRenderPassDescriptor().configure {
      $0.colorAttachments[0].configure { attachment in
        attachment.texture = colorTexture
        attachment.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        attachment.loadAction = .clear
        attachment.storeAction = .store
      }
    }

    commandBuffer
      .makeRenderCommandEncoder(descriptor: viewRenderDescriptor)?
      .configure {
        $0.label = "First Pass Encoder"
        $0.setRenderPipelineState(quadPassPipeline)

        $0.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let imageAspect = Float(imageTexture.width) / Float(imageTexture.height)
        let viewAspect = Float(view.drawableSize.width) / Float(view.drawableSize.height)
        
        var scaleX: Float = 1
        var scaleY: Float = 1
        
        if viewAspect > imageAspect {
          // View is wider than image: scale X down
          scaleX = imageAspect / viewAspect
        } else {
          // View is taller than image: scale Y down
          scaleY = viewAspect / imageAspect
        }
        
        var uniforms = float4x4(
          rows: [
            .init(scaleX, 0, 0, 0),
            .init(0, scaleY, 0, 0),
            .init(0, 0, 1, 0),
            .init(0, 0, 0, 1),
          ]
        )
        $0.setVertexBytes(&uniforms, length: MemoryLayout<float4x4>.size, index: 1)

        $0.setFragmentTexture(imageTexture, index: 0)
        $0.setFragmentSamplerState(view.defaultSampler, index: 0)
        $0.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      }
      .endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  // MARK: Update exercise shader
  
  func setExercise(_ exercise: Exercise, view: MTKView) {
    self.exercise = exercise
    
    // Update fragment function of second pass
    guard
      let fragmentFunction = library.makeFunction(name: "Pikachu2d::\(exercise.shaderFunctionName)") else {
      fatalError("Failed to find fragment function \(exercise.shaderFunctionName)")
    }
    
    quadPassDescriptor.fragmentFunction = fragmentFunction
    
    do {
      quadPassPipeline = try device.makeRenderPipelineState(descriptor: quadPassDescriptor)
    } catch {
      fatalError("Failed to create second pass pipeline state: \(error)")
    }
    
    // Force redraw
    view.setNeedsDisplay()
  }
}

// MARK: - Exercise extension for shader function naming

//extension Exercise {
//  var shaderFunctionName: String {
//    switch self {
//    case .grayscale:
//      return "grayscale"
//    case .invert:
//      return "invert"
//    case .blur:
//      return "blur"
//    case .edgeDetection:
//      return "edgeDetection"
//    case .pixelate:
//      return "pixelate"
//    case .colorShift:
//      return "colorShift"
//    case .fishEye:
//      return "fishEye"
//    case .kaleidoscope:
//      return "kaleidoscope"
//    case .none:
//      return "displayImage2d"
//    }
//  }
//}

// MARK: - Private extension for static id label

private extension Pikachu2dRenderer {
  static let id = "Pikachu2dRenderer"
}

private extension MTKView {
  /// Convenience: linear-filtered, clamp-to-edge sampler
  var defaultSampler: MTLSamplerState {
    if let s = objc_getAssociatedObject(self, &Self.defaultSamplerKey) as? MTLSamplerState {
      return s
    }
    let desc = MTLSamplerDescriptor()
    desc.minFilter = .linear
    desc.magFilter = .linear
    desc.sAddressMode = .clampToEdge
    desc.tAddressMode = .clampToEdge
    let state = device!.makeSamplerState(descriptor: desc)!
    objc_setAssociatedObject(self, &Self.defaultSamplerKey, state, .OBJC_ASSOCIATION_RETAIN)
    return state
  }

  private static var defaultSamplerKey: UInt8 = 0
}
