#!/usr/bin/env python3
"""Independently verify every logged native array against a pinned immutable DB."""
import argparse,hashlib,json,re,sqlite3
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--log',type=Path,required=True);p.add_argument('--run',required=True);p.add_argument('--bindings',type=Path,required=True);p.add_argument('--database',type=Path,required=True);p.add_argument('--database-sha256',required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
if sha(a.database)!=a.database_sha256:raise SystemExit('Database identity differs')
meta=json.loads(a.bindings.read_text());schemas={r['key']:r for r in meta['bindings']};seen={};repetitions={}
pattern=re.compile(r'\[LEKMOD_ARRAY_CACHE\] run='+re.escape(a.run)+r' key=([\w.]+) id=(\d+) data=(\{.*\})$')
with a.log.open()as stream:
 for line in stream:
  m=pattern.search(line.rstrip())
  if not m:continue
  key=(m[1],int(m[2]));raw=json.loads(m[3]);spec=schemas.get(key[0])
  if spec is None:raise SystemExit('Unexpected array: '+key[0])
  if set(raw)!={str(i)for i in range(1,spec['length']+1)}:raise SystemExit('Malformed array shape: '+str(key))
  value=[raw[str(i)]for i in range(1,spec['length']+1)]
  if spec['mode']=='membership':
   if not all(type(v)is bool for v in value):raise SystemExit('Native membership is not boolean: '+str(key))
  elif not all(type(v)is int for v in value):raise SystemExit('Native numeric array is not integer: '+str(key))
  if key in seen and seen[key]!=value:raise SystemExit('Conflicting repeated native row: '+str(key))
  seen[key]=value;repetitions[key]=repetitions.get(key,0)+1
conn=sqlite3.connect('file:'+str(a.database.resolve())+'?immutable=1',uri=True)
q=lambda s:'"'+s.replace('"','""')+'"'
total=0;expected_keys=set();counts={}
for key,spec in schemas.items():
 owner_rows=list(conn.execute('select ID,Type from '+q(spec['table'])))
 for owner_id,owner_type in owner_rows:
  pair=(key,owner_id);expected_keys.add(pair)
  if pair not in seen:raise SystemExit('Missing native row: '+str(pair))
  actual=seen[pair];expected=[False if spec['mode']=='membership'else spec['default']]*spec['length']
  value='cast(r.'+q(spec['value_column'])+' as integer)'if spec['mode']=='indexed-value'else'1'
  sql='select i.ID,'+value+' from '+q(spec['relation_table'])+' r join '+q(spec['index_table'])+' i on r.'+q(spec['index_column'])+'=i.Type where r.'+q(spec['owner_column'])+'=?'
  records=list(conn.execute(sql,(owner_type,)))
  if spec['mode']=='compact-ids':
   if len(records)>len(expected):raise SystemExit('Compact SQL list exceeds bound')
   for n,row in enumerate(records):expected[n]=row[0]
   equal=sorted(actual)==sorted(expected)
  else:
   used={}
   for index,value in records:
    if not 0<=index<len(expected):raise SystemExit('Configured index outside bound')
    v=True if spec['mode']=='membership'else(0 if value is None else value)
    if index in used and used[index]!=v:raise SystemExit('Ambiguous duplicate values require review')
    used[index]=v;expected[index]=v
   equal=actual==expected
  if not equal:raise SystemExit('Native/immutable SQL array mismatch: '+str(pair))
  total+=len(actual)
 counts[key]={'owner_rows':len(owner_rows),'length':spec['length'],'mode':spec['mode']}
if set(seen)!=expected_keys:raise SystemExit('Unexpected native owner rows')
conn.close()
if sha(a.database)!=a.database_sha256:raise SystemExit('Database changed during verification')
result=dict(passed=True,scope='Cached parameter parity only; compact lists compared as multisets, not a gameplay/AI/UI pass.',run=a.run,log={'path':str(a.log),'sha256':sha(a.log)},database={'path':str(a.database),'sha256':a.database_sha256},bindings={'path':str(a.bindings),'sha256':sha(a.bindings)},arrays=counts,native_rows=len(seen),value_comparisons=total,minimum_repeated_observations=min(repetitions.values()),unresolved_input_warnings=meta['warnings'],excluded_bindings=meta['rejected'])
a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:result[k]for k in ['passed','native_rows','value_comparisons','minimum_repeated_observations']}))
