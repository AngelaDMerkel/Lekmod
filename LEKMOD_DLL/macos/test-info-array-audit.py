#!/usr/bin/env python3
"""Exercise the actual generated reader with bounded fake caches under sanitizers."""
from pathlib import Path
import json,re,subprocess,tempfile
root=Path(__file__).resolve().parents[2];port=root/'LEKMOD_DLL/macos';rows=json.loads((port/'info-array-audit-bindings.json').read_text())['bindings']
source=(port/'info-array-audit.cpp').read_text();body=source[source.index('int LekmodMacReadInfoArray'):]
counts={};symbols={};classes={};owners={}
for n,r in enumerate(rows):
 counts[r['owner_count']]=r['owner_slots'];owners[r['table']]=r
 expr=r['dimension_expression']
 if expr.startswith('GC.'):counts[expr[3:-2]]=r['dimension_slots']
 else:symbols[expr]=r['dimension_slots']
 for bound in r['bounds']:
  if bound.startswith('GC.'):counts.setdefault(bound[3:-2],r['length'])
  elif bound.startswith('NUM_'):symbols.setdefault(bound,r['length'])
 methods=classes.setdefault(r['class_name'],{})
 assert r['getter']not in methods
 methods[r['getter']]=(r,n+1)
prefix=r'''
#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>
using lua_Number=double;
static int values_read=0,infos_read=0;static bool missing=false;
static std::map<std::string,int> overrides;
struct lua_State{std::string key;double id=0,pending=0;std::vector<double> result;};
int luaL_error(lua_State*,const char*,...){throw std::runtime_error("guard");}
const char* luaL_checkstring(lua_State*L,int){return L->key.c_str();}
double luaL_checknumber(lua_State*L,int){return L->id;}
void lua_createtable(lua_State*L,int n,int){L->result.assign(n,0);}
void lua_pushboolean(lua_State*L,int n){L->pending=n!=0;}
void lua_pushinteger(lua_State*L,int n){L->pending=n;}
void lua_rawseti(lua_State*L,int,int i){assert(i>0&&size_t(i)<=L->result.size());L->result[i-1]=L->pending;}
'''
types='\n'.join('using '+t+'=int;'for t in sorted({r['owner_index_type']for r in rows}|{r['parameter_type']for r in rows})if t!='int')
structs=[]
for cls,methods in classes.items():
 fields=[];init=[];functions=[]
 for name,(r,seed)in methods.items():
  size=r['length'];fields.append('int a_'+name+'['+str(size)+'];')
  value=('('+str(seed)+'+i)%2')if r['mode']=='membership'else str(seed*1000)+'+i'
  init.append('for(int i=0;i<'+str(size)+';++i)a_'+name+'[i]='+value+';')
  functions.append('int '+name+'('+r['parameter_type']+' i)const{assert(i>=0&&i<'+str(size)+');++values_read;return a_'+name+'[i];}')
 structs.append('struct '+cls+'{'+''.join(fields)+cls+'(){'+''.join(init)+'}'+''.join(functions)+'};')
gc=[]
for name,value in counts.items():gc.append('int '+name+'(){return overrides.count("'+name+'")?overrides["'+name+'"]:'+str(value)+';}')
for n,r in enumerate(owners.values()):gc.append(r['class_name']+' o'+str(n)+';const '+r['class_name']+'* '+r['owner_getter']+'('+r['owner_index_type']+'){++infos_read;return missing?nullptr:&o'+str(n)+';}')
checks=[]
for n,r in enumerate(rows):
 seed=n+1;value=('('+str(seed)+'+i)%2')if r['mode']=='membership'else str(seed*1000)+'+i'
 checks.append('L.key="'+r['key']+'";L.id=0;assert(LekmodMacReadInfoArray(&L)==1);assert(L.result.size()=='+str(r['length'])+');for(int i=0;i<'+str(r['length'])+';++i)assert(L.result[i]=='+value+');')
main=r'''
void rejects(lua_State& L){int previous=values_read;try{LekmodMacReadInfoArray(&L);fprintf(stderr,"accepted invalid request %s id=%f\n",L.key.c_str(),L.id);assert(false);}catch(const std::runtime_error&){}assert(values_read==previous);}
int main(){lua_State L;L.key="FIRST";
 unsetenv("LEKMOD_CONFIG_AUDIT");rejects(L);assert(infos_read==0);
 setenv("LEKMOD_CONFIG_AUDIT","true",1);rejects(L);assert(infos_read==0);
 setenv("LEKMOD_CONFIG_AUDIT","1",1);
 for(double id:{-1.0,0.5,65536.0,std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}){L.id=id;rejects(L);}assert(infos_read==0);
 L.id=0;missing=true;rejects(L);missing=false;
 overrides["OWNERCOUNT"]=OWNERMAX+1;rejects(L);overrides.clear();
 L.id=OWNERMAX;rejects(L);L.id=0;
 L.key="Buildings.m_piResourceQuantityRequirements";overrides["getNumResourceInfos"]=1;rejects(L);overrides.clear();
 L.key="Buildings.m_piPrereqAndTechs";overrides["getNUM_BUILDING_AND_TECH_PREREQS"]=1;rejects(L);overrides.clear();
 L.key="unknown";rejects(L);
 CHECKS
 printf("Array reader guards and ARRAYS bounded getter dispatches pass under ASan/UBSan\n");
}
'''
first=rows[0];main=main.replace('FIRST',first['key']).replace('OWNERCOUNT',first['owner_count']).replace('OWNERMAX',str(first['owner_slots'])).replace('CHECKS','\n'.join(checks)).replace('ARRAYS',str(len(rows)))
with tempfile.TemporaryDirectory(prefix='lekmod-array-probe-')as d:
 p=Path(d);(p/'test.cpp').write_text(prefix+types+'\n'+''.join('const int '+k+'='+str(v)+';'for k,v in symbols.items())+'\n'.join(structs)+'\nstruct Globals{'+''.join(gc)+'}GC;\n'+body+main)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
