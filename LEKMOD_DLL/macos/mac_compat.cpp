#include "CvGameCoreDLLPCH.h"
#include "CvEnumSerialization.h"
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

namespace {
template <typename EnumType>
FDataStream& WriteEnum(FDataStream& stream, const EnumType& value) {
  stream << static_cast<int>(value);
  return stream;
}

template <typename EnumType>
FDataStream& ReadEnum(FDataStream& stream, EnumType& value) {
  int serialized_value = 0;
  stream >> serialized_value;
  value = static_cast<EnumType>(serialized_value);
  return stream;
}
}  // namespace

FDataStream& operator<<(FDataStream& stream, const ButtonPopupTypes& value) {
  return WriteEnum(stream, value);
}

FDataStream& operator>>(FDataStream& stream, ButtonPopupTypes& value) {
  return ReadEnum(stream, value);
}

FDataStream& operator<<(FDataStream& stream, const DiploUIStateTypes& value) {
  return WriteEnum(stream, value);
}

FDataStream& operator>>(FDataStream& stream, DiploUIStateTypes& value) {
  return ReadEnum(stream, value);
}

FDataStream& operator<<(FDataStream& stream,
                        const LeaderheadAnimationTypes& value) {
  return WriteEnum(stream, value);
}

FDataStream& operator>>(FDataStream& stream,
                        LeaderheadAnimationTypes& value) {
  return ReadEnum(stream, value);
}
