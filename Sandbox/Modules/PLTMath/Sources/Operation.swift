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

  static func crossProduct(
    _ a: SIMD2<Float>,
    _ b: SIMD2<Float>
  ) -> Float {
      a.x * b.y - a.y * b.x
  }
  
  public static func convexHull(points: [SIMD2<Float>]) -> [SIMD2<Float>] {
    // Ensure there are at least 3 points (3 points => already convex)
    guard
      points.count >= 3
    else { return points }

    let sorted = points.sorted {
      $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x
    }

    var upper: [SIMD2<Float>] = Array(sorted[0...1])

    for point in sorted.dropFirst(2) {
      upper.append(point)

      while upper.count > 2 {
        let cross = crossProduct(
          upper[upper.count - 3],
          upper[upper.count - 2],
          upper[upper.count - 1]
        )

        // If cross product is zero or negative, the middle point doesn't contribute to the convex hull
        if cross > 0 { break }

        upper.remove(at: upper.count - 2)
      }
    }

    var lower: [SIMD2<Float>] = [sorted[sorted.count - 1], sorted[sorted.count - 2]]

    for point in sorted.dropLast(2).reversed() {
      lower.append(point)

      while lower.count > 2 {
        let cross = crossProduct(
          lower[lower.count - 3],
          lower[lower.count - 2],
          lower[lower.count - 1]
        )

        // If cross product is zero or negative, the middle point doesn't contribute to the convex hull
        if cross > 0 { break }

        lower.remove(at: lower.count - 2)
      }
    }

    lower.removeFirst()
    lower.removeLast()

    return upper + lower
  }
  
  func randomPoints(
    count: Int,
    range: ClosedRange<Float> = 0.0...1.0
  ) -> [SIMD2<Float>] {
      var points = [SIMD2<Float>]()
      for _ in 0..<count {
          let x = Float.random(in: range)
          let y = Float.random(in: range)
          points.append(SIMD2<Float>(x, y))
      }
      return points
  }
}
