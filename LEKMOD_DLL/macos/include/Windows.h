#pragma once

// Minimal Win32 ABI surface used by the Civ V GameCore sources.  Aspyr's
// x86_64 executable exports the non-inline functions declared here.

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <cctype>
#include <cstdio>
#include <cstdarg>
#include <cstdlib>
#include <cwchar>
#include <cwctype>
#include <pthread.h>
#include <strings.h>
#include <memory>
#include <unordered_set>
#include <unordered_map>
#include <array>
#include <climits>

namespace std {
#if __cplusplus >= 201703L
template <class Arg1, class Arg2, class Result>
struct binary_function {
  typedef Arg1 first_argument_type;
  typedef Arg2 second_argument_type;
  typedef Result result_type;
};
#endif
namespace tr1 {
using std::shared_ptr;
using std::unordered_set;
using std::unordered_map;
using std::array;
}
}

#ifndef __stdcall
#define __stdcall
#endif
#ifndef __cdecl
#define __cdecl
#endif
#ifndef WINAPI
#define WINAPI
#endif
#ifndef CALLBACK
#define CALLBACK
#endif
#ifndef DECLSPEC_DEPRECATED
#define DECLSPEC_DEPRECATED __attribute__((deprecated))
#endif

typedef int BOOL;
typedef std::uint8_t BYTE;
typedef std::uint16_t WORD;
typedef std::uint32_t DWORD;
typedef std::int32_t LONG;
typedef std::int16_t SHORT;
typedef std::uint32_t ULONG;
typedef std::uint32_t UINT;
typedef unsigned int uint;
typedef int INT;
typedef unsigned short USHORT;
typedef std::uint8_t UINT8;
typedef std::uint16_t UINT16;
typedef std::uint32_t UINT32;
typedef std::uint64_t UINT64;
typedef std::int8_t INT8;
typedef std::int16_t INT16;
typedef std::int32_t INT32;
typedef std::int64_t INT64;
typedef long long LONGLONG;
typedef std::uint64_t DWORD64;
typedef std::uintptr_t DWORD_PTR;
typedef std::uintptr_t ULONG_PTR;
typedef std::size_t SIZE_T;
typedef void* HANDLE;
typedef void* HINSTANCE;
typedef void* HMODULE;
typedef void* HWND;
typedef struct tagPOINT {
  LONG x;
  LONG y;
} POINT;
typedef char CHAR;
typedef wchar_t WCHAR;
typedef const char* LPCSTR;
typedef const wchar_t* LPCWSTR;
typedef wchar_t* LPWSTR;
typedef void* LPVOID;
typedef const void* LPCVOID;
typedef void* PVOID;
typedef DWORD* LPDWORD;
typedef ULONG* PULONG;
typedef LONG HRESULT;
typedef LONG LRESULT;
typedef ULONG_PTR WPARAM;
typedef LONG LPARAM;

typedef struct _GUID {
  std::uint32_t Data1;
  std::uint16_t Data2;
  std::uint16_t Data3;
  std::uint8_t Data4[8];
} GUID;

inline bool operator==(const GUID& a, const GUID& b) {
  return std::memcmp(&a, &b, sizeof(GUID)) == 0;
}
inline bool operator!=(const GUID& a, const GUID& b) { return !(a == b); }

typedef union _LARGE_INTEGER {
  struct {
    DWORD LowPart;
    LONG HighPart;
  };
  long long QuadPart;
} LARGE_INTEGER;

typedef struct _FILETIME {
  DWORD dwLowDateTime;
  DWORD dwHighDateTime;
} FILETIME;

inline LONG CompareFileTime(const FILETIME* first, const FILETIME* second) {
  const std::uint64_t first_value =
      (static_cast<std::uint64_t>(first->dwHighDateTime) << 32) |
      first->dwLowDateTime;
  const std::uint64_t second_value =
      (static_cast<std::uint64_t>(second->dwHighDateTime) << 32) |
      second->dwLowDateTime;
  return first_value < second_value ? -1 : (first_value > second_value ? 1 : 0);
}

typedef struct _WIN32_FILE_ATTRIBUTE_DATA {
  DWORD dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  DWORD nFileSizeHigh;
  DWORD nFileSizeLow;
} WIN32_FILE_ATTRIBUTE_DATA;

typedef struct _SYSTEMTIME {
  WORD wYear;
  WORD wMonth;
  WORD wDayOfWeek;
  WORD wDay;
  WORD wHour;
  WORD wMinute;
  WORD wSecond;
  WORD wMilliseconds;
} SYSTEMTIME;

typedef struct _EXCEPTION_POINTERS EXCEPTION_POINTERS;
typedef struct _CONTEXT { std::uint64_t opaque[32]; } CONTEXT;

typedef pthread_mutex_t CRITICAL_SECTION;

