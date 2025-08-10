#include <metal_stdlib>
using namespace metal;

namespace MTLQuestModelLoading {
  struct SceneUniforms {
    float4x4 mvp;
    float4x4 model;
  };

  struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
  };

  struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 color;
    float3 worldPosition;
  };

  vertex VertexOut funVertex(
    VertexIn in                [[stage_in]],
    constant SceneUniforms &u  [[buffer(1)]]
  ) {
    VertexOut out;

    // Place the vertex correctly in the 3D space (clip space) - (considering all the manipulations/transformations in the MVP matrix)
    out.position = u.mvp * float4(in.position, 1.0);

    // The model itself may have some transformations which might break the original normals so they also should be transformed
    out.normal = (u.model * float4(in.normal, 0.0)).xyz;

    // Any color actually, putting normals here gives the normal rainbow effect
    out.color = out.normal;

    // Separate world position is needed in the following light direction calculations
    out.worldPosition = (u.model * float4(in.position, 1.0)).xyz;

    return out;
  }

  fragment float4 funFragment(VertexOut in [[stage_in]])
  {
    // Actually should be passed through the buffer, hardcoded for simplicity
    float3 lightPosition = float3(2.0, 8.0, -10.0);

    // Direction vector of the light
    float3 lightDir = normalize(lightPosition - in.worldPosition);

    // Lambertian Reflection
    // The dot product measures how much the surface "faces" the light
    // - 0deg corresponds to a full brightness (dot = 1)
    // - 90deg - no brightness (dot = 0)
    // - 0...90deg - some degree of brightness
    // - >90deg - clamping it to zero, no negative light
    float diff = max(dot(normalize(in.normal), lightDir), 0.0);

    // Diffusing the color
    float3 diffuse = in.color * diff;

    // A hack in order to simulate some indirect light and prevent completely black surface when not lit directly
    float3 ambient = 0.4 * in.color;

    // Final color of the pixel
    return float4(diffuse + ambient, 1.0);
  }
}
