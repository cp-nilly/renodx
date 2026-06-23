#include "../common.hlsl"

[[vk::binding(0, 0)]] Texture2D<float4> textures[2] : register(t0); // Set 0, Binding 0, Array size 2

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    int3 tex_coords = int3(pos.xy, 0);
    float4 ui = textures[0].Load(tex_coords);
    float4 world = textures[1].Load(tex_coords);

    float uiAlpha = ui.a;
    float3 uiColorUnmultiplied = ui.rgb / max(uiAlpha, 0.0001f);
    float4 uiLinear = ApplyUIProcessing(uiColorUnmultiplied, uiAlpha);
    float3 correctedComposite = world.rgb * (1.0f - uiLinear.a) + (uiLinear.rgb * uiLinear.a);
    return float4(correctedComposite, 1.0f);
}