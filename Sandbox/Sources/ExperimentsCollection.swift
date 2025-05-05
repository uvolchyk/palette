//
//  ExperimentsCollection.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 3/23/25.
//

import SwiftUI

struct ExperimentsCollection: View {
  var body: some View {
    NavigationView {
      List {
        NavigationLink(
          "Delaunay Triangulation",
          destination: DelaunayTriangulationView()
        )
        NavigationLink(
          "Dissolve",
          destination: {
            DissolveView()
              .ignoresSafeArea()
          }
        )
        NavigationLink(
          "Convex Hull",
          destination: ConvexHullView()
        )
        NavigationLink(
          "Harmonic Button",
          destination: HarmonicButtonContainerView()
        )
      }
      .navigationTitle("Examples")
    }
  }
}
