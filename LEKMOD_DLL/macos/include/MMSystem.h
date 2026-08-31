#pragma once

#include <Windows.h>

typedef UINT MMRESULT;

extern "C" {
MMRESULT timeBeginPeriod(UINT period);
MMRESULT timeEndPeriod(UINT period);
DWORD timeGetTime(void);
}

#define TIMERR_NOERROR 0

