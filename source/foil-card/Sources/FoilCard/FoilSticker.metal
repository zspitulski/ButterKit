//
//  FoilSticker.metal
//  FoilCard
//
//  Adapted from Sticker by Benjamin Pisano (https://github.com/bpisano/Sticker),
//  FoilShader.metal and ReflectionShader.metal at v1.4.0.
//  MIT License, Copyright (c) 2024 bpisano. See NOTICE.md.
//
//  Changes from Sticker:
//  - The foil's minimum tint (fixed at 0.3 in Sticker) is the `minimumTint`
//    argument. 0.3 lifts dark ink into a muddy grey, so the card style uses
//    a much lower value.
//  - Only the diamond pattern is kept, and the unused blend argument is gone.
//  - Helpers are `static` so their names can't clash with other shaders
//    linked into the same library.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Pseudo-random noise based on position.
static float foilRandom(float2 uv) {
    return fract(sin(dot(uv.xy, float2(12.9898, 78.233))) * 43758.5453);
}

static float foilBrightness(half4 color) {
    return (color.r * 0.299 + color.g * 0.587 + color.b * 0.114);
}

static float foilNoise(float2 uv) {
    float2 i = floor(uv);
    float2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = foilRandom(i);
    float b = foilRandom(i + float2(1.0, 0.0));
    float c = foilRandom(i + float2(0.0, 1.0));
    float d = foilRandom(i + float2(1.0, 1.0));

    // Smooth interpolation
    float2 u = smoothstep(0.0, 1.0, f);

    // Mix 4 corners percentages
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Mixes in the foil color, more on lighter colors, never less than
// `minimumTint`.
static half4 foilLightnessMix(half4 baseColor, half4 overlayColor, float intensity, float minimumTint) {
    float brightness = foilBrightness(baseColor);
    float adjustedMixFactor = max(smoothstep(0.2, 1.0, brightness) * intensity, minimumTint);
    return mix(baseColor, overlayColor, adjustedMixFactor);
}

// Increases contrast based on a pattern value.
static half4 foilIncreaseContrast(half4 source, float pattern, float intensity) {
    float brightness = foilBrightness(source);
    float contrastFactor = mix(1.0, intensity, pattern * brightness);
    return (source - half4(0.5)) * contrastFactor + half4(0.5);
}

// 45° checkerboard.
static float foilDiamondPattern(float2 uv, float scale) {
    float radiansAngle = 45.0 * M_PI_F / 180;

    uv *= scale;

    float cosAngle = cos(radiansAngle);
    float sinAngle = sin(radiansAngle);
    float2 rotatedUV = float2(
                              cosAngle * uv.x - sinAngle * uv.y,
                              sinAngle * uv.x + cosAngle * uv.y
                              );

    return fmod(floor(rotatedUV.x) + floor(rotatedUV.y), 2.0) == 0.0 ? 0.0 : 1.0;
}

[[ stitchable ]] half4 foilSticker(
                                   float2 position,
                                   half4 color,
                                   float2 offset,
                                   float2 size,
                                   float scale,
                                   float intensity,
                                   float minimumTint,
                                   float contrast,
                                   float checkerScale,
                                   float checkerIntensity,
                                   float noiseScale,
                                   float noiseIntensity
) {
    float aspectRatio = size.x / size.y;

    // Normalize the offset by size so it behaves the same at any view size.
    float2 normalizedOffset = (offset + size * 250) / (size * scale) * 0.01;
    float2 normalizedPosition = float2(position.x * aspectRatio, position.y);

    float2 uv = (position / (size * scale)) + normalizedOffset;

    float gradientNoise = foilRandom(position) * 0.1;
    float pattern = foilDiamondPattern(normalizedPosition / size * checkerScale, checkerScale);
    float noise = foilNoise(position / size * noiseScale);

    // Low-saturation color shifts for a metallic look.
    half r = half(contrast + 0.25 * sin(uv.x * 10.0 + gradientNoise));
    half g = half(contrast + 0.25 * cos(uv.y * 10.0 + gradientNoise));
    half b = half(contrast + 0.25 * sin((uv.x + uv.y) * 10.0 - gradientNoise));

    half4 foilColor = half4(r, g, b, 1.0);
    half4 mixedFoilColor = foilLightnessMix(color, foilColor, intensity, minimumTint);

    half4 checkerFoil = foilIncreaseContrast(mixedFoilColor, pattern, checkerIntensity);
    return foilIncreaseContrast(checkerFoil, noise, noiseIntensity);
}

// Soft white highlight that follows the pointer.
[[ stitchable ]] half4 foilStickerReflection(
                                             float2 position,
                                             half4 color,
                                             float2 size,
                                             float2 reflectionPosition,
                                             float reflectionSize,
                                             float intensity
) {
    float2 uv = position / size;
    float d = distance(uv, reflectionPosition);
    float blurFactor = smoothstep(reflectionSize / size.x, 0.0, d);
    half4 reflectionColor = half4(1.0, 1.0, 1.0, intensity * blurFactor);
    return mix(color, reflectionColor, reflectionColor.a);
}
