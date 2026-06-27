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

[[vk::binding(13, 0)]] SamplerState SamplerLinearClampOffsetNoBias : register(s13, space0);
[[vk::binding(0, 5)]] Texture2D<float4> tex : register(t0, space5);
[[vk::binding(1, 5)]] Texture2D<float4> mask_tex : register(t1, space5);

static float2 in_var_TEXCOORD0;
static float4 in_var_COLOR0;
static float4 in_var_TEXCOORD1;
static float4 out_var_SV_TARGET;

struct SPIRV_Cross_Input
{
    float2 in_var_TEXCOORD0 : TEXCOORD0;
    float4 in_var_COLOR0 : TEXCOORD1;
    float4 in_var_TEXCOORD1 : TEXCOORD2;
};

struct SPIRV_Cross_Output
{
    float4 out_var_SV_TARGET : SV_Target0;
};

void frag_main()
{
    float4 _51 = tex.Sample(SamplerLinearClampOffsetNoBias, in_var_TEXCOORD0);
    float _57 = 0.60000002384185791015625f + (sin(ctime_cb_time * 2.5f) * 0.4000000059604644775390625f);
    float _63 = _51.w;
    float4 _76 = clamp(_51 + (((ctime_cb_glow_colour * (float4(_57, _57, _57, 1.0f) * ctime_cb_glow_colour.w)) * (mask_tex.Sample(SamplerLinearClampOffsetNoBias, in_var_TEXCOORD1.zw).x * _63)) * _63), 0.0f.xxxx, 1.0f.xxxx) * in_var_COLOR0.w;
    out_var_SV_TARGET = ApplyUIProcessing(_76.xyz, _76.w);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    in_var_TEXCOORD0 = stage_input.in_var_TEXCOORD0;
    in_var_COLOR0 = stage_input.in_var_COLOR0;
    in_var_TEXCOORD1 = stage_input.in_var_TEXCOORD1;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_var_SV_TARGET = out_var_SV_TARGET;
    return stage_output;
}
