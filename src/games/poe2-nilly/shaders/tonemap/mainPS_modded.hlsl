namespace mainPS_modded {

static float _197;

#include "../../shared.h"

cbuffer type_cpost_processing_desc_cb : register(b0, space9)
{
    int2 cpost_processing_desc_cb_screen_size : packoffset(c0);
    int2 cpost_processing_desc_cb_frame_size : packoffset(c0.z);
    int2 cpost_processing_desc_cb_dynamic_size : packoffset(c1);
    float2 cpost_processing_desc_cb_jitter_offset : packoffset(c1.z);
    row_major float4x4 cpost_processing_desc_cb_viewproj_matrix : packoffset(c2);
    row_major float4x4 cpost_processing_desc_cb_inv_viewproj_matrix : packoffset(c6);
    row_major float4x4 cpost_processing_desc_cb_inv_proj_matrix : packoffset(c10);
    float cpost_processing_desc_cb_time : packoffset(c14);
    float cpost_processing_desc_cb_fade_amount : packoffset(c14.y);
    float cpost_processing_desc_cb_overlay_intensity : packoffset(c14.z);
    uint cpost_processing_desc_cb_fade_enable : packoffset(c14.w);
    float4 cpost_processing_desc_cb_blur_params : packoffset(c15);
    float4 cpost_processing_desc_cb_decay_map_minmax : packoffset(c16);
    float4 cpost_processing_desc_cb_decay_map_size : packoffset(c17);
    float cpost_processing_desc_cb_decay_map_time : packoffset(c18);
    float cpost_processing_desc_cb_decay_map_type : packoffset(c18.y);
    float cpost_processing_desc_cb_creation_time : packoffset(c18.z);
    float cpost_processing_desc_cb_global_stability : packoffset(c18.w);
    float4 cpost_processing_desc_cb_stabiliser_position : packoffset(c19);
    float4 cpost_processing_desc_cb_ritual_sphere_info : packoffset(c20);
    float cpost_processing_desc_cb_ritual_sphere_ratio : packoffset(c21);
    uint cpost_processing_desc_cb_decay_enable : packoffset(c21.y);
    float cpost_processing_desc_cb_original_intensity : packoffset(c21.z);
    uint cpost_processing_desc_cb_dof_enable : packoffset(c21.w);
    float2 cpost_processing_desc_cb_dof_transition_region : packoffset(c22);
    float cpost_processing_desc_cb_dof_focus_range : packoffset(c22.z);
    float cpost_processing_desc_cb_dof_focus_distance : packoffset(c22.w);
    float cpost_processing_desc_cb_post_transform_ratio : packoffset(c23);
    float cpost_processing_desc_cb_exposure : packoffset(c23.y);
    uint cpost_processing_desc_cb_desaturation_enable : packoffset(c23.z);
    uint cpost_processing_desc_cb_vignette_enable : packoffset(c23.w);
    uint cpost_processing_desc_cb_post_transform_enable : packoffset(c24);
    float cpost_processing_desc_cb_hdr_scale : packoffset(c24.y);
    int cpost_processing_desc_cb_oetf_id : packoffset(c24.z);
    float cpost_processing_desc_cb_engine_loading_amount : packoffset(c24.w);
    float cpost_processing_desc_cb_engine_loading_time : packoffset(c25);
    float4 cpost_processing_desc_cb_azmeri_map_minmax : packoffset(c26);
    uint cpost_processing_desc_cb_azmeri_enable : packoffset(c27);
    uint cpost_processing_desc_cb_upscaled_color : packoffset(c27.y);
};

SamplerState SamplerLinearClamp : register(s1, space0);
SamplerState SamplerLinearClampNoBias : register(s9, space0);
Texture2D<float4> source_sampler : register(t0, space5);
Texture2D<float4> depth_sampler : register(t1, space5);
Texture2D<float4> bloom_sampler : register(t2, space5);
Texture2D<float4> dof_foreground_sampler : register(t3, space5);
Texture2D<float4> dof_background_sampler : register(t4, space5);
Texture2D<float4> desaturation_sampler : register(t5, space5);
Texture2D<float4> gear_loading_tex : register(t6, space5);
Texture3D<float4> desaturation_transform_sampler : register(t7, space5);
Texture3D<float4> post_transform_sampler0 : register(t8, space5);
Texture3D<float4> post_transform_sampler1 : register(t9, space5);

static float4 gl_FragCoord;
static float4 out_var_SV_TARGET;

void frag_main()
{
    float2 _203 = float2(cpost_processing_desc_cb_screen_size);
    float2 _204 = gl_FragCoord.xy / _203;
    float2 _207 = float2(cpost_processing_desc_cb_frame_size);
    float2 _208 = _203 / _207;
    float2 _215 = _204 * _208;
    float4 _221 = source_sampler.SampleLevel(SamplerLinearClamp, float4(_215, 0.0f, 0.0f).xy, 0.0f);
    float2 _224 = cpost_processing_desc_cb_jitter_offset / _207;
    float2 _227 = (_204 * (float2(cpost_processing_desc_cb_dynamic_size) / _207)) + _224;
    bool _247;
    if (!(!(cpost_processing_desc_cb_decay_enable != 0u)))
    {
        _247 = !(cpost_processing_desc_cb_decay_map_time > 0.0f);
    }
    else
    {
        _247 = true;
    }
    float4 _306;
    [branch]
    if (_247)
    {
        float4 _304;
        if (length(cpost_processing_desc_cb_blur_params.xy) > 0.001000000047497451305389404296875f)
        {
            float2 _259 = _204 - 0.5f.xx;
            float2 _260 = normalize(_259);
            float2 _269 = (_260 * cpost_processing_desc_cb_blur_params.x) + (float2(-_260.y, _260.x) * cpost_processing_desc_cb_blur_params.y);
            float _271 = pow(length(_259), cpost_processing_desc_cb_blur_params.z);
            float _275 = frac(sin(dot(_204, float2(12.98980045318603515625f, 78.233001708984375f))) * 43758.546875f);
            float4 _277;
            float4 _280;
            _277 = 0.0f.xxxx;
            _280 = 0.0f.xxxx;
            for (int _282 = 0; _282 < 2; )
            {
                float _288 = (float(_282) + _275) * 0.5f;
                float4 _290 = lerp(float4(1.0f, 1.0f, 0.0f, 1.0f), float4(0.0f, 1.0f, 1.0f, 1.0f), _288.xxxx);
                _277 += _290;
                _280 += (source_sampler.SampleLevel(SamplerLinearClamp, float4((_204 - (((_269 * _271) * _288) * 0.100000001490116119384765625f)) * _208, 0.0f, 0.0f).xy, 0.0f) * _290);
                _282++;
                continue;
            }
            _304 = _280 / _277;
        }
        else
        {
            _304 = _221;
        }
        float4 _305 = _304;
        _305.w = 1.0f;
        _306 = _305;
    }
    else
    {
        _306 = _221;
    }
    float4 _371;
    [branch]
    if (cpost_processing_desc_cb_dof_enable != 0u)
    {
        float4 _323 = mul(float4((_204.x * 2.0f) - 1.0f, ((1.0f - _204.y) * 2.0f) - 1.0f, depth_sampler.SampleLevel(SamplerLinearClamp, float4(_227, 0.0f, 0.0f).xy, 0.0f).x, 1.0f), cpost_processing_desc_cb_inv_proj_matrix);
        float _328 = abs((_323 / _323.w.xxxx).z);
        float2 _333 = float4(_215 + _224, 0.0f, 0.0f).xy;
        float3 _356 = _306.xyz * 9.9999997473787516355514526367188e-05f;
        _371 = float4(lerp(lerp(_356 + dof_background_sampler.SampleLevel(SamplerLinearClamp, _333, 0.0f).xyz, _306.xyz, smoothstep(0.0f, 1.0f, 1.0f - clamp((_328 - (cpost_processing_desc_cb_dof_focus_distance + cpost_processing_desc_cb_dof_focus_range)) / cpost_processing_desc_cb_dof_transition_region.y, 0.0f, 1.0f)).xxx), _356 + dof_foreground_sampler.SampleLevel(SamplerLinearClamp, _333, 0.0f).xyz, smoothstep(0.0f, 1.0f, clamp((cpost_processing_desc_cb_dof_focus_distance - _328) / cpost_processing_desc_cb_dof_transition_region.x, 0.0f, 1.0f)).xxx), 1.0f);
    }
    else
    {
        _371 = _306;
    }
    float _374 = _204.x;
    float3 _390 = ((_371.xyz * cpost_processing_desc_cb_original_intensity) + bloom_sampler.SampleLevel(SamplerLinearClampNoBias, float4(_374, _204.y, 0.0f, 0.0f).xy, 0.0f).xyz).xyz * max(1.0f, cpost_processing_desc_cb_exposure);
    float4 _391 = float4(_390.x, _390.y, _390.z, _371.w);
    float4 _418;
    do
    {
        if (cpost_processing_desc_cb_desaturation_enable != 0u)
        {
            float4 _412 = desaturation_transform_sampler.SampleLevel(SamplerLinearClamp, float4(pow(clamp(_390.xyz, 0.0f.xxx, 1.0f.xxx), 0.4545454680919647216796875f.xxx), 0.0f).xyz, 0.0f);
            _418 = lerp(_391, float4(_412.x, _412.y, _412.z, _371.w), clamp(desaturation_sampler.Sample(SamplerLinearClamp, _227).x, 0.0f, 1.0f).xxxx);
            break;
        }
        _418 = _391;
        break;
    } while(false);
    float4 _454;
    if (cpost_processing_desc_cb_post_transform_enable != 0u)
    {
        float _429 = max(max(_418.x, _418.y), max(_418.z, 1.0f));
        float3 _440 = float4(pow(clamp(_418.xyz / _429.xxx, 0.0f.xxx, 1.0f.xxx), 0.4545454680919647216796875f.xxx), 0.0f).xyz;
        float3 _452 = lerp(post_transform_sampler0.SampleLevel(SamplerLinearClamp, _440, 0.0f).xyz, post_transform_sampler1.SampleLevel(SamplerLinearClamp, _440, 0.0f).xyz, cpost_processing_desc_cb_post_transform_ratio.xxx) * _429;
        _454 = float4(_452.x, _452.y, _452.z, _418.w);
    }
    else
    {
        _454 = _418;
    }
    float4 _468 = float4(_454.xyz * lerp(pow(1.0f - pow(length(_204 - 0.5f.xx) * 1.41421353816986083984375f, 2.0f), 1.0f), 1.0f, 0.1500000059604644775390625f), _454.w);
    bool _489;
    do
    {
        if (cpost_processing_desc_cb_oetf_id == 0)
        {
            _489 = false;
            break;
        }
        else
        {
            if (cpost_processing_desc_cb_oetf_id == 1)
            {
                _489 = true;
                break;
            }
            else
            {
                if (cpost_processing_desc_cb_oetf_id == 2)
                {
                    _489 = true;
                    break;
                }
                else
                {
                    if (cpost_processing_desc_cb_oetf_id == 3)
                    {
                        _489 = false;
                        break;
                    }
                    else
                    {
                        _489 = false;
                        break;
                    }
                    break; // unreachable workaround
                }
                break; // unreachable workaround
            }
            break; // unreachable workaround
        }
        break; // unreachable workaround
    } while(false);
    float4 _499;
    if (_489)
    {
        float4 x = _468;
        //float3 _493 = pow(_468.xyz, 1.39999997615814208984375f.xxx);
        //float3 _497 = clamp(_493 / ((_493 * 0.1853885948657989501953125f) + 0.81461131572723388671875f.xxx), 0.0f.xxx, 1.0f.xxx);

        float contrast = RENODX_LOTTES_CONTRAST; // contrast
        float shoulder = RENODX_LOTTES_SHOULDER;
        float hdrMax = 1.0f;
        float midIn = RENODX_LOTTES_MID_IN;
        float midOut = RENODX_LOTTES_MID_OUT;

        float b = -((-pow(midIn, contrast) + (midOut * (pow(hdrMax, contrast * shoulder) * pow(midIn, contrast) - pow(hdrMax, contrast) * pow(midIn, contrast * shoulder) * midOut)) / (pow(hdrMax, contrast * shoulder) * midOut - pow(midIn, contrast * shoulder) * midOut)) / (pow(midIn, contrast * shoulder) * midOut));
        float c = (pow(hdrMax, contrast * shoulder) * pow(midIn, contrast) - pow(hdrMax, contrast) * pow(midIn, contrast * shoulder) * midOut) / (pow(hdrMax, contrast * shoulder) * midOut - pow(midIn, contrast * shoulder) * midOut);

        float3 z = pow(x.xyz, contrast);
        z = saturate(z / (pow(x.xyz, contrast * shoulder) * b + c));
        _499 = float4(z, x.w);
    }
    else
    {
        _499 = _468;
    }
    float4 _508;
    if (cpost_processing_desc_cb_fade_enable != 0u)
    {
        _508 = _499 * cpost_processing_desc_cb_fade_amount;
    }
    else
    {
        _508 = _499;
    }
    float4 _2778;
    do
    {
        [branch]
        if (cpost_processing_desc_cb_engine_loading_amount < 9.9999997473787516355514526367188e-06f)
        {
            _2778 = _508;
            break;
        }
        float2 _518 = ((_204 * 2.0f) - 1.0f.xx) * 1.7999999523162841796875f;
        float2 _525 = (_518 * 1.0f) + ((float2(0.699999988079071044921875f, -1.0f) * (cpost_processing_desc_cb_time * 1.2999999523162841796875f)) * 1.0f);
        float2 _527;
        float _534;
        _527 = 0.0f.xx;
        _534 = 0.0f;
        float _530 = 1.0f;
        float _532 = 1.0f;
        uint _536 = 0u;
        for (; _536 < 2u; )
        {
            uint3 _543 = (asuint(float3(_532, _530, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _544 = _543.y;
            uint _545 = _543.z;
            uint _548 = _543.x + (_544 * _545);
            uint _550 = _544 + (_545 * _548);
            uint3 _553 = uint3(_548, _550, _545 + (_548 * _550));
            uint3 _555 = _553 ^ (_553 >> uint3(16u, 16u, 16u));
            uint _556 = _555.y;
            uint _557 = _555.z;
            uint _560 = _555.x + (_556 * _557);
            uint _562 = _556 + (_557 * _560);
            float2 _528 = _527 + (float3(_197, clamp(asfloat((_562 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_557 + (_560 * _562)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz * 10.0f);
            float2 _583 = ((_525 * _530) + ((float2(0.699999988079071044921875f, -1.0f) * (cpost_processing_desc_cb_time * 0.20000000298023223876953125f)) * 1.0f)) + _528;
            float2 _585 = smoothstep(0.0f.xx, 1.0f.xx, frac(_583));
            float2 _586 = floor(_583);
            uint3 _595 = (asuint(float3(_586, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _596 = _595.y;
            uint _597 = _595.z;
            uint _600 = _595.x + (_596 * _597);
            uint _602 = _596 + (_597 * _600);
            uint3 _605 = uint3(_600, _602, _597 + (_600 * _602));
            uint3 _607 = _605 ^ (_605 >> uint3(16u, 16u, 16u));
            uint3 _623 = (asuint(float3(_586 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _624 = _623.y;
            uint _625 = _623.z;
            uint _628 = _623.x + (_624 * _625);
            uint _630 = _624 + (_625 * _628);
            uint3 _633 = uint3(_628, _630, _625 + (_628 * _630));
            uint3 _635 = _633 ^ (_633 >> uint3(16u, 16u, 16u));
            uint3 _651 = (asuint(float3(_586 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _652 = _651.y;
            uint _653 = _651.z;
            uint _656 = _651.x + (_652 * _653);
            uint _658 = _652 + (_653 * _656);
            uint3 _661 = uint3(_656, _658, _653 + (_656 * _658));
            uint3 _663 = _661 ^ (_661 >> uint3(16u, 16u, 16u));
            uint3 _679 = (asuint(float3(_586 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _680 = _679.y;
            uint _681 = _679.z;
            uint _684 = _679.x + (_680 * _681);
            uint _686 = _680 + (_681 * _684);
            uint3 _689 = uint3(_684, _686, _681 + (_684 * _686));
            uint3 _691 = _689 ^ (_689 >> uint3(16u, 16u, 16u));
            float _702 = _585.y;
            float _707 = lerp(lerp(clamp(asfloat(((_607.x + (_607.y * _607.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_635.x + (_635.y * _635.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), _702), lerp(clamp(asfloat(((_663.x + (_663.y * _663.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_691.x + (_691.y * _691.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), _702), _585.x) * _532;
            _527 = _528;
            _530 *= 1.7000000476837158203125f;
            _532 *= 0.699999988079071044921875f;
            _534 += _707;
            _536++;
            continue;
        }
        float _711 = _518.y;
        float _718 = cpost_processing_desc_cb_engine_loading_time - 4.0f;
        float _723 = ((_534 * 0.300000011920928955078125f) / max(1.0000000116860974230803549289703e-07f, 0.5099999904632568359375f)) * (pow(max(0.0f, 0.75f - smoothstep(-0.5f, 2.0f, _711)), 2.5f) * smoothstep(6.0f, 20.0f, _718 * (2.0f - _711)));
        float2 _731 = (_518 * 4.0f) + ((float2(0.699999988079071044921875f, -1.0f) * (cpost_processing_desc_cb_time * 0.5f)) * 1.0f);
        float2 _733;
        float _740;
        _733 = 0.0f.xx;
        _740 = 0.0f;
        float _736 = 1.0f;
        float _738 = 1.0f;
        uint _742 = 0u;
        for (; _742 < 3u; )
        {
            uint3 _749 = (asuint(float3(_738, _736, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _750 = _749.y;
            uint _751 = _749.z;
            uint _754 = _749.x + (_750 * _751);
            uint _756 = _750 + (_751 * _754);
            uint3 _759 = uint3(_754, _756, _751 + (_754 * _756));
            uint3 _761 = _759 ^ (_759 >> uint3(16u, 16u, 16u));
            uint _762 = _761.y;
            uint _763 = _761.z;
            uint _766 = _761.x + (_762 * _763);
            uint _768 = _762 + (_763 * _766);
            float2 _734 = _733 + (float3(_197, clamp(asfloat((_768 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_763 + (_766 * _768)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz * 10.0f);
            float2 _789 = ((_731 * _736) + ((float2(0.699999988079071044921875f, -1.0f) * (cpost_processing_desc_cb_time * 0.20000000298023223876953125f)) * 1.0f)) + _734;
            float2 _791 = smoothstep(0.0f.xx, 1.0f.xx, frac(_789));
            float2 _792 = floor(_789);
            uint3 _801 = (asuint(float3(_792, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _802 = _801.y;
            uint _803 = _801.z;
            uint _806 = _801.x + (_802 * _803);
            uint _808 = _802 + (_803 * _806);
            uint3 _811 = uint3(_806, _808, _803 + (_806 * _808));
            uint3 _813 = _811 ^ (_811 >> uint3(16u, 16u, 16u));
            uint3 _829 = (asuint(float3(_792 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _830 = _829.y;
            uint _831 = _829.z;
            uint _834 = _829.x + (_830 * _831);
            uint _836 = _830 + (_831 * _834);
            uint3 _839 = uint3(_834, _836, _831 + (_834 * _836));
            uint3 _841 = _839 ^ (_839 >> uint3(16u, 16u, 16u));
            uint3 _857 = (asuint(float3(_792 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _858 = _857.y;
            uint _859 = _857.z;
            uint _862 = _857.x + (_858 * _859);
            uint _864 = _858 + (_859 * _862);
            uint3 _867 = uint3(_862, _864, _859 + (_862 * _864));
            uint3 _869 = _867 ^ (_867 >> uint3(16u, 16u, 16u));
            uint3 _885 = (asuint(float3(_792 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _886 = _885.y;
            uint _887 = _885.z;
            uint _890 = _885.x + (_886 * _887);
            uint _892 = _886 + (_887 * _890);
            uint3 _895 = uint3(_890, _892, _887 + (_890 * _892));
            uint3 _897 = _895 ^ (_895 >> uint3(16u, 16u, 16u));
            float _908 = _791.y;
            float _913 = lerp(lerp(clamp(asfloat(((_813.x + (_813.y * _813.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_841.x + (_841.y * _841.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), _908), lerp(clamp(asfloat(((_869.x + (_869.y * _869.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_897.x + (_897.y * _897.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), _908), _791.x) * _738;
            _733 = _734;
            _736 *= 1.7999999523162841796875f;
            _738 *= 0.5f;
            _740 += _913;
            _742++;
            continue;
        }
        float4 _924 = float4((((float3(1.0f, 0.20000000298023223876953125f, 0.100000001490116119384765625f) * _723) * 0.1500000059604644775390625f) * 0.300000011920928955078125f) * (pow((_740 * 0.5f) / max(1.0000000116860974230803549289703e-07f, 0.875f), 2.0f) * 1.5f), _723) * cpost_processing_desc_cb_engine_loading_amount;
        float _927 = clamp(1.0f + _924.w, 0.0f, 1.0f);
        float2 _932 = _518 * 0.800000011920928955078125f;
        float2 _934 = smoothstep(0.0f.xx, 1.0f.xx, frac(_932));
        float2 _935 = floor(_932);
        uint3 _944 = (asuint(float3(_935, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
        uint _945 = _944.y;
        uint _946 = _944.z;
        uint _949 = _944.x + (_945 * _946);
        uint _951 = _945 + (_946 * _949);
        uint3 _954 = uint3(_949, _951, _946 + (_949 * _951));
        uint3 _956 = _954 ^ (_954 >> uint3(16u, 16u, 16u));
        uint3 _972 = (asuint(float3(_935 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
        uint _973 = _972.y;
        uint _974 = _972.z;
        uint _977 = _972.x + (_973 * _974);
        uint _979 = _973 + (_974 * _977);
        uint3 _982 = uint3(_977, _979, _974 + (_977 * _979));
        uint3 _984 = _982 ^ (_982 >> uint3(16u, 16u, 16u));
        uint3 _1000 = (asuint(float3(_935 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
        uint _1001 = _1000.y;
        uint _1002 = _1000.z;
        uint _1005 = _1000.x + (_1001 * _1002);
        uint _1007 = _1001 + (_1002 * _1005);
        uint3 _1010 = uint3(_1005, _1007, _1002 + (_1005 * _1007));
        uint3 _1012 = _1010 ^ (_1010 >> uint3(16u, 16u, 16u));
        uint3 _1028 = (asuint(float3(_935 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
        uint _1029 = _1028.y;
        uint _1030 = _1028.z;
        uint _1033 = _1028.x + (_1029 * _1030);
        uint _1035 = _1029 + (_1030 * _1033);
        uint3 _1038 = uint3(_1033, _1035, _1030 + (_1033 * _1035));
        uint3 _1040 = _1038 ^ (_1038 >> uint3(16u, 16u, 16u));
        float _1051 = _934.y;
        float _1056 = lerp(-5.5f, -4.5f, lerp(lerp(clamp(asfloat(((_956.x + (_956.y * _956.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_984.x + (_984.y * _984.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), _1051), lerp(clamp(asfloat(((_1012.x + (_1012.y * _1012.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1040.x + (_1040.y * _1040.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), _1051), _934.x));
        float2 _1061;
        float4 _1065;
        _1061 = float2(0.5226194858551025390625f, 8.81068325042724609375f);
        _1065 = 0.0f.xxxx;
        float _1058 = 0.730000019073486328125f;
        float _1063 = 1.15999996662139892578125f;
        uint _1067 = 0u;
        for (; _1067 < 4u; )
        {
            float2 _1071 = _518 * _1063;
            float2 _1073 = (_1071 * 2.0f) + 0.5f.xx;
            float2 _1075 = smoothstep(0.0f.xx, 1.0f.xx, frac(_1073));
            float2 _1076 = floor(_1073);
            uint3 _1085 = (asuint(float3(_1076, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1086 = _1085.y;
            uint _1087 = _1085.z;
            uint _1090 = _1085.x + (_1086 * _1087);
            uint _1092 = _1086 + (_1087 * _1090);
            uint3 _1095 = uint3(_1090, _1092, _1087 + (_1090 * _1092));
            uint3 _1097 = _1095 ^ (_1095 >> uint3(16u, 16u, 16u));
            uint _1098 = _1097.y;
            uint _1099 = _1097.z;
            uint _1102 = _1097.x + (_1098 * _1099);
            uint _1104 = _1098 + (_1099 * _1102);
            uint3 _1124 = (asuint(float3(_1076 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1125 = _1124.y;
            uint _1126 = _1124.z;
            uint _1129 = _1124.x + (_1125 * _1126);
            uint _1131 = _1125 + (_1126 * _1129);
            uint3 _1134 = uint3(_1129, _1131, _1126 + (_1129 * _1131));
            uint3 _1136 = _1134 ^ (_1134 >> uint3(16u, 16u, 16u));
            uint _1137 = _1136.y;
            uint _1138 = _1136.z;
            uint _1141 = _1136.x + (_1137 * _1138);
            uint _1143 = _1137 + (_1138 * _1141);
            uint3 _1163 = (asuint(float3(_1076 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1164 = _1163.y;
            uint _1165 = _1163.z;
            uint _1168 = _1163.x + (_1164 * _1165);
            uint _1170 = _1164 + (_1165 * _1168);
            uint3 _1173 = uint3(_1168, _1170, _1165 + (_1168 * _1170));
            uint3 _1175 = _1173 ^ (_1173 >> uint3(16u, 16u, 16u));
            uint _1176 = _1175.y;
            uint _1177 = _1175.z;
            uint _1180 = _1175.x + (_1176 * _1177);
            uint _1182 = _1176 + (_1177 * _1180);
            uint3 _1202 = (asuint(float3(_1076 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1203 = _1202.y;
            uint _1204 = _1202.z;
            uint _1207 = _1202.x + (_1203 * _1204);
            uint _1209 = _1203 + (_1204 * _1207);
            uint3 _1212 = uint3(_1207, _1209, _1204 + (_1207 * _1209));
            uint3 _1214 = _1212 ^ (_1212 >> uint3(16u, 16u, 16u));
            uint _1215 = _1214.y;
            uint _1216 = _1214.z;
            uint _1219 = _1214.x + (_1215 * _1216);
            uint _1221 = _1215 + (_1216 * _1219);
            float2 _1237 = _1075.y.xx;
            float2 _1243 = lerp(lerp(float3(_197, clamp(asfloat((_1104 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1099 + (_1102 * _1104)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_1143 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1138 + (_1141 * _1143)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _1237), lerp(float3(_197, clamp(asfloat((_1182 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1177 + (_1180 * _1182)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_1221 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1216 + (_1219 * _1221)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _1237), _1075.x.xx) - 0.5f.xx;
            float2 _1247 = _1071 + ((float2(0.699999988079071044921875f, -1.0f) * _718) * 1.0f);
            float2 _1249 = (_1247 + _1061) + (_1243 * 0.1500000059604644775390625f);
            float2 _1250 = floor(_1249);
            uint3 _1257 = (asuint(float3(_1250, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1258 = _1257.y;
            uint _1259 = _1257.z;
            uint _1262 = _1257.x + (_1258 * _1259);
            uint _1264 = _1258 + (_1259 * _1262);
            uint3 _1267 = uint3(_1262, _1264, _1259 + (_1262 * _1264));
            uint3 _1269 = _1267 ^ (_1267 >> uint3(16u, 16u, 16u));
            uint _1270 = _1269.y;
            uint _1271 = _1269.z;
            uint _1274 = _1269.x + (_1270 * _1271);
            uint _1276 = _1270 + (_1271 * _1274);
            float _1283 = clamp(asfloat((_1274 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f);
            float _1295 = _1283 - 0.5f;
            float _1297 = ((cpost_processing_desc_cb_time * 1.5f) * _1295) * 2.0f;
            float2 _1299 = float3(_1283, clamp(asfloat((_1276 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1271 + (_1274 * _1276)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz - 0.5f.xx;
            float _1300 = sin(_1297);
            float _1301 = cos(_1297);
            float2 _1311 = _1249 * 2.0f;
            float2 _1313 = smoothstep(0.0f.xx, 1.0f.xx, frac(_1311));
            float2 _1314 = floor(_1311);
            uint3 _1323 = (asuint(float3(_1314, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1324 = _1323.y;
            uint _1325 = _1323.z;
            uint _1328 = _1323.x + (_1324 * _1325);
            uint _1330 = _1324 + (_1325 * _1328);
            uint3 _1333 = uint3(_1328, _1330, _1325 + (_1328 * _1330));
            uint3 _1335 = _1333 ^ (_1333 >> uint3(16u, 16u, 16u));
            uint _1336 = _1335.y;
            uint _1337 = _1335.z;
            uint _1340 = _1335.x + (_1336 * _1337);
            uint _1342 = _1336 + (_1337 * _1340);
            uint3 _1362 = (asuint(float3(_1314 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1363 = _1362.y;
            uint _1364 = _1362.z;
            uint _1367 = _1362.x + (_1363 * _1364);
            uint _1369 = _1363 + (_1364 * _1367);
            uint3 _1372 = uint3(_1367, _1369, _1364 + (_1367 * _1369));
            uint3 _1374 = _1372 ^ (_1372 >> uint3(16u, 16u, 16u));
            uint _1375 = _1374.y;
            uint _1376 = _1374.z;
            uint _1379 = _1374.x + (_1375 * _1376);
            uint _1381 = _1375 + (_1376 * _1379);
            uint3 _1401 = (asuint(float3(_1314 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1402 = _1401.y;
            uint _1403 = _1401.z;
            uint _1406 = _1401.x + (_1402 * _1403);
            uint _1408 = _1402 + (_1403 * _1406);
            uint3 _1411 = uint3(_1406, _1408, _1403 + (_1406 * _1408));
            uint3 _1413 = _1411 ^ (_1411 >> uint3(16u, 16u, 16u));
            uint _1414 = _1413.y;
            uint _1415 = _1413.z;
            uint _1418 = _1413.x + (_1414 * _1415);
            uint _1420 = _1414 + (_1415 * _1418);
            uint3 _1440 = (asuint(float3(_1314 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1441 = _1440.y;
            uint _1442 = _1440.z;
            uint _1445 = _1440.x + (_1441 * _1442);
            uint _1447 = _1441 + (_1442 * _1445);
            uint3 _1450 = uint3(_1445, _1447, _1442 + (_1445 * _1447));
            uint3 _1452 = _1450 ^ (_1450 >> uint3(16u, 16u, 16u));
            uint _1453 = _1452.y;
            uint _1454 = _1452.z;
            uint _1457 = _1452.x + (_1453 * _1454);
            uint _1459 = _1453 + (_1454 * _1457);
            float2 _1475 = _1313.y.xx;
            float2 _1481 = lerp(lerp(float3(_197, clamp(asfloat((_1342 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1337 + (_1340 * _1342)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_1381 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1376 + (_1379 * _1381)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _1475), lerp(float3(_197, clamp(asfloat((_1420 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1415 + (_1418 * _1420)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_1459 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1454 + (_1457 * _1459)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _1475), _1313.x.xx) - 0.5f.xx;
            float2 _1486 = (_1249 * 3.0f) + cpost_processing_desc_cb_time.xx;
            float2 _1488 = smoothstep(0.0f.xx, 1.0f.xx, frac(_1486));
            float2 _1489 = floor(_1486);
            uint3 _1498 = (asuint(float3(_1489, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1499 = _1498.y;
            uint _1500 = _1498.z;
            uint _1503 = _1498.x + (_1499 * _1500);
            uint _1505 = _1499 + (_1500 * _1503);
            uint3 _1508 = uint3(_1503, _1505, _1500 + (_1503 * _1505));
            uint3 _1510 = _1508 ^ (_1508 >> uint3(16u, 16u, 16u));
            uint _1511 = _1510.y;
            uint _1512 = _1510.z;
            uint _1515 = _1510.x + (_1511 * _1512);
            uint _1517 = _1511 + (_1512 * _1515);
            uint3 _1537 = (asuint(float3(_1489 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1538 = _1537.y;
            uint _1539 = _1537.z;
            uint _1542 = _1537.x + (_1538 * _1539);
            uint _1544 = _1538 + (_1539 * _1542);
            uint3 _1547 = uint3(_1542, _1544, _1539 + (_1542 * _1544));
            uint3 _1549 = _1547 ^ (_1547 >> uint3(16u, 16u, 16u));
            uint _1550 = _1549.y;
            uint _1551 = _1549.z;
            uint _1554 = _1549.x + (_1550 * _1551);
            uint _1556 = _1550 + (_1551 * _1554);
            uint3 _1576 = (asuint(float3(_1489 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1577 = _1576.y;
            uint _1578 = _1576.z;
            uint _1581 = _1576.x + (_1577 * _1578);
            uint _1583 = _1577 + (_1578 * _1581);
            uint3 _1586 = uint3(_1581, _1583, _1578 + (_1581 * _1583));
            uint3 _1588 = _1586 ^ (_1586 >> uint3(16u, 16u, 16u));
            uint _1589 = _1588.y;
            uint _1590 = _1588.z;
            uint _1593 = _1588.x + (_1589 * _1590);
            uint _1595 = _1589 + (_1590 * _1593);
            uint3 _1615 = (asuint(float3(_1489 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1616 = _1615.y;
            uint _1617 = _1615.z;
            uint _1620 = _1615.x + (_1616 * _1617);
            uint _1622 = _1616 + (_1617 * _1620);
            uint3 _1625 = uint3(_1620, _1622, _1617 + (_1620 * _1622));
            uint3 _1627 = _1625 ^ (_1625 >> uint3(16u, 16u, 16u));
            uint _1628 = _1627.y;
            uint _1629 = _1627.z;
            uint _1632 = _1627.x + (_1628 * _1629);
            uint _1634 = _1628 + (_1629 * _1632);
            float2 _1650 = _1488.y.xx;
            float2 _1656 = lerp(lerp(float3(_197, clamp(asfloat((_1517 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1512 + (_1515 * _1517)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_1556 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1551 + (_1554 * _1556)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _1650), lerp(float3(_197, clamp(asfloat((_1595 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1590 + (_1593 * _1595)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_1634 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1629 + (_1632 * _1634)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _1650), _1488.x.xx) - 0.5f.xx;
            float2 _1660 = mul(float2x2(float2(0.644217669963836669921875f, 0.764842212200164794921875f), float2(-0.764842212200164794921875f, 0.644217669963836669921875f)), ((_1249 + (_1481 * 0.100000001490116119384765625f)) - (_1656 * 0.070000000298023223876953125f)) - (((mul(float2x2(float2(_1300, _1301), float2(-_1301, _1300)), _1299) * 2.0f) * 0.3333333432674407958984375f.xx) + (_1250 + 0.5f.xx)));
            float2 _1661 = _1299 * float2(0.4000000059604644775390625f, 0.20000000298023223876953125f);
            float _1669 = 1.0f - smoothstep(0.000600000028498470783233642578125f, 0.0030000000260770320892333984375f, length(_1660 * (float2(2.099999904632568359375f, 1.0499999523162841796875f) + _1661)));
            float _1679 = max(0.0f, exp(length(_1660 * (float2(0.800000011920928955078125f, 0.5f) + _1661)) * (-499.999969482421875f)) - 6.1442124206223525106906890869141e-06f);
            float3 _1681 = (float3(22.75f, 2.76249980926513671875f, 0.324999988079071044921875f) * _1679) * _1679;
            float4 _1687 = float4(float3(10.0f, 2.0f, 1.25f) * _1669, clamp(_1669, 0.0f, 1.0f)) + float4(_1681, clamp(_1679, 0.0f, 1.0f));
            float _1688 = _1295 * 2.5f;
            uint3 _1698 = (asuint(float3(_1250 + 0.21400000154972076416015625f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1699 = _1698.y;
            uint _1700 = _1698.z;
            uint _1703 = _1698.x + (_1699 * _1700);
            uint _1705 = _1699 + (_1700 * _1703);
            uint3 _1708 = uint3(_1703, _1705, _1700 + (_1703 * _1705));
            uint3 _1710 = _1708 ^ (_1708 >> uint3(16u, 16u, 16u));
            float _1722 = (clamp(asfloat(((_1710.x + (_1710.y * _1710.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f) - 1.7999999523162841796875f) * 1.2999999523162841796875f;
            float _1725 = (1.0f - smoothstep(_1688, _1688 + 0.5f, _711)) * smoothstep(_1722, _1722 + 0.5f, _711);
            float _1744 = _1058 * (1.0f - ((smoothstep(0.0f, 1.0f, _723) * float(_1067)) * 0.25f));
            float4 _1745 = (float4(_1687.xyz * _1725, _1687.w * _1725) * (1.0f - smoothstep(_1056 - 1.5f, _1056, _1247.y))) * _1744;
            float _1747 = _1745.w;
            float3 _1759 = float3(_1058, _1058, 0.0f);
            uint3 _1762 = (asuint(_1759) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _1763 = _1762.y;
            uint _1764 = _1762.z;
            uint _1767 = _1762.x + (_1763 * _1764);
            uint _1769 = _1763 + (_1764 * _1767);
            uint3 _1772 = uint3(_1767, _1769, _1764 + (_1767 * _1769));
            uint3 _1774 = _1772 ^ (_1772 >> uint3(16u, 16u, 16u));
            uint _1775 = _1774.y;
            uint _1776 = _1774.z;
            uint _1779 = _1774.x + (_1775 * _1776);
            uint _1781 = _1775 + (_1776 * _1779);
            _1058 *= 0.728999912738800048828125f;
            _1061 += (float3(_197, clamp(asfloat((_1781 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_1776 + (_1779 * _1781)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz * 10.0f);
            _1063 *= 1.15762484073638916015625f;
            _1065 = float4((_1065.xyz * (1.0f - clamp(_1747, 0.0f, 1.0f))) + _1745.xyz, clamp(_1065.w + _1747, 0.0f, 1.0f));
            _1067++;
            continue;
        }
        float4 _1797 = _1065 * cpost_processing_desc_cb_engine_loading_amount;
        float _1799 = _1797.w;
        float _1806 = clamp(_927 + _1799, 0.0f, 1.0f);
        float2 _1820 = float2(1.0f, float(cpost_processing_desc_cb_frame_size.y) / float(cpost_processing_desc_cb_frame_size.x));
        float3 _1822 = float3(_374, _204.y, 0.0f);
        float _1825 = frac(cpost_processing_desc_cb_time * 0.25f) * 6.283185482025146484375f;
        float _1826 = sin(_1825);
        float _1827 = cos(_1825);
        float2 _1832 = mul(float2x2(float2(_1826, _1827), float2(-_1827, _1826)), ((_204 - float2(0.520699977874755859375f, 0.5f)) * 20.0f) * _1820);
        float _1838 = max(abs(_1832.x), abs(_1832.y)) - 0.5f;
        float4 _1850 = gear_loading_tex.Sample(SamplerLinearClamp, _1832 + 0.5f.xx);
        float _1851 = _1850.w;
        float3 _1854 = _1822;
        _1854.z = smoothstep(0.0f, 1.0f, _1851) * 0.20000000298023223876953125f;
        float2 _1858 = ddx(_204);
        float2 _1859 = ddy(_204);
        float _1860 = _1858.x;
        float _1861 = _1859.y;
        float _1863 = _1858.y;
        float _1864 = _1859.x;
        float _1866 = (_1860 * _1861) - (_1863 * _1864);
        float2 _1874 = ((abs(_1866) > 0.0f) ? _1866 : 1.0000000116860974230803549289703e-07f).xx;
        float2x3 _1878 = mul(float2x2(float2(_1861, -_1863) / _1874, float2(-_1864, _1860) / _1874), float2x3(ddx(_1854), ddy(_1854)));
        float3 _1881 = cross(_1878[0], _1878[1]);
        float3 _1885 = _1881 / max(1.0000000116860974230803549289703e-07f, length(_1881)).xxx;
        float3 _1887 = normalize(float3(0.20000000298023223876953125f, 0.800000011920928955078125f, 4.0f) - _1854);
        float3 _1889 = normalize(float3(0.5f, 0.5f, 1.0f) - _1822);
        float3 _1892 = _1850.xyz;
        float _1901 = smoothstep(0.0f, 0.5f, cpost_processing_desc_cb_engine_loading_time - 0.20000000298023223876953125f);
        float _1917 = ((-0.064000003039836883544921875f) + frac(cpost_processing_desc_cb_time * (-0.25f))) * 6.283185482025146484375f;
        float _1918 = sin(_1917);
        float _1919 = cos(_1917);
        float2 _1924 = mul(float2x2(float2(_1918, _1919), float2(-_1919, _1918)), ((_204 - float2(0.4792999923229217529296875f, 0.5f)) * 20.0f) * _1820);
        float _1930 = max(abs(_1924.x), abs(_1924.y)) - 0.5f;
        float4 _1941 = gear_loading_tex.Sample(SamplerLinearClamp, _1924 + 0.5f.xx);
        float _1942 = _1941.w;
        float3 _1945 = _1822;
        _1945.z = smoothstep(0.0f, 1.0f, _1942) * 0.20000000298023223876953125f;
        float2 _1949 = ddx(_204);
        float2 _1950 = ddy(_204);
        float _1951 = _1949.x;
        float _1952 = _1950.y;
        float _1954 = _1949.y;
        float _1955 = _1950.x;
        float _1957 = (_1951 * _1952) - (_1954 * _1955);
        float2 _1965 = ((abs(_1957) > 0.0f) ? _1957 : 1.0000000116860974230803549289703e-07f).xx;
        float2x3 _1969 = mul(float2x2(float2(_1952, -_1954) / _1965, float2(-_1955, _1951) / _1965), float2x3(ddx(_1945), ddy(_1945)));
        float3 _1972 = cross(_1969[0], _1969[1]);
        float3 _1976 = _1972 / max(1.0000000116860974230803549289703e-07f, length(_1972)).xxx;
        float3 _1978 = normalize(float3(0.20000000298023223876953125f, 0.800000011920928955078125f, 4.0f) - _1945);
        float3 _1981 = _1941.xyz;
        float4 _1999 = (((float4(0.800000011920928955078125f.xxx * ((_1892 * clamp(dot(_1885, _1887), 0.0f, 1.0f)) + (_1892 * pow(clamp(dot(_1885, normalize(_1887 + _1889)), 0.0f, 1.0f), 1.0f))), 1.0f) * _1851) * (1.0f - clamp(_1838 / max(1.0000000116860974230803549289703e-07f, length(float2(ddx(_1838), ddy(_1838)))), 0.0f, 1.0f))) * _1901) + ((((float4(0.800000011920928955078125f.xxx * ((_1981 * clamp(dot(_1976, _1978), 0.0f, 1.0f)) + (_1981 * pow(clamp(dot(_1976, normalize(_1978 + _1889)), 0.0f, 1.0f), 1.0f))), 1.0f) * _1942) * (1.0f - clamp(_1930 / max(1.0000000116860974230803549289703e-07f, length(float2(ddx(_1930), ddy(_1930)))), 0.0f, 1.0f))) * _1901) * float4(0.699999988079071044921875f, 0.699999988079071044921875f, 0.699999988079071044921875f, 1.0f));
        float _2008 = clamp(_1806 + _1999.w, 0.0f, 1.0f);
        float2 _2017;
        float4 _2021;
        _2017 = float2(9.1670284271240234375f, 8.5698833465576171875f);
        _2021 = 0.0f.xxxx;
        float _2014 = 1.0f;
        float _2019 = 1.0f;
        uint _2023 = 0u;
        for (; _2023 < 1u; )
        {
            float2 _2027 = _518 * _2019;
            float2 _2029 = (_2027 * 2.0f) + 0.5f.xx;
            float2 _2031 = smoothstep(0.0f.xx, 1.0f.xx, frac(_2029));
            float2 _2032 = floor(_2029);
            uint3 _2041 = (asuint(float3(_2032, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2042 = _2041.y;
            uint _2043 = _2041.z;
            uint _2046 = _2041.x + (_2042 * _2043);
            uint _2048 = _2042 + (_2043 * _2046);
            uint3 _2051 = uint3(_2046, _2048, _2043 + (_2046 * _2048));
            uint3 _2053 = _2051 ^ (_2051 >> uint3(16u, 16u, 16u));
            uint _2054 = _2053.y;
            uint _2055 = _2053.z;
            uint _2058 = _2053.x + (_2054 * _2055);
            uint _2060 = _2054 + (_2055 * _2058);
            uint3 _2080 = (asuint(float3(_2032 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2081 = _2080.y;
            uint _2082 = _2080.z;
            uint _2085 = _2080.x + (_2081 * _2082);
            uint _2087 = _2081 + (_2082 * _2085);
            uint3 _2090 = uint3(_2085, _2087, _2082 + (_2085 * _2087));
            uint3 _2092 = _2090 ^ (_2090 >> uint3(16u, 16u, 16u));
            uint _2093 = _2092.y;
            uint _2094 = _2092.z;
            uint _2097 = _2092.x + (_2093 * _2094);
            uint _2099 = _2093 + (_2094 * _2097);
            uint3 _2119 = (asuint(float3(_2032 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2120 = _2119.y;
            uint _2121 = _2119.z;
            uint _2124 = _2119.x + (_2120 * _2121);
            uint _2126 = _2120 + (_2121 * _2124);
            uint3 _2129 = uint3(_2124, _2126, _2121 + (_2124 * _2126));
            uint3 _2131 = _2129 ^ (_2129 >> uint3(16u, 16u, 16u));
            uint _2132 = _2131.y;
            uint _2133 = _2131.z;
            uint _2136 = _2131.x + (_2132 * _2133);
            uint _2138 = _2132 + (_2133 * _2136);
            uint3 _2158 = (asuint(float3(_2032 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2159 = _2158.y;
            uint _2160 = _2158.z;
            uint _2163 = _2158.x + (_2159 * _2160);
            uint _2165 = _2159 + (_2160 * _2163);
            uint3 _2168 = uint3(_2163, _2165, _2160 + (_2163 * _2165));
            uint3 _2170 = _2168 ^ (_2168 >> uint3(16u, 16u, 16u));
            uint _2171 = _2170.y;
            uint _2172 = _2170.z;
            uint _2175 = _2170.x + (_2171 * _2172);
            uint _2177 = _2171 + (_2172 * _2175);
            float2 _2193 = _2031.y.xx;
            float2 _2199 = lerp(lerp(float3(_197, clamp(asfloat((_2060 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2055 + (_2058 * _2060)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_2099 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2094 + (_2097 * _2099)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _2193), lerp(float3(_197, clamp(asfloat((_2138 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2133 + (_2136 * _2138)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_2177 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2172 + (_2175 * _2177)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _2193), _2031.x.xx) - 0.5f.xx;
            float2 _2203 = _2027 + ((float2(0.699999988079071044921875f, -1.0f) * _718) * 1.0f);
            float2 _2205 = (_2203 + _2017) + (_2199 * 0.1500000059604644775390625f);
            float2 _2206 = floor(_2205);
            uint3 _2213 = (asuint(float3(_2206, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2214 = _2213.y;
            uint _2215 = _2213.z;
            uint _2218 = _2213.x + (_2214 * _2215);
            uint _2220 = _2214 + (_2215 * _2218);
            uint3 _2223 = uint3(_2218, _2220, _2215 + (_2218 * _2220));
            uint3 _2225 = _2223 ^ (_2223 >> uint3(16u, 16u, 16u));
            uint _2226 = _2225.y;
            uint _2227 = _2225.z;
            uint _2230 = _2225.x + (_2226 * _2227);
            uint _2232 = _2226 + (_2227 * _2230);
            float _2239 = clamp(asfloat((_2230 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f);
            float _2251 = _2239 - 0.5f;
            float _2253 = ((cpost_processing_desc_cb_time * 1.5f) * _2251) * 2.0f;
            float2 _2255 = float3(_2239, clamp(asfloat((_2232 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2227 + (_2230 * _2232)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz - 0.5f.xx;
            float _2256 = sin(_2253);
            float _2257 = cos(_2253);
            float2 _2267 = _2205 * 2.0f;
            float2 _2269 = smoothstep(0.0f.xx, 1.0f.xx, frac(_2267));
            float2 _2270 = floor(_2267);
            uint3 _2279 = (asuint(float3(_2270, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2280 = _2279.y;
            uint _2281 = _2279.z;
            uint _2284 = _2279.x + (_2280 * _2281);
            uint _2286 = _2280 + (_2281 * _2284);
            uint3 _2289 = uint3(_2284, _2286, _2281 + (_2284 * _2286));
            uint3 _2291 = _2289 ^ (_2289 >> uint3(16u, 16u, 16u));
            uint _2292 = _2291.y;
            uint _2293 = _2291.z;
            uint _2296 = _2291.x + (_2292 * _2293);
            uint _2298 = _2292 + (_2293 * _2296);
            uint3 _2318 = (asuint(float3(_2270 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2319 = _2318.y;
            uint _2320 = _2318.z;
            uint _2323 = _2318.x + (_2319 * _2320);
            uint _2325 = _2319 + (_2320 * _2323);
            uint3 _2328 = uint3(_2323, _2325, _2320 + (_2323 * _2325));
            uint3 _2330 = _2328 ^ (_2328 >> uint3(16u, 16u, 16u));
            uint _2331 = _2330.y;
            uint _2332 = _2330.z;
            uint _2335 = _2330.x + (_2331 * _2332);
            uint _2337 = _2331 + (_2332 * _2335);
            uint3 _2357 = (asuint(float3(_2270 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2358 = _2357.y;
            uint _2359 = _2357.z;
            uint _2362 = _2357.x + (_2358 * _2359);
            uint _2364 = _2358 + (_2359 * _2362);
            uint3 _2367 = uint3(_2362, _2364, _2359 + (_2362 * _2364));
            uint3 _2369 = _2367 ^ (_2367 >> uint3(16u, 16u, 16u));
            uint _2370 = _2369.y;
            uint _2371 = _2369.z;
            uint _2374 = _2369.x + (_2370 * _2371);
            uint _2376 = _2370 + (_2371 * _2374);
            uint3 _2396 = (asuint(float3(_2270 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2397 = _2396.y;
            uint _2398 = _2396.z;
            uint _2401 = _2396.x + (_2397 * _2398);
            uint _2403 = _2397 + (_2398 * _2401);
            uint3 _2406 = uint3(_2401, _2403, _2398 + (_2401 * _2403));
            uint3 _2408 = _2406 ^ (_2406 >> uint3(16u, 16u, 16u));
            uint _2409 = _2408.y;
            uint _2410 = _2408.z;
            uint _2413 = _2408.x + (_2409 * _2410);
            uint _2415 = _2409 + (_2410 * _2413);
            float2 _2431 = _2269.y.xx;
            float2 _2437 = lerp(lerp(float3(_197, clamp(asfloat((_2298 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2293 + (_2296 * _2298)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_2337 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2332 + (_2335 * _2337)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _2431), lerp(float3(_197, clamp(asfloat((_2376 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2371 + (_2374 * _2376)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_2415 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2410 + (_2413 * _2415)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _2431), _2269.x.xx) - 0.5f.xx;
            float2 _2442 = (_2205 * 3.0f) + cpost_processing_desc_cb_time.xx;
            float2 _2444 = smoothstep(0.0f.xx, 1.0f.xx, frac(_2442));
            float2 _2445 = floor(_2442);
            uint3 _2454 = (asuint(float3(_2445, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2455 = _2454.y;
            uint _2456 = _2454.z;
            uint _2459 = _2454.x + (_2455 * _2456);
            uint _2461 = _2455 + (_2456 * _2459);
            uint3 _2464 = uint3(_2459, _2461, _2456 + (_2459 * _2461));
            uint3 _2466 = _2464 ^ (_2464 >> uint3(16u, 16u, 16u));
            uint _2467 = _2466.y;
            uint _2468 = _2466.z;
            uint _2471 = _2466.x + (_2467 * _2468);
            uint _2473 = _2467 + (_2468 * _2471);
            uint3 _2493 = (asuint(float3(_2445 + float2(0.0f, 1.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2494 = _2493.y;
            uint _2495 = _2493.z;
            uint _2498 = _2493.x + (_2494 * _2495);
            uint _2500 = _2494 + (_2495 * _2498);
            uint3 _2503 = uint3(_2498, _2500, _2495 + (_2498 * _2500));
            uint3 _2505 = _2503 ^ (_2503 >> uint3(16u, 16u, 16u));
            uint _2506 = _2505.y;
            uint _2507 = _2505.z;
            uint _2510 = _2505.x + (_2506 * _2507);
            uint _2512 = _2506 + (_2507 * _2510);
            uint3 _2532 = (asuint(float3(_2445 + float2(1.0f, 0.0f), 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2533 = _2532.y;
            uint _2534 = _2532.z;
            uint _2537 = _2532.x + (_2533 * _2534);
            uint _2539 = _2533 + (_2534 * _2537);
            uint3 _2542 = uint3(_2537, _2539, _2534 + (_2537 * _2539));
            uint3 _2544 = _2542 ^ (_2542 >> uint3(16u, 16u, 16u));
            uint _2545 = _2544.y;
            uint _2546 = _2544.z;
            uint _2549 = _2544.x + (_2545 * _2546);
            uint _2551 = _2545 + (_2546 * _2549);
            uint3 _2571 = (asuint(float3(_2445 + 1.0f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2572 = _2571.y;
            uint _2573 = _2571.z;
            uint _2576 = _2571.x + (_2572 * _2573);
            uint _2578 = _2572 + (_2573 * _2576);
            uint3 _2581 = uint3(_2576, _2578, _2573 + (_2576 * _2578));
            uint3 _2583 = _2581 ^ (_2581 >> uint3(16u, 16u, 16u));
            uint _2584 = _2583.y;
            uint _2585 = _2583.z;
            uint _2588 = _2583.x + (_2584 * _2585);
            uint _2590 = _2584 + (_2585 * _2588);
            float2 _2606 = _2444.y.xx;
            float2 _2612 = lerp(lerp(float3(_197, clamp(asfloat((_2473 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2468 + (_2471 * _2473)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_2512 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2507 + (_2510 * _2512)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _2606), lerp(float3(_197, clamp(asfloat((_2551 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2546 + (_2549 * _2551)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, float3(_197, clamp(asfloat((_2590 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2585 + (_2588 * _2590)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz, _2606), _2444.x.xx) - 0.5f.xx;
            float2 _2616 = mul(float2x2(float2(0.644217669963836669921875f, 0.764842212200164794921875f), float2(-0.764842212200164794921875f, 0.644217669963836669921875f)), ((_2205 + (_2437 * 0.100000001490116119384765625f)) - (_2612 * 0.070000000298023223876953125f)) - (((mul(float2x2(float2(_2256, _2257), float2(-_2257, _2256)), _2255) * 2.0f) * 0.3333333432674407958984375f.xx) + (_2206 + 0.5f.xx)));
            float2 _2617 = _2255 * float2(0.4000000059604644775390625f, 0.20000000298023223876953125f);
            float _2625 = 1.0f - smoothstep(0.000600000028498470783233642578125f, 0.0030000000260770320892333984375f, length(_2616 * (float2(2.099999904632568359375f, 1.0499999523162841796875f) + _2617)));
            float _2635 = max(0.0f, exp(length(_2616 * (float2(0.800000011920928955078125f, 0.5f) + _2617)) * (-499.999969482421875f)) - 6.1442124206223525106906890869141e-06f);
            float3 _2637 = (float3(22.75f, 2.76249980926513671875f, 0.324999988079071044921875f) * _2635) * _2635;
            float4 _2643 = float4(float3(10.0f, 2.0f, 1.25f) * _2625, clamp(_2625, 0.0f, 1.0f)) + float4(_2637, clamp(_2635, 0.0f, 1.0f));
            float _2644 = _2251 * 2.5f;
            uint3 _2654 = (asuint(float3(_2206 + 0.21400000154972076416015625f.xx, 0.0f)) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2655 = _2654.y;
            uint _2656 = _2654.z;
            uint _2659 = _2654.x + (_2655 * _2656);
            uint _2661 = _2655 + (_2656 * _2659);
            uint3 _2664 = uint3(_2659, _2661, _2656 + (_2659 * _2661));
            uint3 _2666 = _2664 ^ (_2664 >> uint3(16u, 16u, 16u));
            float _2678 = (clamp(asfloat(((_2666.x + (_2666.y * _2666.z)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f) - 1.7999999523162841796875f) * 1.2999999523162841796875f;
            float _2681 = (1.0f - smoothstep(_2644, _2644 + 0.5f, _711)) * smoothstep(_2678, _2678 + 0.5f, _711);
            float _2699 = _2014 * (1.0f - (smoothstep(0.0f, 1.0f, _723) * float(_2023)));
            float4 _2700 = (float4(_2643.xyz * _2681, _2643.w * _2681) * (1.0f - smoothstep(_1056 - 1.5f, _1056, _2203.y))) * _2699;
            float _2702 = _2700.w;
            float3 _2714 = float3(_2014, _2014, 0.0f);
            uint3 _2717 = (asuint(_2714) * uint3(1664525u, 1664525u, 1664525u)) + uint3(1013904223u, 1013904223u, 1013904223u);
            uint _2718 = _2717.y;
            uint _2719 = _2717.z;
            uint _2722 = _2717.x + (_2718 * _2719);
            uint _2724 = _2718 + (_2719 * _2722);
            uint3 _2727 = uint3(_2722, _2724, _2719 + (_2722 * _2724));
            uint3 _2729 = _2727 ^ (_2727 >> uint3(16u, 16u, 16u));
            uint _2730 = _2729.y;
            uint _2731 = _2729.z;
            uint _2734 = _2729.x + (_2730 * _2731);
            uint _2736 = _2730 + (_2731 * _2734);
            _2014 *= 0.809999942779541015625f;
            _2017 += (float3(_197, clamp(asfloat((_2736 >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f), clamp(asfloat(((_2731 + (_2734 * _2736)) >> 9u) | 1065353216u) - 1.0f, 0.0f, 1.0f)).yz * 10.0f);
            _2019 *= 1.10249984264373779296875f;
            _2021 = float4((_2021.xyz * (1.0f - clamp(_2702, 0.0f, 1.0f))) + _2700.xyz, clamp(_2021.w + _2702, 0.0f, 1.0f));
            _2023++;
            continue;
        }
        float4 _2752 = _2021 * cpost_processing_desc_cb_engine_loading_amount;
        float _2754 = _2752.w;
        float4 _2766 = float4((float4((float4((float4(_924.xyz, _927).xyz * (1.0f - clamp(_1799, 0.0f, 1.0f))) + _1797.xyz, _1806).xyz * (1.0f - clamp(_1999.w, 0.0f, 1.0f))) + _1999.xyz, _2008).xyz * (1.0f - clamp(_2754, 0.0f, 1.0f))) + _2752.xyz, clamp(_2008 + _2754, 0.0f, 1.0f)) * cpost_processing_desc_cb_engine_loading_amount;
        _2778 = float4((_508.xyz * (1.0f - clamp(_2766.w, 0.0f, 1.0f))) + _2766.xyz, _197);
        break;
    } while(false);
    //float4 _2779 = _2778 * 17.2124996185302734375f;
    float4 _2779 = _2778 * RENODX_WORLD_PEAK_NITS / RENODX_UI_BRIGHTNESS;
    _2779.w = _221.w;
    out_var_SV_TARGET = _2779;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    gl_FragCoord = stage_input.gl_FragCoord;
    gl_FragCoord.w = 1.0 / gl_FragCoord.w;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.out_var_SV_TARGET = out_var_SV_TARGET;
    return stage_output;
}
}