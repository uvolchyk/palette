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
    var color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
  }

  struct SpotlightData {
    var position: SIMD3<Float> = .init(2, 2, 10)
    var direction: SIMD3<Float> = .init(0.0, 0.0, 1.0)
    var coneAngle: Float = .pi / 16
    var color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
  }

  struct DirectionalData {
    var direction: SIMD3<Float> = .init(0.0, 0.0, 1.0)
    var position: SIMD3<Float> = .zero
    var color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
  }

  var wireframeEnabled: Bool = false

  // Shading
  /**
   TODO:
   - Color selection
   - Control ambient
   - Blinn
   - Phong
   - Cook-Torrance
   - Oren-Nayar
   - Material configuration
   - Texture support (albedo, normal map, specular map)
   - Ramp shading
   - Screen Space Reflections
   - Edge highlighting
   */

  var shadingModel: ShadingModel = .lambertianReflection

  // Lighting
  /**
   TODO:
   - Color selection ✅
   - Control intensity
   - Multiple lighting sources
    - Start from predefined
    - Focus on light accumulation
   - Shadows
   - Area lights (softbox, rectangle)
   */

  var lightingModelType: LightingModel = .point

  var pointData: PointData = .init()
  var spotlightData: SpotlightData = .init()
  var directionalData: DirectionalData = .init()

  // Model
  /**
   TODO:
   - Display base plane ✅
   - Model selection
   - Bounding box
   */

  var rotationData: SIMD3<Float> = .zero
  var translationData: SIMD3<Float> = .zero
  var scaleData: SIMD3<Float> = SIMD3<Float>(repeating: 1)

  // Camera
  /**
   TODO:
   - Control FOV, nearZ / farZ
   - Perspective / orthographic projection
   */

  var cameraEye: SIMD3<Float> = SIMD3<Float>(0.0, 2.0, 3.0)
  var center: SIMD3<Float> = .zero
  var up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)

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
  @State private var automaticRotation: Bool = false

  @State private var aggregation: MTLQuestShadingAggregation = .init()
  
  enum SettingsTab {
    case shading, lighting, transform, camera
  }
  
  @State private var selectedTab: SettingsTab = .shading

  let exercise: MTLQuestExercise
  
  var body: some View {
    VStack(spacing: 0) {
      MTLQuestShading(
        exercise: exercise,
        automaticRotation: $automaticRotation,
        aggregation: aggregation
      )
      .frame(maxHeight: .infinity)
      .layoutPriority(1)
      .border(.red)
      
      VStack(spacing: 24.0) {
        Picker("", selection: $selectedTab) {
          Text("Shading").tag(SettingsTab.shading)
          Text("Lighting").tag(SettingsTab.lighting)
          Text("Transform").tag(SettingsTab.transform)
          Text("Camera").tag(SettingsTab.camera)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        
        TabView(selection: $selectedTab) {
          shadingConfiguration()
            .tag(SettingsTab.shading)
          lightingConfiguration()
            .tag(SettingsTab.lighting)
          transformConfiguration()
            .tag(SettingsTab.transform)
          cameraConfiguration()
            .tag(SettingsTab.camera)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
      .padding()
      .frame(maxHeight: .infinity)
      .layoutPriority(1)
    }
  }

  @ViewBuilder
  private func shadingConfiguration() -> some View {
    ScrollView {
      VStack(spacing: 24) {
        Picker("Shading Model", selection: $aggregation.shadingModel) {
          ForEach(MTLQuestShadingAggregation.ShadingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)
        Toggle("Wireframe", isOn: $aggregation.wireframeEnabled)
        Spacer()
      }
    }
    .scrollIndicators(.never)
  }

  @ViewBuilder
  private func lightingConfiguration() -> some View {
    ScrollView {
      VStack(spacing: 24) {
        Picker("Lighting Model", selection: $aggregation.lightingModelType) {
          ForEach(MTLQuestShadingAggregation.LightingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)

        switch aggregation.lightingModelType {
        case .point:
          VStack(alignment: .leading) {
            Text("Point Light Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", aggregation.pointData.position.x))")
              Slider(
                value: $aggregation.pointData.position.x,
                in: -30...30, step: 0.1
              )
              Button(action: {
                aggregation.pointData.position.x = 2
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", aggregation.pointData.position.y))")
              Slider(value: $aggregation.pointData.position.y, in: -30...30, step: 0.1)
              Button(action: {
                aggregation.pointData.position.y = 8
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", aggregation.pointData.position.z))")
              Slider(value: $aggregation.pointData.position.z, in: -30...30, step: 0.1)
              Button(action: {
                aggregation.pointData.position.z = 10
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            ColorPicker("Light Color", selection: Binding(
              get: { Color(red: Double(aggregation.pointData.color.x), green: Double(aggregation.pointData.color.y), blue: Double(aggregation.pointData.color.z)) },
              set: { color in
                var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                aggregation.pointData.color = SIMD3<Float>(Float(r), Float(g), Float(b))
              })
            )
          }
        case .spotlight:
          VStack(alignment: .leading) {
            Text("Spotlight Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", aggregation.spotlightData.position.x))")
              Slider(value: $aggregation.spotlightData.position.x, in: -30...30, step: 0.1)
              Button(action: {
                aggregation.spotlightData.position.x = 2
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", aggregation.spotlightData.position.y))")
              Slider(value: $aggregation.spotlightData.position.y, in: -30...30, step: 0.1)
              Button(action: {
                aggregation.spotlightData.position.y = 8
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", aggregation.spotlightData.position.z))")
              Slider(value: $aggregation.spotlightData.position.z, in: -30...30, step: 0.1)
              Button(action: {
                aggregation.spotlightData.position.z = 10
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            ColorPicker("Light Color", selection: Binding(
              get: { Color(red: Double(aggregation.spotlightData.color.x), green: Double(aggregation.spotlightData.color.y), blue: Double(aggregation.spotlightData.color.z)) },
              set: { color in
                var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                aggregation.spotlightData.color = SIMD3<Float>(Float(r), Float(g), Float(b))
              })
            )
            Divider()
            Text("Direction")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", aggregation.spotlightData.direction.x))")
              Slider(value: $aggregation.spotlightData.direction.x, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", aggregation.spotlightData.direction.y))")
              Slider(value: $aggregation.spotlightData.direction.y, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", aggregation.spotlightData.direction.z))")
              Slider(value: $aggregation.spotlightData.direction.z, in: -1...1, step: 0.01)
            }
            Divider()
            HStack {
              Text("Cone Angle: \(String(format: "%.2f", aggregation.spotlightData.coneAngle))")
              Slider(value: $aggregation.spotlightData.coneAngle, in: 0...(.pi / 2), step: 0.01)
            }
          }
        case .directional:
          VStack(alignment: .leading) {
            Text("Directional Direction")
              .font(.subheadline)
            ColorPicker("Light Color", selection: Binding(
              get: { Color(red: Double(aggregation.directionalData.color.x), green: Double(aggregation.directionalData.color.y), blue: Double(aggregation.directionalData.color.z)) },
              set: { color in
                var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                aggregation.directionalData.color = SIMD3<Float>(Float(r), Float(g), Float(b))
              })
            )
            HStack {
              Text("X: \(String(format: "%.2f", aggregation.directionalData.direction.x))")
              Slider(value: $aggregation.directionalData.direction.x, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", aggregation.directionalData.direction.y))")
              Slider(value: $aggregation.directionalData.direction.y, in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", aggregation.directionalData.direction.z))")
              Slider(value: $aggregation.directionalData.direction.z, in: -1...1, step: 0.01)
            }
          }
        }
        Spacer()
      }
    }
    .scrollIndicators(.never)
  }

  @ViewBuilder
  private func transformConfiguration() -> some View {
    ScrollView {
      VStack(spacing: 16) {
        VStack(alignment: .leading) {
          Text("Rotation")
            .font(.subheadline)
          HStack {
            Text("Yaw: \(String(format: "%.2f", aggregation.rotationData.x))")
            Slider(value: $aggregation.rotationData.x, in: -Float.pi...Float.pi, step: 0.01)
            Button(action: {
              aggregation.rotationData.x = 0
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          
          HStack {
            Text("Pitch: \(String(format: "%.2f", aggregation.rotationData.y))")
            Slider(value: $aggregation.rotationData.y, in: -Float.pi...Float.pi, step: 0.01)
            Button(action: {
              aggregation.rotationData.y = 0
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          
          HStack {
            Text("Head: \(String(format: "%.2f", aggregation.rotationData.z))")
            Slider(value: $aggregation.rotationData.z, in: -Float.pi...Float.pi, step: 0.01)
            Button(action: {
              aggregation.rotationData.z = 0
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          Spacer()
        }
        VStack(alignment: .leading) {
          Text("Translation")
            .font(.subheadline)
          HStack {
            Text("Translation X: \(String(format: "%.2f", aggregation.translationData.x))")
            Slider(value: $aggregation.translationData.x, in: -50...50, step: 0.01)
            Button(action: {
              aggregation.translationData.x = 0
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          HStack {
            Text("Translation Y: \(String(format: "%.2f", aggregation.translationData.y))")
            Slider(value: $aggregation.translationData.y, in: -50...50, step: 0.01)
            Button(action: {
              aggregation.translationData.y = 0
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          HStack {
            Text("Translation Z: \(String(format: "%.2f", aggregation.translationData.z))")
            Slider(value: $aggregation.translationData.z, in: -50...50, step: 0.01)
            Button(action: {
              aggregation.translationData.z = 0
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          Spacer()
        }
        VStack(alignment: .leading) {
          Text("Scale")
            .font(.subheadline)
          HStack {
            Text("Scale X: \(String(format: "%.2f", aggregation.scaleData.x))")
            Slider(value: $aggregation.scaleData.x, in: 0.1...5, step: 0.01)
            Button(action: {
              aggregation.scaleData.x = 1
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          HStack {
            Text("Scale Y: \(String(format: "%.2f", aggregation.scaleData.y))")
            Slider(value: $aggregation.scaleData.y, in: 0.1...5, step: 0.01)
            Button(action: {
              aggregation.scaleData.y = 1
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          HStack {
            Text("Scale Z: \(String(format: "%.2f", aggregation.scaleData.z))")
            Slider(value: $aggregation.scaleData.z, in: 0.1...5, step: 0.01)
            Button(action: {
              aggregation.scaleData.z = 1
            }, label: { Image(systemName: "arrow.clockwise") })
          }
          Spacer()
        }
      }
      .padding(.vertical)
    }
    .scrollIndicators(.never)
  }
  
  @ViewBuilder
  private func cameraConfiguration() -> some View {
    ScrollView {
      VStack(spacing: 16) {
        Text("Camera")
          .font(.headline)
          .padding(.top)
        
        // Eye
        Text("Eye")
          .font(.subheadline)
        HStack {
          Text("Eye X: \(String(format: "%.2f", aggregation.cameraEye.x))")
          Slider(value: $aggregation.cameraEye.x, in: -5...5, step: 0.01)
          Button(action: {
            aggregation.cameraEye.x = 0
          }, label: { Image(systemName: "arrow.clockwise") })
        }
        HStack {
          Text("Eye Y: \(String(format: "%.2f", aggregation.cameraEye.y))")
          Slider(value: $aggregation.cameraEye.y, in: -5...5, step: 0.01)
          Button(action: {
            aggregation.cameraEye.y = 2
          }, label: { Image(systemName: "arrow.clockwise") })
        }
        HStack {
          Text("Eye Z: \(String(format: "%.2f", aggregation.cameraEye.z))")
          Slider(value: $aggregation.cameraEye.z, in: -5...5, step: 0.01)
          Button(action: {
            aggregation.cameraEye.z = 3.0
          }, label: { Image(systemName: "arrow.clockwise") })
        }

        // Center
        Text("Center")
          .font(.subheadline)
          .padding(.top, 8)
        HStack {
          Text("Center X: \(String(format: "%.2f", aggregation.center.x))")
          Slider(value: $aggregation.center.x, in: -50...50, step: 0.01)
          Button(action: {
            aggregation.center.x = 0
          }, label: { Image(systemName: "arrow.clockwise") })
        }
        HStack {
          Text("Center Y: \(String(format: "%.2f", aggregation.center.y))")
          Slider(value: $aggregation.center.y, in: -50...50, step: 0.01)
          Button(action: {
            aggregation.center.y = 0
          }, label: { Image(systemName: "arrow.clockwise") })
        }
        HStack {
          Text("Center Z: \(String(format: "%.2f", aggregation.center.z))")
          Slider(value: $aggregation.center.z, in: -50...50, step: 0.01)
          Button(action: {
            aggregation.center.z = 0
          }, label: { Image(systemName: "arrow.clockwise") })
        }

        // Up
        Text("Up")
          .font(.subheadline)
          .padding(.top, 8)
        HStack {
          Text("Up X: \(String(format: "%.2f", aggregation.up.x))")
          Slider(value: $aggregation.up.x, in: -1...1, step: 0.01)
          Button(action: {
            aggregation.up.x = 0
          }, label: { Image(systemName: "arrow.clockwise") })
        }
        HStack {
          Text("Up Y: \(String(format: "%.2f", aggregation.up.y))")
          Slider(value: $aggregation.up.y, in: -1...1, step: 0.01)
          Button(action: {
            aggregation.up.y = 1
          }, label: { Image(systemName: "arrow.clockwise") })
        }
        HStack {
          Text("Up Z: \(String(format: "%.2f", aggregation.up.z))")
          Slider(value: $aggregation.up.z, in: -1...1, step: 0.01)
          Button(action: {
            aggregation.up.z = 0
          }, label: { Image(systemName: "arrow.clockwise") })
        }
      }
      .padding(.vertical)
    }
    .scrollIndicators(.never)
  }
}