#define TRUE 1
#define FALSE 0
#define MAX_PATH 260
#define MAXINT INT_MAX
#define INVALID_HANDLE_VALUE ((HANDLE)(std::intptr_t)-1)
#define INVALID_FILE_SIZE ((DWORD)0xffffffffu)
#define INVALID_FILE_ATTRIBUTES ((DWORD)0xffffffffu)
#define ERROR_FILE_NOT_FOUND 2u

#define DLL_PROCESS_DETACH 0
#define DLL_PROCESS_ATTACH 1
#define DLL_THREAD_ATTACH 2
#define DLL_THREAD_DETACH 3

#define GENERIC_READ 0x80000000u
#define GENERIC_WRITE 0x40000000u
#define FILE_SHARE_READ 0x00000001u
#define FILE_SHARE_WRITE 0x00000002u
#define CREATE_ALWAYS 2u
#define OPEN_EXISTING 3u
#define FILE_ATTRIBUTE_NORMAL 0x00000080u
#define FILE_FLAG_SEQUENTIAL_SCAN 0x08000000u
#define GetFileExInfoStandard 0
#define CP_UTF8 65001u
#define HeapCompatibilityInformation 0
#define EXCEPTION_EXECUTE_HANDLER 1

#define ZeroMemory(destination, length) std::memset((destination), 0, (length))
#define CopyMemory(destination, source, length) std::memcpy((destination), (source), (length))
#define UNREFERENCED_PARAMETER(value) ((void)(value))

extern "C" {
BOOL CloseHandle(HANDLE object);
HRESULT CoCreateGuid(GUID* guid);
BOOL DeleteFileW(LPCWSTR name);
HANDLE CreateFileW(LPCWSTR name, DWORD access, DWORD share, LPVOID security,
                   DWORD creation, DWORD attributes, HANDLE template_file);
BOOL GetFileAttributesExW(LPCWSTR name, int info_level,
                          WIN32_FILE_ATTRIBUTE_DATA* data);
DWORD GetLastError(void);
DWORD GetFileSize(HANDLE file, DWORD* high_size);
BOOL ReadFile(HANDLE file, LPVOID buffer, DWORD bytes_to_read,
              DWORD* bytes_read, LPVOID overlapped);
HANDLE HeapCreate(DWORD options, SIZE_T initial_size, SIZE_T maximum_size);
BOOL HeapDestroy(HANDLE heap);
LPVOID HeapAlloc(HANDLE heap, DWORD flags, SIZE_T bytes);
BOOL HeapFree(HANDLE heap, DWORD flags, LPVOID memory);
BOOL HeapSetInformation(HANDLE heap, int information_class,
                        LPVOID information, SIZE_T information_length);
int MultiByteToWideChar(UINT code_page, DWORD flags, LPCSTR input,
                        int input_length, LPWSTR output, int output_length);
void OutputDebugStringA(LPCSTR text);
BOOL QueryPerformanceCounter(LARGE_INTEGER* value);
BOOL QueryPerformanceFrequency(LARGE_INTEGER* value);
}

#define OutputDebugString OutputDebugStringA

#ifndef APIENTRY
#define APIENTRY WINAPI
#endif
#ifndef _CRTIMP
#define _CRTIMP
#endif

#define _In_
#define _In_bytecount_(size)
#define _In_opt_
#define _In_opt_z_
#define _Inout_
#define _Inout_opt_
#define _Out_
#define _Out_opt_
#define _In_z_
#define _Inout_z_cap_(size)
#define _Ret_maybenull_
#define _Ret_opt_
#define _Ret_opt_z_
#define _Ret_z_
#define _Inout_z_cap_c_(size)
#define _Check_return_
#define __checkReturn
#define __in
#define __out
#define __out_opt
#define _vsnprintf vsnprintf
#define _malloca std::malloc
#define _freea std::free
#define _strdup ::strdup

// Secure CRT entry points are exported by the Aspyr executable with C++
// linkage.  These declarations deliberately match the undefined symbols used
// by the stock GameCore dylib.  Array overloads reproduce MSVC's size-deducing
// templates so the unmodified Firaxis call sites continue to compile.
int sprintf_s(char* buffer, std::size_t size, const char* format, ...);
int vsprintf_s(char* buffer, std::size_t size, const char* format,
               std::va_list arguments);
int strcpy_s(char* destination, std::size_t size, const char* source);
int strncpy_s(char* destination, std::size_t size, const char* source,
              std::size_t count);
int wcscpy_s(wchar_t* destination, std::size_t size, const wchar_t* source);
int _itoa_s(int value, char* buffer, std::size_t size, int radix);

template <std::size_t Size>
inline int sprintf_s(char (&buffer)[Size], const char* format, ...) {
  std::va_list arguments;
  va_start(arguments, format);
  const int result = vsprintf_s(buffer, Size, format, arguments);
  va_end(arguments);
  return result;
}

