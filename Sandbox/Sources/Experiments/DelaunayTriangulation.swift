//
//  DelaunayTriangulation.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 3/23/25.
//

import SwiftUI
import PLTMath

struct DelaunayTriangulation {
  var vertices: [SIMD2<Float>]

  static func randomPoints(
    count: Int,
    within bounds: SIMD2<Float>
  ) -> [SIMD2<Float>] {
    (0..<count).map { _ in
      SIMD2<Float>(
        x: .random(in: 0..<bounds.x),
        y: .random(in: 0..<bounds.y)
      )
    }
  }
}

struct DelaunayTriangulationView: View {
  var body: some View {
    ZStack {
      Canvas {
        context,
        size in
        let points = DelaunayTriangulation.randomPoints(
          count: 20,
          within: .init(
            x: Float(size.width - 40.0),
            y: Float(size.height - 40.0)
          )
        )
        let triangulation = PLTMath.Operation.bwTriangulate(Set(points))
        
        var _path = Path()
        
        triangulation.forEach { triangle in
          _path.move(to: .init(triangle.v0))
          _path.addLine(to: .init(triangle.v1))
          _path.addLine(to: .init(triangle.v2))
          _path.closeSubpath()

          _path.addEllipse(
            in: .init(
              x: CGFloat(triangle.v0.x) - 4.0,
              y: CGFloat(triangle.v0.y) - 4.0,
              width: 8.0,
              height: 8.0
            )
          )
          _path.addEllipse(
            in: .init(
              x: CGFloat(triangle.v1.x) - 4.0,
              y: CGFloat(triangle.v1.y) - 4.0,
              width: 8.0,
              height: 8.0
            )
          )
          _path.addEllipse(
            in: .init(
              x: CGFloat(triangle.v2.x) - 4.0,
              y: CGFloat(triangle.v2.y) - 4.0,
              width: 8.0,
              height: 8.0
            )
          )
          
          let _center = triangle.triangleCenter
          _path.addEllipse(
            in: .init(
              x: CGFloat(_center.x) - 1.0,
              y: CGFloat(_center.y) - 1.0,
              width: 2.0,
              height: 2.0
            )
          )
        }

        context.stroke(_path, with: .color(.black))
      }
    }
    .frame(width: 400.0, height: 400.0)
  }
}

extension CGPoint {
  init(_ simd: SIMD2<Float>) {
    self.init(x: Double(simd.x), y: Double(simd.y))
  }
}

#Preview {
  DelaunayTriangulationView()
}
