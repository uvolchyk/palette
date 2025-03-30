//
//  ConvexHull.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 3/27/25.
//

import SwiftUI
import PLTMath

struct ConvexHullView: View {
  let engine = MovingPointsEngine(
    pointCount: 90,
    boundingBox: .zero,
    maxSpeed: 0.5
  )
  
  private let pointRadius: CGFloat = 2
  
  var body: some View {
    Canvas { context, size in
      let boundingBox = SIMD2<Float>(
        x: Float(size.width - 80),
        y: Float(size.height - 80)
      )
      
      // Update bounding box if needed
      if engine.points.isEmpty {
        engine.updateBoundingBox(boundingBox, pointCount: 90)
        engine.start()
      }
      
      let convexHull = PLTMath.Operation.convexHull(points: engine.points)

      // Draw the convex hull
      var hullPath = Path()
      if let firstPoint = convexHull.first {
        hullPath.move(to: CGPoint(firstPoint))
        for point in convexHull.dropFirst() {
          hullPath.addLine(to: CGPoint(point))
        }
        hullPath.closeSubpath()
      }

      // Draw all points
      var pointsPath = Path()
      for point in engine.points {
        let rect = CGRect(
          x: CGFloat(point.x) - pointRadius,
          y: CGFloat(point.y) - pointRadius,
          width: pointRadius * 2,
          height: pointRadius * 2
        )
        pointsPath.addEllipse(in: rect)
      }

      context.stroke(hullPath, with: .color(.black), lineWidth: 1)
      context.fill(pointsPath, with: .color(.blue))
    }
    .frame(width: 300, height: 300)
    .onDisappear {
      engine.stop()
    }
  }
}


#Preview {
  ConvexHullView()
}
