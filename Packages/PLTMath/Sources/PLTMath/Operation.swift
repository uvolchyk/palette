//
//  Operation.swift
//  PLTMath
//
//  Created by Uladzislau Volchyk on 3/22/25.
//

import math_h

public enum Operation {
  // Bowyer-Watson Algorithm for Delaunay Triangulation
  // https://www.gorillasun.de/blog/bowyer-watson-algorithm-for-delaunay-triangulation/
  public static func bwTriangulate(
    _ points: Set<SIMD2<Float>>
  ) -> Set<Primitive.Triangle> {
    let st = Primitive.Triangle.superTriangle(points: points)

    var triangles = Set(CollectionOfOne(st))

    points.forEach { point in
      triangles.insert(point)
    }

    triangles = triangles.filter { triangle in
      !(triangle.v0 == st.v0 || triangle.v0 == st.v1 || triangle.v0 == st.v2 ||
      triangle.v1 == st.v0 || triangle.v1 == st.v1 || triangle.v1 == st.v2 ||
      triangle.v2 == st.v0 || triangle.v2 == st.v1 || triangle.v2 == st.v2)
    }

    return triangles
  }

  static func distance(
    _ p0: SIMD2<Float>,
    _ p1: SIMD2<Float>
  ) -> Float {
    sqrt(pow(p0.x - p1.x, 2) + pow(p0.y - p1.y, 2))
  }

  static func crossProduct(
    _ v0: SIMD2<Float>,
    _ v1: SIMD2<Float>,
    _ v2: SIMD2<Float>
  ) -> Float {
    (v1.x - v0.x) * (v2.y - v0.y) - (v1.y - v0.y) * (v2.x - v0.x)
  }
}
