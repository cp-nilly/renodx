#pragma once

#include <combaseapi.h>
#include <embed/shaders.h>
#include <shlwapi.h>
#include <wincodec.h>
#include <include/reshade.hpp>
#include <shared_mutex>
#include <unordered_map>
#include <vector>
#include <atomic>

#include "./blue_noise/ldr_lll1_7.h"

#pragma comment(lib, "Windowscodecs.lib")
#pragma comment(lib, "Shlwapi.lib")

namespace frame_capture {

// World capture tracking.
inline std::atomic<bool> g_world_captured_this_frame = {false};

// Track the active render target and its associated view per command list.
struct CommandListState {
  reshade::api::resource active_rt = {0};
  reshade::api::resource_view active_rtv = {0};
};

// Access the shared mutex for thread-safe command list state access.
inline std::shared_mutex& GetCmdListMutex() {
  static std::shared_mutex mutex;
  return mutex;
}

// Access the global map of active command list states.
inline std::unordered_map<reshade::api::command_list*, CommandListState>& GetCmdListStates() {
  static std::unordered_map<reshade::api::command_list*, CommandListState> states;
  return states;
}

// Access the shared mutex protecting global captured texture resources.
inline std::shared_mutex& GetResourceMutex() {
  static std::shared_mutex mutex;
  return mutex;
}

// Persistent graphics resources for the captured frame, isolated UI, and Blue Noise.
inline reshade::api::resource g_texture_sr = {};
inline reshade::api::resource_view g_texture_srv = {};
inline reshade::api::resource g_ui_texture = {};
inline reshade::api::resource_view g_ui_texture_srv = {};

// Blue Noise resource handles
inline reshade::api::resource g_blue_noise_texture = {};
inline reshade::api::resource_view g_blue_noise_srv = {};

// Presentation rendering states and backbuffer descriptors.
inline std::vector<reshade::api::resource_view> g_backbuffer_rtvs = {};
inline reshade::api::pipeline g_composite_pipeline = {};
inline reshade::api::pipeline_layout g_composite_layout = {};
inline reshade::api::sampler g_linear_sampler = {};

// Decodes the embedded PNG byte array directly from memory using WIC and COM streams
inline bool LoadPNGFromMemory(const unsigned char* buffer, size_t size, std::vector<uint8_t>& out_pixels, uint32_t& out_width, uint32_t& out_height) {
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Create an IStream wrapping our raw embedded memory buffer
  IStream* stream = SHCreateMemStream(buffer, static_cast<UINT>(size));
  if (stream == nullptr) return false;

  IWICImagingFactory* factory = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    stream->Release();
    return false;
  }

  IWICBitmapDecoder* decoder = nullptr;
  // Initialize the WIC decoder using our memory stream instead of a file path
  hr = factory->CreateDecoderFromStream(stream, nullptr, WICDecodeMetadataCacheOnDemand, &decoder);
  if (FAILED(hr)) {
    stream->Release();
    factory->Release();
    return false;
  }

  IWICBitmapFrameDecode* frame = nullptr;
  hr = decoder->GetFrame(0, &frame);
  if (FAILED(hr)) {
    decoder->Release();
    stream->Release();
    factory->Release();
    return false;
  }

  hr = frame->GetSize(&out_width, &out_height);
  if (FAILED(hr)) {
    frame->Release();
    decoder->Release();
    stream->Release();
    factory->Release();
    return false;
  }

  IWICFormatConverter* converter = nullptr;
  hr = factory->CreateFormatConverter(&converter);
  if (FAILED(hr)) {
    frame->Release();
    decoder->Release();
    stream->Release();
    factory->Release();
    return false;
  }

  hr = converter->Initialize(frame, GUID_WICPixelFormat32bppRGBA, WICBitmapDitherTypeNone, nullptr, 0.0, WICBitmapPaletteTypeCustom);
  if (FAILED(hr)) {
    converter->Release();
    frame->Release();
    decoder->Release();
    stream->Release();
    factory->Release();
    return false;
  }

