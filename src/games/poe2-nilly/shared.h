#ifndef SRC_TEMPLATE_SHARED_H_
#define SRC_TEMPLATE_SHARED_H_

// Must be 32bit aligned
// Should be 4x32
struct ShaderInjectData {
  float world_peak_nits;  // Offset 0  (4 bytes) - Default: 1000.f, Range: 48.f - 1000.f
  float ui_brightness;    // Offset 4  (4 bytes) - Default: 200.f,  Range: 48.f - 500.f
  float lottes_contrast;  // Offset 8  (4 bytes) - Default: 1.4f,   Range: 1.0f - 2.0f
  float lottes_shoulder;  // Offset 12 (4 bytes) - Default: 1.0f,   Range: 0.0f - 2.0f

  float lottes_mid_in;   // Offset 16 (4 bytes) - Default: 0.26f,  Range: 0.01f - 1.0f
  float lottes_mid_out;  // Offset 20 (4 bytes) - Default: 0.18f,  Range: 0.01f - 1.0f
  float lottes_b;        // Offset 24 (4 bytes) - Precalculated on CPU
  float vanilla;
  float ui_toggle;
};

#define RENODX_WORLD_PEAK_NITS                        shader_injection.world_peak_nits
#define RENODX_UI_BRIGHTNESS                          shader_injection.ui_brightness
#define RENODX_LOTTES_CONTRAST                        shader_injection.lottes_contrast
#define RENODX_LOTTES_SHOULDER                        shader_injection.lottes_shoulder
#define RENODX_LOTTES_MID_IN                          shader_injection.lottes_mid_in
#define RENODX_LOTTES_MID_OUT                         shader_injection.lottes_mid_out
#define RENODX_LOTTES_B                               shader_injection.lottes_b
#define RENODX_LOTTES_C                               shader_injection.lottes_c
#define RENODX_UI_TOGGLE                              shader_injection.ui_toggle
#define RENODX_VANILLA                                shader_injection.vanilla

#ifndef __cplusplus
#ifdef __SLANG__

/*
  Shaders use different push constants (depends on pipeline not shaders actually. So if a vertex shader is using
  push constants but not frag/pixel shader, then that vertex shader push constant has to be accounted for
  since they share the same pipeline)

  Anyway, here we define different offsets based on shader used
*/
#ifdef USE_TONEMAP_PUSHCONSTANTS
#define PUSH_CONSTANTS_OFFSET 0
#endif

// Fallback
#ifndef PUSH_CONSTANTS_OFFSET
#define PUSH_CONSTANTS_OFFSET 0
#endif

/*
  We need to account for the padding of the original struct
  (Aux size is 120 bytes & Setting is 8 bytes). Vulkan adjustments
  will add the correct offset when pushing constants,
  but we still need to define the proper offset
  to account for the original game/emulator push constants.

  IMPORTANT: AUX SIZE WILL BECOME 128 Bytes because alignment depends on the largest
  element within the struct. Aux Data has uvec4 which is 16 bytes, so total size will
  have to be aligned to 16. Settings largest element is 4 bytes so it aligns to 4 bytes,
  so final size will be 8. This is important for offsets and will mess up cbuffers unless
  they're manually aligned. You can use define DEBUG_LEVEL_1/DEBUG_LEVEL_2 and renodx will
  log the injection offset
  e.g. utils::constants::PushShaderInjections(layout: 0x0165a600000165a6[2], dispatch: true, resource_tag: -1, offset: 4) <- Might look different
  Offset here is 4(in float4) so it is 16

  PUSH CONSTANTS TOTAL SIZE LIMIT IS 256 BYTES! You can't add cbuffers willy nilly.
  Log should show a warning if it overflows
*/

struct PushData {
  [[vk::offset(PUSH_CONSTANTS_OFFSET)]]
  ShaderInjectData shader_injection;
};

[[vk::push_constant]]
PushData gPush;

#define shader_injection gPush.shader_injection
#else
#if ((__SHADER_TARGET_MAJOR == 5 && __SHADER_TARGET_MINOR >= 1) || __SHADER_TARGET_MAJOR >= 6)
cbuffer injected_buffer : register(b13, space50) {
#elif (__SHADER_TARGET_MAJOR < 5) || ((__SHADER_TARGET_MAJOR == 5) && (__SHADER_TARGET_MINOR < 1))
cbuffer injected_buffer : register(b13) {
#endif
  ShaderInjectData shader_injection : packoffset(c0);
}
#endif

#include "../../shaders/renodx.hlsl"

#endif

#endif  // SRC_TEMPLATE_SHARED_H_
