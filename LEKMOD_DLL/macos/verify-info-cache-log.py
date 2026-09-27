#!/usr/bin/env python3
"""Compare logged native cache values with a pinned immutable resolved database."""
import argparse,hashlib,json,re,sqlite3
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--log',type=Path,required=True);p.add_argument('--run',required=True);p.add_argument('--database',type=Path,required=True);p.add_argument('--database-sha256',required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2]
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
if sha(a.database)!=a.database_sha256:raise SystemExit('Database identity differs')
meta=json.loads((root/'LEKMOD_DLL/macos/info-cache-audit-bindings.json').read_text());schemas={row['table']:row['bindings']for row in meta['tables']};seen={}
pattern=re.compile(r'\[LEKMOD_CONFIG_CACHE\] run='+re.escape(a.run)+r' table=(\w+) id=(\d+) data=(\{.*\})$')
for line in a.log.read_text(errors='strict').splitlines():
 m=pattern.search(line)
 if m:
  key=(m[1],int(m[2]));value=json.loads(m[3])
  if key in seen and seen[key]!=value:raise SystemExit('Conflicting repeated native cache row: '+str(key))
  seen[key]=value
conn=sqlite3.connect('file:'+str(a.database.resolve())+'?mode=ro&immutable=1',uri=True);conn.row_factory=sqlite3.Row
counts={};total=0
for table,fields in schemas.items():
 assert re.fullmatch(r'\w+',table)
 rows=list(conn.execute('SELECT * FROM "'+table+'"'));expected_ids={row['ID']for row in rows};actual_ids={i for t,i in seen if t==table}
 if actual_ids!=expected_ids:raise SystemExit('Missing/unexpected rows for '+table)
 checks=0
 for row in rows:
  native=seen[(table,row['ID'])]
  if set(native)!=set(fields):raise SystemExit('Wrong native columns for '+table)
  for column,binding in fields.items():
   actual=native[column];expected=row[column]
   if binding['reader']=='GetBool':
    if isinstance(expected,str):
     if expected.lower()not in ('true','false','0','1'):raise SystemExit('Unrecognized SQL boolean '+repr(expected))
     expected=expected.lower()in ('true','1')
    else:expected=bool(expected)
   elif expected is None:expected=0
   equal=type(actual)==type(expected)and actual==expected if isinstance(expected,bool) else actual==expected
   if binding['reader']in ('GetFloat','GetDouble'):equal=abs(actual-expected)<=max(1,abs(expected))*1e-6
   if not equal:raise SystemExit(f'Native/immutable DB mismatch {table}/{row["ID"]}/{column}: {actual!r} != {expected!r}')
   checks+=1
 counts[table]={'rows':len(rows),'fields':len(fields),'comparisons':checks};total+=checks
if set(t for t,i in seen)!=set(schemas):raise SystemExit('Unexpected/missing native table')
result={'passed':True,'scope':'Native cached scalar values vs separately pinned immutable database; not proof of gameplay consumers.','run':a.run,'log':str(a.log),'log_sha256':sha(a.log),'database':str(a.database),'database_sha256':a.database_sha256,'bindings_sha256':sha(root/'LEKMOD_DLL/macos/info-cache-audit-bindings.json'),'tables':counts,'native_rows':len(seen),'value_comparisons':total}
a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'passed':True,'native_rows':len(seen),'value_comparisons':total,'tables':len(counts)}))
