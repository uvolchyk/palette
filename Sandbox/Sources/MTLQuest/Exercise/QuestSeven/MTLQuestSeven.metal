//
//  MTLQuestSeven.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/21/25.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

namespace MTLQuestSeven {
  struct SceneUniforms
  {
      float4x4     mvp;
  };

  struct VertexIn {
    float4 position  [[attribute(0)]];
    float3 color  [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]]; // screen pixels
    float3 color;
  };

  [[vertex]] VertexOut funVertex(
    VertexIn in [[stage_in]],
    constant SceneUniforms &uniforms [[buffer(1)]]
  ) {
    return VertexOut {
      .position = uniforms.mvp * in.position,
      .color = in.color,
    };
  }

  [[fragment]] float4 funFragment(
    VertexOut in [[stage_in]]
//    texture2d<float>       spriteTex  [[texture(0)]],
//    sampler samp [[sampler(0)]],
  ) {

    return float4(in.color, 1);
  }
}
