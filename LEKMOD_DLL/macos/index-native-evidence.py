#!/usr/bin/env python3
"""Index strict historical evidence contracts without granting gameplay coverage."""
from pathlib import Path
from collections import Counter,defaultdict
import importlib.util,json,hashlib,argparse
root=Path(__file__).resolve().parents[2];port=root/'LEKMOD_DLL/macos'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,required=True,help='Write a retrieval index; this is not an acceptance register')
args=parser.parse_args()
spec=importlib.util.spec_from_file_location('gate',port/'check-gameplay-acceptance.py');gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)
cache={}
def sha(p):
 s=p.stat();k=(str(p),s.st_mtime_ns,s.st_size)
 if k not in cache:cache[k]=hashlib.sha256(p.read_bytes()).hexdigest()
 return cache[k]
gate.sha=sha
reports=[]
for p in sorted((root/'build/macos/playtests').glob('*/report.json')):
 try:r=json.loads(p.read_text())
 except (ValueError,OSError):continue
 reports.append((p,r))
byload=defaultdict(list)
for p,r in reports:
 if r.get('status')=='passed-scenario-reload-only':byload[(r.get('scenario'),r.get('save_sha256'))].append((p,r))
accepted=[];rejected=[]
for p,r in reports:
 if r.get('status')!='passed-scenario-checks-only' or r.get('scenario')in [None,'batch']:continue
 for q,t in byload[(r.get('scenario'),r.get('saved_sha256'))]:
  contract=dict(kind='native-run-replay',report=str(p.relative_to(root)),replay_report=str(q.relative_to(root)),scenario=r['scenario'],required_assertions=list(r.get('functional_checks',{}).get('outcomes',{})),gamecore_sha256=r.get('binary_sha256'))
  refs=[dict(path=str(x.relative_to(root)),sha256=sha(x))for x in [p,q]]
  try:gate.native_run_replay_contract(dict(id=r['scenario'],evidence_contract=contract,evidence=refs),root)
  except (KeyError,ValueError,OSError)as e:rejected.append(dict(scenario=r['scenario'],run=p.parent.name,replay=q.parent.name,reason=str(e)));continue
  accepted.append(dict(scenario=r['scenario'],run=p.parent.name,replay=q.parent.name,assertions=contract['required_assertions'],contract=contract,evidence=refs))
batches=[]
for p,r in reports:
 if r.get('scenario')!='batch' or not r.get('status','').startswith('passed'):continue
 bp=p.with_name('batch-report.json')
 if not bp.is_file():continue
 b=json.loads(bp.read_text())
 for row in b.get('results',[]):
  if row.get('mode')!='run' or row.get('failed'):continue
  contract=dict(kind='native-batch-stage',report=str(p.relative_to(root)),batch_report=str(bp.relative_to(root)),stage=row['id'],required_assertions=list(row.get('outcomes',{})),gamecore_sha256=r.get('binary_sha256'))
  refs=[dict(path=str(x.relative_to(root)),sha256=sha(x))for x in [p,bp]]
  try:gate.native_batch_contract(dict(id=row['id'],evidence_contract=contract,evidence=refs),root)
  except (KeyError,ValueError,OSError)as e:rejected.append(dict(stage=row['id'],run=p.parent.name,reason=str(e)));continue
  batches.append(dict(stage=row['id'],run=p.parent.name,assertions=contract['required_assertions'],contract=contract,evidence=refs))
out=dict(scope='Evidence retrieval index only. Does not map source effects, prove candidate applicability or close any acceptance gate.',reports_inspected=len(reports),verified_process_pairs=accepted,verified_passing_batch_pairs=batches,rejected_contract_candidates=rejected)
args.output.write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(dict(reports=len(reports),process_pairs=len(accepted),distinct_scenarios=len(set(x['scenario']for x in accepted)),batch_pairs=len(batches),rejected=len(rejected),scenarios=sorted(set(x['scenario']for x in accepted))),indent=2))
