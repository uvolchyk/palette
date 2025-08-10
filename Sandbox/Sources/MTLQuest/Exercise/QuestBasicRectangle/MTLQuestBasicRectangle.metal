//
//  MTLQuestBasicRectangle.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

#include <metal_stdlib>

using namespace metal;

namespace MTLQuestBasicRectangle {
  struct VertexIn {
    float4 position  [[attribute(0)]];
    float3 color     [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]];
    float3 color;
  };

  [[vertex]] VertexOut funVertex(
    VertexIn in [[stage_in]],
    constant float4x4 &projectionMatrix [[buffer(1)]]
  ) {
    return VertexOut {
      .position = projectionMatrix * in.position,
      .color = in.color,
    };
  }

  [[fragment]] half4 funFragment(
    VertexOut in [[stage_in]],
    constant float &time [[buffer(1)]]
  ) {
    half3 rgb = half3(in.color);

    rgb.r += sin(time);
    rgb.g -= cos(time);

    return half4(rgb, 1.0);
  }
}
