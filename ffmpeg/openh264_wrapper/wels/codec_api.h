//
// This file is a wrapper with dynamic loader for OpenH264 binaries
// Tested with ffmpeg source tree with enabled OpenH264 support
//
// Based on the header file from OpenH264 project:
//     https://github.com/cisco/openh264/blob/master/codec/api/svc/codec_api.h
//

#ifndef __WELS_VIDEO_CODEC_SVC_API_WRAPPER_H__
#define __WELS_VIDEO_CODEC_SVC_API_WRAPPER_H__

#define WelsCreateSVCEncoder WelsCreateSVCEncoder_
#define WelsDestroySVCEncoder WelsDestroySVCEncoder_
#define WelsGetDecoderCapability WelsGetDecoderCapability_
#define WelsCreateDecoder WelsCreateDecoder_
#define WelsDestroyDecoder WelsDestroyDecoder_
#define WelsGetCodecVersion WelsGetCodecVersion_
#define WelsGetCodecVersionEx WelsGetCodecVersionEx_

// include original file
#include "include/wels/codec_api.h"

#undef WelsCreateSVCEncoder
#undef WelsDestroySVCEncoder
#undef WelsGetDecoderCapability
#undef WelsCreateDecoder
#undef WelsDestroyDecoder
#undef WelsGetCodecVersion
#undef WelsGetCodecVersionEx

// Declarations
int WelsCreateSVCEncoder(ISVCEncoder** ppEncoder);
void WelsDestroySVCEncoder(ISVCEncoder* pEncoder);
int WelsGetDecoderCapability(SDecoderCapability* pDecCapability);
long WelsCreateDecoder(ISVCDecoder** ppDecoder);
void WelsDestroyDecoder(ISVCDecoder* pDecoder);
OpenH264Version WelsGetCodecVersion(void);
void WelsGetCodecVersionEx(OpenH264Version *pVersion);


#ifdef OPENH264WRAPPER_WITH_IMPLEMENTATION

// Fallback
// TODO Calling convention?
static int WelsCreateSVCEncoder_fallback (ISVCEncoder** ppEncoder) { return 1; /*error*/ }
static void WelsDestroySVCEncoder_fallback (ISVCEncoder* pEncoder) { }
static int WelsGetDecoderCapability_fallback (SDecoderCapability* pDecCapability) { return 1; /*error*/ }
static long WelsCreateDecoder_fallback (ISVCDecoder** ppDecoder) { return 1; /*error*/ }
static void WelsDestroyDecoder_fallback (ISVCDecoder* pDecoder) { }
static OpenH264Version WelsGetCodecVersion_fallback (void)
{
    static const OpenH264Version v  = {0, 0, 0, 0};
    return v;
}
static void WelsGetCodecVersionEx_fallback (OpenH264Version *pVersion)
{
    static const OpenH264Version v  = {0, 0, 0, 0};
    *pVersion = v;
}

typedef int (*FN_WelsCreateSVCEncoder) (ISVCEncoder** ppEncoder);
typedef void (*FN_WelsDestroySVCEncoder) (ISVCEncoder* pEncoder);
typedef int (*FN_WelsGetDecoderCapability) (SDecoderCapability* pDecCapability);
typedef long (*FN_WelsCreateDecoder) (ISVCDecoder** ppDecoder);
typedef void (*FN_WelsDestroyDecoder) (ISVCDecoder* pDecoder);
typedef OpenH264Version (*FN_WelsGetCodecVersion) (void);
typedef void (*FN_WelsGetCodecVersionEx) (OpenH264Version *pVersion);

static FN_WelsCreateSVCEncoder p_WelsCreateSVCEncoder = WelsCreateSVCEncoder_fallback;
static FN_WelsDestroySVCEncoder p_WelsDestroySVCEncoder = WelsDestroySVCEncoder_fallback;
static FN_WelsGetDecoderCapability p_WelsGetDecoderCapability = WelsGetDecoderCapability_fallback;
static FN_WelsCreateDecoder p_WelsCreateDecoder = WelsCreateDecoder_fallback;
static FN_WelsDestroyDecoder p_WelsDestroyDecoder = WelsDestroyDecoder_fallback;
static FN_WelsGetCodecVersion p_WelsGetCodecVersion = WelsGetCodecVersion_fallback;
static FN_WelsGetCodecVersionEx p_WelsGetCodecVersionEx = WelsGetCodecVersionEx_fallback;

#include <stdio.h>
#ifdef _WIN32
#include <windows.h>
#elif defined __linux__ || defined __APPLE__
#include <dlfcn.h>
#endif

