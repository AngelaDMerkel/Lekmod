#!/usr/bin/env python3
"""Generate an opt-in bounded cache-array reader and separate data-driven scenario."""
import argparse,hashlib,json,re
from pathlib import Path
from playtest_batch import lua as lua_value
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2];port=root/'LEKMOD_DLL/macos';data=json.loads(a.input.read_text());rows=data['bindings'];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for r in rows:
 assert sha(root/r['source'])==r['source_sha256']
 assert re.fullmatch(r'[\w.]+',r['key'])and re.fullmatch(r'\w+',r['getter'])and re.fullmatch(r'[\w: ]+',r['parameter_type'])
 assert 0<r['owner_slots']<65536 and 0<r['length']<=r['dimension_slots']<65536
 assert all(re.fullmatch(r'GC\.\w+\(\)|NUM_\w+|\d+',x)for x in r['bounds']+[r['dimension_expression']])
assert sha(root/data['utility']['path'])==data['utility']['sha256']
(port/'info-array-audit-bindings.json').write_text(json.dumps(data,indent=2)+'\n')
cpp=['// Generated bounded read-only array reader. Explicit process opt-in only.','#include "CvGameCoreDLLPCH.h"','#include "Lua/CvLuaSupport.h"','#include <cstdlib>','#include <cstring>','int LekmodMacReadInfoArray(lua_State* L)','{',' const char* enabled=std::getenv("LEKMOD_CONFIG_AUDIT");',' if (!enabled || std::strcmp(enabled,"1")!=0) return luaL_error(L,"ReadInfoArrayForTest requires the explicit test environment");',' const char* key=luaL_checkstring(L,1);',' const lua_Number raw=luaL_checknumber(L,2);',' if (raw!=raw || raw<0 || raw>65535) return luaL_error(L,"invalid array owner index");',' const int id=static_cast<int>(raw);',' if (raw!=static_cast<lua_Number>(id)) return luaL_error(L,"noninteger array owner index");']
for r in rows:
 cpp += [' if (std::strcmp(key,"'+r['key']+'") == 0)',' {',f'  if (static_cast<int>(GC.{r["owner_count"]}())!={r["owner_slots"]} || id>={r["owner_slots"]}) return luaL_error(L,"array owner bounds/data shape changed");',f'  if (static_cast<int>({r["dimension_expression"]})!={r["dimension_slots"]}) return luaL_error(L,"array dimension changed");']
 for bound in r['bounds']:cpp += [f'  if (static_cast<int>({bound})<{r["length"]}) return luaL_error(L,"array getter bound changed");']
 cpp += [f'  const {r["class_name"]}* info=GC.{r["owner_getter"]}(static_cast<{r["owner_index_type"]}>(id));','  if (!info) return luaL_error(L,"array owner entry missing");',f'  lua_createtable(L,{r["length"]},0);',f'  for (int i=0;i<{r["length"]};++i)', '  {',f'   {"lua_pushboolean"if r["mode"]=="membership"else"lua_pushinteger"}(L,info->{r["getter"]}(static_cast<{r["parameter_type"]}>(i)));','   lua_rawseti(L,-2,i+1);','  }','  return 1;',' }']
cpp += [' return luaL_error(L,"unsupported array-cache key");','}'];(port/'info-array-audit.cpp').write_text('\n'.join(cpp)+'\n')
p=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaGame.cpp';s=p.read_text()
if 'LekmodMacReadInfoArray'not in s:
 s=s.replace('extern int LekmodMacReadInfoCache(lua_State* L);','extern int LekmodMacReadInfoCache(lua_State* L);\nextern int LekmodMacReadInfoArray(lua_State* L);',1)
 s=s.replace('RegisterMethod(L, LekmodMacReadInfoCache, "ReadInfoCacheForTest");','RegisterMethod(L, LekmodMacReadInfoCache, "ReadInfoCacheForTest");\n\tRegisterMethod(L, LekmodMacReadInfoArray, "ReadInfoArrayForTest");',1);p.write_text(s)
p=port/'build.json';cfg=json.loads(p.read_text())
if 'info-array-audit.cpp'not in cfg['extra_sources']:cfg['extra_sources'].append('info-array-audit.cpp');p.write_text(json.dumps(cfg,indent=2)+'\n')
minimal=[{k:r[k]for k in ['key','table','relation_table','index_table','index_column','owner_column','value_column','mode','default','length','owner_slots']}for r in rows]
tables=sorted({r['table']for r in rows});items=['arrays-'+t for t in tables]+['arrays-boundary-guards','arrays-read-only']
lua='-- Generated descriptors: actual cached getters are compared with resolved GameInfo.\nlocal descriptors='+lua_value(minimal)+'\nlocal tables='+lua_value(tables)+'\nLekmodScenario={name="array-cache",items='+lua_value(items)+'}\n'
lua+=(port/'array-cache-audit-scenario-body.lua').read_text();(port/'playtest-scenario-array-cache.lua').write_text(lua)
print(json.dumps({'arrays':len(rows),'tables':tables,'comparisons':sum(r['comparisons']for r in rows),'assertions':len(items)},indent=2))
