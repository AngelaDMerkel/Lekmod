#!/usr/bin/env python3
"""Trace conflicting shipped flavor cells and demonstrate unordered-query sensitivity.

Read-only offline evidence only; never chooses replacement AI weights or claims
that either query ordering is the actual native host's observed ordering.
"""
import argparse,hashlib,json,sqlite3,xml.etree.ElementTree as ET
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--database',type=Path,required=True);p.add_argument('--database-sha256',required=True);p.add_argument('--xml',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(a.database)==a.database_sha256,'database identity differs'
xml=ET.parse(a.xml).getroot();db=sqlite3.connect('file:'+str(a.database.resolve())+'?immutable=1',uri=True);result=[]
try:
 for table,col in [('Building_Flavors','BuildingType'),('Unit_Flavors','UnitType'),('Policy_Flavors','PolicyType'),('Technology_Flavors','TechType'),('Leader_Flavors','LeaderType')]:
  groups=db.execute(f'SELECT "{col}",FlavorType FROM "{table}" GROUP BY "{col}",FlavorType HAVING count(distinct Flavor)>1').fetchall()
  for owner,flavor in groups:
   authored=[{c.tag:c.text for c in row}for row in xml.findall('.//'+table+'/Row')if row.findtext(col)==owner and row.findtext('FlavorType')==flavor]
   stored=db.execute(f'SELECT rowid,Flavor FROM "{table}" WHERE "{col}"=? AND FlavorType=? ORDER BY rowid',(owner,flavor)).fetchall()
   assert [int(row['Flavor'])for row in authored]==[value for _,value in stored],'XML/database values differ'
   query=f'select Flavors.ID, Flavor from "{table}" inner join Flavors on FlavorType = Flavors.Type where "{col}" = ?'
   fid=db.execute('select ID from Flavors where Type=?',(flavor,)).fetchone()[0]
   db.execute('pragma reverse_unordered_selects=OFF');normal=db.execute(query,(owner,)).fetchall()
   db.execute('pragma reverse_unordered_selects=ON');reverse=db.execute(query,(owner,)).fetchall()
   db.execute('pragma reverse_unordered_selects=OFF')
   plan=db.execute('explain query plan '+query,(owner,)).fetchall()
   winner=lambda rows:[v for i,v in rows if i==fid][-1]
   result.append(dict(table=table,owner=owner,flavor=flavor,stored_rows=stored,xml_rows=authored,normal_last=winner(normal),reversed_last=winner(reverse),query=query,query_plan=plan))
finally:db.close()
assert sha(a.database)==a.database_sha256,'read-only database changed'
report=dict(scope='Offline source/query-order sensitivity only; no inferred author intent or native gameplay verdict.',database={'path':str(a.database),'sha256':a.database_sha256},source={'path':str(a.xml),'sha256':sha(a.xml)},sqlite_version=sqlite3.sqlite_version,rows=result)
a.output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'conflicting_cells':len(result),'order_sensitive_cells':sum(r['normal_last']!=r['reversed_last']for r in result),'source_rows_verified':sum(len(r['xml_rows'])for r in result)}))