template <std::size_t Size>
inline int vsprintf_s(char (&buffer)[Size], const char* format,
                      std::va_list arguments) {
  return vsprintf_s(buffer, Size, format, arguments);
}

template <std::size_t Size>
inline int strcpy_s(char (&destination)[Size], const char* source) {
  return strcpy_s(destination, Size, source);
}

template <std::size_t Size>
inline int wcscpy_s(wchar_t (&destination)[Size], const wchar_t* source) {
  return wcscpy_s(destination, Size, source);
}

template <std::size_t Size>
inline int _itoa_s(int value, char (&buffer)[Size], int radix) {
  return _itoa_s(value, buffer, Size, radix);
}

#define fprintf_s std::fprintf

inline void InitializeCriticalSection(CRITICAL_SECTION* section) {
  pthread_mutex_init(section, nullptr);
}
inline void DeleteCriticalSection(CRITICAL_SECTION* section) {
  pthread_mutex_destroy(section);
}
inline void EnterCriticalSection(CRITICAL_SECTION* section) {
  pthread_mutex_lock(section);
}
inline void LeaveCriticalSection(CRITICAL_SECTION* section) {
  pthread_mutex_unlock(section);
}

inline LONG InterlockedIncrement(volatile LONG* value) {
  return __sync_add_and_fetch(value, 1);
}
inline LONG InterlockedDecrement(volatile LONG* value) {
  return __sync_sub_and_fetch(value, 1);
}
inline LONG InterlockedExchangeAdd(volatile LONG* value, LONG amount) {
  return __sync_fetch_and_add(value, amount);
}
inline LONG InterlockedAnd(volatile LONG* value, LONG mask) {
  return __sync_fetch_and_and(value, mask);
}
inline LONG InterlockedOr(volatile LONG* value, LONG mask) {
  return __sync_fetch_and_or(value, mask);
}
inline LONG InterlockedCompareExchange(volatile LONG* value, LONG exchange,
                                       LONG comparand) {
  return __sync_val_compare_and_swap(value, comparand, exchange);
}
inline long long InterlockedIncrement64(volatile long long* value) {
  return __sync_add_and_fetch(value, 1);
}
inline long long InterlockedDecrement64(volatile long long* value) {
  return __sync_sub_and_fetch(value, 1);
}
inline void* InterlockedCompareExchangePointer(void* volatile* value,
                                               void* exchange,
                                               void* comparand) {
  return __sync_val_compare_and_swap(value, comparand, exchange);
}

inline wchar_t* _wcsnset(wchar_t* text, wchar_t value, std::size_t count) {
  for (std::size_t i = 0; i < count && text[i] != L'\0'; ++i) text[i] = value;
  return text;
}
inline int _wcsicmp(const wchar_t* a, const wchar_t* b) {
  return ::wcscasecmp(a, b);
}
inline int _wcsnicmp(const wchar_t* a, const wchar_t* b, std::size_t count) {
  return ::wcsncasecmp(a, b, count);
}
inline int _wcsicoll(const wchar_t* a, const wchar_t* b) {
  return ::wcscasecmp(a, b);
}
inline wchar_t* _wcsupr(wchar_t* text) {
  for (wchar_t* p = text; *p != L'\0'; ++p) *p = std::towupper(*p);
  return text;
}
inline wchar_t* _wcslwr(wchar_t* text) {
  for (wchar_t* p = text; *p != L'\0'; ++p) *p = std::towlower(*p);
  return text;
}
inline wchar_t* _wcsrev(wchar_t* text) {
  const std::size_t length = std::wcslen(text);
  for (std::size_t i = 0; i < length / 2; ++i) {
    const wchar_t value = text[i];
    text[i] = text[length - i - 1];
    text[length - i - 1] = value;
  }
  return text;
}

inline char* _strnset(char* text, int value, std::size_t count) {
  for (std::size_t i = 0; i < count && text[i] != '\0'; ++i)
    text[i] = static_cast<char>(value);
  return text;
}
inline int _stricmp(const char* a, const char* b) { return ::strcasecmp(a, b); }
inline int _strnicmp(const char* a, const char* b, std::size_t count) {
  return ::strncasecmp(a, b, count);
}
inline int _stricoll(const char* a, const char* b) { return ::strcasecmp(a, b); }
inline char* _strupr(char* text) {
  for (char* p = text; *p != '\0'; ++p)
    *p = static_cast<char>(std::toupper(static_cast<unsigned char>(*p)));
  return text;
}
inline char* _strlwr(char* text) {
  for (char* p = text; *p != '\0'; ++p)
    *p = static_cast<char>(std::tolower(static_cast<unsigned char>(*p)));
  return text;
}
inline char* _strrev(char* text) {
  const std::size_t length = std::strlen(text);
  for (std::size_t i = 0; i < length / 2; ++i) {
    const char value = text[i];
    text[i] = text[length - i - 1];
    text[length - i - 1] = value;
  }
  return text;
}
