//
//  MTLQuestFive.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 7/15/25.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

namespace MTLQuestFive {
  struct FlipbookUniforms
  {
      float     time;        // seconds, monotonic
      uint      columns;     // e.g. 8
      uint      rows;        // e.g. 4
      float     fps;         // e.g. 12.0f
  };

  struct VertexIn {
    float4 position  [[attribute(0)]];
    float2 uv     [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]]; // screen pixels
    float2 uv;
  };

  [[vertex]] VertexOut funVertex(
    VertexIn in [[stage_in]],
    constant float4x4 &projectionMatrix [[buffer(1)]]
  ) {
    return VertexOut {
      .position = projectionMatrix * in.position,
      .uv = in.uv,
    };
  }

  [[fragment]] float4 funFragment(
    VertexOut in [[stage_in]],
    texture2d<float>       spriteTex  [[texture(0)]],
    sampler samp [[sampler(0)]],
    constant FlipbookUniforms &U      [[buffer(2)]]
  ) {
    uint totalFrames = U.columns * U.rows;
    const float edge = 1.0 / 64.0;
    float2 uv = in.uv;

    return spriteTex.sample(samp, uv);
  }
}
