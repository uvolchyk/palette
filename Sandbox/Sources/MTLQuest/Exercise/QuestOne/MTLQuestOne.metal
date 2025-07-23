//
//  MTLQuestOne.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/13/25.
//

#include <metal_stdlib>

using namespace metal;

namespace MTLQuestOne {
  struct VertexIn {
    float4 position  [[attribute(0)]];
    float3 color     [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]];
    float3 color;
  };

  [[vertex]] VertexOut triVertex(
    VertexIn in [[stage_in]],
    constant float4x4 &projectionMatrix [[buffer(1)]]
  ) {
    return VertexOut {
      .position = projectionMatrix * in.position,
      .color = in.color,
    };
  }

  [[fragment]] half4 triFragment(
    VertexOut in [[stage_in]]
  ) {
    return half4(half3(in.color), 1.0);
  }
}
