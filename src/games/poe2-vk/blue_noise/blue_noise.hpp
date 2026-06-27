#pragma once

#include <combaseapi.h>
#include <shlwapi.h>
#include <wincodec.h>
#include <include/reshade.hpp>
#include <shared_mutex>
#include <vector>

#include "./ldr_lll1_7.h"

#pragma comment(lib, "Windowscodecs.lib")
#pragma comment(lib, "Shlwapi.lib")

namespace blue_noise {

inline std::shared_mutex& GetResourceMutex() {
  static std::shared_mutex mutex;
  return mutex;
}

// Persistent GPU resources for the Blue Noise texture
inline reshade::api::resource g_blue_noise_texture = {};
inline reshade::api::resource_view g_blue_noise_srv = {};

// Decodes the embedded PNG byte array directly from memory using WIC
inline bool LoadPNGFromMemory(const unsigned char* buffer, size_t size, std::vector<uint8_t>& out_pixels, uint32_t& out_width, uint32_t& out_height) {
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  IStream* stream = SHCreateMemStream(buffer, static_cast<UINT>(size));
  if (stream == nullptr) return false;

  IWICImagingFactory* factory = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    stream->Release();
    return false;
  }

  IWICBitmapDecoder* decoder = nullptr;
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

  hr = converter->Initialize(frame, GUID_WICPixelFormat8bppGray, WICBitmapDitherTypeNone, nullptr, 0.0, WICBitmapPaletteTypeCustom);
  if (FAILED(hr)) {
    converter->Release();
    frame->Release();
    decoder->Release();
    stream->Release();
    factory->Release();
    return false;
  }

  out_pixels.resize(out_width * out_height);
  hr = converter->CopyPixels(nullptr, out_width, static_cast<UINT>(out_pixels.size()), out_pixels.data());

  converter->Release();
  frame->Release();
  decoder->Release();
  stream->Release();
  factory->Release();
  return SUCCEEDED(hr);
}

// Loads the embedded Blue Noise data and uploads it to the GPU
inline void LoadBlueNoiseTexture(reshade::api::device* device) {
  if (g_blue_noise_texture != 0) return;

  std::vector<uint8_t> pixels;
  uint32_t width = 0, height = 0;

  if (!LoadPNGFromMemory(blue_noise::ldr_lll1_7, sizeof(blue_noise::ldr_lll1_7), pixels, width, height)) {
    return;
  }

  reshade::api::resource_desc desc = {};
  desc.type = reshade::api::resource_type::texture_2d;
  desc.texture.width = width;
  desc.texture.height = height;
  desc.texture.depth_or_layers = 1;
  desc.texture.levels = 1;
  desc.texture.format = reshade::api::format::r8_unorm;
  desc.texture.samples = 1;
  desc.heap = reshade::api::memory_heap::gpu_only;
  desc.usage = reshade::api::resource_usage::shader_resource;

  reshade::api::subresource_data init_data = {};
  init_data.data = pixels.data();
  init_data.row_pitch = width;
  init_data.slice_pitch = pixels.size();

  if (device->create_resource(desc, &init_data, reshade::api::resource_usage::shader_resource, &g_blue_noise_texture)) {
    reshade::api::resource_view_desc srv_desc = {};
    srv_desc.type = reshade::api::resource_view_type::texture_2d;
    srv_desc.format = reshade::api::format::r8_unorm;
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

// Releases GPU texture allocations on device destruction
inline void DestroyBlueNoiseTexture(reshade::api::device* device) {
  std::unique_lock<std::shared_mutex> lock(GetResourceMutex());
  if (g_blue_noise_srv != 0) {
    device->destroy_resource_view(g_blue_noise_srv);
    g_blue_noise_srv = {};
  }
  if (g_blue_noise_texture != 0) {
    device->destroy_resource(g_blue_noise_texture);
    g_blue_noise_texture = {};
  }
}

// Callback function tied to ReShade's destroy_device event
inline void OnDestroyDevice(reshade::api::device* device) {
  DestroyBlueNoiseTexture(device);
}

inline void RegisterEvents() {
  reshade::register_event<reshade::addon_event::destroy_device>(OnDestroyDevice);
}

inline void UnregisterEvents() {
  reshade::unregister_event<reshade::addon_event::destroy_device>(OnDestroyDevice);
}

}  // namespace blue_noise
