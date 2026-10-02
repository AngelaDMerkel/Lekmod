#!/usr/bin/env python3
"""Map bounded read-only array accessors from existing exact-build Clang ASTs."""
import argparse,hashlib,json
from pathlib import Path
from native_array_audit import array_mapping
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--compiled-bindings',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2];meta=json.loads(a.compiled_bindings.read_text());rows=[]
for row in meta['rows']:
    if 'class'not in row:continue
    source=(root/row['source']).read_bytes()
    if hashlib.sha256(source).hexdigest()!=row['source_sha256']:raise SystemExit('changed source: '+row['source'])
    mapping=array_mapping(a.compiled_bindings.parent/(row['class']+'.ast.json'),source)
    rows.append(dict(table=row['table'],class_name=row['class'],source=row['source'],source_sha256=row['source_sha256'],**mapping))
result=dict(scope='Compiled loader/getter mapping, not runtime parity or gameplay coverage.',tables=rows)
a.output.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'mapped':sum(len(r['bindings'])for r in rows),'rejected':sum(len(r['rejected'])for r in rows),'tables':[(r['table'],len(r['bindings']))for r in rows if r['bindings']]},indent=2))