  out_pixels.resize(out_width * out_height * 4);
  hr = converter->CopyPixels(nullptr, out_width * 4, static_cast<UINT>(out_pixels.size()), out_pixels.data());

  converter->Release();
  frame->Release();
  decoder->Release();
  stream->Release();
  factory->Release();
  return SUCCEEDED(hr);
}

// Loads the embedded Blue Noise data and uploads it to the GPU
inline void LoadBlueNoiseTexture(reshade::api::device* device) {
  if (g_blue_noise_texture != 0) return;  // Already loaded

  std::vector<uint8_t> pixels;
  uint32_t width = 0, height = 0;

  // Load from our inline embedded C++ array instead of reading a file from disk
  if (!LoadPNGFromMemory(blue_noise::ldr_lll1_7, sizeof(blue_noise::ldr_lll1_7), pixels, width, height)) {
    return;  // Failed to decode
  }

  reshade::api::resource_desc desc = {};
  desc.type = reshade::api::resource_type::texture_2d;
  desc.texture.width = width;
  desc.texture.height = height;
  desc.texture.depth_or_layers = 1;
  desc.texture.levels = 1;
  desc.texture.format = reshade::api::format::r8g8b8a8_unorm;
  desc.texture.samples = 1;
  desc.heap = reshade::api::memory_heap::gpu_only;
  desc.usage = reshade::api::resource_usage::shader_resource;

  reshade::api::subresource_data init_data = {};
  init_data.data = pixels.data();
  init_data.row_pitch = width * 4;
  init_data.slice_pitch = pixels.size();

  if (device->create_resource(desc, &init_data, reshade::api::resource_usage::shader_resource, &g_blue_noise_texture)) {
    reshade::api::resource_view_desc srv_desc = {};
    srv_desc.type = reshade::api::resource_view_type::texture_2d;
    srv_desc.format = reshade::api::format::r8g8b8a8_unorm;
    srv_desc.texture.first_level = 0;
    srv_desc.texture.level_count = 1;
    srv_desc.texture.first_layer = 0;
    srv_desc.texture.layer_count = 1;

    device->create_resource_view(
        g_blue_noise_texture,
        reshade::api::resource_usage::shader_resource,
        srv_desc,
        &g_blue_noise_srv);
  }
}

// Initialize state tracking when a command list is created.
inline void OnInitCommandList(reshade::api::command_list* cmd_list) {
  std::unique_lock<std::shared_mutex> lock(GetCmdListMutex());
  GetCmdListStates()[cmd_list] = CommandListState();
}

// Clean up state tracking when a command list is destroyed.
inline void OnDestroyCommandList(reshade::api::command_list* cmd_list) {
  std::unique_lock<std::shared_mutex> lock(GetCmdListMutex());
  GetCmdListStates().erase(cmd_list);
}

