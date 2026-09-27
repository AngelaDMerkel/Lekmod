#!/usr/bin/env python3
"""Generate the opt-in read-only probe from reviewed compiled bindings.

Writes the probe/metadata and adds its macOS registration/build source if absent.
"""
from pathlib import Path
import json,re
import argparse,hashlib,os
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);a=p.parse_args();input_path=a.input.resolve()
root=Path(__file__).resolve().parents[2];os.chdir(root);data=json.loads(input_path.read_text())
for row in data['rows']:
 if row.get('bindings'):
  assert hashlib.sha256(Path(row['source']).read_bytes()).hexdigest()==row['source_sha256'], 'changed source: '+row['source']
  for name,b in row['bindings'].items():
   assert re.fullmatch(r'[A-Za-z_]\w*',name)and re.fullmatch(r'[A-Za-z_]\w*',b['getter']), 'invalid generated identifier'
gh=Path('LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvGlobals.h').read_text(errors='replace')
names={'Buildings':'Building','Units':'Unit','UnitPromotions':'Promotion','Traits':'Trait','Policies':'Policy','Beliefs':'Belief','Improvements':'Improvement','Technologies':'Tech','Projects':'Project','Specialists':'Specialist','HandicapInfos':'Handicap','GameSpeeds':'GameSpeed','Eras':'Era','Leaders':'LeaderHead','Worlds':'World','Terrains':'Terrain','Features':'Feature','Resources':'Resource','Builds':'Build','Routes':'Route','GameOptions':'GameOption','PolicyBranchTypes':'PolicyBranch'}
rows=[];skipped=[]
for r in data['rows']:
 if not r.get('bindings'):continue
 stem=names[r['table']];get='get'+stem+'Info';count='getNum'+stem+'Infos'
 m=re.search(r'\b'+get+r'\(\s*(\w+)\s+\w+\s*\)',gh)
 if not m or count not in gh:skipped.append({'table':r['table'],'reason':'No global cached-info accessor; do not synthesize one from the expected database.'});continue
 rows.append({**r,'getter':get,'count':count,'index_type':m[1]})
out={'schema':1,'scope':'Read-only compiled-cache comparison, not gameplay-outcome coverage.','generation_input':'Clang AST under exact build-report flags','tables':rows,'skipped_tables':skipped}
Path('LEKMOD_DLL/macos/info-cache-audit-bindings.json').write_text(json.dumps(out,indent=2)+'\n')
cpp=['// Generated from info-cache-audit-bindings.json. Read-only, explicit test opt-in.','#include "CvGameCoreDLLPCH.h"','#include "Lua/CvLuaSupport.h"','#include <cstdlib>','#include <cstring>','int LekmodMacReadInfoCache(lua_State* L)','{',' const char* enabled=std::getenv("LEKMOD_CONFIG_AUDIT");',' if (!enabled || std::strcmp(enabled,"1")!=0) return luaL_error(L,"ReadInfoCacheForTest requires the explicit test environment");',' const char* table=luaL_checkstring(L,1);',' const int id=luaL_checkint(L,2);']
for r in rows:
 cpp+=[' if (std::strcmp(table,"'+r['table']+'") == 0)',' {','  if (id<0 || id>=static_cast<int>(GC.'+r['count']+'())) return luaL_error(L,"info-cache index out of bounds");','  const '+r['class']+'* info=GC.'+r['getter']+'(static_cast<'+r['index_type']+'>(id));','  if (!info) return luaL_error(L,"info-cache entry missing");','  lua_createtable(L,0,'+str(len(r['bindings']))+');']
 for column,b in sorted(r['bindings'].items()):
  push='lua_pushboolean'if b['reader']=='GetBool'else'lua_pushnumber'if b['reader']in ('GetFloat','GetDouble')else'lua_pushinteger'
  cpp+=['  '+push+'(L,info->'+b['getter']+'()); lua_setfield(L,-2,"'+column+'");']
 cpp+=['  return 1;',' }']
cpp+=[' return luaL_error(L,"unsupported info-cache table");','}']
Path('LEKMOD_DLL/macos/info-cache-audit.cpp').write_text('\n'.join(cpp)+'\n')
p=Path('LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaGame.cpp');b=p.read_bytes()
if b'LekmodMacReadInfoCache'not in b:
 at=b'#define Method(func) RegisterMethod(L, l##func, #func);';assert at in b;b=b.replace(at,b'#if defined(__APPLE__)\nextern int LekmodMacReadInfoCache(lua_State* L);\n#endif\n\n'+at,1)
 at=b'void CvLuaGame::RegisterMembers(lua_State* L)\n{';assert at in b;b=b.replace(at,at+b'\n#if defined(__APPLE__)\n\tRegisterMethod(L, LekmodMacReadInfoCache, "ReadInfoCacheForTest");\n#endif',1);p.write_bytes(b)
p=Path('LEKMOD_DLL/macos/build.json');cfg=json.loads(p.read_text())
if 'info-cache-audit.cpp'not in cfg['extra_sources']:cfg['extra_sources'].append('info-cache-audit.cpp');p.write_text(json.dumps(cfg,indent=2)+'\n')
print('Opt-in read-only probe:',sum(len(r['bindings'])for r in rows),'fields,',len(rows),'tables; excluded',skipped)
