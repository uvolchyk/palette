//
//  ConvexHull.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 3/27/25.
//

import SwiftUI
import PLTMath

struct ConvexHullView: View {
  var body: some View {
    Canvas { context, size in
      let points = DelaunayTriangulation.randomPoints(
        count: 90,
        within: .init(
          x: Float(size.width - 80),
          y: Float(size.height - 80)
        )
      )

      let convexHull = PLTMath.Operation.convexHull(points: points)

      var hullPath = Path()
      if let firstPoint = convexHull.first {
        hullPath.move(to: CGPoint(firstPoint))
        for point in convexHull.dropFirst() {
          hullPath.addLine(to: CGPoint(point))
        }
        hullPath.closeSubpath()
      }

      var pointsPath = Path()
      for point in points {
        let rect = CGRect(
          x: CGFloat(point.x) - 2,
          y: CGFloat(point.y) - 2,
          width: 4,
          height: 4
        )
        pointsPath.addEllipse(in: rect)
      }

      context.stroke(hullPath, with: .color(.black), lineWidth: 2)
      context.fill(pointsPath, with: .color(.blue))
    }
    .frame(width: 300, height: 300)
  }
}


#Preview {
  ConvexHullView()
}
