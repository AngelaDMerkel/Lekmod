#pragma once

#include <cstdio>
#include <cwchar>

typedef wchar_t TCHAR;

#define _T(value) L##value
#define _tprintf std::wprintf
#define _stprintf_s std::swprintf

