public enum Primitive {
  public struct Edge2<T: SIMDScalar & Hashable>: Hashable {
    var v0: SIMD2<T>
    var v1: SIMD2<T>
  }

  public struct Circle: Equatable {
    var center: SIMD2<Float>
    var radius: Float

    func contains(_ p: SIMD2<Float>) -> Bool {
      Operation.distance(center, p) <= radius
    }

    public init(
      center: SIMD2<Float>,
      radius: Float
    ) {
      self.center = center
      self.radius = radius
    }

    init?(_ points: Set<SIMD2<Float>>) {
      // Progressively add points to circle or recompute circle
      var c: Circle?

      points.forEach { p in
        if
          let _c = c, !_c.contains(p)
        {
          c = Circle(points.subtracting([p]), p)
        } else if
          c == nil
        {
          c = Circle(points.subtracting([p]), p)
        }
      }

      guard let c else { return nil }
      self = c
    }

    public init?(
      _ points: Set<SIMD2<Float>>,
      _ p: SIMD2<Float>
    ) {
      var c = Circle(center: p, radius: 0)

      points.forEach { q in
        if c.contains(q) { return }

        if c.radius == 0 {
          c = Circle(p, q)
        } else {
          c = Circle(points.subtracting([q]), p, q)
        }
      }

      self = c
    }

    public init(
      _ a: SIMD2<Float>,
      _ b: SIMD2<Float>
    ) {
      let center = (a + b) / 2

      let r0 = Operation.distance(center, a)
      let r1 = Operation.distance(center, b)

      self = Circle(
        center: center,
        radius: max(r0, r1)
      )
    }

    public init(
      _ points: Set<SIMD2<Float>>,
      _ p: SIMD2<Float>,
      _ q: SIMD2<Float>
    ) {
      let circle = Circle(p, q)

      var left: Circle?
      var right: Circle?

      points.forEach { r in
        if circle.contains(r) { return }

        guard
          let circumCircle = Circle(p, q, r)
        else { return }

        let cross = Operation.crossProduct(p, q, r)

        if
          cross > 0,
          (left == nil || Operation.crossProduct(p, q, circumCircle.center) > Operation.crossProduct(p, q, left!.center))
        {
          // find the bigger circumCircle on the left side
          left = circumCircle
        } else if
          cross < 0,
          (right == nil || Operation.crossProduct(p, q, circumCircle.center) < Operation.crossProduct(p, q, right!.center))
        {
          // find the bigger circumCircle on the right side
          right = circumCircle
        }
      }

      if
        left == nil,
        right == nil
      {
        self = circle
      } else if
        left == nil,
        let right
      {
        self = right
      } else if
        let left,
        right == nil
      {
        self = left
      } else if
        let left,
        let right
      {
        self = left.radius <= right.radius ? left : right
      } else {
        fatalError("Assertion error")
      }
    }

    public init?(
      _ a: SIMD2<Float>,
      _ b: SIMD2<Float>,
      _ c: SIMD2<Float>
    ) {
      let ox = (min(a.x, b.x, c.x) + max(a.x, b.x, c.x)) / 2
      let oy = (min(a.y, b.y, c.y) + max(a.y, b.y, c.y)) / 2

      let ax = a.x - ox
      let ay = a.y - oy

      let bx = b.x - ox
      let by = b.y - oy

      let cx = c.x - ox
      let cy = c.y - oy

      let d = (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) * 2

      if d == 0 { return nil }

      let x = ox + ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
      let y = oy + ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d

      let ra = Operation.distance(.init(x, y), a)
      let rb = Operation.distance(.init(x, y), b)
      let rc = Operation.distance(.init(x, y), c)

      self = Circle(
        center: .init(x, y),
        radius: max(ra, rb, rc)
      )
    }
  }

  public struct Triangle: Hashable {
    public var v0: SIMD2<Float>
    public var v1: SIMD2<Float>
    public var v2: SIMD2<Float>

    public init(
      v0: SIMD2<Float>,
      v1: SIMD2<Float>,
      v2: SIMD2<Float>
    ) {
      self.v0 = v0
      self.v1 = v1
      self.v2 = v2
    }

    public var circumcircle: Circle {
      Circle(v0, v1, v2)!
    }

    public var triangleCenter: SIMD2<Float> {
      .init(
        (v0.x + v1.x + v2.x) / 3,
        (v0.y + v1.y + v2.y) / 3
      )
    }

    func isInCircumcircle(_ p: SIMD2<Float>) -> Bool {
      circumcircle.contains(p)
    }

    static func superTriangle(
      points: Set<SIMD2<Float>>
    ) -> Triangle {
      var minX = Float.greatestFiniteMagnitude
      var minY = Float.greatestFiniteMagnitude

      var maxX = -Float.greatestFiniteMagnitude
      var maxY = -Float.greatestFiniteMagnitude

      points.forEach { p in
        minX = min(minX, p.x)
        minY = min(minY, p.y)
        
        maxX = max(maxX, p.x)
        maxY = max(maxY, p.y)
      }

      let dx = maxX - minX
      let dy = maxY - minY

      let v0 = SIMD2<Float>(minX - dx, minY - dy * 3.0)
      let v1 = SIMD2<Float>(minX - dx, maxY + dy)
      let v2 = SIMD2<Float>(maxX + dx * 3.0, maxY + dy)

      return Triangle(v0: v0, v1: v1, v2: v2)
    }
  }
}

extension Set where Element == Primitive.Triangle {
  mutating func insert(_ v0: SIMD2<Float>) {
    var badTriangles = Set<Primitive.Triangle>()
    var polygon = Set<Primitive.Edge2<Float>>()

    // Find all triangles that are no longer valid due to the new vertex
    for triangle in self {
      if triangle.isInCircumcircle(v0) {
        badTriangles.insert(triangle)
      }
    }
    
    // Extract edges from bad triangles
    for triangle in badTriangles {
      let edges = [
        Primitive.Edge2(v0: triangle.v0, v1: triangle.v1),
        Primitive.Edge2(v0: triangle.v1, v1: triangle.v2),
        Primitive.Edge2(v0: triangle.v2, v1: triangle.v0)
      ]
      
      for edge in edges {
        // Check if this edge appears once (non-shared) in all bad triangles
        let isShared = badTriangles.filter { badTriangle in
          badTriangle != triangle && (
            (badTriangle.v0 == edge.v0 && badTriangle.v1 == edge.v1) ||
            (badTriangle.v1 == edge.v0 && badTriangle.v2 == edge.v1) ||
            (badTriangle.v2 == edge.v0 && badTriangle.v0 == edge.v1) ||
            (badTriangle.v0 == edge.v1 && badTriangle.v1 == edge.v0) ||
            (badTriangle.v1 == edge.v1 && badTriangle.v2 == edge.v0) ||
            (badTriangle.v2 == edge.v1 && badTriangle.v0 == edge.v0)
          )
        }.count
        
        if isShared == 0 {
          polygon.insert(edge)
        }
      }
    }
    
    // Remove bad triangles from the triangulation
    var _triangles = self.filter { !badTriangles.contains($0) }
    
    // Re-triangulate the polygon hole
    for edge in polygon {
      _triangles.insert(.init(v0: v0, v1: edge.v0, v2: edge.v1))
    }

    self = _triangles
  }
}
