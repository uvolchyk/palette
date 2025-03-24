//
//  DissolveView.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 3/23/25.


import SwiftUI
import MetalKit
import PLTMetal

final class DissolveViewController: UIViewController {
  private lazy var metalView = MTKView()
  private var renderer: DissolveRenderer!

  override func loadView() {
    view = metalView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    renderer = DissolveRenderer(mtkView: metalView)
  }
}

struct DissolveView: UIViewControllerRepresentable {
  func makeUIViewController(
    context: Context
  ) -> some UIViewController {
    DissolveViewController()
  }
  
  func updateUIViewController(
    _ uiViewController: UIViewControllerType,
    context: Context
  ) {}
}

#Preview {
  DissolveView()
}
