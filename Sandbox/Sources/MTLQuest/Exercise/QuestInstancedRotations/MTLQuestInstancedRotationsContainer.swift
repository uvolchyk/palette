//
//  MTLQuestInstancedRotationsContainer.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/3/25.
//

import SwiftUI

struct MTLQuestInstancedRotationsContainer: View {
  @State private var showPanel = false
  
  @State private var yaw: Float = 0
  @State private var pitch: Float = 0
  @State private var head: Float = 0
  
  // New state property to control automatic rotation toggle
  @State private var automaticRotation: Bool = true
  
  let exercise: MTLQuestExercise
  
  var body: some View {
    ZStack(alignment: .bottom) {
      MTLQuestInstancedRotations(
        exercise: exercise,
        yaw: $yaw,
        pitch: $pitch,
        head: $head,
        automaticRotation: $automaticRotation
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
        Text("Camera Controls")
          .font(.headline)
        
        // Toggle for automatic rotation
        Toggle("Automatic Rotation", isOn: $automaticRotation)
        
        Group {
          VStack(alignment: .leading) {
            HStack {
              Text("Yaw (Oy - Green): \(String(format: "%.2f", yaw))")
              Button(
                action: { yaw = 0 },
                label: { Image(systemName: "arrow.clockwise") }
              )
            }
            Slider(value: Binding(
              get: { yaw },
              set: { yaw = $0 }
            ), in: -Float.pi ... Float.pi, step: 0.01)
          }
          VStack(alignment: .leading) {
            HStack {
              Text("Pitch (Ox - Red): \(String(format: "%.2f", pitch))")
              Button(
                action: { pitch = 0 },
                label: { Image(systemName: "arrow.clockwise") }
              )
            }
            Slider(value: Binding(
              get: { pitch },
              set: { pitch = $0 }
            ), in: -Float.pi ... Float.pi, step: 0.01)
          }
          VStack(alignment: .leading) {
            HStack {
              Text("Head (Oz - Blue): \(String(format: "%.2f", head))")
              Button(
                action: { head = 0 },
                label: {
                  Image(systemName: "arrow.clockwise")
                }
              )
            }
            Slider(value: Binding(
              get: { head },
              set: { head = $0 }
            ), in: -Float.pi ... Float.pi, step: 0.01)
          }
        }
        
        Spacer()
      }
      .padding()
      .presentationDetents([.medium, .large])
    }
  }
}

