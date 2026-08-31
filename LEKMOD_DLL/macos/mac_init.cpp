#include "CvGameCoreDLLPCH.h"
#include "CvDllContext.h"

__attribute__((constructor)) static void LekmodMacInitialize() {
  timeBeginPeriod(1);
  CvDllGameContext::InitializeSingleton();
}

__attribute__((destructor)) static void LekmodMacTerminate() {
  timeEndPeriod(1);
  CvDllGameContext::DestroySingleton();
}

