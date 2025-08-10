import SwiftUI

struct MTLQuestCameraRotationContainer: View {
  @State private var showPanel = false
  @State private var yaw: Float = 0
  @State private var pitch: Float = 0
  @State private var head: Float = 0
  
  let exercise: MTLQuestExercise
  
  var body: some View {
    ZStack(alignment: .bottom) {
      MTLQuestCameraRotation(
        exercise: exercise,
        yaw: yaw,
        pitch: pitch,
        head: head
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
        Text("Camera Controls").font(.headline)
        HStack {
          Text("Yaw (Oy - Green)")
          Slider(value: Binding(get: { yaw }, set: { yaw = $0 }), in: -Float.pi ... Float.pi, step: 0.01)
          Text(String(format: "%.2f", yaw))
        }
        HStack {
          Text("Pitch (Ox - Red)")
          Slider(value: Binding(get: { pitch }, set: { pitch = $0 }), in: -Float.pi/2 ... Float.pi/2, step: 0.01)
          Text(String(format: "%.2f", pitch))
        }
        HStack {
          Text("Head (Oz - Blue)")
          Slider(value: Binding(get: { head }, set: { head = $0 }), in: -Float.pi ... Float.pi, step: 0.01)
          Text(String(format: "%.1f", head))
        }
        Spacer()
      }
      .padding()
      .presentationDetents([.medium, .large])
    }
  }
}
