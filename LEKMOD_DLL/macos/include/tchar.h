#pragma once

#include <cstdio>
#include <cstring>

// The GameCore project is built with Visual Studio's MultiByte character set.
// Keep TCHAR narrow so its object layout and all engine-facing signatures match
// Aspyr's stock x86_64 GameCore library.
typedef char TCHAR;

#define _T(value) value
#define _tprintf std::printf
#define _stprintf_s std::snprintf
#define _tcslen std::strlen
#define _tcsicmp _stricmp
