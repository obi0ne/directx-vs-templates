//
// pch.h
// Header for standard system include files.
//

#pragma once

#include <winsdkver.h>
#define _WIN32_WINNT 0x0A00
#include <sdkddkver.h>

// Use the C++ standard templated min/max
#define NOMINMAX

// DirectX apps don't need GDI
#define NODRAWTEXT
#define NOGDI
#define NOBITMAP

// Include <mcx.h> if you need this
#define NOMCX

// Include <winsvc.h> if you need this
#define NOSERVICE

// WinHelp is deprecated
#define NOHELP

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>

#include <wrl/client.h>
#include <wrl/event.h>

#include <d3d12.h>
#include <dxgi1_6.h>

#include <DirectXMath.h>
#include <DirectXColors.h>

#include "d3dx12.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <exception>
#include <iterator>
#include <memory>
#include <stdexcept>
#include <system_error>

// To use graphics and CPU markup events with the latest version of PIX, change this to include <pix3.h>
// then add the NuGet package WinPixEventRuntime to the project.
#include <pix.h>

#ifdef _DEBUG
#include <dxgidebug.h>
#endif

namespace DX
{
    // Helper class for COM exceptions
    class com_exception : public std::exception
    {
    public:
        com_exception(HRESULT hr) noexcept : result(hr) {}

        const char* what() const override
        {
            static char s_str[64] = {};
            sprintf_s(s_str, "Failure with HRESULT of %08X", static_cast<unsigned int>(result));
            return s_str;
        }

    private:
        HRESULT result;
    };

    // Helper utility converts D3D API failures into exceptions.
    inline void ThrowIfFailed(HRESULT hr)
    {
        if (FAILED(hr))
        {
            throw com_exception(hr);
        }
    }
}
