#include "../common.hlsl"
#include "../shared.h"

[[vk::binding(0, 0)]] Texture2D<float4> textures[3] : register(t0);

float DrawFullScreenBandingTest(float2 uv, float ditherNoise) {
    float bitDepth = uv.y / 0.25f;
    bitDepth = trunc(bitDepth);
    bitDepth = bitDepth * 2.0 + 4.0;

    float maxValue = exp2(bitDepth) - 1.0;
    float stepNoise = ditherNoise - 0.5f;
    float ditheredX = uv.x + (stepNoise / maxValue);
    return round(saturate(ditheredX) * maxValue) / maxValue;
}

float GenerateBlueNoise(int2 pixelCoord) {
    // Tiled 256x256 blue noise
    int2 texCoords = pixelCoord % 256; 
    float4 noiseSample = textures[2].Load(int3(texCoords, 0));
    return noiseSample.r;
}

float4 main(float4 pos: SV_Position, float2 uv: TEXCOORD0) : SV_Target
{
    int3 tex_coords = int3(pos.xy, 0);
    float4 world = textures[1].Load(tex_coords);
    float4 ui = textures[0].Load(tex_coords);

    // Process UI
    float uiAlpha = ui.a;
    float3 uiColorUnmultiplied = ui.rgb / max(uiAlpha, 0.0001f);
    float4 uiLinear = ApplyUIProcessing(uiColorUnmultiplied, uiAlpha);

    bool ditherTestPattern = false; // debug flag

    // Select background
    float3 background;
    if (ditherTestPattern) {
        float noise = 0.5f;
        if (RENODX_DITHER > 0.f)
            noise = GenerateBlueNoise(int2(pos.xy));
        
        background = DrawFullScreenBandingTest(uv, noise).xxx;
    } else {
        background = world.rgb;
    }

    // Composite the UI over the background
    float3 finalComposite = background * (1.0f - uiLinear.a) + (uiLinear.rgb * uiLinear.a);

    // Apply Dither
    if (!ditherTestPattern && RENODX_DITHER != 0.f) {
        float noise = GenerateBlueNoise(int2(pos.xy));
        float ditherScale = 1.0f / 1023.0f;
        float3 noiseShaping = max(finalComposite, 0.01f);
        finalComposite = finalComposite + (noise - 0.5f) * ditherScale * noiseShaping;
    }

    return float4(max(finalComposite, 0.0f), 1.0f);
}