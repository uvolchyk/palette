// Pikachu2dShaders.metal
#include <metal_stdlib>
#import "Quad.h"

using namespace metal;

namespace Pikachu2d {
  vertex float4 quadVertex(
    uint vertexID [[ vertex_id ]]
  ) {
    float2 pos[4] = {
      float2(-1.0, -1.0),
      float2(-1.0,  1.0),
      float2( 1.0, -1.0),
      float2( 1.0,  1.0)
    };

    return float4(pos[vertexID], 0.0, 1.0);
  }

  fragment float4 displayImage2d(
    float4 position [[ position ]],
    texture2d<float> image [[ texture(0) ]],
    sampler imgSampler [[ sampler(0) ]]
  ) {
    float2 texcoord = (position.xy * 0.5) + 0.5;
    return image.sample(imgSampler, texcoord);
  }

  // Texture coordinates range [0, 1].
  // X-positive values go from the top-left to the top-right;
  // Y-positive go from top-left to bottom-left.
  constexpr sampler sampler2d(coord::normalized, filter::nearest);

  /// Returns a float in range [0,1)
  float rand(float2 co) {
    return fract(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
  }
  
  [[fragment]] half4 transform_passthrough(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float,access::sample> texture [[texture(0)]]
  ) {
    float4 const color = texture.sample(sampler2d, in.texCoord);
    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_mirror(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float4 const color = texture.sample(sampler2d, float2(in.texCoord.x, 1.0 - in.texCoord.y));
    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_symmetry(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float4 const color = texture.sample(sampler2d, float2(in.texCoord.x, 0.5 - abs(in.texCoord.y - 0.5)));
    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_rotation(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
//    float2 screenSize = float2(texture.get_width(), texture.get_height());
//    float2 centeredCoord = in.texCoord - 0.5;
//    centeredCoord.x *= screenSize.x / screenSize.y;
//
//    // https://en.wikipedia.org/wiki/Polar_coordinate_system
//    float a = atan2(centeredCoord.x, centeredCoord.y) + .6;
//    centeredCoord = float2(cos(a), sin(a)) * length(centeredCoord);
//    centeredCoord.x *= screenSize.y / screenSize.x;
//    centeredCoord += 0.5;
//
//    float4 color = texture.sample(sampler2d, centeredCoord);
//
//    return half4(half3(color.rgb), 1);

    float2 screenSize = float2(texture.get_width(), texture.get_height());
    float2 centeredCoords = (in.texCoord - 0.5) * screenSize;

    // https://en.wikipedia.org/wiki/Rotation_matrix
    float angle = M_PI_F / 4.0;
    float2x2 rotationMatrix = float2x2(
      cos(angle), -sin(angle),
      sin(angle),  cos(angle)
    );
    float2 rotatedCoords = centeredCoords * rotationMatrix;
    float2 rotatedTexCoord = (rotatedCoords / screenSize) + 0.5;

    float4 color = texture.sample(sampler2d, rotatedTexCoord);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_zoom(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    const float factor = 0.5;
    const float zoom = 1 / factor;

    // < 1
    // smaller region of the texture => image looks bigger
    // для заполнения экранных пикселей используется меньшее количество текселей => картинка больше
    // > 1
    // bigger region of the texture => image looks smaller
    // для заполнения экранных пикселей используется большее количество текселей => картинка меньше
    float2 uv = in.texCoord -= 0.5;
    uv *= zoom;
    uv += 0.5;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_zoomDistortion(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    const float factor = 4;
    const float zoom = 1 / factor;

    // < 1
    // smaller region of the texture => image looks bigger
    // для заполнения экранных пикселей используется меньшее количество текселей => картинка больше
    // > 1
    // bigger region of the texture => image looks smaller
    // для заполнения экранных пикселей используется большее количество текселей => картинка меньше
    float2 uv = in.texCoord -= 0.5;
    uv *= smoothstep(0.0, zoom, length(uv));
    uv += 0.5;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_repetitions(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float factor = 4;

    float2 uv = in.texCoord;

    uv *= factor;
    uv = fract(uv);

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }
  
  [[fragment]] half4 transform_spiral(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 screenSize = float2(texture.get_width(), texture.get_height());
    float2 uv = in.texCoord - 0.5;
    uv.x *= screenSize.x / screenSize.y;

    // Apply a logic similar to the rotation effect.
    // But the angle depends on the distance from the center.
    // Far from the center => greater distortion angle (also considering the multiplier).
    float a = atan2(uv.x, uv.y) + length(uv) * 10.0;
    uv = float2(cos(a), sin(a)) * length(uv);
    uv += 0.5;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_thunder(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 screenSize = float2(texture.get_width(), texture.get_height());
    float2 uv = in.texCoord - 0.5;
    uv.x *= screenSize.x / screenSize.y;

    float l = length(uv) + 1.0;
    float a = atan2(uv.x, uv.y);

    uv = fract(abs(float2(a, l)) + 0.5);

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }
  
  [[fragment]] half4 transform_clamp(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    // < 0.1 => return uv.y at 0.1
    // ~ 0.1...0.4 => return uv.y
    // > 0.4 => return uv.y at 0.4
    uv.y = clamp(uv.y, 0.1, 0.4);

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_fold(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    uv -= 0.5;
    uv.y -= abs(uv.x);
    uv += 0.5;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_pixelise(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    // https://gamedev.stackexchange.com/questions/111017/pixelation-shader-explanation
    // 16x16 quants grid
    const float edge = 1.0 / 16.0;

    // Quantisation.
    // uv / edge -> map [0,1] to [0,16] (find a quant)
    // floor -> round to the nearest integer from the bottom (stick to an edge)
    // edge * result -> map [0,16] to [0,1] (find a texel)
    float2 uv = in.texCoord;
    uv = float2(
      edge * floor(uv.x / edge),
      edge * floor(uv.y / edge)
    );

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_vague(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    const float frequency = 100.0;
    const float amplitude = 0.05;
    float2 uv = in.texCoord;

    // Offset a horizontal coordinate by a amount specified by the harmonic oscillation.
    uv.x += cos(uv.y * frequency) * amplitude;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }
  
  [[fragment]] half4 transform_colonne(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    // factor allows to control the amount of "lines"
    // < 1 -> bigger a single line is
    // > 1 -> smaller a single line is
    const float factor = 0.5;

    // floor allows this fractal behavior
    float2 uv = in.texCoord;
    uv.x += cos(floor(uv.y * 40.0 * factor) / factor) * 0.1;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_crash(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    // 16x16 quants grid
    const float edge = 1.0 / 256.0;

    // `rand` is the source of enthropy (and actually deterministic in the used implementation);
    // but because the input parameter is represented by quants,
    // the same transform is applied to chunks of pixels.
    float2 uv = in.texCoord;
    uv += rand(float2(
      edge * floor(uv.x / edge),
      edge * floor(uv.y / edge)
    ) * 4.0) * 0.4;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_scanline(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    // `rand` generates values in range [0,1)
    // multiplying it by 2 and subtracting 1 maps it to the range [-1,1)
    // smoothstep here acts as a "blending factor"
    uv.x += (rand(uv.yy) * 2.0 - 1.0) * smoothstep(0.0, 1.0, sin(uv.y * 5.0));

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 transform_double_frequency(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    // oscillation at high frequency
    float dir = sin(abs(uv.y * 2000.0));

    // we can use sin value only to get the transform,
    // this way the texture will be translated multiple times with different offsets depending on the sin value
    // uv.x += dir * 0.05;

    // with `sign` function the texture gets translated only times (left / right) at the same offset
    uv.x += sign(dir) * 0.05;

    float4 color = texture.sample(sampler2d, uv);

    return half4(half3(color.rgb), 1);
  }

  [[fragment]] half4 filter_noir(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    float4 color = texture.sample(sampler2d, uv);

    // https://medium.com/sketch-app-sources/mixing-colours-of-equal-luminance-part-1-41f69518d647
    // https://en.wikipedia.org/wiki/Grayscale
    float luminance = color.r * 0.54 + color.g * 0.8 + color.b * 0.44;

    return half4(half3(luminance), 1);
  }

  [[fragment]] half4 filter_black(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    float4 color = texture.sample(sampler2d, uv);

    // https://medium.com/sketch-app-sources/mixing-colours-of-equal-luminance-part-1-41f69518d647
    // https://en.wikipedia.org/wiki/Grayscale
    float luminance = color.r * 0.54 + color.g * 0.8 + color.b * 0.44;

    // https://en.wikipedia.org/wiki/Thresholding_(image_processing)
    // if the luminance region is bright enough -> return 1.0, otherwise return 0.0
    return half4(step(1.2, luminance));
  }

  [[fragment]] half4 filter_threshold(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    const float factor = 2.0;
    float2 uv = in.texCoord;

    float4 color = texture.sample(sampler2d, uv);

    // https://en.wikipedia.org/wiki/Thresholding_(image_processing)
    return half4(ceil(color * factor) / factor);
  }

  [[fragment]] half4 filter_chromatic_aberration(
    Global::QuadVertexOut in [[stage_in]],
    texture2d<float, access::sample> texture [[texture(0)]]
  ) {
    float2 uv = in.texCoord;

    float4 color = texture.sample(sampler2d, uv);

    // https://en.wikipedia.org/wiki/Chromatic_aberration
    color.r = texture.sample(sampler2d, float2(uv.x - 0.02, uv.y)).r;
    color.b = texture.sample(sampler2d, float2(uv.x + 0.02, uv.y)).b;

    return half4(color);
  }
}
