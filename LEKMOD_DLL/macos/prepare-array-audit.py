#!/usr/bin/env python3
"""Bind reviewed array loaders to an immutable database and native bounds.

This prepares parameter checks only, never automatic gameplay acceptance.
"""
import argparse,hashlib,json,re,sqlite3
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--bindings',type=Path,required=True);p.add_argument('--database',type=Path,required=True);p.add_argument('--database-sha256',required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(a.database)==a.database_sha256,'database hash mismatch'
db=sqlite3.connect('file:'+str(a.database.resolve())+'?immutable=1',uri=True)
assert db.execute('pragma quick_check').fetchone()[0]=='ok'
quote=lambda name:'"'+name.replace('"','""')+'"'
maxrows=lambda table:db.execute('select coalesce(max(ID),-1)+1 from '+quote(table)).fetchone()[0]
stems={'Buildings':'Building','Units':'Unit','UnitPromotions':'Promotion','Traits':'Trait','Policies':'Policy','Beliefs':'Belief','Improvements':'Improvement','Technologies':'Tech','Specialists':'Specialist','HandicapInfos':'Handicap','Leaders':'LeaderHead','Terrains':'Terrain','Features':'Feature','Resources':'Resource','Builds':'Build','Routes':'Route','Civilizations':'Civilization'}
dims={t:'GC.getNum'+stem+'Infos()'for t,stem in {**stems,'BuildingClasses':'BuildingClass','UnitClasses':'UnitClass','UnitCombatInfos':'UnitCombatClass','HurryInfos':'Hurry','Eras':'Era'}.items()}
dims.update(Domains='NUM_DOMAIN_TYPES',Yields='NUM_YIELD_TYPES',UnitAIInfos='NUM_UNITAI_TYPES',Flavors='GC.getNumFlavorTypes()',MajorCivApproachTypes='NUM_MAJOR_CIV_APPROACHES',MinorCivApproachTypes='NUM_MINOR_CIV_APPROACHES')
def bounds(expr):
 for table,value in dims.items():
  if value==expr:return maxrows(table)
 m=re.fullmatch(r'GC\.get(NUM_\w+)\(\)',expr)
 if m:
  row=db.execute('select Value from Defines where Name=?',(m[1],)).fetchone()
  if row:return int(row[0])
 if expr.isdigit():return int(expr)
 raise ValueError('unreviewed bound '+expr)
globals=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvGlobals.h').read_text()
result=[];rejected=[];warnings=[]
for table in json.loads(a.bindings.read_text())['tables']:
 assert sha(root/table['source'])==table['source_sha256']
 if not table['bindings']:continue
 stem=stems.get(table['table']);getter='get'+stem+'Info'if stem else '';count='getNum'+stem+'Infos'if stem else ''
 m=re.search(r'\b'+getter+r'\(\s*(\w+)\s+\w+\s*\)',globals)if getter else None
 if not m or count not in globals:rejected.append({'table':table['table'],'reason':'no verified global owner accessor'});continue
 owner_table=table['table'];owner_types={r[0]for r in db.execute('select Type from '+quote(owner_table))}
 for b in table['bindings']:
  key=owner_table+'.'+b['member'];axis=b['index_table'];relation=b['relation_table']
  try:
   axis_size=maxrows(axis);limit=min(axis_size,*[bounds(x)for x in b['bounds']])
   assert axis_size>0 and limit>0
   types={r[0]:r[1]for r in db.execute('select Type,ID from '+quote(axis))}
   owners={row[0]:row[1]for row in db.execute('select ID,Type from '+quote(owner_table))}
   columns=[b['owner_column'],b['index_column']]+([b['value_column']]if b['mode']=='indexed-value'else[])
   sql='select '+','.join(quote(x)for x in columns)+' from '+quote(relation)
   cells={};compact={};orphans=[];conflicts=[]
   for row in db.execute(sql):
    own,typ=row[:2]
    if own not in owner_types or typ not in types:orphans.append(list(row));continue
    index=types[typ]
    if b['mode']=='compact-ids':compact.setdefault(own,[]).append(index);continue
    value=True if b['mode']=='membership'else(0 if row[2]is None else int(row[2]))
    pair=(own,index)
    if pair in cells and cells[pair]!=value:conflicts.append([own,index,cells[pair],value])
    cells[pair]=value
   if conflicts:rejected.append({'key':key,'reason':'conflicting duplicate rows; query order requires review','examples':conflicts[:5]});continue
   if b['mode']=='compact-ids'and any(len(v)>limit for v in compact.values()):rejected.append({'key':key,'reason':'configured compact list exceeds legal getter bound'});continue
   if b['mode']!='compact-ids'and any(index>=limit for own,index in cells):rejected.append({'key':key,'reason':'configured value is outside legal getter bound'});continue
   if orphans:warnings.append({'key':key,'orphan_rows_not_loaded_by_inner_join':len(orphans),'examples':orphans[:3]})
   result.append(dict(**b,key=key,table=owner_table,class_name=table['class_name'],source=table['source'],source_sha256=table['source_sha256'],owner_getter=getter,owner_count=count,owner_index_type=m[1],owner_slots=maxrows(owner_table),owner_rows=len(owners),dimension_expression=dims[axis],dimension_slots=axis_size,length=limit,comparisons=len(owners)*limit))
  except (ValueError,AssertionError,sqlite3.Error)as e:rejected.append({'key':key,'reason':str(e)or'invalid dimension/bound'})
out=dict(schema=1,scope='Bounded read-only native cache parameter comparison; gameplay consumers remain separate.',database={'path':str(a.database),'sha256':a.database_sha256},input={'path':str(a.bindings),'sha256':sha(a.bindings)},utility={'path':'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvDatabaseUtility.cpp','sha256':sha(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvDatabaseUtility.cpp')},bindings=result,rejected=rejected,warnings=warnings)
db.close()
a.output.write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({'arrays':len(result),'owner_tables':len({r['table']for r in result}),'value_comparisons':sum(r['comparisons']for r in result),'rejected':rejected,'warnings':warnings},indent=2))
