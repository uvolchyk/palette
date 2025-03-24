import MetalKit

public final class DissolveRenderer: NSObject {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue

  private let pipelineState: MTLRenderPipelineState

  private var vertexBuffer: MTLBuffer!
  private var vertexCount = 0

  private var visibilityThreshold: Float = 0.0
  private var timer: Float = 0.0
  var duration: Float = 2.0

  public init?(mtkView: MTKView) {
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let queue = device.makeCommandQueue(),
      let library = try? device.makeDefaultLibrary(bundle: Bundle(for: DissolveRenderer.self)),
      let vertexFunc = library.makeFunction(name: "DissolveShader::vertexShader"),
      let fragmentFunc = library.makeFunction(name: "DissolveShader::fragmentShader")
    else { return nil }

    self.device = device
    mtkView.device = device
    commandQueue = queue

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunc
    pipelineDescriptor.fragmentFunction = fragmentFunc

    pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true

    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

    do {
      pipelineState = try device.makeRenderPipelineState(
        descriptor: pipelineDescriptor
      )
    } catch {
      return nil
    }

    super.init()
    mtkView.delegate = self

    // position.x, position.y, position.z, position.w, progress, color RGBA
    let vertexData: [Float] = [
      // triangle 1
      -1.0,  1.0, 0.0, 1.0, 0.0, 0.9176470588, 0.2235294118, 0.3921568627, 1,
       1.0,  1.0, 0.0, 1.0, 0.0, 0.1058823529, 0.5019607843, 0.9490196078, 1,
      -1.0, -1.0, 0.0, 1.0, 1.0, 0.4117647059, 0.8352941176, 0.8745098039, 1,

      // triangle 2
      -1.0, -1.0, 0.0, 1.0, 1.0, 0.4117647059, 0.8352941176, 0.8745098039, 1,
       1.0,  1.0, 0.0, 1.0, 0.0, 0.1058823529, 0.5019607843, 0.9490196078, 1,
       1.0, -1.0, 0.0, 1.0, 1.0, 0.3882352941, 0.3882352941, 0.8431372549, 1,
    ]

    vertexCount = vertexData.count / 9
    vertexBuffer = device.makeBuffer(
      bytes: vertexData,
      length: MemoryLayout<Float>.stride * vertexData.count
    )
  }
}

extension DissolveRenderer: MTKViewDelegate {
  public func draw(in view: MTKView) {
    guard
      let drawable = view.currentDrawable,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let descriptor = view.currentRenderPassDescriptor,
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
    else { return }

    timer += 1.0 / (Float(view.preferredFramesPerSecond) * duration)
    visibilityThreshold = Float(timer).truncatingRemainder(dividingBy: 2.0)

    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBuffer(
      vertexBuffer,
      offset: 0,
      index: 0
    )

    renderEncoder.setFragmentBytes(
      &visibilityThreshold,
      length: MemoryLayout<Float>.stride,
      index: 1
    )

    renderEncoder.drawPrimitives(
      type: .triangleStrip,
      vertexStart: 0,
      vertexCount: vertexCount
    )

    renderEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  public func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {}
}
