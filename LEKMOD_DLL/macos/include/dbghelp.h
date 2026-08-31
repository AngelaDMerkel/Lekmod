#pragma once

#include <Windows.h>

struct _EXCEPTION_POINTERS;
struct _CONTEXT;

typedef struct _MINIDUMP_EXCEPTION_INFORMATION {
  DWORD ThreadId;
  EXCEPTION_POINTERS* ExceptionPointers;
  BOOL ClientPointers;
} MINIDUMP_EXCEPTION_INFORMATION;

typedef enum _MINIDUMP_TYPE {
  MiniDumpNormal = 0,
  MiniDumpWithDataSegs = 0x1,
  MiniDumpWithFullMemory = 0x2,
  MiniDumpWithHandleData = 0x4,
  MiniDumpWithUnloadedModules = 0x20,
  MiniDumpWithIndirectlyReferencedMemory = 0x40,
  MiniDumpWithProcessThreadData = 0x100,
  MiniDumpWithPrivateReadWriteMemory = 0x200,
  MiniDumpWithFullMemoryInfo = 0x800,
  MiniDumpWithThreadInfo = 0x1000,
  MiniDumpWithCodeSegs = 0x2000,
  MiniDumpWithFullAuxiliaryState = 0x8000
} MINIDUMP_TYPE;

typedef LONG(WINAPI* LPTOP_LEVEL_EXCEPTION_FILTER)(EXCEPTION_POINTERS*);

inline HANDLE GetCurrentProcess() { return nullptr; }
inline DWORD GetCurrentProcessId() { return 0; }
inline DWORD GetCurrentThreadId() { return 0; }
inline DWORD GetLastError() { return 0; }
inline void GetLocalTime(void*) {}
inline BOOL SymInitialize(HANDLE, const char*, BOOL) { return FALSE; }
inline BOOL MiniDumpWriteDump(HANDLE, DWORD, HANDLE, MINIDUMP_TYPE,
                              MINIDUMP_EXCEPTION_INFORMATION*, void*, void*) {
  return FALSE;
}
inline LPTOP_LEVEL_EXCEPTION_FILTER SetUnhandledExceptionFilter(
    LPTOP_LEVEL_EXCEPTION_FILTER) {
  return nullptr;
}