#ifdef _WIN32
#define LIBRARY_HANDLE_TYPE HANDLE
#else
#define LIBRARY_HANDLE_TYPE void*
#endif
static int _loadLibrary(const char* name, LIBRARY_HANDLE_TYPE* handle)
{
#ifdef _WIN32
    *handle = LoadLibraryA(name);
#define GETADDR(name) GetProcAddress(handle, #name)
#elif defined __linux__ || defined __APPLE__
    *handle = dlopen(name, RTLD_LAZY | RTLD_GLOBAL);
#define GETADDR(name) dlsym(handle, #name)
#else
#error "Not supported platform"
#endif
    return (handle != NULL) ? 1 : 0;
}


static void _initLibrary(void)
{
    static const char* defaultLibraryName =
#ifdef _WIN32
#if defined _M_X64 || defined __x86_64__
        "openh264-1.8.0-win64.dll"
#else
        "openh264-1.8.0-win32.dll"
#endif
// Linux/Unix based on dlopen/dlsym
#elif defined __linux__
# if defined __x86_64__
        "libopenh264-1.8.0-linux64.4.so"
# else
        "libopenh264-1.8.0-linux32.4.so"
# endif
#elif defined __APPLE__
# if defined __x86_64__
        "libopenh264-1.8.0-osx64.4.dylib"
# else
        "libopenh264-1.8.0-osx32.4.dylib"
# endif
#else
#error "Not supported platform"
#endif
    ;

    int errors = 0;
    void *fn_addr = NULL;

    const char* forced_name = getenv("OPENH264_LIBRARY");
    const char* libraryName = forced_name == NULL ? defaultLibraryName : forced_name;

    LIBRARY_HANDLE_TYPE handle = NULL;
    if (_loadLibrary(libraryName, &handle) == 0)
    {
        errors++;
    }
    else if (handle == NULL)
    {
        errors++;
    }
    else
    {
#define FILLADDR(name) \
        fn_addr = GETADDR(name); \
        if (fn_addr != NULL) \
            p_ ## name = (FN_ ## name)fn_addr; \
        else \
            errors++;
        FILLADDR(WelsCreateSVCEncoder)
        FILLADDR(WelsDestroySVCEncoder)
#ifdef _WIN32
        // Not exported into DLL: FILLADDR(WelsGetDecoderCapability)
#else
        FILLADDR(WelsGetDecoderCapability)
#endif
        FILLADDR(WelsCreateDecoder)
        FILLADDR(WelsDestroyDecoder)
        FILLADDR(WelsGetCodecVersion)
        FILLADDR(WelsGetCodecVersionEx)
    }
#undef FILLADDR
#undef GETADDR
#undef LIBRARY_HANDLE_TYPE
    if (errors == 0)
    {
        fprintf(stderr, "\n\tOpenH264 Video Codec provided by Cisco Systems, Inc.\n\n");
    }
    else
    {
        fprintf(stderr, "\nFailed to load OpenH264 library: %s\n", libraryName);
        fprintf(stderr, "\tPlease check environment and/or download library: https://github.com/cisco/openh264/releases\n\n");
    }
}

static void initLibrary(void)
{
    static bool initialized = false;
    if (initialized)
        return;
    _initLibrary();
    initialized = true;
}

#define WRAP(name, ret_type, decl_args, call_args) \
ret_type name decl_args { \
    initLibrary(); \
    return p_ ## name call_args; \
}

#define WRAP_VOID(name, decl_args, call_args) \
void name decl_args { \
    initLibrary(); \
    p_ ## name call_args; \
}

WRAP(WelsCreateSVCEncoder, int, (ISVCEncoder** ppEncoder), (ppEncoder) )
WRAP_VOID(WelsDestroySVCEncoder, (ISVCEncoder* pEncoder), (pEncoder) )
WRAP(WelsGetDecoderCapability, int, (SDecoderCapability* pDecCapability), (pDecCapability) )
WRAP(WelsCreateDecoder, long, (ISVCDecoder** ppDecoder), (ppDecoder) )
WRAP_VOID(WelsDestroyDecoder, (ISVCDecoder* pDecoder), (pDecoder) )
WRAP(WelsGetCodecVersion, OpenH264Version, (void), () )
WRAP_VOID(WelsGetCodecVersionEx, (OpenH264Version *pVersion), (pVersion) )

#endif

#endif // __WELS_VIDEO_CODEC_SVC_API_WRAPPER_H__
