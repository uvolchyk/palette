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

    var metalCompatible: MTLQuestShadingPointLight {
      .init(
        position: position,
        _pad0: .zero,
        color: color,
        intensity: 1.0
      )
    }
  }

  struct SpotlightData {
    var position: SIMD3<Float> = .init(2, 2, 10)
    var direction: SIMD3<Float> = .init(0.0, 0.0, 1.0)
    var coneAngle: Float = .pi / 16
    var color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)

    var metalCompatible: MTLQuestShadingSpotLight {
      .init(
        position: position,
        _pad0: .zero,
        direction: direction,
        cosOuter: coneAngle,
        color: color,
        intensity: 1.0,
        cosInner: coneAngle - 0.1,
        _pad1: (0.0, 0.0, 0.0)
      )
    }
  }

  struct DirectionalData {
    var direction: SIMD3<Float> = .init(0.0, 0.0, 1.0)
    var position: SIMD3<Float> = .zero
    var color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)

    var metalCompatible: MTLQuestShadingDirLight {
      .init(
        direction: direction,
        _pad0: .zero,
        color: color,
        intensity: 1.0
      )
    }
  }

  struct LightingSource {
    var lightingModelType: LightingModel = .point

    var pointData: PointData = .init()
    var spotlightData: SpotlightData = .init()
    var directionalData: DirectionalData = .init()
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
   - Multiple lighting sources ✅
    - Start from predefined ✅
    - Focus on light accumulation ✅
   - Shadows
   - Area lights (softbox, rectangle)
   */

  var lightingSources: [LightingSource] = [
    .init(
      lightingModelType: .point,
      pointData: PointData(
        position: .init(-6, 2, 10),
      )
    ),
    .init(
      lightingModelType: .point,
      pointData: PointData(
        position: .init(6, 2, 10),
      )
    ),
    .init(
      lightingModelType: .point,
      pointData: PointData(
        position: .init(2, 6, 10),
      )
    )
  ]

  var activeLightIndex: Int = 0

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
        Picker("Light #", selection: $aggregation.activeLightIndex) {
          ForEach(0..<aggregation.lightingSources.count, id: \.self) { i in
            Text("Light \(i+1)").tag(i)
          }
        }
        .pickerStyle(.segmented)

        let bindingSource = Binding<MTLQuestShadingAggregation.LightingSource>(
          get: { aggregation.lightingSources[aggregation.activeLightIndex] },
          set: { aggregation.lightingSources[aggregation.activeLightIndex] = $0 }
        )

        Picker("Lighting Model", selection: Binding(
          get: { bindingSource.wrappedValue.lightingModelType },
          set: { newValue in
            var source = bindingSource.wrappedValue
            source.lightingModelType = newValue
            bindingSource.wrappedValue = source
          })) {
          ForEach(MTLQuestShadingAggregation.LightingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)

        switch bindingSource.wrappedValue.lightingModelType {
        case .point:
          VStack(alignment: .leading) {
            Text("Point Light Position")
              .font(.subheadline)

            HStack {
              Text("X: \(String(format: "%.2f", bindingSource.wrappedValue.pointData.position.x))")
              Slider(
                value: Binding(
                  get: { bindingSource.wrappedValue.pointData.position.x },
                  set: { newVal in
                    var source = bindingSource.wrappedValue
                    source.pointData.position.x = newVal
                    bindingSource.wrappedValue = source
                  }
                ),
                in: -30...30, step: 0.1
              )
              Button(action: {
                var source = bindingSource.wrappedValue
                source.pointData.position.x = 2
                bindingSource.wrappedValue = source
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", bindingSource.wrappedValue.pointData.position.y))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.pointData.position.y },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.pointData.position.y = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -30...30, step: 0.1)
              Button(action: {
                var source = bindingSource.wrappedValue
                source.pointData.position.y = 8
                bindingSource.wrappedValue = source
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", bindingSource.wrappedValue.pointData.position.z))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.pointData.position.z },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.pointData.position.z = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -30...30, step: 0.1)
              Button(action: {
                var source = bindingSource.wrappedValue
                source.pointData.position.z = 10
                bindingSource.wrappedValue = source
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            ColorPicker("Light Color", selection: Binding(
              get: {
                let c = bindingSource.wrappedValue.pointData.color
                return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
              },
              set: { color in
                var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                var source = bindingSource.wrappedValue
                source.pointData.color = SIMD3<Float>(Float(r), Float(g), Float(b))
                bindingSource.wrappedValue = source
              })
            )
          }
        case .spotlight:
          VStack(alignment: .leading) {
            Text("Spotlight Position")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.position.x))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.position.x },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.position.x = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -30...30, step: 0.1)
              Button(action: {
                var source = bindingSource.wrappedValue
                source.spotlightData.position.x = 2
                bindingSource.wrappedValue = source
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Y: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.position.y))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.position.y },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.position.y = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -30...30, step: 0.1)
              Button(action: {
                var source = bindingSource.wrappedValue
                source.spotlightData.position.y = 8
                bindingSource.wrappedValue = source
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            HStack {
              Text("Z: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.position.z))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.position.z },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.position.z = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -30...30, step: 0.1)
              Button(action: {
                var source = bindingSource.wrappedValue
                source.spotlightData.position.z = 10
                bindingSource.wrappedValue = source
              }, label: { Image(systemName: "arrow.clockwise") })
            }
            ColorPicker("Light Color", selection: Binding(
              get: {
                let c = bindingSource.wrappedValue.spotlightData.color
                return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
              },
              set: { color in
                var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                var source = bindingSource.wrappedValue
                source.spotlightData.color = SIMD3<Float>(Float(r), Float(g), Float(b))
                bindingSource.wrappedValue = source
              })
            )
            Divider()
            Text("Direction")
              .font(.subheadline)
            HStack {
              Text("X: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.direction.x))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.direction.x },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.direction.x = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.direction.y))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.direction.y },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.direction.y = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.direction.z))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.direction.z },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.direction.z = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -1...1, step: 0.01)
            }
            Divider()
            HStack {
              Text("Cone Angle: \(String(format: "%.2f", bindingSource.wrappedValue.spotlightData.coneAngle))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.spotlightData.coneAngle },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.spotlightData.coneAngle = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: 0...(.pi / 2), step: 0.01)
            }
          }
        case .directional:
          VStack(alignment: .leading) {
            Text("Directional Direction")
              .font(.subheadline)
            ColorPicker("Light Color", selection: Binding(
              get: {
                let c = bindingSource.wrappedValue.directionalData.color
                return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
              },
              set: { color in
                var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
                UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
                var source = bindingSource.wrappedValue
                source.directionalData.color = SIMD3<Float>(Float(r), Float(g), Float(b))
                bindingSource.wrappedValue = source
              })
            )
            HStack {
              Text("X: \(String(format: "%.2f", bindingSource.wrappedValue.directionalData.direction.x))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.directionalData.direction.x },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.directionalData.direction.x = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Y: \(String(format: "%.2f", bindingSource.wrappedValue.directionalData.direction.y))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.directionalData.direction.y },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.directionalData.direction.y = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -1...1, step: 0.01)
            }
            HStack {
              Text("Z: \(String(format: "%.2f", bindingSource.wrappedValue.directionalData.direction.z))")
              Slider(value: Binding(
                get: { bindingSource.wrappedValue.directionalData.direction.z },
                set: { newVal in
                  var source = bindingSource.wrappedValue
                  source.directionalData.direction.z = newVal
                  bindingSource.wrappedValue = source
                }
              ), in: -1...1, step: 0.01)
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

