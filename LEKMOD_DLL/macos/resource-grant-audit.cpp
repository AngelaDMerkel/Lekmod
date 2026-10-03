// Read-only native rule/history inspection, available only to an opted-in test process.
#include "CvGameCoreDLLPCH.h"
#include "Lua/CvLuaSupport.h"
#include <cstdlib>
#include <cstring>

namespace {
void integer(lua_State* L, const char* key, int value) {
 lua_pushinteger(L, value); lua_setfield(L, -2, key);
}
void boolean(lua_State* L, const char* key, bool value) {
 lua_pushboolean(L, value); lua_setfield(L, -2, key);
}
void rules(lua_State* L, const std::vector<FreeResourceCities>& values) {
 if (values.size() > 1024) { luaL_error(L, "resource rule vector exceeds diagnostic bound"); return; }
 lua_createtable(L, static_cast<int>(values.size()), 0);
 for (size_t i = 0; i < values.size(); ++i) {
  const FreeResourceCities& r = values[i]; lua_createtable(L, 0, 12);
  integer(L, "resource", r.m_eResource); integer(L, "quantity", r.m_iResourceQuantity);
  integer(L, "technology", r.m_eTechRequired); integer(L, "city_limit", r.m_iNumCities);
  integer(L, "group", r.m_iGroup); integer(L, "priority", r.m_iPriority);
  boolean(L, "city", r.m_bCity); boolean(L, "found", r.m_bFound);
  boolean(L, "tech", r.m_bTech); boolean(L, "unique_area", r.m_bUniqueArea);
  boolean(L, "cycle", r.m_bCycleGroup); boolean(L, "claim", r.m_bClaimPlot);
  lua_rawseti(L, -2, static_cast<int>(i) + 1);
 }
}
void pairs(lua_State* L, const std::vector<std::pair<int, int> >& values) {
 if (values.size() > 16384) { luaL_error(L, "resource history exceeds diagnostic bound"); return; }
 lua_createtable(L, static_cast<int>(values.size()), 0);
 for (size_t i = 0; i < values.size(); ++i) {
  lua_createtable(L, 0, 2); integer(L, "group", values[i].first); integer(L, "value", values[i].second);
  lua_rawseti(L, -2, static_cast<int>(i) + 1);
 }
}
}
int LekmodMacReadResourceGrants(lua_State* L) {
 const char* enabled = std::getenv("LEKMOD_CONFIG_AUDIT");
 if (!enabled || std::strcmp(enabled, "1") != 0)
  return luaL_error(L, "ReadResourceGrantsForTest requires the explicit test environment");
 const lua_Number raw = luaL_checknumber(L, 1);
 if (raw != raw || raw < 0 || raw >= MAX_MAJOR_CIVS) return luaL_error(L, "invalid resource owner");
 const int id = static_cast<int>(raw);
 if (raw != static_cast<lua_Number>(id)) return luaL_error(L, "noninteger resource owner");
 CvPlayer& player = GET_PLAYER(static_cast<PlayerTypes>(id));
 if (!player.isAlive() || player.isMinorCiv() || player.isBarbarian()) return luaL_error(L, "inactive resource owner");
 CvPlayerTraits* traits = player.GetPlayerTraits();
 if (!traits) return luaL_error(L, "resource owner traits missing");
 lua_createtable(L, 0, 9);
 integer(L, "owner", id); integer(L, "civilization", player.getCivilizationType());
 boolean(L, "founded_first_city", player.isFoundedFirstCity());
 rules(L, traits->GetFreeResourceCities()); lua_setfield(L, -2, "player_rules");
 pairs(L, traits->GetUsedGroupAreas()); lua_setfield(L, -2, "used_areas");
 pairs(L, traits->GetGroupPriority()); lua_setfield(L, -2, "priorities");
 integer(L, "player_city_gold", traits->GetFreeResourceCityYieldChange(YIELD_GOLD));
 lua_createtable(L, 0, 0); int index = 1;
 for (int i = 0; i < GC.getNumTraitInfos(); ++i) {
  const TraitTypes type = static_cast<TraitTypes>(i);
  const CvTraitEntry* info = GC.getTraitInfo(type);
  if (info && traits->HasTrait(type)) {
   lua_createtable(L, 0, 3); integer(L, "id", i);
   rules(L, info->GetFreeResourceCities()); lua_setfield(L, -2, "rules");
   integer(L, "city_gold", info->GetFreeResourceCityYieldChange(YIELD_GOLD));
   lua_rawseti(L, -2, index++);
  }
 }
 lua_setfield(L, -2, "trait_cache");
 lua_createtable(L, 0, 0); index = 1; int loop = 0;
 for (CvCity* city = player.firstCity(&loop); city; city = player.nextCity(&loop)) {
  lua_createtable(L, 0, 4); integer(L, "id", city->GetID()); integer(L, "area", city->plot()->getArea());
  integer(L, "grant_gold", city->GetYieldFromFreeResourceCity(YIELD_GOLD));
  lua_createtable(L, 0, 0);
  for (int i = 0; i < GC.getNumResourceInfos(); ++i) {
   const int quantity = city->GetFreeResource(static_cast<ResourceTypes>(i));
   if (quantity) { lua_pushinteger(L, quantity); lua_rawseti(L, -2, i); }
  }
  lua_setfield(L, -2, "free_resources"); lua_rawseti(L, -2, index++);
 }
 lua_setfield(L, -2, "cities");
 return 1;
}
