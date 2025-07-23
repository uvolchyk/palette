//
//  ShaderLibrary.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

import MetalKit

public struct ShaderLibrary {
  let library: MTLLibrary
  let namespace: String?
  
  public init(
    library: MTLLibrary,
    namespace: String? = nil
  ) {
    self.library = library
    self.namespace = namespace
  }

  public func function(
    named name: String,
    type: MTLFunctionType? = nil,
    constantValues: MTLFunctionConstantValues? = nil
  ) throws -> MTLFunction {
    let scopedNamed = namespace.map { "\($0)::\(name)" } ?? name
    let constantValues = constantValues ?? MTLFunctionConstantValues()
    let function = try library.makeFunction(name: scopedNamed, constantValues: constantValues)

    if let type, function.functionType != type {
      fatalError()
    }

    return function
  }
}