// Capture the active render target into the persistent texture, resolving MSAA if necessary.
inline void CopyFrame(reshade::api::command_list* cmd_list) {
  reshade::api::resource src_rt = {};
  {
    std::shared_lock<std::shared_mutex> lock(GetCmdListMutex());
    auto& states = GetCmdListStates();
    auto it = states.find(cmd_list);
    if (it != states.end()) {
      src_rt = it->second.active_rt;
    }
  }

  if (src_rt.handle == 0) return;

  std::unique_lock<std::shared_mutex> res_lock(GetResourceMutex());

  reshade::api::device* device = cmd_list->get_device();
  reshade::api::resource_desc src_desc = device->get_resource_desc(src_rt);

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
    desc.texture.depth_or_layers = src_desc.texture.depth_or_layers;
    desc.texture.levels = src_desc.texture.levels;
    desc.texture.format = src_desc.texture.format;
    desc.texture.samples = 1;
    desc.heap = reshade::api::memory_heap::gpu_only;
    desc.usage = reshade::api::resource_usage::copy_dest | reshade::api::resource_usage::resolve_dest | reshade::api::resource_usage::shader_resource;

    if (device->create_resource(desc, nullptr, reshade::api::resource_usage::undefined, &g_texture_sr)) {
      reshade::api::resource_view_desc srv_desc = {};
      srv_desc.type = (desc.texture.depth_or_layers > 1)
                          ? reshade::api::resource_view_type::texture_2d_array
                          : reshade::api::resource_view_type::texture_2d;

      srv_desc.format = desc.texture.format;
      srv_desc.texture.first_level = 0;
      srv_desc.texture.level_count = desc.texture.levels;
      srv_desc.texture.first_layer = 0;
      srv_desc.texture.layer_count = desc.texture.depth_or_layers;

      device->create_resource_view(
          g_texture_sr,
          reshade::api::resource_usage::shader_resource,
          srv_desc,
          &g_texture_srv);
    }
  }

  if (g_texture_sr == 0) return;

  reshade::api::resource_usage src_old_state = reshade::api::resource_usage::render_target;
  reshade::api::resource_usage src_new_state = (src_desc.texture.samples > 1)
                                                   ? reshade::api::resource_usage::resolve_source
                                                   : reshade::api::resource_usage::copy_source;

  cmd_list->barrier(src_rt, src_old_state, src_new_state);

  reshade::api::resource_usage dst_new_state = (src_desc.texture.samples > 1)
                                                   ? reshade::api::resource_usage::resolve_dest
                                                   : reshade::api::resource_usage::copy_dest;

  cmd_list->barrier(g_texture_sr, reshade::api::resource_usage::undefined, dst_new_state);

  if (src_desc.texture.samples > 1) {
    cmd_list->resolve_texture_region(
        src_rt, 0, nullptr,
        g_texture_sr, 0, 0, 0, 0,
        src_desc.texture.format);
  } else {
    cmd_list->copy_resource(src_rt, g_texture_sr);
  }

  cmd_list->barrier(src_rt, src_new_state, src_old_state);
  cmd_list->barrier(g_texture_sr, dst_new_state, reshade::api::resource_usage::shader_resource);
}

// Clear the active render target to transparent black to isolate UI drawing.
inline void ClearFrame(reshade::api::command_list* cmd_list) {
  reshade::api::resource src_rt = {};
  reshade::api::resource_view src_rtv = {};
  {
    std::shared_lock<std::shared_mutex> lock(GetCmdListMutex());
    auto& states = GetCmdListStates();
    auto it = states.find(cmd_list);
    if (it != states.end()) {
      src_rt = it->second.active_rt;
      src_rtv = it->second.active_rtv;
    }
  }

  if (src_rt.handle == 0 || src_rtv.handle == 0) return;

  const float clear_color[4] = {0.0f, 0.0f, 0.0f, 0.0f};
  cmd_list->clear_render_target_view(src_rtv, clear_color);
}

// Track active render target updates when the game begins a new render pass.
inline void OnBeginRenderPass(
    reshade::api::command_list* cmd_list,
    uint32_t count,
    const reshade::api::render_pass_render_target_desc* rts,
    const reshade::api::render_pass_depth_stencil_desc* ds) {
  if (count > 0 && rts[0].view.handle != 0) {
    reshade::api::device* device = cmd_list->get_device();

    std::unique_lock<std::shared_mutex> lock(GetCmdListMutex());
    CommandListState& state = GetCmdListStates()[cmd_list];
    state.active_rt = device->get_resource_from_view(rts[0].view);
    state.active_rtv = rts[0].view;
  }
}

