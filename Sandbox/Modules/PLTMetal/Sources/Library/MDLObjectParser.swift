//
//  MDLObjectParser.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/26/25.
//

import ModelIO
import MetalKit

public struct MDLObjectParser {
  public let mesh: MTKMesh
  public let submesh: MTKSubmesh

  public init(
    modelURL: URL,
    device: MTLDevice,
  ) {
    let allocator = MTKMeshBufferAllocator(device: device)

    let mdlVertexDescriptor = MDLVertexDescriptor()
    mdlVertexDescriptor.attributes[0] = MDLVertexAttribute(
      name: MDLVertexAttributePosition,
      format: .float3,
      offset: 0,
      bufferIndex: 0
    )
    mdlVertexDescriptor.attributes[1] = MDLVertexAttribute(
      name: MDLVertexAttributeNormal,
      format: .float3,
      offset: 12,
      bufferIndex: 0
    )
    mdlVertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: 24)

    let asset = MDLAsset(
      url: modelURL,
      vertexDescriptor: mdlVertexDescriptor,
      bufferAllocator: allocator
    )

    let mdlMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh
    let mesh = try! MTKMesh(mesh: mdlMesh, device: device)

    self.mesh = mesh
    self.submesh = mesh.submeshes.first!
  }
}
