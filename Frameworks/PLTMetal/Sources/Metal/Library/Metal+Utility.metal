//
//  Metal+Utility.metal
//  PLTMetal
//
//  Created by Uladzislau Volchyk on 3/23/25.
//

#include <metal_stdlib>
using namespace metal;

float rand(float2 n) {
  return fract(sin(dot(n, n)) * length(n));
}

float dissolveNoise(float2 n) {
  const float2 d = float2(0.0, 1.0);

  float2 b = floor(n);
  float2 f = smoothstep(float2(0.0), float2(1.0), fract(n));

  return mix(
    mix(rand(b),           rand(b + d.yx), f.x),
    mix(rand(b + d.xy),    rand(b + d.yy), f.x),
    f.y
  );
}
