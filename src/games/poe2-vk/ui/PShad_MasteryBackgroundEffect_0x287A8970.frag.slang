#include "../common.hlsl"

[[vk::binding(0, 9)]]
cbuffer type_ctime_cb : register(b0, space9)
{
    float ctime_cb_time : packoffset(c0);
    row_major float4x4 ctime_cb_transform : packoffset(c1);
    float ctime_cb_sdr_scale : packoffset(c5);
    float ctime_cb_alpha : packoffset(c5.y);
    float ctime_cb_dissolve_cutoff : packoffset(c5.z);
    float ctime_cb_brightness_percent : packoffset(c5.w);
    float ctime_cb_shine_frequency_scale : packoffset(c6);
    float ctime_cb_shine_time_scale : packoffset(c6.y);
    uint ctime_cb_mask_use_localspace_uv : packoffset(c6.z);
    float4 ctime_cb_passive_graph_size : packoffset(c7);
    float4 ctime_cb_passive_graph_ss_offset_size : packoffset(c8);
    float ctime_cb_passive_graph_zoom : packoffset(c9);
    float4 ctime_cb_glow_colour : packoffset(c10);
    float4 ctime_cb_centre_uv_image_size : packoffset(c11);
    float4 ctime_cb_icon_glow_params : packoffset(c12);
    float ctime_cb_low_shine_concentration : packoffset(c13);
    float4 ctime_cb_low_shine_colour : packoffset(c14);
    float4 ctime_cb_full_shine_colour : packoffset(c15);
    float4 ctime_cb_shockwave_info[10] : packoffset(c16);
    uint ctime_cb_num_shockaves : packoffset(c26);
    float ctime_cb_distortion_intensity : packoffset(c26.y);
    float ctime_cb_phase : packoffset(c26.z);
    int ctime_cb_random : packoffset(c26.w);
};

[[vk::binding(12, 0)]] SamplerState SamplerLinearWrapOffsetNoBias : register(s12, space0);
[[vk::binding(13, 0)]] SamplerState SamplerLinearClampOffsetNoBias : register(s13, space0);
[[vk::binding(0, 5)]] Texture2D<float4> tex : register(t0, space5);
[[vk::binding(1, 5)]] Texture2D<float4> noise_map : register(t1, space5);

static float2 in_var_TEXCOORD0;
static float4 out_var_SV_TARGET;

struct SPIRV_Cross_Input
{
    float2 in_var_TEXCOORD0 : TEXCOORD0;
};

struct SPIRV_Cross_Output
{
    float4 out_var_SV_TARGET : SV_Target0;
};

void frag_main()
{
    float2 _49 = (in_var_TEXCOORD0 - ctime_cb_centre_uv_image_size.xy) * 1.0f;
    float2 _62 = float2((atan2(_49.y, _49.x) * 0.15915493667125701904296875f) + 0.5f, length(_49) * 2.0f) + float2(0.0f, ctime_cb_time * (-0.039999999105930328369140625f));
    float2 _65 = float2(1.0f, 0.0f) * (ctime_cb_time * 0.0350000001490116119384765625f);
    float4 _88 = tex.Sample(SamplerLinearClampOffsetNoBias, in_var_TEXCOORD0);
    float4 _91 = lerp(_88, _88 * 2.0f, max(noise_map.SampleLevel(SamplerLinearWrapOffsetNoBias, float4(_62 + _65, 0.0f, 1.0f).xy, 1.0f).x, noise_map.SampleLevel(SamplerLinearWrapOffsetNoBias, float4((-_62) + _65, 0.0f, 1.0f).xy, 1.0f).x).xxxx);
    out_var_SV_TARGET = ApplyUIProcessing(_91.xyz, _91.w);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    in_var_TEXCOORD0 = stage_input.in_var_TEXCOORD0;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_var_SV_TARGET = out_var_SV_TARGET;
    return stage_output;
}
