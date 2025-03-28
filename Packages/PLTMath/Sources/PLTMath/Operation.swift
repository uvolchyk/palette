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
      guard points.count >= 3 else { return points }
      
      // Brute-force: find all edges such that all other points lie on one side.
      var hullEdges = [(SIMD2<Float>, SIMD2<Float>)]()
      for i in 0..<points.count {
          for j in 0..<points.count where i != j {
              let p = points[i]
              let q = points[j]
              var isEdge = true
              var sign: Float = 0
              for k in 0..<points.count where k != i && k != j {
                  let r = points[k]
                  let cp = crossProduct(q - p, r - p)
                  if cp != 0 {
                      if sign == 0 {
                          sign = cp
                      } else if cp * sign < 0 {
                          isEdge = false
                          break
                      }
                  }
              }
              if isEdge {
                  hullEdges.append((p, q))
              }
          }
      }
      
      // Collect all points that appeared as endpoints of a hull edge.
      var hullPoints = Set<SIMD2<Float>>()
      for (p, q) in hullEdges {
          hullPoints.insert(p)
          hullPoints.insert(q)
      }
      
      // Order the hull points using Andrew's monotone chain.
      let pointsOnHull = Array(hullPoints)
      let sorted = pointsOnHull.sorted {
          ($0.x, $0.y) < ($1.x, $1.y)
      }
      
      var lower: [SIMD2<Float>] = []
      for p in sorted {
          while lower.count >= 2 &&
                  crossProduct(lower[lower.count - 1] - lower[lower.count - 2], p - lower[lower.count - 2]) <= 0 {
              lower.removeLast()
          }
          lower.append(p)
      }
      
      var upper: [SIMD2<Float>] = []
      for p in sorted.reversed() {
          while upper.count >= 2 &&
                  crossProduct(upper[upper.count - 1] - upper[upper.count - 2], p - upper[upper.count - 2]) <= 0 {
              upper.removeLast()
          }
          upper.append(p)
      }
      
      // The first and last points of each chain are duplicated.
      lower.removeLast()
      upper.removeLast()
      
      return lower + upper
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
