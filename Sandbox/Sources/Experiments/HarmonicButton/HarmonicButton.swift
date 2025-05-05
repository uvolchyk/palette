//
//  HarmonicButton.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 4/27/25.
//

import SwiftUI

struct HarmonicButton: View {
  var body: some View {
    Button(
      action: {},
      label: {}
    )
    .frame(width: 240.0, height: 70.0)
    .buttonStyle(HarmonicStyle())
  }
}

struct HarmonicStyle: ButtonStyle {
  @State private var scale: CGFloat = 1.0

  @State private var speedMultiplier: Double = 1.0
  @State private var amplitude: Float = 0.5

  @State private var elapsedTime: Double = 0.0
  private let updateInterval: Double = 0.016
  
  func makeBody(configuration: Configuration) -> some View {
    TimelineView(.periodic(from: .now, by: updateInterval / speedMultiplier)) { context in
      configuration.label
        .spatialWrap(Capsule(), lineWidth: 1.0)
        .background {
          Rectangle()
            .colorEffect(ShaderLibrary.default.harmonicColorEffect(
              .boundingRect, // bounding rect
              .float(6), // waves count,
              .float(elapsedTime), // animation clock
              .float(amplitude), // amplitude
              .float(configuration.isPressed ? 1.0 : 0.0) // monochrome coeff
            ))
        }
        .clipShape(Capsule())
        .scaleEffect(scale)
        .onChange(of: context.date) { _, _ in
          elapsedTime += updateInterval * speedMultiplier
        }
    }
    .onChange(of: configuration.isPressed) { _, newValue in
      withAnimation(.spring(duration: 0.3)) {
        amplitude = newValue ? 2.0 : 0.5
        speedMultiplier = newValue ? 2.0 : 1.0
        scale = newValue ? 0.95 : 1.0
      }
    }
    .sensoryFeedback(.impact, trigger: configuration.isPressed)
  }
}

extension View {
  @ViewBuilder
  func spatialWrap(
    _ shape: some InsettableShape,
    lineWidth: CGFloat
  ) -> some View {
    self
      .background {
        shape
          .strokeBorder(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: .white.opacity(0.4), location: 0.0),
                .init(color: .white.opacity(0.0), location: 0.4),
                .init(color: .white.opacity(0.0), location: 0.6),
                .init(color: .white.opacity(0.1), location: 1.0),
              ]),
              startPoint: .init(x: 0.16, y: -0.4),
              endPoint: .init(x: 0.2, y: 1.5)
            ),
            style: .init(lineWidth: lineWidth)
          )
      }
  }
}

struct HarmonicButtonContainerView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      HarmonicButton()
    }
  }
}
