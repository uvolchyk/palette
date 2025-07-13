#ifndef QUAD_H
#define QUAD_H

#include <metal_stdlib>
using namespace metal;

namespace Global {
  struct QuadVertexIn {
    float2 position  [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
  };

  struct QuadVertexOut {
    float4 position [[position]];
    float2 texCoord;
  };

  [[vertex]] QuadVertexOut quadVertex(
    QuadVertexIn in [[stage_in]],
    constant float4x4 &projectionMatrix [[buffer(1)]]
  ) {
    return QuadVertexOut {
      .position = projectionMatrix * float4(in.position, 0, 1),
      .texCoord = in.texCoord
    };
  }

  [[fragment]] half4 quadFragment(
    QuadVertexOut in [[stage_in]],
    texture2d<half> tex [[texture(0)]],
    sampler s [[sampler(0)]]
  ) {
    return tex.sample(s, in.texCoord);               // plain, un-lit texture
  }
}

#endif
