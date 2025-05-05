//
//  SpatialContainerView.swift
//  Sandbox
//
//  Created by Uladzislau Volchyk on 2/7/25.
//  Copyright © 2025 Star Unicorn. All rights reserved.
//

import UIKit

public final class SpatialContainerView: UIVisualEffectView {
  private lazy var borderLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
    layer.fillColor = UIColor.clear.cgColor
    layer.lineWidth = borderWidth
    return layer
  }()

  private lazy var maskLayer: CAShapeLayer = CAShapeLayer()
  
  public override func layoutSubviews() {
    super.layoutSubviews()

    let path = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: corners,
      cornerRadii: CGSize(
        width: cornerRadius,
        height: cornerRadius
      )
    )

    maskLayer.path = path.cgPath
    borderLayer.path = path.cgPath
  }

  public init(
    cornerRadius: CGFloat = 0,
    corners: UIRectCorner = .allCorners
  ) {
    self.cornerRadius = cornerRadius
    self.corners = corners

    super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    layer.mask = maskLayer
    contentView.layer.addSublayer(borderLayer)
  }

  private let cornerRadius: CGFloat
  private let corners: UIRectCorner
  
  var borderWidth: CGFloat = 1.4 {
    didSet { borderLayer.lineWidth = borderWidth }
  }

  required init?(coder: NSCoder) { nil }
}

#if DEBUG

import SwiftUI

struct SpatialContainerViewRepresentable: UIViewRepresentable {
  func makeUIView(context: Context) -> SpatialContainerView {
    let view = SpatialContainerView(cornerRadius: 30.0)
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }
  
  func updateUIView(_ uiView: SpatialContainerView, context: Context) {}
}

#Preview {
  ZStack {
    Rectangle().fill(.blue.gradient)
      .ignoresSafeArea()
    SpatialContainerViewRepresentable()
      .frame(width: 200.0, height: 100.0)
      .overlay {
        Button {
          
        } label: {
          Text("✨")
            .foregroundStyle(.white)
            .padding(.vertical, 6.0)
            .padding(.horizontal, 12.0)
            .background(.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
        }
      }
  }
}

#endif
