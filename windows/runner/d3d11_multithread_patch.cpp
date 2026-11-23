#include "d3d11_multithread_patch.h"

#include <windows.h>

#include <d3d10_1.h>
#include <d3d11.h>
#include <dxgi.h>

#include <cstdint>
#include <cstring>

namespace venera {
namespace {

using GetProcAddressFn = FARPROC(WINAPI*)(HMODULE, LPCSTR);
using D3D11CreateDeviceFn = HRESULT(WINAPI*)(
    IDXGIAdapter*, D3D_DRIVER_TYPE, HMODULE, UINT, const D3D_FEATURE_LEVEL*,
    UINT, UINT, ID3D11Device**, D3D_FEATURE_LEVEL*, ID3D11DeviceContext**);
using D3D11CreateDeviceAndSwapChainFn = HRESULT(WINAPI*)(
    IDXGIAdapter*, D3D_DRIVER_TYPE, HMODULE, UINT, const D3D_FEATURE_LEVEL*,
    UINT, UINT, const DXGI_SWAP_CHAIN_DESC*, IDXGISwapChain**,
    ID3D11Device**, D3D_FEATURE_LEVEL*, ID3D11DeviceContext**);

GetProcAddressFn g_real_get_proc_address = nullptr;
D3D11CreateDeviceFn g_real_create_device = nullptr;
D3D11CreateDeviceAndSwapChainFn g_real_create_device_and_swap_chain = nullptr;
bool g_installed = false;

void EnableMultithreadProtection(ID3D11Device* device) {
  if (device == nullptr) {
    return;
  }
  ID3D10Multithread* multithread = nullptr;
  if (SUCCEEDED(device->QueryInterface(
          __uuidof(ID3D10Multithread), reinterpret_cast<void**>(&multithread)))) {
    multithread->SetMultithreadProtected(TRUE);
    multithread->Release();
  }
}

HRESULT WINAPI HookedCreateDevice(IDXGIAdapter* adapter,
                                  D3D_DRIVER_TYPE driver_type,
                                  HMODULE software,
                                  UINT flags,
                                  const D3D_FEATURE_LEVEL* feature_levels,
                                  UINT feature_level_count,
                                  UINT sdk_version,
                                  ID3D11Device** device,
                                  D3D_FEATURE_LEVEL* feature_level,
                                  ID3D11DeviceContext** context) {
  const HRESULT result = g_real_create_device(
      adapter, driver_type, software, flags, feature_levels, feature_level_count,
      sdk_version, device, feature_level, context);
  if (SUCCEEDED(result) && device != nullptr) {
    EnableMultithreadProtection(*device);
  }
  return result;
}

HRESULT WINAPI HookedCreateDeviceAndSwapChain(
    IDXGIAdapter* adapter,
    D3D_DRIVER_TYPE driver_type,
    HMODULE software,
    UINT flags,
    const D3D_FEATURE_LEVEL* feature_levels,
    UINT feature_level_count,
    UINT sdk_version,
    const DXGI_SWAP_CHAIN_DESC* swap_chain_desc,
    IDXGISwapChain** swap_chain,
    ID3D11Device** device,
    D3D_FEATURE_LEVEL* feature_level,
    ID3D11DeviceContext** context) {
  const HRESULT result = g_real_create_device_and_swap_chain(
      adapter, driver_type, software, flags, feature_levels, feature_level_count,
      sdk_version, swap_chain_desc, swap_chain, device, feature_level, context);
  if (SUCCEEDED(result) && device != nullptr) {
    EnableMultithreadProtection(*device);
  }
  return result;
}

// ANGLE resolves d3d11.dll entry points at runtime, so wrapping the addresses
// it asks for is enough to reach its device before it is used.
FARPROC WINAPI HookedGetProcAddress(HMODULE module, LPCSTR name) {
  FARPROC address = g_real_get_proc_address(module, name);
  if (address == nullptr || name == nullptr) {
    return address;
  }
  // An import can also be requested by ordinal, in which case `name` is a small
  // integer rather than a pointer to a string; dereferencing it would fault.
  if ((reinterpret_cast<ULONG_PTR>(name) >> 16) == 0) {
    return address;
  }
  if (name[0] != 'D') {
    return address;
  }
  if (std::strcmp(name, "D3D11CreateDevice") == 0) {
    g_real_create_device = reinterpret_cast<D3D11CreateDeviceFn>(address);
    return reinterpret_cast<FARPROC>(&HookedCreateDevice);
  }
  if (std::strcmp(name, "D3D11CreateDeviceAndSwapChain") == 0) {
    g_real_create_device_and_swap_chain =
        reinterpret_cast<D3D11CreateDeviceAndSwapChainFn>(address);
    return reinterpret_cast<FARPROC>(&HookedCreateDeviceAndSwapChain);
  }
  return address;
}

void PatchGetProcAddressImport(HMODULE module) {
  auto* base = reinterpret_cast<uint8_t*>(module);
  auto* dos_header = reinterpret_cast<IMAGE_DOS_HEADER*>(base);
  if (dos_header->e_magic != IMAGE_DOS_SIGNATURE) {
    return;
  }
  auto* nt_headers =
      reinterpret_cast<IMAGE_NT_HEADERS*>(base + dos_header->e_lfanew);
  if (nt_headers->Signature != IMAGE_NT_SIGNATURE) {
    return;
  }
  const IMAGE_DATA_DIRECTORY& directory =
      nt_headers->OptionalHeader
          .DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
  if (directory.VirtualAddress == 0) {
    return;
  }
  auto* descriptor = reinterpret_cast<IMAGE_IMPORT_DESCRIPTOR*>(
      base + directory.VirtualAddress);
  for (; descriptor->Name != 0; ++descriptor) {
    const auto* dll_name = reinterpret_cast<const char*>(base + descriptor->Name);
    if (_stricmp(dll_name, "kernel32.dll") != 0 &&
        _stricmp(dll_name, "kernelbase.dll") != 0) {
      continue;
    }
    // Walk the lookup table for names and the address table for the slots.
    auto* lookup = reinterpret_cast<IMAGE_THUNK_DATA*>(
        base + (descriptor->OriginalFirstThunk != 0 ? descriptor->OriginalFirstThunk
                                                    : descriptor->FirstThunk));
    auto* thunk =
        reinterpret_cast<IMAGE_THUNK_DATA*>(base + descriptor->FirstThunk);
    for (; lookup->u1.AddressOfData != 0; ++lookup, ++thunk) {
      if (IMAGE_SNAP_BY_ORDINAL(lookup->u1.Ordinal)) {
        continue;
      }
      auto* import_by_name =
          reinterpret_cast<IMAGE_IMPORT_BY_NAME*>(base + lookup->u1.AddressOfData);
      if (std::strcmp(reinterpret_cast<const char*>(import_by_name->Name),
                      "GetProcAddress") != 0) {
        continue;
      }
      auto* slot = reinterpret_cast<FARPROC*>(&thunk->u1.Function);
      DWORD previous_protection = 0;
      if (VirtualProtect(slot, sizeof(*slot), PAGE_READWRITE,
                         &previous_protection) == FALSE) {
        continue;
      }
      *slot = reinterpret_cast<FARPROC>(&HookedGetProcAddress);
      DWORD ignored = 0;
      VirtualProtect(slot, sizeof(*slot), previous_protection, &ignored);
    }
  }
}

}  // namespace

void InstallD3D11MultithreadPatch() {
  if (g_installed) {
    return;
  }
  g_real_get_proc_address = &GetProcAddress;
  if (g_real_get_proc_address == nullptr) {
    return;
  }
  // The engine library sits next to the executable and will be loaded for the
  // window anyway; loading it here guarantees the import table exists.
  HMODULE engine = LoadLibraryW(L"flutter_windows.dll");
  if (engine == nullptr) {
    engine = GetModuleHandleW(L"flutter_windows.dll");
  }
  if (engine == nullptr) {
    return;
  }
  PatchGetProcAddressImport(engine);
  g_installed = true;
}

}  // namespace venera
