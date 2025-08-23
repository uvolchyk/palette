//
//  MTLQuestShadingContainer.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/9/25.
//

import SwiftUI

enum MTLQuestShadingModel: Int, CaseIterable, Identifiable {
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

enum MTLQuestLightingModel {
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
  
  case point(PointData)
  case spotlight(SpotlightData)
  case directional(DirectionalData)

  var position: SIMD3<Float> {
    switch self {
    case .point(let data): data.position
    case .spotlight(let data): data.position
    case .directional(let data): data.position
    }
  }

  var index: Int {
    switch self {
    case .point: 0
    case .spotlight: 1
    case .directional: 2
    }
  }
}

enum MTLQuestLightingModelType: CaseIterable, Identifiable {
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

struct MTLQuestShadingContainer: View {
  @State private var showPanel = false
  
  @State private var yaw: Float = 0
  @State private var pitch: Float = 0
  @State private var head: Float = 0
  
  // New state property to control automatic rotation toggle
  @State private var automaticRotation: Bool = false
  
  @State private var shadingModel: MTLQuestShadingModel = .lambertianReflection
  @State private var lightingModelType: MTLQuestLightingModelType = .point
  @State private var lightingModelData: MTLQuestLightingModel = .point(.init())
  
  let exercise: MTLQuestExercise
  
  var body: some View {
    ZStack(alignment: .bottom) {
      MTLQuestShading(
        exercise: exercise,
        yaw: $yaw,
        pitch: $pitch,
        head: $head,
        automaticRotation: $automaticRotation,
        shadingModel: $shadingModel,
        lightingModelData: $lightingModelData
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
        Picker("Shading Model", selection: $shadingModel) {
          ForEach(MTLQuestShadingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)

        Picker("Lighting Model", selection: $lightingModelType) {
          ForEach(MTLQuestLightingModelType.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .onChange(of: lightingModelType) { _, newType in
          switch newType {
          case .point: lightingModelData = .point(.init())
          case .spotlight: lightingModelData = .spotlight(.init())
          case .directional: lightingModelData = .directional(.init())
          }
        }
        .pickerStyle(.segmented)
        
        switch lightingModelData {
        case .point(let data):
          VStack(alignment: .leading) {
            Text("Point Light Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", data.position.x))")
              Slider(value: Binding(
                get: { data.position.x },
                set: {
                  var newData = data
                  newData.position.x = $0
                  lightingModelData = .point(newData)
                }), in: -30...30, step: 0.1)
              Button(action: {
                var newData = data
                newData.position.x = 2
                lightingModelData = .point(newData)
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", data.position.y))")
              Slider(value: Binding(
                get: { data.position.y },
                set: {
                  var newData = data
                  newData.position.y = $0
                  lightingModelData = .point(newData)
                }), in: -30...30, step: 0.1)
              Button(action: {
                var newData = data
                newData.position.y = 8
                lightingModelData = .point(newData)
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", data.position.z))")
              Slider(value: Binding(
                get: { data.position.z },
                set: {
                  var newData = data
                  newData.position.z = $0
                  lightingModelData = .point(newData)
                }), in: -30...30, step: 0.1)
              Button(action: {
                var newData = data
                newData.position.z = 10
                lightingModelData = .point(newData)
              }, label: { Image(systemName: "arrow.clockwise") })
            }
          }
        case .spotlight(let data):
          VStack(alignment: .leading) {
            Text("Spotlight Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", data.position.x))")
              Slider(value: Binding(
                get: { data.position.x },
                set: {
                  var newData = data
                  newData.position.x = $0
                  lightingModelData = .spotlight(newData)
                }), in: -30...30, step: 0.1)
              Button(action: {
                var newData = data
                newData.position.x = 2
                lightingModelData = .spotlight(newData)
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", data.position.y))")
              Slider(value: Binding(
                get: { data.position.y },
                set: {
                  var newData = data
                  newData.position.y = $0
                  lightingModelData = .spotlight(newData)
                }), in: -30...30, step: 0.1)
              Button(action: {
                var newData = data
                newData.position.y = 8
                lightingModelData = .spotlight(newData)
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", data.position.z))")
              Slider(value: Binding(
                get: { data.position.z },
                set: {
                  var newData = data
                  newData.position.z = $0
                  lightingModelData = .spotlight(newData)
                }), in: -30...30, step: 0.1)
              Button(action: {
                var newData = data
                newData.position.z = 10
                lightingModelData = .spotlight(newData)
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            Divider()
            Text("Direction")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", data.direction.x))")
              Slider(value: Binding(
                get: { data.direction.x },
                set: {
                  var newData = data
                  newData.direction.x = $0
                  lightingModelData = .spotlight(newData)
                }), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", data.direction.y))")
              Slider(value: Binding(
                get: { data.direction.y },
                set: {
                  var newData = data
                  newData.direction.y = $0
                  lightingModelData = .spotlight(newData)
                }), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", data.direction.z))")
              Slider(value: Binding(
                get: { data.direction.z },
                set: {
                  var newData = data
                  newData.direction.z = $0
                  lightingModelData = .spotlight(newData)
                }), in: -1...1, step: 0.01)
            }
            Divider()
            HStack {
              Text("Cone Angle: \(String(format: "%.2f", data.coneAngle))")
              Slider(value: Binding(
                get: { data.coneAngle },
                set: {
                  var newData = data
                  newData.coneAngle = $0
                  lightingModelData = .spotlight(newData)
                }), in: 0...(.pi / 2), step: 0.01)
            }
          }
        case .directional(let data):
          VStack(alignment: .leading) {
            Text("Directional Direction")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", data.direction.x))")
              Slider(value: Binding(
                get: { data.direction.x },
                set: {
                  var newData = data
                  newData.direction.x = $0
                  lightingModelData = .directional(newData)
                }), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", data.direction.y))")
              Slider(value: Binding(
                get: { data.direction.y },
                set: {
                  var newData = data
                  newData.direction.y = $0
                  lightingModelData = .directional(newData)
                }), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", data.direction.z))")
              Slider(value: Binding(
                get: { data.direction.z },
                set: {
                  var newData = data
                  newData.direction.z = $0
                  lightingModelData = .directional(newData)
                }), in: -1...1, step: 0.01)
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

