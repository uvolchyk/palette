//
//  Math3D.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/26/25.
//

import CoreGraphics
import simd

extension simd_float4x4 {
  public static func perspective(
    fovYRadians: Float,
    aspect: Float,
    nearZ: Float,
    farZ: Float
  ) -> Self {
    let yScale = 1 / tan(fovYRadians * 0.5)
    let xScale = yScale / aspect
    let zRange = farZ - nearZ
    let zScale = farZ / zRange
    let wz = -nearZ * zScale
    
    return Self(
      SIMD4<Float>( xScale,   0,      0,   0 ),
      SIMD4<Float>(      0, yScale,   0,   0 ),
      SIMD4<Float>(      0,      0, zScale, 1 ),
      SIMD4<Float>(      0,      0,   wz,   0 )
    )
  }

  public static func lookAt(
    eye: SIMD3<Float>,
    center: SIMD3<Float>,
    up: SIMD3<Float>
  ) -> simd_float4x4 {
    let zAxis = normalize(center - eye)         // Forward
    let xAxis = normalize(cross(up, zAxis))     // Right
    let yAxis = cross(zAxis, xAxis)             // Up
    let translation = SIMD3<Float>(
      -dot(xAxis, eye),
       -dot(yAxis, eye),
       -dot(zAxis, eye)
    )
    return simd_float4x4(
      SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0),
      SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0),
      SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0),
      SIMD4<Float>(translation.x, translation.y, translation.z, 1)
    )
  }
}

extension Double {
  /// Number of radians in *one turn*.
  @_transparent public static var τ: Double { Double.pi * 2 }
  /// Number of radians in *half a turn*.
  @_transparent public static var π: Double { Double.pi }
}

extension Float {
  /// Number of radians in *one turn*.
  @_transparent public static var τ: Float { Float(Double.τ) }
  /// Number of radians in *half a turn*.
  @_transparent public static var π: Float { Float(Double.π) }

  public func clamp(
    minValue: Float,
    maxValue: Float
  ) -> Float {
    min(max(minValue, self), maxValue)
  }

  public static func lerp(_ from: Float, _ to: Float, _ t: Float) -> Float {
    from + (to - from) * t
  }
}

public extension SIMD4 {
  var xy: SIMD2<Scalar> {
    SIMD2([self.x, self.y])
  }

  var xyz: SIMD3<Scalar> {
    SIMD3([self.x, self.y, self.z])
  }
}

public extension float4x4 {
  /// Creates a 4x4 matrix representing a translation given by the provided vector.
  /// - parameter vector: Vector giving the direction and magnitude of the translation.
  init(translate vector: SIMD3<Float>) {
    // List of the matrix' columns
    let baseX: SIMD4<Float> = [1, 0, 0, 0]
    let baseY: SIMD4<Float> = [0, 1, 0, 0]
    let baseZ: SIMD4<Float> = [0, 0, 1, 0]
    let baseW: SIMD4<Float> = [vector.x, vector.y, vector.z, 1]
    self.init(baseX, baseY, baseZ, baseW)
  }

  /// Creates a 4x4 matrix representing a uniform scale given by the provided scalar.
  /// - parameter s: Scalar giving the uniform magnitude of the scale.
  init(scale s: Float) {
    self.init(diagonal: [s, s, s, 1])
  }

  init(scale s: SIMD3<Float>) {
    self.init(diagonal: .init(s.x, s.y, s.z, 1))
  }

  /// Creates a 4x4 matrix that will rotate through the given vector and given angle.
  /// - parameter angle: The amount of radians to rotate from the given vector center.
  init(rotate vector: SIMD3<Float>, angle: Float) {
    let c: Float = cos(angle)
    let s: Float = sin(angle)
    let cm = 1 - c

    let x0 = vector.x*vector.x + (1-vector.x*vector.x)*c
    let x1 = vector.x*vector.y*cm - vector.z*s
    let x2 = vector.x*vector.z*cm + vector.y*s

    let y0 = vector.x*vector.y*cm + vector.z*s
    let y1 = vector.y*vector.y + (1-vector.y*vector.y)*c
    let y2 = vector.y*vector.z*cm - vector.x*s

    let z0 = vector.x*vector.z*cm - vector.y*s
    let z1 = vector.y*vector.z*cm + vector.x*s
    let z2 = vector.z*vector.z + (1-vector.z*vector.z)*c

    // List of the matrix' columns
    let baseX: SIMD4<Float> = [x0, x1, x2, 0]
    let baseY: SIMD4<Float> = [y0, y1, y2, 0]
    let baseZ: SIMD4<Float> = [z0, z1, z2, 0]
    let baseW: SIMD4<Float> = [ 0,  0,  0, 1]
    self.init(baseX, baseY, baseZ, baseW)
  }

