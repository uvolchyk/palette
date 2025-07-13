//
//  DissolveShader.metal
//  PLTMetal
//
//  Created by Uladzislau Volchyk on 3/23/25.
//

#include <metal_stdlib>
using namespace metal;

float dissolveNoise(float2 n);

namespace DissolveShader {
  struct VertexOut {
    float4 position [[position]];
    float  progress;
    float4 color;
  };

  vertex VertexOut vertexShader(
    uint vertexID [[vertex_id]],
    constant float* vertices [[buffer(0)]]
  ) {
    VertexOut out;

    out.position = float4(
      vertices[vertexID * 9],
      vertices[vertexID * 9 + 1],
      vertices[vertexID * 9 + 2],
      vertices[vertexID * 9 + 3]
    );

    out.progress = vertices[vertexID * 9 + 4];

    out.color = float4(
      vertices[vertexID * 9 + 5],
      vertices[vertexID * 9 + 6],
      vertices[vertexID * 9 + 7],
      vertices[vertexID * 9 + 8]
    );

    return out;
  }

  fragment float4 fragmentShader(
    VertexOut in [[stage_in]],
    constant float &visibilityThreshold [[buffer(1)]]
  ) {
    float2 uv = in.position.xy;

    float _delayedAge = visibilityThreshold - in.progress;

    float _noise = dissolveNoise(uv * 0.1);
    float _alpha = step(_delayedAge, _noise);

    return float4(in.color.rgb, _alpha);
  }
}
