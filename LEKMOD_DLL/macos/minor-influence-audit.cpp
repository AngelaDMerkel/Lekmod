// Exact stored influence, available only to an explicitly opted-in test process.
#include "CvGameCoreDLLPCH.h"
#include "CvMinorCivAI.h"
#include "Lua/CvLuaSupport.h"
#include <cstdlib>
#include <cstring>

int LekmodMacReadMinorInfluence(lua_State* L) {
 const char* enabled = std::getenv("LEKMOD_CONFIG_AUDIT");
 if (!enabled || std::strcmp(enabled, "1") != 0)
  return luaL_error(L, "ReadMinorInfluenceForTest requires the explicit test environment");
 const lua_Number minorRaw = luaL_checknumber(L, 1);
 const lua_Number majorRaw = luaL_checknumber(L, 2);
 if (minorRaw != minorRaw || minorRaw < MAX_MAJOR_CIVS || minorRaw >= MAX_CIV_PLAYERS ||
     majorRaw != majorRaw || majorRaw < 0 || majorRaw >= MAX_MAJOR_CIVS)
  return luaL_error(L, "invalid minor or major influence index");
 const int minorID = static_cast<int>(minorRaw);
 const int majorID = static_cast<int>(majorRaw);
 if (minorRaw != static_cast<lua_Number>(minorID) || majorRaw != static_cast<lua_Number>(majorID))
  return luaL_error(L, "noninteger influence index");
 CvPlayer& minor = GET_PLAYER(static_cast<PlayerTypes>(minorID));
 CvPlayer& major = GET_PLAYER(static_cast<PlayerTypes>(majorID));
 if (!minor.isAlive() || !minor.isMinorCiv() || minor.isBarbarian() ||
     !major.isAlive() || major.isMinorCiv() || major.isBarbarian())
  return luaL_error(L, "inactive or invalid influence owner roles");
 const CvMinorCivAI* ai = minor.GetMinorCivAI();
 if (!ai) return luaL_error(L, "minor influence state missing");
 // This const accessor reads the saved hundredths directly. It does not set
 // influence, advance time, update alliances or change synchronization state.
 lua_pushinteger(L, ai->GetBaseFriendshipWithMajorTimes100(static_cast<PlayerTypes>(majorID)));
 return 1;
}
