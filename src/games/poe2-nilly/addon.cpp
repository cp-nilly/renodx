/*
 * Copyright (C) 2024 Carlos Lopez
 * SPDX-License-Identifier: MIT
 */

#define ImTextureID ImU64

//#define DEBUG_LEVEL_0
//#define DEBUG_LEVEL_1
//#define DEBUG_LEVEL_2
#define RENODX_MODS_SWAPCHAIN_VERSION 2 // nop?

#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>

#include <embed/shaders.h>

#include "../../mods/shader.hpp"
#include "../../mods/swapchain.hpp"
#include "../../templates/settings.hpp"
#include "../../utils/settings.hpp"
#include "./shared.h"

namespace {

#include <cmath>

renodx::mods::shader::CustomShaders custom_shaders = {
  __ALL_CUSTOM_SHADERS
};

ShaderInjectData shader_injection;

renodx::utils::settings::Settings settings = {
    new renodx::utils::settings::Setting{
        .key = "WorldPeakNits",
        .binding = &shader_injection.world_peak_nits,
        .default_value = 1000.f,
        .label = "World Peak Nits",
        .section = "Tone Mapping",
        .tooltip = "Sets the peak brightness of the world in nits",
        .min = 48.f,
        .max = 4000.f,
        .is_enabled = []() { return shader_injection.vanilla == 0.f; },
    },
    new renodx::utils::settings::Setting{
        .key = "UIBrightness",
        .binding = &shader_injection.ui_brightness,
        .default_value = 200.f,
        .label = "UI Brightness",
        .section = "Tone Mapping",
        .tooltip = "Sets the brightness of UI and HUD elements",
        .min = 48.f,
        .max = 500.f,
        .is_enabled = []() { return shader_injection.vanilla == 0.f; },
    },
    new renodx::utils::settings::Setting{
        .key = "LottesContrast",
        .binding = &shader_injection.lottes_contrast,
        .default_value = 1.40f,
        .label = "Contrast",
        .section = "Tone Mapping",
        .tooltip = "Adjusts the tonemapping contrast curve.",
        .min = 1.00f,
        .max = 2.00f,
        .format = "%.2f",
        .is_enabled = []() { return shader_injection.vanilla == 0.f; },
    },
    new renodx::utils::settings::Setting{
        .key = "LottesShoulder",
        .binding = &shader_injection.lottes_shoulder,
        .default_value = 1.00f,
        .label = "Shoulder",
        .section = "Tone Mapping",
        .tooltip = "Adjusts the shoulder curve roll-off.",
        .min = 0.00f,
        .max = 2.00f,
        .format = "%.2f",
        .is_enabled = []() { return shader_injection.vanilla == 0.f; },
    },
    new renodx::utils::settings::Setting{
        .key = "LottesMidIn",
        .binding = &shader_injection.lottes_mid_in,
        .default_value = 0.26f,
        .label = "Mid In",
        .section = "Tone Mapping",
        .tooltip = "Input reference level for midtones.",
        .min = 0.01f,
        .max = 1.00f,
        .format = "%.2f",
        .is_enabled = []() { return shader_injection.vanilla == 0.f; },
    },
    new renodx::utils::settings::Setting{
        .key = "LottesMidOut",
        .binding = &shader_injection.lottes_mid_out,
        .default_value = 0.18f,
        .label = "Mid Out",
        .section = "Tone Mapping",
        .tooltip = "Output target level for midtones.",
        .min = 0.01f,
        .max = 1.00f,
        .format = "%.2f",
        .is_enabled = []() { return shader_injection.vanilla == 0.f; },
    },
    new renodx::utils::settings::Setting{
        .key = "UIToggle",
        .binding = &shader_injection.ui_toggle,
        .value_type = renodx::utils::settings::SettingValueType::BOOLEAN,
        .default_value = 1.f,
        .label = "Toggle UI",
        .section = "Toggles",
        .tooltip = "Turn on / off the ui.",
    },
    new renodx::utils::settings::Setting{
        .key = "Vanilla",
        .binding = &shader_injection.vanilla,
        .value_type = renodx::utils::settings::SettingValueType::BOOLEAN,
        .default_value = 1.f,
        .label = "Vanilla",
        .section = "Toggles",
        .tooltip = "Toggle poe2's vanilla hdr.",
    },
};

// Reset only the 6 customized sliders to their defaults
void OnPresetOff() {
  //renodx::utils::settings::UpdateSettings({
  //    {"WorldPeakNits", 1000.f},
  //    {"UIBrightness", 200.f},
  //    {"LottesContrast", 1.40f},
  //    {"LottesShoulder", 1.00f},
  //    {"LottesMidIn", 0.26f},
  //    {"LottesMidOut", 0.18f},
  //    {"UIToggle", 1.f},
  //    {"Vanilla", 0.f},
  //});
}

void OnPresent(
    reshade::api::command_queue* queue,
    reshade::api::swapchain* swapchain,
    const reshade::api::rect* source_rect,
    const reshade::api::rect* dest_rect,
    uint32_t dirty_rect_count,
    const reshade::api::rect* dirty_rects) {
  //// Calculate Lottes 'b' and 'c' parameters dynamically on the CPU
  //float contrast = shader_injection.lottes_contrast;
  //float shoulder = shader_injection.lottes_shoulder;
  //float midIn = shader_injection.lottes_mid_in;
  //float midOut = shader_injection.lottes_mid_out;

  //// Scale maximum input brightness relative to SDR reference (80 nits)
  //float hdrMax = shader_injection.world_peak_nits / shader_injection.ui_brightness;
  //if (hdrMax <= midIn) hdrMax = midIn + 0.01f;  // Prevent division by zero

  //float M1 = std::pow(midIn, contrast);
  //float M2 = std::pow(midIn, contrast * shoulder);
  //float H1 = std::pow(hdrMax, contrast * shoulder);
  //float H2 = std::pow(hdrMax, contrast);

  //float denominator = (H1 * midOut) - (M2 * midOut);
  //if (std::abs(denominator) < 1e-5f) denominator = 1e-5f;

  //// Set the precalculated values directly inside the shader injection buffer
  //shader_injection.lottes_c = ((H1 * M1) - (H2 * M2 * midOut)) / denominator;

  //float b_num = -M1 + (midOut * shader_injection.lottes_c);
  //float b_den = M2 * midOut;
  //if (std::abs(b_den) < 1e-5f) b_den = 1e-5f;

  //shader_injection.lottes_b = -(b_num / b_den);

  //float contrast = shader_injection.lottes_contrast;  // contrast
  //float shoulder = shader_injection.lottes_shoulder;
  //float hdrMax = 1.0f;
  //float midIn = shader_injection.lottes_mid_in;
  //float midOut = shader_injection.lottes_mid_out;

  //shader_injection.lottes_b = -((-pow(midIn, contrast) + (midOut * (pow(hdrMax, contrast * shoulder) * pow(midIn, contrast) - pow(hdrMax, contrast) * pow(midIn, contrast * shoulder) * midOut)) / (pow(hdrMax, contrast * shoulder) * midOut - pow(midIn, contrast * shoulder) * midOut)) / (pow(midIn, contrast * shoulder) * midOut));
  //shader_injection.lottes_c = (pow(hdrMax, contrast * shoulder) * pow(midIn, contrast) - pow(hdrMax, contrast) * pow(midIn, contrast * shoulder) * midOut) / (pow(hdrMax, contrast * shoulder) * midOut - pow(midIn, contrast * shoulder) * midOut);
}

bool initialized = false;

}  // namespace