// Compile the pipeline and descriptor layouts required for final screen compositing.
inline bool CreatePipeline(reshade::api::device* device, reshade::api::format rt_format) {
  reshade::api::descriptor_range range_set0 = {
      .binding = 0,
      .dx_register_index = 0,
      .dx_register_space = 0,
      .count = 3,
      .visibility = reshade::api::shader_stage::all_graphics,
      .array_size = 3,
      .type = reshade::api::descriptor_type::shader_resource_view};

  reshade::api::pipeline_layout_param params[1];
  params[0].type = reshade::api::pipeline_layout_param_type::push_descriptors;
  params[0].push_descriptors = range_set0;

  if (!device->create_pipeline_layout(1, params, &g_composite_layout)) {
    return false;
  }

  std::vector<reshade::api::pipeline_subobject> subobjects;

  reshade::api::shader_desc vs_desc = {__0xFEED0002.data(), __0xFEED0002.size(), "main"};
  subobjects.push_back({reshade::api::pipeline_subobject_type::vertex_shader, 1, &vs_desc});

  reshade::api::shader_desc ps_desc = {__0xFEED0001.data(), __0xFEED0001.size(), "main"};
  subobjects.push_back({reshade::api::pipeline_subobject_type::pixel_shader, 1, &ps_desc});

  reshade::api::blend_desc blend_desc = {};
  blend_desc.blend_enable[0] = false;
  blend_desc.render_target_write_mask[0] = 0xF;
  subobjects.push_back({reshade::api::pipeline_subobject_type::blend_state, 1, &blend_desc});

  reshade::api::rasterizer_desc rasterizer_desc = {};
  rasterizer_desc.fill_mode = reshade::api::fill_mode::solid;
  rasterizer_desc.cull_mode = reshade::api::cull_mode::none;
  subobjects.push_back({reshade::api::pipeline_subobject_type::rasterizer_state, 1, &rasterizer_desc});

  reshade::api::depth_stencil_desc depth_desc = {};
  depth_desc.depth_enable = false;
  depth_desc.depth_write_mask = false;
  subobjects.push_back({reshade::api::pipeline_subobject_type::depth_stencil_state, 1, &depth_desc});

  reshade::api::primitive_topology topology = reshade::api::primitive_topology::triangle_list;
  subobjects.push_back({reshade::api::pipeline_subobject_type::primitive_topology, 1, &topology});

  subobjects.push_back({reshade::api::pipeline_subobject_type::render_target_formats, 1, &rt_format});

  if (!device->create_pipeline(g_composite_layout, static_cast<uint32_t>(subobjects.size()), subobjects.data(), &g_composite_pipeline)) {
    device->destroy_pipeline_layout(g_composite_layout);
    g_composite_layout = {};
    return false;
  }

  return true;
}

