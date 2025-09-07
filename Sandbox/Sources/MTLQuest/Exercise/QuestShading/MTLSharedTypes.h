//
//  MTLSharedTypes.h
//  Sandbox
//
//  Created by Uladzislau Volchyk on 8/29/25.
//

// SharedTypes.h
#pragma once
#include <simd/simd.h>
#ifdef __METAL_VERSION__
#define HOSTDEVICE device
#else
#define HOSTDEVICE
#endif

typedef enum : uint32_t {
    LightTypePoint = 0,
    LightTypeSpot  = 1,
    LightTypeDir   = 2,
} MTLQuestShadingLightType;

typedef struct {
    simd_float3 position;   float _pad0;   // 16B stride for float3
    simd_float3 color;      float intensity;
} MTLQuestShadingPointLight;

typedef struct {
    simd_float3 position;   float _pad0;
    simd_float3 direction;  float cosOuter; // precompute cos(angle)
    simd_float3 color;      float intensity;
    float       cosInner;   float _pad1[3]; // optional inner cone & pad
} MTLQuestShadingSpotLight;

typedef struct {
    simd_float3 direction;  float _pad0;
    simd_float3 color;      float intensity;
} MTLQuestShadingDirLight;

typedef struct {
    uint32_t pointCount;
    uint32_t spotCount;
    uint32_t dirCount;
    uint32_t _pad; // keep 16B alignment
} MTLQuestShadingLightingCounts;