extern "C" __declspec(dllexport) constexpr const char* NAME = "RenoDX";
extern "C" __declspec(dllexport) constexpr const char* DESCRIPTION = "RenoDX (POE2 Vulkan)";

BOOL APIENTRY DllMain(HMODULE h_module, DWORD fdw_reason, LPVOID lpv_reserved) {
  switch (fdw_reason) {
    case DLL_PROCESS_ATTACH:
      if (!reshade::register_addon(h_module)) return FALSE;

      if (!initialized) {
        renodx::mods::swapchain::ignored_device_apis = {
            reshade::api::device_api::d3d11,
            reshade::api::device_api::d3d12,
        };
        renodx::mods::swapchain::target_format = reshade::api::format::r10g10b10a2_unorm;
        renodx::mods::shader::allow_multiple_push_constants = true;
        renodx::mods::shader::minimum_constant_buffer_stages = reshade::api::shader_stage::pixel;

        renodx::mods::swapchain::use_resource_cloning = true;
        renodx::mods::swapchain::swap_chain_proxy_vertex_shader = __swap_chain_proxy_vertex_shader;
        renodx::mods::swapchain::swap_chain_proxy_pixel_shader = __swap_chain_proxy_pixel_shader;

        renodx::mods::swapchain::SetUseHDR10(true);

        shader_injection.ui_toggle = 0.f;

        initialized = true;
      }

      break;
    case DLL_PROCESS_DETACH:
      reshade::unregister_event<reshade::addon_event::present>(OnPresent);
      reshade::unregister_addon(h_module);
      break;
  }

  renodx::utils::settings::Use(fdw_reason, &settings, &OnPresetOff);
  //renodx::mods::swapchain::Use(fdw_reason, &shader_injection);
  renodx::mods::shader::Use(fdw_reason, custom_shaders, &shader_injection);

  return TRUE;
}
