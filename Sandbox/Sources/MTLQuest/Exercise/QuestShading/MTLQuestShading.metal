//
//  MTLQuestShading.metal
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/9/25.
//

#include <metal_stdlib>
#include "MTLSharedTypes.h"

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
    float3 color;
  };

  struct LightingSpotlightData {
    float3 position;
    float3 direction;
    float coneAngle;
    float3 color;
  };

  struct LightingDirectionalData {
    float3 direction;
    float3 position;
    float3 color;
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
    constant MTLQuestShadingLightingCounts &lightingCounts [[buffer(2)]],
    constant MTLQuestShadingPointLight *pointLights [[buffer(3)]],
    constant MTLQuestShadingSpotLight *spotLights [[buffer(4)]],
    constant MTLQuestShadingDirLight *dirLights [[buffer(5)]]
  ) {
    float3 totalShaded = float3(0.0);

    auto evalShading = [&](float3 N, float3 L, float3 baseColor) -> float3 {
      switch (ShadingModel(shadingModel)) {
        case Gooch:
          return shadingGooch(N, normalize(L), normalize(-L));
        case LambertianReflection:
          return shadingLambertianReflection(N, normalize(L), baseColor);
        case BandedLighting:
          return shadingBandedLighting(N, normalize(L), baseColor);
      }
      return float3(0.0);
    };

    // Point lights
    for (uint32_t i = 0; i < lightingCounts.pointCount; i++) {
      const MTLQuestShadingPointLight pl = pointLights[i];

      float3 L = normalize(pl.position - in.worldPosition);
      float att = shadePoint(pl.position, in.worldPosition);

      // Shade with chosen model
      float3 shaded = evalShading(in.normal, L, in.color);

      // Accumulate modulated by attenuation and color
      totalShaded += shaded * att * pl.color;
    }

    // Spot lights
    auto spotlightConeFactor = [&](float3 lightPos, float3 lightDir, float3 surfacePos, float cosInner, float cosOuter) -> float {
      float3 Lvec = normalize(lightPos - surfacePos);    // from surface to light
      float3 D    = normalize(lightDir);                 // light’s pointing direction
      float theta = dot(Lvec, D);                        // compare with cone axis

      return saturate((theta - cosOuter) / max(1e-4, (cosInner - cosOuter)));
    };

    for (uint32_t i = 0; i < lightingCounts.spotCount; i++) {
      const MTLQuestShadingSpotLight sl = spotLights[i];

      float3 L = normalize(sl.position - in.worldPosition);

      // Distance attenuation similar to point light
      float distAtt = shadePoint(sl.position, in.worldPosition);

      // Cone factor using stored cosines
      float cone = spotlightConeFactor(sl.position, sl.direction, in.worldPosition, sl.cosInner, sl.cosOuter);

      // Distance factor * cone factor * base light source intensity factor
      float att = distAtt * cone * sl.intensity;

      // Shade with chosen model
      float3 shaded = evalShading(in.normal, L, in.color);

      // Accumulate modulated by attenuation and color
      totalShaded += shaded * att * sl.color;
    }

    // Directional lights
    for (uint32_t i = 0; i < lightingCounts.dirCount; i++) {
      const MTLQuestShadingDirLight dl = dirLights[i];

      // Directional light direction is assumed to be the light-to-surface direction for shading functions.
      float3 L = normalize(-dl.direction);

      float att = dl.intensity;

      float3 shaded = evalShading(in.normal, L, dl.color);

      totalShaded += shaded * att * dl.color;
    }

    return float4(totalShaded, 1.0);
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

  // ---START---
  // draw a plane
  struct PlaneVertexIn {
    float3 position [[attribute(0)]];
  };
  struct PlaneVertexOut {
    float4 position [[position]];
  };
  vertex PlaneVertexOut funPlaneVertex(
    PlaneVertexIn in [[stage_in]],
    constant SceneUniforms &u [[buffer(1)]]
  ) {
    PlaneVertexOut out;
    out.position = u.mvp * float4(in.position, 1.0);
    return out;
  }
  fragment float4 funPlaneFragment(PlaneVertexOut in [[stage_in]]) {
    return float4(0.7, 0.7, 0.7, 0.08);
  }
  // ---END---
}

