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
    case .lambertianReflection: "Lambertian Reflection"
    case .bandedLighting: "Banded Lighting"
    }
  }
}

enum MTLQuestLightingModel: Int, CaseIterable, Identifiable {
  case point
  case spotlight
  case directional

  var id: Self { self }

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
  
  @State private var lightPosition: SIMD3<Float> = .init(2, 8, 10)
  
  // New state property to control automatic rotation toggle
  @State private var automaticRotation: Bool = false
  
  @State private var shadingModel: MTLQuestShadingModel = .lambertianReflection
  @State private var lightingModel: MTLQuestLightingModel = .point
  
  let exercise: MTLQuestExercise
  
  var body: some View {
    ZStack(alignment: .bottom) {
      MTLQuestShading(
        exercise: exercise,
        yaw: $yaw,
        pitch: $pitch,
        head: $head,
        automaticRotation: $automaticRotation,
        lightPosition: $lightPosition,
        shadingModel: $shadingModel,
        lightingModel: $lightingModel
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

        Picker("Lighting Model", selection: $lightingModel) {
          ForEach(MTLQuestLightingModel.allCases) { model in
            Text(model.displayName).tag(model)
          }
        }
        .pickerStyle(.segmented)
        
//        Text("Camera Controls")
//          .font(.headline)
//        
//        // Toggle for automatic rotation
//        Toggle("Automatic Rotation", isOn: $automaticRotation)
//        
//        Group {
//          VStack(alignment: .leading) {
//            HStack {
//              Text("Yaw (Oy - Green): \(String(format: "%.2f", yaw))")
//              Button(
//                action: { yaw = 0 },
//                label: { Image(systemName: "arrow.clockwise") }
//              )
//            }
//            Slider(value: Binding(
//              get: { yaw },
//              set: { yaw = $0 }
//            ), in: -Float.pi ... Float.pi, step: 0.01)
//          }
//          VStack(alignment: .leading) {
//            HStack {
//              Text("Pitch (Ox - Red): \(String(format: "%.2f", pitch))")
//              Button(
//                action: { pitch = 0 },
//                label: { Image(systemName: "arrow.clockwise") }
//              )
//            }
//            Slider(value: Binding(
//              get: { pitch },
//              set: { pitch = $0 }
//            ), in: -Float.pi ... Float.pi, step: 0.01)
//          }
//          VStack(alignment: .leading) {
//            HStack {
//              Text("Head (Oz - Blue): \(String(format: "%.2f", head))")
//              Button(
//                action: { head = 0 },
//                label: {
//                  Image(systemName: "arrow.clockwise")
//                }
//              )
//            }
//            Slider(value: Binding(
//              get: { head },
//              set: { head = $0 }
//            ), in: -Float.pi ... Float.pi, step: 0.01)
//          }
//        }
        
        Text("Light Position (xyz)")
          .font(.subheadline)
        
        VStack(alignment: .leading) {
          HStack {
            Text("X: \(String(format: "%.2f", lightPosition.x))")
            Slider(value: $lightPosition.x, in: -30...30, step: 0.1)
            Button(action: { lightPosition.x = 2 }, label: { Image(systemName: "arrow.clockwise") })
          }
          HStack {
            Text("Y: \(String(format: "%.2f", lightPosition.y))")
            Slider(value: $lightPosition.y, in: -30...30, step: 0.1)
            Button(action: { lightPosition.y = 8 }, label: { Image(systemName: "arrow.clockwise") })
          }
          HStack {
            Text("Z: \(String(format: "%.2f", lightPosition.z))")
            Slider(value: $lightPosition.z, in: -30...30, step: 0.1)
            Button(action: { lightPosition.z = -10 }, label: { Image(systemName: "arrow.clockwise") })
          }
        }
        
        Spacer()
      }
      .padding()
      .presentationDetents([.medium, .large])
    }
  }
}

