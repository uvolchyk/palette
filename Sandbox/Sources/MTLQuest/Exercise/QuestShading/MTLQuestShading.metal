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
    BandedLighting = 2,
  };

  enum LightingModel {
    Point = 0,
    Spotlight = 1,
    Directional = 2,
  };

  struct LightingPointData {
    float3 position;
  };

  struct LightingSpotlightData {
    float3 position;
    float3 direction;
    float coneAngle;
  };

  struct LightingDirectionalData {
    float3 direction;
    float3 position;
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

//    // A hack in order to simulate some indirect light and prevent completely black surface when not lit directly
//    float3 ambient = 0.4 * color;

    // Final color of the pixel
    return diffuse;
  }

  float3 shadingBandedLighting(
    float3 normal,
    float3 lightDirection,
    float3 color
  ) {
    float NdotL = max(0.0, dot(normalize(normal), normalize(lightDirection)));

    float steps = 6.0;
    float q = floor(NdotL * steps + 0.5) / steps;
    float3 final = color * (q + 0.4);
    return final;
  }

  float shadePoint(float3 pointLocation, float3 surfaceLocation) {
    float range = 30.0;
    float d = length(surfaceLocation - pointLocation);

    if (d > 30.0) { return 0.0; }

    float intensity = 70;

    float attenuation = intensity / pow(max(d, 0.001), 2);

    float x = 1.0 - d / range;
    float smooth = x * x * (3.0 - 2.0 * x); // smoothstep

    return attenuation * smooth;
  }

  float spotlightFactor(
    float3 lightPos,
    float3 lightDir,
    float3 surfacePos,
    float innerAngle,
    float outerAngle
  ) {
    float3 L = normalize(lightPos - surfacePos);
    float3 D = normalize(lightDir);

    // cos because the dot product is cos
    float cosInner = cos(innerAngle);
    float cosOuter = cos(outerAngle);

    // calculate whether the surface is within the cone
    float theta = dot(L, D);

    // gradual attenuation from 1 in the centre to 0 outside the cone
    // cosInner - cosOuter creates a cool gradient
    return saturate((theta - cosOuter) / (cosInner - cosOuter));
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
    constant int &shadingModel [[buffer(1)]],
    constant int &lightingModel [[buffer(2)]],
    constant void* lightingModelData [[buffer(3)]]
  ) {
    float3 lightDir = float3(1.0);

    float attenuation = 1.0;
    switch (LightingModel(lightingModel)) {
      case Point: {
        const constant LightingPointData* pointData = (const constant LightingPointData*)lightingModelData;
        lightDir = normalize(pointData->position - in.worldPosition);
        attenuation = shadePoint(pointData->position, in.worldPosition);
        break;
      }
      case Spotlight: {
        const constant LightingSpotlightData* spotlightData = (const constant LightingSpotlightData*)lightingModelData;
        lightDir = normalize(spotlightData->direction);
        float angle = spotlightData->coneAngle;
        attenuation = spotlightFactor(spotlightData->position, lightDir, in.worldPosition, angle, angle + 0.05);
        break;
      }
      case Directional: {
        const constant LightingDirectionalData* directionalData = (const constant LightingDirectionalData*)lightingModelData;
        lightDir = directionalData->direction;
        break;
      }
    };

    float3 shade = 0.0;

    switch (ShadingModel(shadingModel)) {
    case Gooch:
      shade = shadingGooch(in.normal, lightDir, lightDir);
      break;

    case LambertianReflection:
      shade = shadingLambertianReflection(in.normal, lightDir, in.color);
      break;

    case BandedLighting:
      shade = shadingBandedLighting(in.normal, lightDir, float3(0.5));
      break;
    };

    return float4(shade * attenuation + in.color * 0.1, 1.0);
  }

  struct GizmoVertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
  };

  struct GizmoInstance {
    float4x4 model;
    float3 color;
  };

  struct GizmoVertexOut {
    float4 position [[position]];
    float4 color;
  };

  // MVP matrix for gizmo is at buffer(2)
  vertex GizmoVertexOut funVertexGizmo(
    GizmoVertexIn in          [[stage_in]],
    constant SceneUniforms &u    [[buffer(1)]],
    constant GizmoInstance *instanceModels [[buffer(2)]],
    uint instanceID                  [[instance_id]]
  ) {
    GizmoInstance instance = instanceModels[instanceID];

    GizmoVertexOut out;

    out.position = u.mvp * instance.model * float4(in.position, 1.0);

    out.color = float4(instance.color, 1.0);

    return out;
  }

  fragment float4 funFragmentGizmo(GizmoVertexOut in [[stage_in]]) {
    return in.color;
  }
}
