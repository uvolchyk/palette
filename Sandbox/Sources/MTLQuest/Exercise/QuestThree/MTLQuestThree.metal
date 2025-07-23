//
//  MTLQuestThree.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/14/25.
//

#include <metal_stdlib>

using namespace metal;

namespace MTLQuestThree {
  struct VertexIn {
    float4 position  [[attribute(0)]];
    float3 bary      [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]];
    float3 bary;
  };

  [[vertex]] VertexOut funVertex(
    VertexIn in [[stage_in]],
    constant float4x4 &projectionMatrix [[buffer(1)]]
  ) {
    return VertexOut {
      .position = projectionMatrix * in.position,
      .bary = in.bary,
    };
  }

  [[fragment]] half4 funFragment(
    VertexOut in [[stage_in]],
    constant float &time [[buffer(1)]]
  ) {
    // distance from the nearest edge in barycentric space
    float d = min(min(in.bary.x, in.bary.y), in.bary.z);

    // convert 'pxThickness' (1-2 px typical) into barycentric units
    float aa     = fwidth(d);                  // derivative gives 1-pixel span
    float edge   = smoothstep(2.0 * aa, 0.0, d);

    // edge == 1 on edges, 0 in interior — invert for blending
    float interior = 1.0 - edge;

    // choose one of two looks:
    //  A) overlay only wires      -> return float4(wireColor.rgb, edge);
    //  B) solid surface + wires   -> mix fill & wire like this:
    float3 fill = float3(0.0);       // whatever your material is
    float3 finalRgb = mix(float3(1.0), fill, interior);
    return half4(half3(finalRgb), 1);
  }
}
