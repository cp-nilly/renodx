#include "../../shared.h"

static float _105;

cbuffer type_cconstants_cb : register(b0, space9)
{
    float4 cconstants_cb_point_light_positions[64] : packoffset(c0);
    float4 cconstants_cb_point_light_colors[64] : packoffset(c64);
    float4 cconstants_cb_screen_size : packoffset(c128);
    uint cconstants_cb_point_lights_count : packoffset(c129);
    float cconstants_cb_time : packoffset(c129.y);
    float cconstants_cb_sdr_scale : packoffset(c129.z);
};

SamplerState SamplerLinearClamp : register(s1, space0);
SamplerState SamplerLinearClampNoBias : register(s9, space0);
SamplerState SamplerLinearWrapOffsetNoBias : register(s12, space0);
TextureCube<float4> specular_cube : register(t0, space5);
TextureCube<float4> diffuse_cube : register(t1, space5);
Texture2D<float4> environment_ggx_tex : register(t2, space5);
Texture2D<float4> albedo_tex : register(t3, space5);
Texture2D<float4> normal_tex : register(t4, space5);
Texture2D<float4> roughness_tex : register(t5, space5);
Texture2D<float4> bent_normal_tex : register(t6, space5);
Texture2D<float4> ao_tex : register(t7, space5);
Texture2D<float4> depth_tex : register(t8, space5);
Texture2D<float4> metal_tex : register(t9, space5);

static float4 gl_FragCoord;
static float2 in_var_TEXCOORD0;
static float4 in_var_COLOR0;
static float4 out_var_SV_TARGET;

struct SPIRV_Cross_Input
{
    float2 in_var_TEXCOORD0 : TEXCOORD0;
    float4 in_var_COLOR0 : TEXCOORD1;
    float4 gl_FragCoord : SV_Position;
};

struct SPIRV_Cross_Output
{
    float4 out_var_SV_TARGET : SV_Target0;
};

uint2 spvTextureSize(TextureCube<float4> Tex, uint Level, out uint Param)
{
    uint2 ret;
    Tex.GetDimensions(Level, ret.x, ret.y, Param);
    return ret;
}