// Allocate UI structures, composite pipeline, and views whenever the swapchain is initialized.
inline void OnInitSwapchain(reshade::api::swapchain* swapchain) {
  reshade::api::device* device = swapchain->get_device();

  std::unique_lock<std::shared_mutex> res_lock(GetResourceMutex());

  // Load the Blue Noise Texture from Memory
  LoadBlueNoiseTexture(device);

  if (g_composite_pipeline != 0) {
    device->destroy_pipeline(g_composite_pipeline);
    g_composite_pipeline = {};
  }
  if (g_composite_layout != 0) {
    device->destroy_pipeline_layout(g_composite_layout);
    g_composite_layout = {};
  }
  if (g_linear_sampler != 0) {
    device->destroy_sampler(g_linear_sampler);
    g_linear_sampler = {};
  }
  if (g_ui_texture_srv != 0) {
    device->destroy_resource_view(g_ui_texture_srv);
    g_ui_texture_srv = {};
  }
  if (g_ui_texture != 0) {
    device->destroy_resource(g_ui_texture);
    g_ui_texture = {};
  }
  for (auto rtv : g_backbuffer_rtvs) {
    if (rtv != 0) device->destroy_resource_view(rtv);
  }
  g_backbuffer_rtvs.clear();

  reshade::api::resource backbuffer_0 = swapchain->get_back_buffer(0);
  reshade::api::resource_desc backbuffer_desc = device->get_resource_desc(backbuffer_0);

  if (backbuffer_desc.texture.width == 0 || backbuffer_desc.texture.height == 0) {
    return;
  }

  uint32_t buffer_count = swapchain->get_back_buffer_count();
  g_backbuffer_rtvs.resize(buffer_count);

  reshade::api::format typed_format = backbuffer_desc.texture.format;
  if (typed_format == reshade::api::format::r16g16b16a16_typeless) {
    typed_format = reshade::api::format::r16g16b16a16_float;
  }

  for (uint32_t i = 0; i < buffer_count; ++i) {
    reshade::api::resource backbuffer = swapchain->get_back_buffer(i);
    device->create_resource_view(
        backbuffer,
        reshade::api::resource_usage::render_target,
        reshade::api::resource_view_desc(typed_format),
        &g_backbuffer_rtvs[i]);
  }

  reshade::api::resource_desc safe_desc = {};
  safe_desc.type = reshade::api::resource_type::texture_2d;
  safe_desc.texture.width = backbuffer_desc.texture.width;
  safe_desc.texture.height = backbuffer_desc.texture.height;
  safe_desc.texture.depth_or_layers = backbuffer_desc.texture.depth_or_layers;
  safe_desc.texture.levels = backbuffer_desc.texture.levels;
  safe_desc.texture.format = typed_format;
  safe_desc.texture.samples = 1;
  safe_desc.heap = reshade::api::memory_heap::gpu_only;
  safe_desc.usage = reshade::api::resource_usage::copy_dest | reshade::api::resource_usage::shader_resource;

  if (device->create_resource(safe_desc, nullptr, reshade::api::resource_usage::undefined, &g_ui_texture)) {
    reshade::api::resource_view_desc srv_desc = {};
    srv_desc.type = (safe_desc.texture.depth_or_layers > 1)
                        ? reshade::api::resource_view_type::texture_2d_array
                        : reshade::api::resource_view_type::texture_2d;

    srv_desc.format = typed_format;
    srv_desc.texture.first_level = 0;
    srv_desc.texture.level_count = safe_desc.texture.levels;
    srv_desc.texture.first_layer = 0;
    srv_desc.texture.layer_count = safe_desc.texture.depth_or_layers;

    device->create_resource_view(
        g_ui_texture,
        reshade::api::resource_usage::shader_resource,
        srv_desc,
        &g_ui_texture_srv);
  }

  if (!CreatePipeline(device, typed_format)) {
    if (g_ui_texture_srv != 0) {
      device->destroy_resource_view(g_ui_texture_srv);
      g_ui_texture_srv = {};
    }
    if (g_ui_texture != 0) {
      device->destroy_resource(g_ui_texture);
      g_ui_texture = {};
    }
  }
}

// Clean up swapchain descriptors, custom pipelines, and view handles on destruction.
inline void OnDestroySwapchain(reshade::api::swapchain* swapchain) {
  reshade::api::device* device = swapchain->get_device();

  std::unique_lock<std::shared_mutex> res_lock(GetResourceMutex());

  if (g_composite_pipeline != 0) {
    device->destroy_pipeline(g_composite_pipeline);
    g_composite_pipeline = {};
  }
  if (g_composite_layout != 0) {
    device->destroy_pipeline_layout(g_composite_layout);
    g_composite_layout = {};
  }
  if (g_linear_sampler != 0) {
    device->destroy_sampler(g_linear_sampler);
    g_linear_sampler = {};
  }

  for (auto rtv : g_backbuffer_rtvs) {
    if (rtv != 0) {
      device->destroy_resource_view(rtv);
    }
  }
  g_backbuffer_rtvs.clear();

  if (g_texture_srv != 0) {
    device->destroy_resource_view(g_texture_srv);
    g_texture_srv = {};
  }
  if (g_texture_sr != 0) {
    device->destroy_resource(g_texture_sr);
    g_texture_sr = {};
  }
  if (g_ui_texture_srv != 0) {
    device->destroy_resource_view(g_ui_texture_srv);
    g_ui_texture_srv = {};
  }
  if (g_ui_texture != 0) {
    device->destroy_resource(g_ui_texture);
    g_ui_texture = {};
  }
  if (g_blue_noise_srv != 0) {
    device->destroy_resource_view(g_blue_noise_srv);
    g_blue_noise_srv = {};
  }
  if (g_blue_noise_texture != 0) {
    device->destroy_resource(g_blue_noise_texture);
    g_blue_noise_texture = {};
  }
}

