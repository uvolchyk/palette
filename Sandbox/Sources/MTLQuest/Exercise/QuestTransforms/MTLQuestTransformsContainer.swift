//
//  MTLQuestTransformsContainer.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/31/25.
//

import SwiftUI

struct MTLQuestTransformsContainer: View {
  @State private var showPanel = false
  
  @State private var yaw0: Float = 0
  @State private var pitch0: Float = 0
  @State private var head0: Float = 0
  
  @State private var yaw1: Float = 0
  @State private var pitch1: Float = 0
  @State private var head1: Float = 0
  
  @State private var position: Int = 0
  @State private var useQuaternion: Bool = true
  
  let exercise: MTLQuestExercise
  
  var body: some View {
    ZStack(alignment: .bottom) {
      MTLQuestTransforms(
        exercise: exercise,
        yaw0: $yaw0,
        pitch0: $pitch0,
        head0: $head0,
        yaw1: $yaw1,
        pitch1: $pitch1,
        head1: $head1,
        position: $position,
        useQuaternion: $useQuaternion,
        animationDuration: 0.5
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
      VStack(spacing: 24) {
        Text("Camera Controls")
          .font(.headline)

        HStack {
          Text("Method")
          Picker(
            selection: $useQuaternion,
            content: {
              Text("Euler")
                .tag(false)
              Text("Quaternion")
                .tag(true)
            },
            label: {
              Text("Rotation Method")
            }
          )
          .pickerStyle(.segmented)
        }
        
        HStack {
          Text("Position")
          Picker(
            selection: $position,
            content: {
              Text("1").tag(0)
              Text("2").tag(1)
            },
            label: {
              Text("Position")
            }
          )
          .pickerStyle(.segmented)
        }
        
        Group {
          HStack {
            Text("Yaw (Oy - Green) [Pos \(position + 1)]")
            Slider(value: Binding(
              get: {
                position == 0 ? yaw0 : yaw1
              },
              set: {
                if position == 0 {
                  yaw0 = $0
                } else {
                  yaw1 = $0
                }
              }
            ), in: -Float.pi ... Float.pi, step: 0.01)
            Text(String(format: "%.2f", position == 0 ? yaw0 : yaw1))
          }
          HStack {
            Text("Pitch (Ox - Red) [Pos \(position + 1)]")
            Slider(value: Binding(
              get: {
                position == 0 ? pitch0 : pitch1
              },
              set: {
                if position == 0 {
                  pitch0 = $0
                } else {
                  pitch1 = $0
                }
              }
            ), in: -Float.pi ... Float.pi, step: 0.01)
            Text(String(format: "%.2f", position == 0 ? pitch0 : pitch1))
          }
          HStack {
            Text("Head (Oz - Blue) [Pos \(position + 1)]")
            Slider(value: Binding(
              get: {
                position == 0 ? head0 : head1
              },
              set: {
                if position == 0 {
                  head0 = $0
                } else {
                  head1 = $0
                }
              }
            ), in: -Float.pi ... Float.pi, step: 0.01)
            Text(String(format: "%.2f", position == 0 ? head0 : head1))
          }
        }
        
        Spacer()
      }
      .padding()
      .presentationDetents([.medium, .large])
    }
  }
}

