#!/usr/bin/env python3
"""Compile the actual diagnostic body against instrumented read-only getters."""
from pathlib import Path
import json,re,subprocess,tempfile
root=Path(__file__).resolve().parents[2];port=root/'LEKMOD_DLL/macos'
bindings=json.loads((port/'info-cache-audit-bindings.json').read_text())['tables']
source=(port/'info-cache-audit.cpp').read_text();body=source[source.index('int LekmodMacReadInfoCache'):]
prefix=r'''
#include <map>
#include <string>
#include <stdexcept>
#include <cstdlib>
#include <cstring>
#include <cassert>
#include <cstdio>
static int accesses=0;
struct lua_State {std::string table;int id;std::map<std::string,double> result;double pending=0;};
int luaL_error(lua_State*,const char*,...){throw std::runtime_error("guard");}
const char* luaL_checkstring(lua_State*L,int){return L->table.c_str();}
int luaL_checkint(lua_State*L,int){return L->id;}
void lua_createtable(lua_State*L,int,int){L->result.clear();}
void lua_pushboolean(lua_State*L,int n){L->pending=n!=0;}
void lua_pushinteger(lua_State*L,int n){L->pending=n;}
void lua_pushnumber(lua_State*L,double n){L->pending=n;}
void lua_setfield(lua_State*L,int,const char*name){L->result[name]=L->pending;}
'''
classes=[];gc=[];checks=[]
for n,row in enumerate(bindings):
 methods={};expected={}
 for column,b in sorted(row['bindings'].items()):
  method=b['getter'];value=methods.setdefault(method,10+n*100+len(methods))
  expected[column]=1 if b['reader']=='GetBool' else value
 cls=row['class'];classes.append('struct '+cls+'{'+''.join('int '+m+'()const{++accesses;return '+str(v)+';}'for m,v in methods.items())+'};')
 gc.append(cls+' i'+str(n)+'; int '+row['count']+'(){return 2;} '+cls+'* '+row['getter']+'('+row['index_type']+' i){++accesses;return i==1?&i'+str(n)+':nullptr;}')
 checks.append('L.table="'+row['table']+'";L.id=1;assert(LekmodMacReadInfoCache(&L)==1);assert(L.result.size()=='+str(len(expected))+');'+''.join('assert(L.result.at("'+k+'") == '+str(v)+');'for k,v in expected.items()))
types='\n'.join('using '+t+'=int;'for t in sorted({r['index_type']for r in bindings}))
main=r'''
int main(){lua_State L;L.table="Buildings";L.id=1;
 unsetenv("LEKMOD_CONFIG_AUDIT");try{LekmodMacReadInfoCache(&L);assert(false);}catch(const std::runtime_error&){}assert(accesses==0);
 setenv("LEKMOD_CONFIG_AUDIT","1",1);
 for(int id:{-1,0,2}){L.id=id;try{LekmodMacReadInfoCache(&L);assert(false);}catch(const std::runtime_error&){}}
 L.table="unknown";L.id=1;try{LekmodMacReadInfoCache(&L);assert(false);}catch(const std::runtime_error&){}
 CHECKS
 printf("Read-only cache probe: environment/index/null/table guards and all MAPPINGS field dispatches pass\n");
}
'''.replace('CHECKS','\n'.join(checks)).replace('MAPPINGS',str(sum(len(r['bindings'])for r in bindings)))
with tempfile.TemporaryDirectory(prefix='lekmod-info-cache-')as d:
 p=Path(d);(p/'test.cpp').write_text(prefix+types+'\n'.join(classes)+'\nstruct Globals{'+''.join(gc)+'}GC;\n'+body+main)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
