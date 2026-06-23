#include "../common.hlsl"

// =====================================================================================
// Constant Buffers & Bindings
// =====================================================================================

[[vk::binding(0, 9)]]
cbuffer type_cpost_processing_desc_cb : register(b0, space9)
{
    int cpost_processing_desc_cb_viewport_width               : packoffset(c0);
    int cpost_processing_desc_cb_viewport_height              : packoffset(c0.y);
    int cpost_processing_desc_cb_oetf_id                      : packoffset(c0.z);
    float4 cpost_processing_desc_cb_src_frame_to_dynamic_scale : packoffset(c1);
};

[[vk::binding(1, 0)]]
SamplerState SamplerLinearClamp : register(s1, space0);

[[vk::binding(0, 5)]]
Texture2D<float4> source_sampler : register(t0, space5);

// =====================================================================================
// Shader Input/Output Structures
// =====================================================================================

struct SPIRV_Cross_Input
{
    float4 gl_FragCoord : SV_Position;
};

struct SPIRV_Cross_Output
{
    float4 out_var_SV_TARGET : SV_Target0;
};

// =====================================================================================
// OETF Helper Functions (Color Space Conversions)
// =====================================================================================

/**
 * Applies the standard sRGB (IEC 61966-2-1) Opto-Electronic Transfer Function.
 * Converts linear HDR/SDR color values to gamma-encoded values for standard displays.
 */
float3 ApplySRGBOETF(float3 linearColor)
{
    float3 clampedColor = clamp(linearColor, 0.0f.xxx, 1.0f.xxx);
    float3 srgbColor;

    srgbColor.r = (clampedColor.r > 0.0031308f) ? (1.055f * pow(clampedColor.r, 0.41666667f) - 0.055f) : (12.92f * clampedColor.r);
    srgbColor.g = (clampedColor.g > 0.0031308f) ? (1.055f * pow(clampedColor.g, 0.41666667f) - 0.055f) : (12.92f * clampedColor.g);
    srgbColor.b = (clampedColor.b > 0.0031308f) ? (1.055f * pow(clampedColor.b, 0.41666667f) - 0.055f) : (12.92f * clampedColor.b);

    return srgbColor;
}

/**
 * Applies the SMPTE ST 2084 (PQ / Perceptual Quantizer) OETF for HDR10 displays.
 * Includes an initial color space conversion matrix (typically BT.709 to BT.2020 / LMS).
 */
float3 ApplyPQOETF(float3 linearColor)
{
    // Color space conversion matrix
    float3x3 colorMatrix = float3x3(
        float3(0.62740397f, 0.32928198f, 0.04331360f),
        float3(0.06909699f, 0.91953998f, 0.01136120f),
        float3(0.01639159f, 0.08801320f, 0.89559501f)
    );
    
    float3 transformedColor = mul(colorMatrix, linearColor);
    
    // Normalize luminance mapping (0.008 factor maps peak scene brightness relative to 10k nits PQ range)
    float3 scaledColor = clamp(transformedColor * 0.008f, 0.0f.xxx, 1.0f.xxx);
    
    // PQ Mathematical formulation constants:
    // m1 = 2610 / 16384 = 0.159301758
    // m2 = 2523 / 32    = 78.84375
    // c1 = 3424 / 4096  = 0.8359375
    // c2 = 2413 / 128   = 18.8515625
    // c3 = 2392 / 128   = 18.6875
    float3 powerTerm  = pow(scaledColor, 0.159301758f.xxx);
    float3 numerator   = 0.8359375f.xxx + (powerTerm * 18.8515625f.xxx);
    float3 denominator = 1.0f.xxx + (powerTerm * 18.6875f.xxx);
    
    return pow(numerator / denominator, 78.84375f.xxx);
}

// =====================================================================================
// Fragment Shader Execution
// =====================================================================================

float4 ProcessPostProcessing(float4 fragCoord)
{
    // -------------------------------------------------------------
    // 1. Texture Coordinate Setup with Dynamic Resolution Scaling
    // -------------------------------------------------------------
    float2 viewportSize = float2(
        float(cpost_processing_desc_cb_viewport_width), 
        float(cpost_processing_desc_cb_viewport_height)
    );

    // Calculate standard 0.0 to 1.0 screen UV coordinates
    float2 normalizedUV = fragCoord.xy / viewportSize;

    // Apply dynamic resolution scale (xy) and clamp to active viewport region bounds (zw)
    float2 clampedUV = min(
        normalizedUV * cpost_processing_desc_cb_src_frame_to_dynamic_scale.xy,
        cpost_processing_desc_cb_src_frame_to_dynamic_scale.zw
    );

    // Sample the final scene color buffer (Final Frame = World + UI)
    float4 sourceColor = source_sampler.SampleLevel(SamplerLinearClamp, clampedUV, 0.0f);

    // -------------------------------------------------------------
    // 2. Select and Apply Opto-Electronic Transfer Function (OETF)
    // -------------------------------------------------------------
    float4 finalColor;
    finalColor.a = sourceColor.a; // Retain original texture alpha globally

    switch (cpost_processing_desc_cb_oetf_id)
    {
    case 0: // REC709
        finalColor.rgb = ApplySRGBOETF(sourceColor.rgb);
        break;

    case 1: // ST2084
        // Case only run when HDR ticked
        // No longer need to PQ since we upgraded swapchain to 16bit. Let Windows PQ.
        // Final adjustments have been moved to OnPresent custom shader that is run before present.
        finalColor.rgb = sourceColor.rgb / 1.45f;
        break;

    case 2: // LINEAR
    case 3: // LINEAR SDR
        // Case only run when HDR not ticked.
        finalColor.rgb = sourceColor.rgb;
        break;

    default:
        finalColor.rgb = ApplySRGBOETF(sourceColor.rgb);
        break;
    }

    return finalColor;
}

// =====================================================================================
// Main Pixel Shader Entry Point
// =====================================================================================

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    float4 fragCoord = stage_input.gl_FragCoord;
    
    // Correct perspective interpolation divide
    fragCoord.w = 1.0f / fragCoord.w;
    
    SPIRV_Cross_Output stage_output;
    stage_output.out_var_SV_TARGET = ProcessPostProcessing(fragCoord);
    return stage_output;
}