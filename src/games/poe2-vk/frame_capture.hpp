#pragma once

#include <include/reshade.hpp>

namespace frame_capture {

// Global handles
inline reshade::api::resource g_texture_sr = {};
inline reshade::api::resource_view g_texture_srv = {};

// Thread-local variables to track the active Vulkan render target and its view
inline thread_local reshade::api::resource g_active_thread_rt = {};
inline thread_local reshade::api::resource_view g_active_thread_rtv = {};

inline void CopyFrame(reshade::api::command_list* cmd_list) {
  reshade::api::resource src_rt = g_active_thread_rt;
  if (g_texture_sr == 0 || src_rt == 0)
    return;

  // Transition source into copy source
  cmd_list->barrier(
      src_rt,
      reshade::api::resource_usage::shader_resource,
      reshade::api::resource_usage::copy_source);

  // Transition destination into copy dest
  cmd_list->barrier(
      g_texture_sr,
      reshade::api::resource_usage::shader_resource,
      reshade::api::resource_usage::copy_dest);

  // Copy current frame buffer into persistent texture
  cmd_list->copy_resource(src_rt, g_texture_sr);

  // Restore source for continued shader sampling
  cmd_list->barrier(
      src_rt,
      reshade::api::resource_usage::copy_source,
      reshade::api::resource_usage::shader_resource);

  // Make destination readable by later shaders
  cmd_list->barrier(
      g_texture_sr,
      reshade::api::resource_usage::copy_dest,
      reshade::api::resource_usage::shader_resource);
}

inline void ClearFrame(reshade::api::command_list* cmd_list) {
  reshade::api::resource src_rt = g_active_thread_rt;
  reshade::api::resource_view src_rtv = g_active_thread_rtv;
  if (src_rt == 0 || src_rtv == 0)
    return;

  // Transition active render target to render_target state to allow clearing
  cmd_list->barrier(
      src_rt,
      reshade::api::resource_usage::shader_resource,
      reshade::api::resource_usage::render_target);

  // Clear active frame to transparent black (0, 0, 0, 0)
  const float clear_color[4] = {0.0f, 0.0f, 0.0f, 0.0f};
  cmd_list->clear_render_target_view(src_rtv, clear_color);

  // Transition active render target back to shader_resource
  //cmd_list->barrier(
  //    src_rt,
  //    reshade::api::resource_usage::render_target,
  //    reshade::api::resource_usage::shader_resource);
}

inline void OnInitSwapchain(reshade::api::swapchain* swapchain) {
  reshade::api::device* device = swapchain->get_device();
  reshade::api::resource backbuffer = swapchain->get_back_buffer(0);
  reshade::api::resource_desc backbuffer_desc = device->get_resource_desc(backbuffer);

  reshade::api::resource_desc desc = {};
  desc.type = reshade::api::resource_type::texture_2d;
  desc.texture.width = backbuffer_desc.texture.width;
  desc.texture.height = backbuffer_desc.texture.height;
  desc.texture.depth_or_layers = 1;
  desc.texture.levels = 1;
  desc.texture.format = reshade::api::format::r16g16b16a16_float;
  desc.texture.samples = 1;
  desc.heap = reshade::api::memory_heap::gpu_only;
  desc.usage = reshade::api::resource_usage::copy_dest | reshade::api::resource_usage::shader_resource;

  if (device->create_resource(desc, nullptr, reshade::api::resource_usage::undefined, &g_texture_sr)) {
    device->create_resource_view(
        g_texture_sr,
        reshade::api::resource_usage::shader_resource,
        reshade::api::resource_view_desc(reshade::api::format::r16g16b16a16_float),
        &g_texture_srv);
  }
}

inline void OnDestroySwapchain(reshade::api::swapchain* swapchain) {
  reshade::api::device* device = swapchain->get_device();

  if (g_texture_srv != 0) {
    device->destroy_resource_view(g_texture_srv);
    g_texture_srv = {};
  }
  if (g_texture_sr != 0) {
    device->destroy_resource(g_texture_sr);
    g_texture_sr = {};
  }
}

// Track render target attachments and their views
inline void OnBeginRenderPass(
    reshade::api::command_list* cmd_list,
    uint32_t count,
    const reshade::api::render_pass_render_target_desc* rts,
    const reshade::api::render_pass_depth_stencil_desc* ds) {
  if (count > 0 && rts[0].view.handle != 0) {
    reshade::api::device* device = cmd_list->get_device();
    g_active_thread_rt = device->get_resource_from_view(rts[0].view);
    g_active_thread_rtv = rts[0].view;
  }
}

inline void RegisterEvents() {
  reshade::register_event<reshade::addon_event::init_swapchain>(
    reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::init_swapchain>::decl>(OnInitSwapchain));
  reshade::register_event<reshade::addon_event::destroy_swapchain>(
    reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::destroy_swapchain>::decl>(OnDestroySwapchain));
  reshade::register_event<reshade::addon_event::begin_render_pass>(
    reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::begin_render_pass>::decl>(OnBeginRenderPass));
}

inline void UnregisterEvents() {
  reshade::unregister_event<reshade::addon_event::init_swapchain>(
    reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::init_swapchain>::decl>(OnInitSwapchain));
  reshade::unregister_event<reshade::addon_event::destroy_swapchain>(
    reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::destroy_swapchain>::decl>(OnDestroySwapchain));
  reshade::unregister_event<reshade::addon_event::begin_render_pass>(
    reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::begin_render_pass>::decl>(OnBeginRenderPass));
}

}  // namespace frame_capture