// Combine the isolated UI texture and the captured game scene into the final backbuffer swapchain.
inline void CompositeFrame(
    reshade::api::command_list* cmd_list,
    reshade::api::device* device,
    reshade::api::resource backbuffer,
    reshade::api::resource_view current_rtv) {
  std::shared_lock<std::shared_mutex> res_lock(GetResourceMutex());

  if (g_texture_srv == 0 || g_ui_texture == 0 || g_ui_texture_srv == 0 || g_composite_layout == 0 || g_composite_pipeline == 0 || g_blue_noise_srv == 0) return;

  reshade::api::resource_desc desc = device->get_resource_desc(backbuffer);

  cmd_list->barrier(
      backbuffer,
      reshade::api::resource_usage::render_target,
      reshade::api::resource_usage::copy_source);

  cmd_list->barrier(
      g_ui_texture,
      reshade::api::resource_usage::shader_resource,
      reshade::api::resource_usage::copy_dest);

  cmd_list->copy_resource(backbuffer, g_ui_texture);

  cmd_list->barrier(
      backbuffer,
      reshade::api::resource_usage::copy_source,
      reshade::api::resource_usage::render_target);

  cmd_list->barrier(
      g_ui_texture,
      reshade::api::resource_usage::copy_dest,
      reshade::api::resource_usage::shader_resource);

  reshade::api::render_pass_render_target_desc rt_desc = {current_rtv};
  cmd_list->begin_render_pass(1, &rt_desc, nullptr);

  cmd_list->bind_pipeline(reshade::api::pipeline_stage::all_graphics, g_composite_pipeline);

  reshade::api::viewport vp = {0.0f, 0.0f, static_cast<float>(desc.texture.width), static_cast<float>(desc.texture.height), 0.0f, 1.0f};
  cmd_list->bind_viewports(0, 1, &vp);

  reshade::api::rect scissor = {0, 0, static_cast<int32_t>(desc.texture.width), static_cast<int32_t>(desc.texture.height)};
  cmd_list->bind_scissor_rects(0, 1, &scissor);

  reshade::api::resource_view srvs[3] = {
      g_ui_texture_srv,
      g_texture_srv,
      g_blue_noise_srv};

  reshade::api::descriptor_table_update update = {};
  update.binding = 0;
  update.array_offset = 0;
  update.type = reshade::api::descriptor_type::shader_resource_view;
  update.count = 3;
  update.descriptors = srvs;

  cmd_list->push_descriptors(
      reshade::api::shader_stage::all_graphics,
      g_composite_layout,
      0,
      update);

  cmd_list->draw(3, 1, 0, 0);

  cmd_list->end_render_pass();

  cmd_list->barrier(
      backbuffer,
      reshade::api::resource_usage::render_target,
      reshade::api::resource_usage::present);
}

// Bind custom functions to ReShade callbacks.
inline void RegisterEvents() {
  reshade::register_event<reshade::addon_event::init_command_list>(OnInitCommandList);
  reshade::register_event<reshade::addon_event::destroy_command_list>(OnDestroyCommandList);
  reshade::register_event<reshade::addon_event::init_swapchain>(
      reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::init_swapchain>::decl>(OnInitSwapchain));
  reshade::register_event<reshade::addon_event::destroy_swapchain>(
      reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::destroy_swapchain>::decl>(OnDestroySwapchain));
  reshade::register_event<reshade::addon_event::begin_render_pass>(OnBeginRenderPass);
}

// Unbind custom functions from ReShade callbacks.
inline void UnregisterEvents() {
  reshade::unregister_event<reshade::addon_event::init_command_list>(OnInitCommandList);
  reshade::unregister_event<reshade::addon_event::destroy_command_list>(OnDestroyCommandList);
  reshade::unregister_event<reshade::addon_event::init_swapchain>(
      reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::init_swapchain>::decl>(OnInitSwapchain));
  reshade::unregister_event<reshade::addon_event::destroy_swapchain>(
      reinterpret_cast<reshade::addon_event_traits<reshade::addon_event::destroy_swapchain>::decl>(OnDestroySwapchain));
  reshade::unregister_event<reshade::addon_event::begin_render_pass>(OnBeginRenderPass);
}

}  // namespace frame_capture
