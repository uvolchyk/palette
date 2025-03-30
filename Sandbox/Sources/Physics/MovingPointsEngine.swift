//
//  MovingPointsEngine.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 3/30/25.
//

import Foundation

/// A general-purpose engine for managing moving points within a bounded area
@Observable
public final class MovingPointsEngine {
  public private(set) var points: [SIMD2<Float>] = []
  
  private var velocities: [SIMD2<Float>] = []
  private var boundingBox: SIMD2<Float>
  private var task: Task<Void, Never>?
  
  public var maxSpeed: Float
  public var timeInterval: TimeInterval
  
  /// Initialize the engine with parameters
  /// - Parameters:
  ///   - pointCount: Number of points to generate
  ///   - boundingBox: The area within which points can move
  ///   - maxSpeed: Maximum velocity for points
  ///   - timeInterval: Update interval in seconds
  public init(
    pointCount: Int,
    boundingBox: SIMD2<Float>,
    maxSpeed: Float = 0.5,
    timeInterval: TimeInterval = 0.016
  ) {
    self.boundingBox = boundingBox
    self.maxSpeed = maxSpeed
    self.timeInterval = timeInterval
    
    if boundingBox != .zero {
      initializePoints(count: pointCount)
    }
  }
  
  private func initializePoints(count: Int) {
    // Initialize random points
    self.points = DelaunayTriangulation.randomPoints(
      count: count,
      within: boundingBox
    )
    
    // Initialize random velocities
    self.velocities = (0..<count).map { _ in
      SIMD2<Float>(
        x: Float.random(in: -maxSpeed...maxSpeed),
        y: Float.random(in: -maxSpeed...maxSpeed)
      )
    }
  }
  
  /// Start the animation engine
  public func start() {
    stop()
    
    task = Task { [weak self] in
      guard let self = self else { return }
      
      while !Task.isCancelled {
        await MainActor.run {
          self.updatePositions()
        }
        try? await Task.sleep(for: .seconds(timeInterval))
      }
    }
  }
  
  /// Stop the animation engine
  public func stop() {
    task?.cancel()
    task = nil
  }
  
  /// Update the bounding box (e.g., when view size changes)
  public func updateBoundingBox(_ newBox: SIMD2<Float>, pointCount: Int) {
    boundingBox = newBox
    if points.isEmpty && boundingBox != .zero {
      initializePoints(count: pointCount)
    }
  }
  
  /// Set new points with random velocities
  public func setPoints(_ newPoints: [SIMD2<Float>]) {
    points = newPoints
    velocities = (0..<points.count).map { _ in
      SIMD2<Float>(
        x: Float.random(in: -maxSpeed...maxSpeed),
        y: Float.random(in: -maxSpeed...maxSpeed)
      )
    }
  }
  
  /// Set custom velocities for points
  public func setVelocities(_ newVelocities: [SIMD2<Float>]) {
    guard newVelocities.count == points.count else { return }
    velocities = newVelocities
  }
  
  private func updatePositions() {
    for i in 0..<points.count {
      // Update position based on velocity
      points[i] = SIMD2<Float>(
        x: points[i].x + velocities[i].x,
        y: points[i].y + velocities[i].y
      )
      
      // Bounce off the edges of the bounding box
      if points[i].x <= 0 || points[i].x >= boundingBox.x {
        velocities[i].x = -velocities[i].x
      }
      
      if points[i].y <= 0 || points[i].y >= boundingBox.y {
        velocities[i].y = -velocities[i].y
      }
      
      // Ensure points stay within bounds
      points[i].x = min(max(points[i].x, 0), boundingBox.x)
      points[i].y = min(max(points[i].y, 0), boundingBox.y)
    }
  }
  
  deinit {
    stop()
  }
}
