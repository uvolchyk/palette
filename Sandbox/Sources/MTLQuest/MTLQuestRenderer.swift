//
//  MTLQuestRenderer.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import MetalKit

final class MTLQuestRenderer: NSObject, MTKViewDelegate {
  let device: any MTLDevice
  let commandQueue: any MTLCommandQueue
  let configurator: (any MTLCommandBuffer, MTKView) -> Void

  init(
    device: any MTLDevice,
    configurator: @escaping (any MTLCommandBuffer, MTKView) -> Void
  ) {
    self.device = device
    self.configurator = configurator

    guard
      let queue = device.makeCommandQueue()
    else {
      fatalError()
    }

    self.commandQueue = queue
  }

  func mtkView(
    _ view: MTKView,
    drawableSizeWillChange size: CGSize
  ) {
    
  }

  func draw(in view: MTKView) {
    guard
      let commandBuffer = commandQueue.makeCommandBuffer()
    else {
      return
    }

    configurator(commandBuffer, view)
  }
}
