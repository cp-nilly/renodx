#include "../../shared.h"

static float _72;

cbuffer type_cminimap_blending_pixel_cb : register(b0, space9)
{
    float4 cminimap_blending_pixel_cb_viewport_size : packoffset(c0);
    float cminimap_blending_pixel_cb_geometry_opacity : packoffset(c1);
    float cminimap_blending_pixel_cb_walkability_opacity : packoffset(c1.y);
    float cminimap_blending_pixel_cb_sdr_scale : packoffset(c1.z);
    uint cminimap_blending_pixel_cb_use_royale_data : packoffset(c1.w);
};

SamplerState SamplerLinearClampOffsetNoBias : register(s13, space0);
Texture2D<float4> walkability_sampler : register(t0, space5);
Texture2D<float4> geometry_sampler : register(t1, space5);

static float4 gl_FragCoord;
static float4 out_var_SV_TARGET;

struct SPIRV_Cross_Input
{
    float4 gl_FragCoord : SV_Position;
};

struct SPIRV_Cross_Output
{
    float4 out_var_SV_TARGET : SV_Target0;
};

void frag_main()
{
    float2 _79 = gl_FragCoord.xy / cminimap_blending_pixel_cb_viewport_size.xy;
    float4 _83 = walkability_sampler.Sample(SamplerLinearClampOffsetNoBias, _79);
    float _84 = _83.x;
    float _90 = clamp((_84 - 0.550000011920928955078125f) * 5.0f, 0.0f, 1.0f);
    float4 _92 = lerp(float4(1.0f, 1.0f, 1.0f, 0.00999999977648258209228515625f), float4(0.5f, 0.5f, 1.0f, 0.5f), clamp((_84 - 0.24999998509883880615234375f) * 5.0f, 0.0f, 1.0f).xxxx);
    float _101 = clamp(_83.y * 2.0f, 0.0f, 1.0f);
    float4 _112 = geometry_sampler.Sample(SamplerLinearClampOffsetNoBias, _79);
    float _118 = _112.w * clamp(length(_112.xyz) * 50.0f, 0.0f, 1.0f);
    float4 _119 = float4(1.0f, 1.0f, 1.0f, _101);
    float4 _124 = lerp(lerp(_92, float4(_92.xyz, 0.0f), _90.xxxx) * _119, float4(0.0f, 0.5f, 1.0f, 0.5f), pow(clamp(clamp(((_101 * (1.0f - _101)) * 4.0f) * clamp(2.0f - (2.0f * _84), 0.0f, 1.0f), 0.0f, 1.0f), 0.0f, 1.0f), 25.0f).xxxx);
    _112.w = lerp(_118, _118 * lerp(1.0f, 0.300000011920928955078125f, cminimap_blending_pixel_cb_walkability_opacity), 1.0f - _90) * cminimap_blending_pixel_cb_geometry_opacity;
    float _136 = _124.w * cminimap_blending_pixel_cb_walkability_opacity;
    float4 _137 = _112 * _119;
    float3 _138 = _124.xyz;
    float3 _140 = _137.xyz;
    float _141 = _137.w;
    float3 _142 = _140 * _141;
    float3 _148 = _141.xxx;
    float _150 = 1.0f - _141;
    float _159 = min(1.0f, 1.0f - ((1.0f - _136) * _150));
    float4 _163 = float4(lerp(lerp(((_138 * _136) + _142) / ((_136 + _141) + 0.00999999977648258209228515625f).xxx, _140, _148), lerp((_138 * _150) + _142, _140, _148), _136.xxx), _159);
    float4 _233;
    if (!(cminimap_blending_pixel_cb_use_royale_data != 0u))
    {
        float _172 = _83.z * 2.0f;
        float _175 = _159 * clamp(1.0f - _172, 0.0f, 1.0f);
        float4 _176 = _163;
        _176.w = _175;
        float _181 = (_83.w - 1.0f) + _172;
        float _189;
        if (_181 > 0.9900000095367431640625f)
        {
            _189 = 0.0f;
        }
        else
        {
            _189 = pow(clamp(_181, 0.0f, 1.0f), 2.0f) * 0.800000011920928955078125f;
        }
        float3 _207 = (_176.xyz * _175).xyz + (float4(pow(clamp(((3.0f * _189) * _189) - (((2.0f * _189) * _189) * _189), 0.0f, 1.0f).xxx, float3(1.1018698215484619140625f, 2.7502377033233642578125f, 19.5606479644775390625f)), _72).xyz * _101).xyz;
        _233 = float4(_207.x, _207.y, _207.z, _176.w);
    }
    else
    {
        float3 _210 = _163.xyz * _159;
        float _212 = _83.w;
        float4 _232;
        if (_212 > 0.0f)
        {
            _232 = lerp(float4(_210.x, _210.y, _210.z, _163.w), float4(0.0588235296308994293212890625f, 0.6235294342041015625f, 1.0f, 1.0f), ((clamp(_212, 0.0f, 1.0f) * 0.5f) * _101).xxxx);
        }
        else
        {
            float _222 = _83.z;
            float4 _231;
            if (_222 > 0.0f)
            {
                _231 = lerp(float4(_210.x, _210.y, _210.z, _163.w), float4(1.0f, 0.13725490868091583251953125f, 0.0f, 1.0f), ((clamp(_222, 0.0f, 1.0f) * 0.5f) * _101).xxxx);
            }
            else
            {
                _231 = float4(_210.x, _210.y, _210.z, _163.w);
            }
            _232 = _231;
        }
        _233 = _232;
    }
    out_var_SV_TARGET = float4(clamp((pow(clamp(_233.xyz, 0.0f.xxx, 1.0f.xxx), 1.0499999523162841796875f.xxx) - 0.001000000047497451305389404296875f.xxx) * 1.00100100040435791015625f.xxx, 0.0f.xxx, 1.0f.xxx) * cminimap_blending_pixel_cb_sdr_scale, _233.w);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    if (!RENODX_UI_TOGGLE) discard;
    gl_FragCoord = stage_input.gl_FragCoord;
    gl_FragCoord.w = 1.0 / gl_FragCoord.w;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_var_SV_TARGET = out_var_SV_TARGET;
    return stage_output;
}
