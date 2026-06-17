#pragma once

#include <include/reshade.hpp>

namespace frame_capture {

inline bool g_is_hdr = false; // so toggling/starting game in sdr doesn't completely break everything

// Global handles
inline reshade::api::resource g_texture_sr = {};
inline reshade::api::resource_view g_texture_srv = {};

// Thread-local variables to track the active Vulkan render target and its view
inline thread_local reshade::api::resource g_active_thread_rt = {};
inline thread_local reshade::api::resource_view g_active_thread_rtv = {};

inline void CopyFrame(reshade::api::command_list* cmd_list) {
  if (!g_is_hdr)
    return;

  reshade::api::resource src_rt = g_active_thread_rt;
  if (src_rt == 0)
    return;

  reshade::api::device* device = cmd_list->get_device();
  reshade::api::resource_desc src_desc = device->get_resource_desc(src_rt);

  // Check if we need to (re)create our persistent texture to match the source
  bool need_create = false;
  if (g_texture_sr == 0) {
    need_create = true;
  } else {
    reshade::api::resource_desc dst_desc = device->get_resource_desc(g_texture_sr);
    if (dst_desc.texture.width != src_desc.texture.width || dst_desc.texture.height != src_desc.texture.height || dst_desc.texture.format != src_desc.texture.format) {
      need_create = true;
    }
  }

  if (need_create) {
    if (g_texture_srv != 0) {
      device->destroy_resource_view(g_texture_srv);
      g_texture_srv = {};
    }
    if (g_texture_sr != 0) {
      device->destroy_resource(g_texture_sr);
      g_texture_sr = {};
    }

    reshade::api::resource_desc desc = {};
    desc.type = reshade::api::resource_type::texture_2d;
    desc.texture.width = src_desc.texture.width;
    desc.texture.height = src_desc.texture.height;
    desc.texture.depth_or_layers = 1;
    desc.texture.levels = 1;
    desc.texture.format = src_desc.texture.format;
    desc.texture.samples = 1;
    desc.heap = reshade::api::memory_heap::gpu_only;
    desc.usage = reshade::api::resource_usage::copy_dest | reshade::api::resource_usage::shader_resource;

    if (device->create_resource(desc, nullptr, reshade::api::resource_usage::undefined, &g_texture_sr)) {
      device->create_resource_view(
          g_texture_sr,
          reshade::api::resource_usage::shader_resource,
          reshade::api::resource_view_desc(desc.texture.format),
          &g_texture_srv);
    }
  }

  if (g_texture_sr == 0)
    return;

  // Transition source from render_target to copy_source
  cmd_list->barrier(
      src_rt,
      reshade::api::resource_usage::render_target,
      reshade::api::resource_usage::copy_source);

  // Transition destination to copy_dest
  cmd_list->barrier(
      g_texture_sr,
      reshade::api::resource_usage::shader_resource,
      reshade::api::resource_usage::copy_dest);

  // Copy current frame buffer into persistent texture
  cmd_list->copy_resource(src_rt, g_texture_sr);

  // Restore source to render_target state
  cmd_list->barrier(
      src_rt,
      reshade::api::resource_usage::copy_source,
      reshade::api::resource_usage::render_target);

  // Make destination readable by later shaders
  cmd_list->barrier(
      g_texture_sr,
      reshade::api::resource_usage::copy_dest,
      reshade::api::resource_usage::shader_resource);
}

inline void ClearFrame(reshade::api::command_list* cmd_list) {
  if (!g_is_hdr)
    return;

  reshade::api::resource src_rt = g_active_thread_rt;
  reshade::api::resource_view src_rtv = g_active_thread_rtv;
  if (src_rt == 0 || src_rtv == 0)
    return;

  const float clear_color[4] = {0.0f, 0.0f, 0.0f, 0.0f};
  cmd_list->clear_render_target_view(src_rtv, clear_color);
}

inline void OnInitSwapchain(reshade::api::swapchain* swapchain) {
  reshade::api::device* device = swapchain->get_device();
  reshade::api::resource backbuffer = swapchain->get_back_buffer(0);
  reshade::api::resource_desc backbuffer_desc = device->get_resource_desc(backbuffer);

  if (backbuffer_desc.texture.format == reshade::api::format::r16g16b16a16_float ||
      backbuffer_desc.texture.format == reshade::api::format::r10g10b10a2_unorm ||
      backbuffer_desc.texture.format == reshade::api::format::b10g10r10a2_unorm) {
    g_is_hdr = true;
  } else {
    g_is_hdr = false;
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
  g_is_hdr = false;
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
