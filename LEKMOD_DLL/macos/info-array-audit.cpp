// Generated bounded read-only array reader. Explicit process opt-in only.
#include "CvGameCoreDLLPCH.h"
#include "Lua/CvLuaSupport.h"
#include <cstdlib>
#include <cstring>
int LekmodMacReadInfoArray(lua_State* L)
{
 const char* enabled=std::getenv("LEKMOD_CONFIG_AUDIT");
 if (!enabled || std::strcmp(enabled,"1")!=0) return luaL_error(L,"ReadInfoArrayForTest requires the explicit test environment");
 const char* key=luaL_checkstring(L,1);
 const lua_Number raw=luaL_checknumber(L,2);
 if (raw!=raw || raw<0 || raw>65535) return luaL_error(L,"invalid array owner index");
 const int id=static_cast<int>(raw);
 if (raw!=static_cast<lua_Number>(id)) return luaL_error(L,"noninteger array owner index");
 if (std::strcmp(key,"Buildings.m_piSeaPlotYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetSeaPlotYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piRiverPlotYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetRiverPlotYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piLakePlotYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetLakePlotYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piSeaResourceYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetSeaResourceYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piYieldChangePerPop") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangePerPop(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piYieldChangePerReligion") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangePerReligion(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piYieldModifier") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piAreaYieldModifier") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetAreaYieldModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piGlobalYieldModifier") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetGlobalYieldModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piTechEnhancedYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetTechEnhancedYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piSameLandMassYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetSameLandMassYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piDifferentLandMassYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetDifferentLandMassYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piResourceQuantityRequirements") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->GetResourceQuantityRequirement(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piResourceQuantity") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->GetResourceQuantity(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_paiHurryModifier") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumHurryInfos())!=2) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumHurryInfos())<2) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,2,0);
  for (int i=0;i<2;++i)
  {
   lua_pushinteger(L,info->GetHurryModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piUnitCombatFreeExperience") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())!=18) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())<18) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,18,0);
  for (int i=0;i<18;++i)
  {
   lua_pushinteger(L,info->GetUnitCombatFreeExperience(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piUnitCombatProductionModifiers") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())!=18) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())<18) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,18,0);
  for (int i=0;i<18;++i)
  {
   lua_pushinteger(L,info->GetUnitCombatProductionModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piDomainFreeExperience") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_DOMAIN_TYPES)!=5) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_DOMAIN_TYPES)<5) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,5,0);
  for (int i=0;i<5;++i)
  {
   lua_pushinteger(L,info->GetDomainFreeExperience(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piDomainFreeExperiencePerGreatWork") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_DOMAIN_TYPES)!=5) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_DOMAIN_TYPES)<5) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,5,0);
  for (int i=0;i<5;++i)
  {
   lua_pushinteger(L,info->GetDomainFreeExperiencePerGreatWork(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piDomainProductionModifier") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_DOMAIN_TYPES)!=5) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_DOMAIN_TYPES)<5) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,5,0);
  for (int i=0;i<5;++i)
  {
   lua_pushinteger(L,info->GetDomainProductionModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piPrereqNumOfBuildingClass") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetPrereqNumOfBuildingClass(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_pbBuildingClassNeededInCity") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushboolean(L,info->IsBuildingClassNeededInCity(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piNumFreeUnits") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitInfos())!=267) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitInfos())<267) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,267,0);
  for (int i=0;i<267;++i)
  {
   lua_pushinteger(L,info->GetNumFreeUnits(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_paiBuildingClassHappiness") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassHappiness(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piLockedBuildingClasses") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetLockedBuildingClasses(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piPrereqAndTechs") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNUM_BUILDING_AND_TECH_PREREQS())<3) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,3,0);
  for (int i=0;i<3;++i)
  {
   lua_pushinteger(L,info->GetPrereqAndTechs(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piLocalResourceAnds") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNUM_BUILDING_RESOURCE_PREREQS())<6) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,6,0);
  for (int i=0;i<6;++i)
  {
   lua_pushinteger(L,info->GetLocalResourceAnd(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piLocalResourceOrs") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNUM_BUILDING_RESOURCE_PREREQS())<6) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,6,0);
  for (int i=0;i<6;++i)
  {
   lua_pushinteger(L,info->GetLocalResourceOr(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Buildings.m_piGarrisonYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildingInfos())!=269 || id>=269) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBuildingEntry* info=GC.getBuildingInfo(static_cast<BuildingTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetGarrisonYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_piProductionTraits") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTraitInfos())!=115) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTraitInfos())<115) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,115,0);
  for (int i=0;i<115;++i)
  {
   lua_pushinteger(L,info->GetProductionTraits(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_piResourceQuantityRequirements") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->GetResourceQuantityRequirement(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_piProductionModifierBuildings") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingInfos())!=269) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingInfos())<269) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,269,0);
  for (int i=0;i<269;++i)
  {
   lua_pushinteger(L,info->GetBuildingProductionModifier(static_cast<BuildingTypes>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbFreePromotions") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumPromotionInfos())!=343) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumPromotionInfos())<343) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,343,0);
  for (int i=0;i<343;++i)
  {
   lua_pushboolean(L,info->GetFreePromotions(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbUpgradeUnitClass") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitClassInfos())!=113) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitClassInfos())<113) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,113,0);
  for (int i=0;i<113;++i)
  {
   lua_pushboolean(L,info->GetUpgradeUnitClass(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbUnitAIType") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_UNITAI_TYPES)!=42) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_UNITAI_TYPES)<42) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,42,0);
  for (int i=0;i<42;++i)
  {
   lua_pushboolean(L,info->GetUnitAIType(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbNotUnitAIType") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_UNITAI_TYPES)!=42) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_UNITAI_TYPES)<42) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,42,0);
  for (int i=0;i<42;++i)
  {
   lua_pushboolean(L,info->GetNotUnitAIType(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbBuilds") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildInfos())!=72) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildInfos())<72) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,72,0);
  for (int i=0;i<72;++i)
  {
   lua_pushboolean(L,info->GetBuilds(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbGreatPeoples") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumSpecialistInfos())!=7) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumSpecialistInfos())<7) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,7,0);
  for (int i=0;i<7;++i)
  {
   lua_pushboolean(L,info->GetGreatPeoples(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbBuildings") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingInfos())!=269) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingInfos())<269) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,269,0);
  for (int i=0;i<269;++i)
  {
   lua_pushboolean(L,info->GetBuildings(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Units.m_pbBuildingClassRequireds") == 0)
 {
  if (static_cast<int>(GC.getNumUnitInfos())!=267 || id>=267) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvUnitEntry* info=GC.getUnitInfo(static_cast<UnitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushboolean(L,info->GetBuildingClassRequireds(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Traits.m_piWorldWonderYieldChanges") == 0)
 {
  if (static_cast<int>(GC.getNumTraitInfos())!=115 || id>=115) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvTraitEntry* info=GC.getTraitInfo(static_cast<TraitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetWorldWonderYieldChanges(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Traits.m_piPuppetYieldModifiers") == 0)
 {
  if (static_cast<int>(GC.getNumTraitInfos())!=115 || id>=115) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvTraitEntry* info=GC.getTraitInfo(static_cast<TraitTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetPuppetYieldModifiers(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piYieldModifier") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piCityYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetCityYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piCoastalCityYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetCoastalCityYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piCapitalYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetCapitalYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piCapitalYieldPerPopChange") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetCapitalYieldPerPopChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piCapitalYieldModifier") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetCapitalYieldModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piGreatWorkYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetGreatWorkYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piSpecialistExtraYield") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetSpecialistExtraYield(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiHurryModifier") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumHurryInfos())!=2) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumHurryInfos())<2) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,2,0);
  for (int i=0;i<2;++i)
  {
   lua_pushinteger(L,info->GetHurryModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_pabSpecialistValid") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumSpecialistInfos())!=7) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumSpecialistInfos())<7) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,7,0);
  for (int i=0;i<7;++i)
  {
   lua_pushboolean(L,info->IsSpecialistValid(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiUnitCombatFreeExperiences") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())!=18) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())<18) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,18,0);
  for (int i=0;i<18;++i)
  {
   lua_pushinteger(L,info->GetUnitCombatFreeExperiences(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiUnitCombatProductionModifiers") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())!=18) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitCombatClassInfos())<18) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,18,0);
  for (int i=0;i<18;++i)
  {
   lua_pushinteger(L,info->GetUnitCombatProductionModifiers(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiBuildingClassCultureChanges") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassCultureChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiBuildingClassProductionModifiers") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassProductionModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiBuildingClassTourismModifiers") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassTourismModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiBuildingClassHappiness") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassHappiness(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiFreeUnitClasses") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitClassInfos())!=113) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitClassInfos())<113) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,113,0);
  for (int i=0;i<113;++i)
  {
   lua_pushinteger(L,info->GetNumFreeUnitsByClass(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_paiTourismOnUnitCreation") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumUnitClassInfos())!=113) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumUnitClassInfos())<113) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,113,0);
  for (int i=0;i<113;++i)
  {
   lua_pushinteger(L,info->GetTourismByUnitClassCreated(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piPolicyResourceQuantity") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->GetPolicyResourceQuantity(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Policies.m_piImprovementCultureChange") == 0)
 {
  if (static_cast<int>(GC.getNumPolicyInfos())!=136 || id>=136) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumImprovementInfos())!=46) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumImprovementInfos())<46) return luaL_error(L,"array getter bound changed");
  const CvPolicyEntry* info=GC.getPolicyInfo(static_cast<PolicyTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,46,0);
  for (int i=0;i<46;++i)
  {
   lua_pushinteger(L,info->GetImprovementCultureChanges(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piYieldChangeAnySpecialist") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangeAnySpecialist(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piYieldChangeTradeRoute") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangeTradeRoute(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piYieldChangeNaturalWonder") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangeNaturalWonder(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piYieldModifierNaturalWonder") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldModifierNaturalWonder(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piMaxYieldModifierPerFollower") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetMaxYieldModifierPerFollower(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piResourceHappiness") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->GetResourceHappiness(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piResourceQuantityModifiers") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->GetResourceQuantityModifier(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_paiBuildingClassHappiness") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassHappiness(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_paiBuildingClassTourism") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushinteger(L,info->GetBuildingClassTourism(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_pbFaithPurchaseUnitEraEnabled") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumEraInfos())!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumEraInfos())<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushboolean(L,info->IsFaithUnitPurchaseEra(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_pbBuildingClassEnabled") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushboolean(L,info->IsBuildingClassEnabled(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Beliefs.m_piYieldChangeWorldWonder") == 0)
 {
  if (static_cast<int>(GC.getNumBeliefInfos())!=94 || id>=94) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvBeliefEntry* info=GC.getBeliefInfo(static_cast<BeliefTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangeWorldWonder(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_pbTerrainMakesValid") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTerrainInfos())!=9) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTerrainInfos())<9) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,9,0);
  for (int i=0;i<9;++i)
  {
   lua_pushboolean(L,info->GetTerrainMakesValid(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_pbFeatureMakesValid") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumFeatureInfos())!=26) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumFeatureInfos())<26) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,26,0);
  for (int i=0;i<26;++i)
  {
   lua_pushboolean(L,info->GetFeatureMakesValid(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_pbImprovementMakesValid") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumImprovementInfos())!=46) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumImprovementInfos())<46) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,46,0);
  for (int i=0;i<46;++i)
  {
   lua_pushboolean(L,info->GetImprovementMakesValid(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piYieldPerEra") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetYieldChangePerEra(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piAdjacentCityYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetAdjacentCityYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piAdjacentMountainYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetAdjacentMountainYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piCoastalLandYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetCoastalLandYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piFreshWaterChange") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetFreshWaterYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piHillsYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetHillsYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piRiverSideYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetRiverSideYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piPrereqNatureYield") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->GetPrereqNatureYield(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Improvements.m_piFlavorValue") == 0)
 {
  if (static_cast<int>(GC.getNumImprovementInfos())!=46 || id>=46) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumFlavorTypes())!=39) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumFlavorTypes())<39) return luaL_error(L,"array getter bound changed");
  const CvImprovementEntry* info=GC.getImprovementInfo(static_cast<ImprovementTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,39,0);
  for (int i=0;i<39;++i)
  {
   lua_pushinteger(L,info->GetFlavorValue(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Specialists.m_piFlavorValue") == 0)
 {
  if (static_cast<int>(GC.getNumSpecialistInfos())!=7 || id>=7) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumFlavorTypes())!=39) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumFlavorTypes())<39) return luaL_error(L,"array getter bound changed");
  const CvSpecialistInfo* info=GC.getSpecialistInfo(static_cast<SpecialistTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,39,0);
  for (int i=0;i<39;++i)
  {
   lua_pushinteger(L,info->getFlavorValue(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Specialists.m_piYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumSpecialistInfos())!=7 || id>=7) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvSpecialistInfo* info=GC.getSpecialistInfo(static_cast<SpecialistTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"HandicapInfos.m_pbFreeTechs") == 0)
 {
  if (static_cast<int>(GC.getNumHandicapInfos())!=9 || id>=9) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTechInfos())<81) return luaL_error(L,"array getter bound changed");
  const CvHandicapInfo* info=GC.getHandicapInfo(static_cast<HandicapTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,81,0);
  for (int i=0;i<81;++i)
  {
   lua_pushboolean(L,info->isFreeTechs(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"HandicapInfos.m_pbAIFreeTechs") == 0)
 {
  if (static_cast<int>(GC.getNumHandicapInfos())!=9 || id>=9) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTechInfos())<81) return luaL_error(L,"array getter bound changed");
  const CvHandicapInfo* info=GC.getHandicapInfo(static_cast<HandicapTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,81,0);
  for (int i=0;i<81;++i)
  {
   lua_pushboolean(L,info->isAIFreeTechs(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Leaders.m_piMajorCivApproachBiases") == 0)
 {
  if (static_cast<int>(GC.getNumLeaderHeadInfos())!=117 || id>=117) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_MAJOR_CIV_APPROACHES)!=7) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_MAJOR_CIV_APPROACHES)<7) return luaL_error(L,"array getter bound changed");
  const CvLeaderHeadInfo* info=GC.getLeaderHeadInfo(static_cast<LeaderHeadTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,7,0);
  for (int i=0;i<7;++i)
  {
   lua_pushinteger(L,info->GetMajorCivApproachBias(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Leaders.m_piMinorCivApproachBiases") == 0)
 {
  if (static_cast<int>(GC.getNumLeaderHeadInfos())!=117 || id>=117) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_MINOR_CIV_APPROACHES)!=5) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_MINOR_CIV_APPROACHES)<5) return luaL_error(L,"array getter bound changed");
  const CvLeaderHeadInfo* info=GC.getLeaderHeadInfo(static_cast<LeaderHeadTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,5,0);
  for (int i=0;i<5;++i)
  {
   lua_pushinteger(L,info->GetMinorCivApproachBias(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Leaders.m_pbTraits") == 0)
 {
  if (static_cast<int>(GC.getNumLeaderHeadInfos())!=117 || id>=117) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTraitInfos())!=115) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTraitInfos())<115) return luaL_error(L,"array getter bound changed");
  const CvLeaderHeadInfo* info=GC.getLeaderHeadInfo(static_cast<LeaderHeadTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,115,0);
  for (int i=0;i<115;++i)
  {
   lua_pushboolean(L,info->hasTrait(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Terrains.m_piYields") == 0)
 {
  if (static_cast<int>(GC.getNumTerrainInfos())!=9 || id>=9) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvTerrainInfo* info=GC.getTerrainInfo(static_cast<TerrainTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getYield(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Terrains.m_piRiverYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumTerrainInfos())!=9 || id>=9) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvTerrainInfo* info=GC.getTerrainInfo(static_cast<TerrainTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getRiverYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Terrains.m_piHillsYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumTerrainInfos())!=9 || id>=9) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvTerrainInfo* info=GC.getTerrainInfo(static_cast<TerrainTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getHillsYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Terrains.m_piMountainYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumTerrainInfos())!=9 || id>=9) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvTerrainInfo* info=GC.getTerrainInfo(static_cast<TerrainTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getMountainYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Features.m_piYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumFeatureInfos())!=26 || id>=26) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvFeatureInfo* info=GC.getFeatureInfo(static_cast<FeatureTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Features.m_piRiverYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumFeatureInfos())!=26 || id>=26) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvFeatureInfo* info=GC.getFeatureInfo(static_cast<FeatureTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getRiverYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Features.m_piHillsYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumFeatureInfos())!=26 || id>=26) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvFeatureInfo* info=GC.getFeatureInfo(static_cast<FeatureTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getHillsYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Features.m_piMountainYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumFeatureInfos())!=26 || id>=26) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvFeatureInfo* info=GC.getFeatureInfo(static_cast<FeatureTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getMountainYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Features.m_pbTerrain") == 0)
 {
  if (static_cast<int>(GC.getNumFeatureInfos())!=26 || id>=26) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTerrainInfos())!=9) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTerrainInfos())<9) return luaL_error(L,"array getter bound changed");
  const CvFeatureInfo* info=GC.getFeatureInfo(static_cast<FeatureTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,9,0);
  for (int i=0;i<9;++i)
  {
   lua_pushboolean(L,info->isTerrain(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Resources.m_piYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumResourceInfos())!=57 || id>=57) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvResourceInfo* info=GC.getResourceInfo(static_cast<ResourceTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Resources.m_piFlavor") == 0)
 {
  if (static_cast<int>(GC.getNumResourceInfos())!=57 || id>=57) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumFlavorTypes())!=39) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumFlavorTypes())<39) return luaL_error(L,"array getter bound changed");
  const CvResourceInfo* info=GC.getResourceInfo(static_cast<ResourceTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,39,0);
  for (int i=0;i<39;++i)
  {
   lua_pushinteger(L,info->getFlavorValue(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Resources.m_pbTerrain") == 0)
 {
  if (static_cast<int>(GC.getNumResourceInfos())!=57 || id>=57) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTerrainInfos())!=9) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTerrainInfos())<9) return luaL_error(L,"array getter bound changed");
  const CvResourceInfo* info=GC.getResourceInfo(static_cast<ResourceTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,9,0);
  for (int i=0;i<9;++i)
  {
   lua_pushboolean(L,info->isTerrain(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Resources.m_pbFeature") == 0)
 {
  if (static_cast<int>(GC.getNumResourceInfos())!=57 || id>=57) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumFeatureInfos())!=26) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumFeatureInfos())<26) return luaL_error(L,"array getter bound changed");
  const CvResourceInfo* info=GC.getResourceInfo(static_cast<ResourceTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,26,0);
  for (int i=0;i<26;++i)
  {
   lua_pushboolean(L,info->isFeature(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Resources.m_pbFeatureTerrain") == 0)
 {
  if (static_cast<int>(GC.getNumResourceInfos())!=57 || id>=57) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTerrainInfos())!=9) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTerrainInfos())<9) return luaL_error(L,"array getter bound changed");
  const CvResourceInfo* info=GC.getResourceInfo(static_cast<ResourceTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,9,0);
  for (int i=0;i<9;++i)
  {
   lua_pushboolean(L,info->isFeatureTerrain(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Builds.m_paiTechTimeChange") == 0)
 {
  if (static_cast<int>(GC.getNumBuildInfos())!=72 || id>=72) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTechInfos())<81) return luaL_error(L,"array getter bound changed");
  const CvBuildInfo* info=GC.getBuildInfo(static_cast<BuildTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,81,0);
  for (int i=0;i<81;++i)
  {
   lua_pushinteger(L,info->getTechTimeChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Routes.m_piYieldChange") == 0)
 {
  if (static_cast<int>(GC.getNumRouteInfos())!=2 || id>=2) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(NUM_YIELD_TYPES)!=8) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(NUM_YIELD_TYPES)<8) return luaL_error(L,"array getter bound changed");
  const CvRouteInfo* info=GC.getRouteInfo(static_cast<RouteTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,8,0);
  for (int i=0;i<8;++i)
  {
   lua_pushinteger(L,info->getYieldChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Routes.m_piTechMovementChange") == 0)
 {
  if (static_cast<int>(GC.getNumRouteInfos())!=2 || id>=2) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTechInfos())<81) return luaL_error(L,"array getter bound changed");
  const CvRouteInfo* info=GC.getRouteInfo(static_cast<RouteTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,81,0);
  for (int i=0;i<81;++i)
  {
   lua_pushinteger(L,info->getTechMovementChange(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Routes.m_piResourceQuantityRequirements") == 0)
 {
  if (static_cast<int>(GC.getNumRouteInfos())!=2 || id>=2) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumResourceInfos())!=57) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumResourceInfos())<57) return luaL_error(L,"array getter bound changed");
  const CvRouteInfo* info=GC.getRouteInfo(static_cast<RouteTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,57,0);
  for (int i=0;i<57;++i)
  {
   lua_pushinteger(L,info->getResourceQuantityRequirement(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Civilizations.m_pbCivilizationFreeBuildingClass") == 0)
 {
  if (static_cast<int>(GC.getNumCivilizationInfos())!=118 || id>=118) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())!=176) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumBuildingClassInfos())<176) return luaL_error(L,"array getter bound changed");
  const CvCivilizationInfo* info=GC.getCivilizationInfo(static_cast<CivilizationTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,176,0);
  for (int i=0;i<176;++i)
  {
   lua_pushboolean(L,info->isCivilizationFreeBuildingClass(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Civilizations.m_pbCivilizationFreeTechs") == 0)
 {
  if (static_cast<int>(GC.getNumCivilizationInfos())!=118 || id>=118) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTechInfos())<81) return luaL_error(L,"array getter bound changed");
  const CvCivilizationInfo* info=GC.getCivilizationInfo(static_cast<CivilizationTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,81,0);
  for (int i=0;i<81;++i)
  {
   lua_pushboolean(L,info->isCivilizationFreeTechs(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Civilizations.m_pbCivilizationDisableTechs") == 0)
 {
  if (static_cast<int>(GC.getNumCivilizationInfos())!=118 || id>=118) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumTechInfos())!=81) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumTechInfos())<81) return luaL_error(L,"array getter bound changed");
  const CvCivilizationInfo* info=GC.getCivilizationInfo(static_cast<CivilizationTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,81,0);
  for (int i=0;i<81;++i)
  {
   lua_pushboolean(L,info->isCivilizationDisableTechs(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 if (std::strcmp(key,"Civilizations.m_pbLeaders") == 0)
 {
  if (static_cast<int>(GC.getNumCivilizationInfos())!=118 || id>=118) return luaL_error(L,"array owner bounds/data shape changed");
  if (static_cast<int>(GC.getNumLeaderHeadInfos())!=117) return luaL_error(L,"array dimension changed");
  if (static_cast<int>(GC.getNumLeaderHeadInfos())<117) return luaL_error(L,"array getter bound changed");
  const CvCivilizationInfo* info=GC.getCivilizationInfo(static_cast<CivilizationTypes>(id));
  if (!info) return luaL_error(L,"array owner entry missing");
  lua_createtable(L,117,0);
  for (int i=0;i<117;++i)
  {
   lua_pushboolean(L,info->isLeaders(static_cast<int>(i)));
   lua_rawseti(L,-2,i+1);
  }
  return 1;
 }
 return luaL_error(L,"unsupported array-cache key");
}
