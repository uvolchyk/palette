//
//  MTLQuestShadingContainer.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/9/25.
//

import SwiftUI

@Observable
final class MTLQuestShadingAggregation {
  enum ShadingModel: Int, CaseIterable, Identifiable {
    case gooch = 0
    case lambertianReflection
    case bandedLighting
    
    var id: Self { self }
    
    var displayName: String {
      switch self {
      case .gooch: "Gooch"
      case .lambertianReflection: "Lambert"
      case .bandedLighting: "Banded"
      }
    }
  }

  enum LightingModel: CaseIterable, Identifiable {
    case point
    case spotlight
    case directional

    var id: String { displayName }

    var displayName: String {
      switch self {
      case .point: "Point"
      case .spotlight: "Spotlight"
      case .directional: "Directional"
      }
    }
  }

  struct PointData {
    var position: SIMD3<Float> = .init(2, 2, 10)
  }

  struct SpotlightData {
    var position: SIMD3<Float> = .init(2, 2, 10)
    var direction: SIMD3<Float> = .init(0.0, 0.0, 1.0)
    var coneAngle: Float = .pi / 16
  }

  struct DirectionalData {
    var direction: SIMD3<Float> = .init(0.0, 0.0, 1.0)
    var position: SIMD3<Float> = .zero
  }

  var shadingModel: ShadingModel = .lambertianReflection
  var lightingModelType: LightingModel = .point

  var pointData: PointData = .init()
  var spotlightData: SpotlightData = .init()
  var directionalData: DirectionalData = .init()

  var position: SIMD3<Float> {
    switch lightingModelType {
    case .point: pointData.position
    case .spotlight: spotlightData.position
    case .directional: directionalData.position
    }
  }

  var index: Int {
    switch lightingModelType {
    case .point: 0
    case .spotlight: 1
    case .directional: 2
    }
  }
}

struct MTLQuestShadingContainer: View {
  @State private var showPanel = false
  
  @State private var yaw: Float = 0
  @State private var pitch: Float = 0
  @State private var head: Float = 0
  
  // New state property to control automatic rotation toggle
  @State private var automaticRotation: Bool = false

  @State private var lightingAggregation: MTLQuestShadingAggregation = .init()

  let exercise: MTLQuestExercise
  
  var body: some View {
    ZStack(alignment: .bottom) {
      MTLQuestShading(
        exercise: exercise,
        yaw: $yaw,
        pitch: $pitch,
        head: $head,
        automaticRotation: $automaticRotation,
        lightingAggregation: lightingAggregation
      )
      .edgesIgnoringSafeArea(.all)
      
      Button {
        showPanel.toggle()
      } label: {
        Label("Camera Controls", systemImage: "camera.viewfinder")
          .padding(.horizontal)
          .padding(.vertical, 8)
          .background(.thinMaterial, in: Capsule())
      }
      .padding(.bottom, 16)
    }
    .sheet(isPresented: $showPanel) {
      VStack(spacing: 24.0) {
        Picker("Shading Model", selection: $lightingAggregation.shadingModel) {
          ForEach(MTLQuestShadingAggregation.ShadingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)

        Picker("Lighting Model", selection: $lightingAggregation.lightingModelType) {
          ForEach(MTLQuestShadingAggregation.LightingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)

        switch lightingAggregation.lightingModelType {
        case .point:
          VStack(alignment: .leading) {
            Text("Point Light Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", lightingAggregation.pointData.position.x))")
              Slider(
                value: $lightingAggregation.pointData.position.x,
                in: -30...30, step: 0.1
              )
              Button(action: {
                lightingAggregation.pointData.position.x = 2
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", lightingAggregation.pointData.position.y))")
              Slider(value: $lightingAggregation.pointData.position.y, in: -30...30, step: 0.1)
              Button(action: {
                lightingAggregation.pointData.position.y = 8
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", lightingAggregation.pointData.position.z))")
              Slider(value: $lightingAggregation.pointData.position.z, in: -30...30, step: 0.1)
              Button(action: {
                lightingAggregation.pointData.position.z = 10
              }, label: { Image(systemName: "arrow.clockwise") })
            }
          }
        case .spotlight:
          VStack(alignment: .leading) {
            Text("Spotlight Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", lightingAggregation.spotlightData.position.x))")
              Slider(value: $lightingAggregation.spotlightData.position.x, in: -30...30, step: 0.1)
              Button(action: {
                lightingAggregation.spotlightData.position.x = 2
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", lightingAggregation.spotlightData.position.y))")
              Slider(value: $lightingAggregation.spotlightData.position.y, in: -30...30, step: 0.1)
              Button(action: {
                lightingAggregation.spotlightData.position.y = 8
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", lightingAggregation.spotlightData.position.z))")
              Slider(value: $lightingAggregation.spotlightData.position.z, in: -30...30, step: 0.1)
              Button(action: {
                lightingAggregation.spotlightData.position.z = 10
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            Divider()
            Text("Direction")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", lightingAggregation.spotlightData.direction.x))")
              Slider(value: $lightingAggregation.spotlightData.direction.x, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", lightingAggregation.spotlightData.direction.y))")
              Slider(value: $lightingAggregation.spotlightData.direction.y, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", lightingAggregation.spotlightData.direction.z))")
              Slider(value: $lightingAggregation.spotlightData.direction.z, in: -1...1, step: 0.01)
            }
            Divider()
            HStack {
              Text("Cone Angle: \(String(format: "%.2f", lightingAggregation.spotlightData.coneAngle))")
              Slider(value: $lightingAggregation.spotlightData.coneAngle, in: 0...(.pi / 2), step: 0.01)
            }
          }
        case .directional:
          VStack(alignment: .leading) {
            Text("Directional Direction")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", lightingAggregation.directionalData.direction.x))")
              Slider(value: $lightingAggregation.directionalData.direction.x, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", lightingAggregation.directionalData.direction.y))")
              Slider(value: $lightingAggregation.directionalData.direction.y, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", lightingAggregation.directionalData.direction.z))")
              Slider(value: $lightingAggregation.directionalData.direction.z, in: -1...1, step: 0.01)
            }
          }
        }
        Spacer()
      }
      .padding()
      .presentationDetents([.medium, .large])
    }
  }
}

