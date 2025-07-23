//
//  MTLQuestFour.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/15/25.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

namespace MTLQuestFour {
  struct VertexIn {
    float4 position  [[attribute(0)]];
    float3 color     [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]]; // screen pixels
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
    VertexOut in [[stage_in]]
  ) {
    // quantisation
    // 100 pixels per quant
    const float edge = 100.0;

    float2 uv = floor(in.position.xy / edge);

    // odd-even mask
    float mask = fmod(uv.x + uv.y, 2.0);

    return half4(half3(1.0, 0.0, 0.5) * mask, 1.0);
  }
}