void frag_main()
{
    float4 _113 = albedo_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0);
    float4 _116 = normal_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0);
    float4 _119 = roughness_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0);
    float4 _125 = ao_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0);
    float4 _128 = depth_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0);
    float4 _131 = metal_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0);
    float3 _141 = float3(gl_FragCoord.xy / cconstants_cb_screen_size.xy, lerp(0.300000011920928955078125f, 0.699999988079071044921875f, _128.x));
    float _142 = _125.x;
    float3 _146 = normalize((_116.xyz * 2.0f) - 1.0f.xxx);
    float3 _149 = _146;
    _149.y = _146.y * (-1.0f);
    float3 _154 = normalize((bent_normal_tex.Sample(SamplerLinearWrapOffsetNoBias, in_var_TEXCOORD0).xyz * 2.0f) - 1.0f.xxx) * _142;
    _154.y = _154.y * (-1.0f);
    float _158 = _119.x;
    float _159 = 1.0f - _158;
    float3 _161 = _113.xyz;
    float3 _162 = _131.x.xxx;
    float3 _163 = lerp(_161, 0.0f.xxx, _162);
    float3 _165 = lerp(0.039999999105930328369140625f.xxx, clamp(_161, 0.0f.xxx, 1.0f.xxx), _162);
    float3x3 _167 = mul(mul(float3x3(float3(1.0f, 0.0f, 0.0f), float3(0.0f, 0.70866978168487548828125f, 0.70554029941558837890625f), float3(0.0f, -0.70554029941558837890625f, 0.70866978168487548828125f)), float3x3(float3(-0.9364566802978515625f, 0.0f, -0.35078322887420654296875f), float3(0.0f, 1.0f, 0.0f), float3(0.35078322887420654296875f, 0.0f, -0.9364566802978515625f))), float3x3(float3(1.0f, 0.0f, 0.0f), float3(0.0f, -1.0f, 0.0f), float3(0.0f, 0.0f, 1.0f)));
    float4 _172 = diffuse_cube.Sample(SamplerLinearClamp, mul(_154, _167));
    float _183 = _146.z;
    float4 _189 = environment_ggx_tex.SampleLevel(SamplerLinearClamp, float4(abs(_183), _159, 0.0f, 0.0f).xy, 0.0f);
    uint _195_dummy_parameter;
    float _202 = log2(float(int(spvTextureSize(specular_cube, uint(0), _195_dummy_parameter).x)) / (1.57079589366912841796875f / (_158 * _158)));
    float3 _223 = normalize(_154);
    float _224 = length(_154);
    float3 _226;
    _226 = 0.0f.xxx;
    for (uint _229 = 0u; _229 < cconstants_cb_point_lights_count; )
    {
        float _247 = clamp((1.0f - cconstants_cb_point_light_positions[_229].y) * 5.0f, 0.0f, 1.0f);
        float3 _250 = cconstants_cb_point_light_positions[_229].xyz - _141;
        _250.z = _250.z * 0.5f;
        float3 _254 = normalize(_250);
        float3 _268 = ((cconstants_cb_point_light_colors[_229].xyz / (dot(_250, _250) + 1.0000000116860974230803549289703e-07f).xxx) * (((clamp(cconstants_cb_point_light_positions[_229].x * 5.0f, 0.0f, 1.0f) * clamp(cconstants_cb_point_light_positions[_229].y * 5.0f, 0.0f, 1.0f)) * _247) * _247)) * clamp((dot(_223, _254) - (1.0f - _224)) * 10.0f, 0.0f, 1.0f);
        float _273 = clamp(_158, 0.0f, 1.0f);
        float _275 = max(_273 * _273, 0.00200000009499490261077880859375f);
        float _276 = _275 * _275;
        float3 _278 = normalize(float3(-0.0f, -0.0f, 1.0f) + _254);
        float _280 = clamp(dot(_149, _278), 0.0f, 1.0f);
        float _282 = clamp(dot(_254, _149), 0.0f, 1.0f);
        float _285 = clamp(_278.z, 0.0f, 1.0f);
        float _292 = _275 * 0.5f;
        float _293 = 1.0f - _292;
        _226 += (((_268 * max(0.0f, dot(_149, _254))) * _163) + (((((lerp(exp2((((-5.554729938507080078125f) * _285) - 6.9831600189208984375f) * _285).xxx, 1.0f.xxx, _165) * (_276 / pow((((_276 - 1.0f) * _280) * _280) + 1.0f, 2.0f))) * (1.0f / (((clamp(_183, 0.0f, 1.0f) * _293) + _292) * ((_282 * _293) + _292)))) * _282) * 0.25f.xxx) * _268));
        _229++;
        continue;
    }
    float _314 = _113.w;
    float4 _320 = float4((((((_172.xyz * 3.3299999237060546875f) * _163) * _142) + (((float4((_189.x.xxx + (_165 * _189.y)) * specular_cube.SampleLevel(SamplerLinearClampNoBias, float4(mul(float3(0.0f, 0.0f, -1.0f) - ((_149 * 2.0f) * dot(float3(0.0f, 0.0f, -1.0f), _149)), _167), _202).xyz, _202).xyz, _105) * 3.3299999237060546875f) * 1.0f).xyz * lerp(_142, 1.0f, _159))) + (_226 * 0.0199999995529651641845703125f)) * _314, _314) * in_var_COLOR0;
    out_var_SV_TARGET = float4(clamp((pow(clamp(_320.xyz, 0.0f.xxx, 1.0f.xxx), 1.0499999523162841796875f.xxx) - 0.001000000047497451305389404296875f.xxx) * 1.00100100040435791015625f.xxx, 0.0f.xxx, 1.0f.xxx) * cconstants_cb_sdr_scale, _320.w);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    if (!RENODX_UI_TOGGLE) discard;
    gl_FragCoord = stage_input.gl_FragCoord;
    gl_FragCoord.w = 1.0 / gl_FragCoord.w;
    in_var_TEXCOORD0 = stage_input.in_var_TEXCOORD0;
    in_var_COLOR0 = stage_input.in_var_COLOR0;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_var_SV_TARGET = out_var_SV_TARGET;
    return stage_output;
}