  /// Creates a perspective matrix from an aspect ratio, field of view, and near/far Z planes.
  init(
    perspectiveWithAspect aspect: Float,
    fovy: Float,
    near: Float,
    far: Float
  ) {
    let yScale = 1 / tan(fovy * 0.5)
    let xScale = yScale / aspect
    let zRange = far - near
    let zScale = -(far + near) / zRange
    let wzScale = -2 * far * near / zRange

    // List of the matrix' columns
    let vectorP: SIMD4<Float> = [xScale,      0,       0,  0]
    let vectorQ: SIMD4<Float> = [     0, yScale,       0,  0]
    let vectorR: SIMD4<Float> = [     0,      0,  zScale, -1]
    let vectorS: SIMD4<Float> = [     0,      0, wzScale,  0]
    self.init(vectorP, vectorQ, vectorR, vectorS)
  }
}

extension CGSize {
  public var aspectMatrix: float4x4 {
    let f_width = Float(width)
    let f_height = Float(height)
    
    var scaleX: Float = 1
    var scaleY: Float = 1
    
    if f_width > f_height {
      scaleX = f_height / f_width
    } else if f_height > f_width {
      scaleY = f_width / f_height
    }
    
    // Now build your matrix:
    return float4x4(
      rows: [
        .init(scaleX, 0, 0, 0),
        .init(0, scaleY, 0, 0),
        .init(0, 0, 1, 0),
        .init(0, 0, 0, 1),
      ]
    )
  }
}

extension simd_float4x4 {
  /// Rotation around Z axis
  public static func rotationZ(angleRadians: Float) -> simd_float4x4 {
    let c = cos(angleRadians)
    let s = sin(angleRadians)
    return simd_float4x4(
      SIMD4<Float>( c,  s, 0, 0),
      SIMD4<Float>(-s,  c, 0, 0),
      SIMD4<Float>( 0,  0, 1, 0),
      SIMD4<Float>( 0,  0, 0, 1)
    )
  }

  /// Rotation around X axis
  public static func rotationX(angleRadians: Float) -> simd_float4x4 {
    let c = cos(angleRadians)
    let s = sin(angleRadians)
    return simd_float4x4(
      SIMD4<Float>(1, 0,  0, 0),
      SIMD4<Float>(0, c,  s, 0),
      SIMD4<Float>(0,-s,  c, 0),
      SIMD4<Float>(0, 0,  0, 1)
    )
  }

  /// Rotation around Y axis
  public static func rotationY(angleRadians: Float) -> simd_float4x4 {
    let c = cos(angleRadians)
    let s = sin(angleRadians)
    return simd_float4x4(
      SIMD4<Float>( c, 0, -s, 0),
      SIMD4<Float>( 0, 1,  0, 0),
      SIMD4<Float>( s, 0,  c, 0),
      SIMD4<Float>( 0, 0,  0, 1)
    )
  }

  public init(
    quaternionFromYaw yaw: Float, pitch: Float, head: Float
  ) {
    // Euler angles order: yaw (Y), pitch (X), head (Z)
    let qYaw = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
    let qPitch = simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
    let qHead = simd_quatf(angle: head, axis: SIMD3<Float>(0, 0, 1))

    self = simd_float4x4(qHead * qPitch * qYaw)
  }

  public init(
    eulerFromYaw yaw: Float, pitch: Float, head: Float
  ) {
    // Rotation order: Z(head) * X(pitch) * Y(yaw)
    let rz = simd_float4x4.rotationZ(angleRadians: head)
    let rx = simd_float4x4.rotationX(angleRadians: pitch)
    let ry = simd_float4x4.rotationY(angleRadians: yaw)

    self = rz * rx * ry
  }
}
