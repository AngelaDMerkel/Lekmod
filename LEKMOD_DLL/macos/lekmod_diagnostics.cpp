#include "CvGameCoreDLLPCH.h"
#include "LekmodMacDiagnostics.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>

void LekmodMacLogVisualEvent(const char* eventName, int owner, int objectId,
                            int objectType, int x, int y, int detail) {
  static volatile LONG sequence = 0;
  static FILE* logFile = NULL;
  if (!logFile) {
    const char* userHome = std::getenv("HOME");
    if (!userHome) return;
    char path[1024];
    const char* suffix =
        "/Library/Application Support/Sid Meier's Civilization 5/Logs/LekmodRender.log";
    if (std::strlen(userHome) + std::strlen(suffix) >= sizeof(path)) return;
    std::snprintf(path, sizeof(path), "%s%s", userHome, suffix);
    logFile = std::fopen(path, "a");
    if (!logFile) return;
    std::setvbuf(logFile, NULL, _IOLBF, 0);
  }

  flockfile(logFile);
  std::fprintf(logFile,
      "[LEKMOD_RENDER] seq=%d ms=%u event=%s owner=%d id=%d type=%d x=%d y=%d detail=%d\n",
      InterlockedIncrement(&sequence), timeGetTime(), eventName, owner,
      objectId, objectType, x, y, detail);
  std::fflush(logFile);
  funlockfile(logFile);
}

