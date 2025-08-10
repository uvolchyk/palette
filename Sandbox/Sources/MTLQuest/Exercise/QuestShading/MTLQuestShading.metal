//
//  MTLQuestShading.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/9/25.
//

#include <metal_stdlib>
using namespace metal;

namespace MTLQuestShading {
  enum ShadingModel {
    Gooch = 0,
    LambertianReflection = 1,
  };

  float3 shadingGooch(float3 normal, float3 lightDirection, float3 eyeDirection) {
    float NdotL = dot(normalize(normal), lightDirection);

    float t = (NdotL + 1.0) / 2.0;
    float3 reflection = 2 * NdotL * normal - lightDirection;
    float s = max(100.0 * dot(reflection, eyeDirection) - 97.0, 0.0);

    float3 highlight = float3(1.0);
    float3 warm = float3(1.0, 0.0, 0.0);
    float3 cool = float3(0.0, 0.0, 1.0);

    return s * highlight + (1 - s) * (t * warm + (1 - t) * cool);
  }

  float3 shadingLambertianReflection(
    float3 normal,
    float3 lightDirection,
    float3 color
  ) {
    // Lambertian Reflection
    // The dot product measures how much the surface "faces" the light
    // - 0deg corresponds to a full brightness (dot = 1)
    // - 90deg - no brightness (dot = 0)
    // - 0...90deg - some degree of brightness
    // - >90deg - clamping it to zero, no negative light
    float diff = max(dot(normalize(normal), lightDirection), 0.0);

    // Diffusing the color
    float3 diffuse = color * diff;

    // A hack in order to simulate some indirect light and prevent completely black surface when not lit directly
    float3 ambient = 0.4 * color;

    // Final color of the pixel
    return diffuse + ambient;
  }

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
    VertexIn in                      [[stage_in]],
    constant SceneUniforms &u        [[buffer(1)]],
    constant float4x4 *instanceModels [[buffer(2)]],
    uint instanceID                  [[instance_id]]
  ) {
    VertexOut out;

    // Fetch the per-instance model matrix
    float4x4 model = instanceModels[instanceID];

    // Place the vertex correctly in clip space, applying the instance model matrix and the MVP projection/view matrix
    out.position = u.mvp * model * float4(in.position, 1.0);

    // Transform the normal by the instance model matrix to account for instance-specific transformations
    out.normal = (model * float4(in.normal, 0.0)).xyz;

    // Any color actually, putting normals here gives the normal rainbow effect
    out.color = out.normal;

    // Separate world position is needed in the following light direction calculations
    out.worldPosition = (model * float4(in.position, 1.0)).xyz;

    return out;
  }

  fragment float4 funFragment(
    VertexOut in [[stage_in]],
    constant float3 &lightPosition [[buffer(1)]],
    constant int &shadingModel [[buffer(2)]]
  )
  {
    float3 lightDir = normalize(lightPosition - in.worldPosition);

    switch (ShadingModel(shadingModel)) {
    case Gooch:
      return float4(shadingGooch(in.normal, lightDir, lightDir), 1.0);
    case LambertianReflection:
      return float4(shadingLambertianReflection(in.normal, lightDir, in.color), 1.0);
    };
  }

  struct GizmoVertexIn {
    float3 position [[attribute(0)]];
    float3 color    [[attribute(1)]];
  };

  struct GizmoVertexOut {
    float4 position [[position]];
    float4 color;
  };

  // MVP matrix for gizmo is at buffer(2)
  vertex GizmoVertexOut gizmo_vertex(
    GizmoVertexIn in          [[stage_in]],
    constant SceneUniforms &u    [[buffer(2)]]
  ) {
    GizmoVertexOut out;
    out.position = u.mvp * float4(in.position, 1.0);
    out.color = float4(in.color, 1.0);
    return out;
  }

  fragment float4 gizmo_fragment(GizmoVertexOut in [[stage_in]]) {
    return in.color;
  }
}

