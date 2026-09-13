#pragma once

#if defined(__APPLE__)
void LekmodMacLogVisualEvent(const char* eventName, int owner, int objectId,
	int objectType, int x, int y, int detail = 0);
#else
inline void LekmodMacLogVisualEvent(const char*, int, int, int, int, int, int = 0) {}
#endif
