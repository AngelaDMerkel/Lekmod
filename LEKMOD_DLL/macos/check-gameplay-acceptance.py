#!/usr/bin/env python3
"""Validate acceptance evidence identities and report the real G0 gate state."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
CASE_STATUSES = {'untriaged','ready','harness-blocked','product-failed','passed','covered-by-evidence','out-of-scope'}
SURFACE_STATUSES = {'untriaged','mapped','presentation-only','out-of-scope'}


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve(root, value):
    path = Path(value)
    if path.is_absolute() or '..' in path.parts:
        raise ValueError('register references must stay inside the checkout: ' + value)
    return root / path


def native_batch_contract(case, root):
    contract=case.get('evidence_contract',{})
    if contract.get('kind')=='native-batch-stages':
        stages=contract.get('stages',[])
        if not stages or any(c.get('kind')not in {'native-batch-stage','native-isolated-stage'} for c in stages):
            raise ValueError('composite evidence needs nonempty native stage contracts')
        identities=[(c['report'],c['batch_report'],c['stage']) for c in stages]
        if len(set(identities))!=len(identities):
            raise ValueError('duplicate composite evidence stage')
        for stage in stages:
            native_batch_contract(dict(case,evidence_contract=stage),root)
        return
    isolated=contract.get('kind')=='native-isolated-stage'
    if contract.get('kind')not in {'native-batch-stage','native-isolated-stage'}:
        raise ValueError('passing case needs a supported evidence contract: '+case['id'])
    evidence_paths={r['path'] for r in case['evidence']}
    if not {contract['report'],contract['batch_report']}<=evidence_paths:
        raise ValueError('evidence contract references unpinned reports')
    report=json.loads(resolve(root,contract['report']).read_text())
    batch=json.loads(resolve(root,contract['batch_report']).read_text())
    status_ok=(report.get('status')=='failed-functional-checks' and report.get('functional_checks',{}).get('failed')is True) if isolated else report.get('status','').startswith('passed')
    if not (status_ok and report.get('normal_exit_verified') is True
            and report.get('process_returncode')==0 and report.get('binary_sha256')==contract['gamecore_sha256']
            and report.get('settings_restored')is True and report.get('temporary_ui_hooks_restored')is True
            and report.get('manual_saves_preserved')is True and not report.get('lua_runtime_errors')
            and report.get('synchronization_checks') and not any(report['synchronization_checks'].values())
            and not report.get('new_diagnostics') and batch.get('complete')is True and (batch.get('failed')is True if isolated else batch.get('failed')is False)):
        raise ValueError('native report does not satisfy pass/exit/preservation contract: '+case['id'])
    if isolated:
        reviewed=contract.get('unrelated_failures',[])
        allowed={r['stage'] for r in reviewed}
        failed={r['id'] for r in batch['results'] if r['failed']}
        if (not reviewed or len(allowed)!=len(reviewed) or allowed!=failed or contract['stage']in allowed
                or any(r.get('classification')!='harness-oracle-error' or not r.get('reason') for r in reviewed)
                or not contract.get('required_assertions')):
            raise ValueError('isolated stage has unreviewed/selected failures')
        outcomes=report.get('functional_checks',{}).get('outcomes',{})
        for item,value in outcomes.items():
            if value!='PASS' and not (value=='FAIL' and (item=='batch-complete' or item.split('::')[0]in allowed)):
                raise ValueError('isolated stage has an unaccounted global failure')
        for item in contract['required_assertions']+['save-reload']:
            if outcomes.get(contract['stage']+'::'+item)!='PASS':
                raise ValueError('isolated stage lacks matching native report assertions')
    selected=[r for r in batch['results']if r['id']==contract['stage']]
    if len(selected)!=2 or {r['mode']for r in selected}!={'run','reload'}:
        raise ValueError('missing or duplicate stage/replay')
    run=next(r for r in selected if r['mode']=='run');replay=next(r for r in selected if r['mode']=='reload')
    if (run['failed'] or replay['failed'] or run['state']!=replay['state'] or
            not set(contract['required_assertions'])<=set(run['outcomes']) or
            any(v!='PASS'for v in run['outcomes'].values()) or replay['outcomes'].get('save-reload')!='PASS'):
        raise ValueError('native stage assertion/replay failed: '+case['id'])
    for row in selected:
        if isolated:
            verification=row.get('save_verification',{})
            if not (verification.get('writer_closed')is True and verification.get('source_copy_match')is True
                    and verification.get('sha256')==row['saved_sha256']):
                raise ValueError('isolated stage checkpoint not fully verified')
        path=Path(row['saved_copy'])
        if not path.is_file() or sha(path)!=row['saved_sha256']:
            raise ValueError('native checkpoint bytes differ: '+case['id'])


def validate(register, root=ROOT):
    if register.get('schema_version') != 1: raise ValueError('unsupported register schema')
    checked = set()
    def reference(row):
        path=resolve(root,row['path']);expected=row['sha256']
        key=(str(path),expected)
        if key not in checked:
            if not path.is_file() or sha(path)!=expected: raise ValueError('changed/missing reference: '+row['path'])
            checked.add(key)
    for value in register['discovery'].values():
        if isinstance(value,dict) and {'path','sha256'}<=set(value): reference(value)
    discovery=json.loads(resolve(root,register['discovery']['report']['path']).read_text())
    surface_ids={r['id']for r in discovery['candidates']};case_ids=set();cases=register['cases']
    mandatory={'id','group','title','status','source_references','owners','expected_result','units','supplied_inputs','actual_trigger','negative_controls','transitions','persistence_requirement','required_evidence_level','fixtures','batch','stage','evidence','surface_ids'}
    for row in cases:
        if mandatory-set(row):raise ValueError('incomplete case '+row.get('id','?'))
        if row['id']in case_ids:raise ValueError('duplicate case ID')
        case_ids.add(row['id'])
        if row['status']not in CASE_STATUSES:raise ValueError('invalid case status')
        if not set(row['surface_ids'])<=surface_ids:raise ValueError('case references unknown surface')
        for ref in row['source_references']+row['evidence']+row['fixtures']:reference(ref)
        if row['status']in {'ready','passed','covered-by-evidence'}:
            expected=row['expected_result']
            empty=expected is None or expected=='' or (isinstance(expected,(dict,list)) and not expected)
            if not row['fixtures'] or not row['source_references'] or empty or row.get('missing_design'):
                raise ValueError('case declared ready/passed with incomplete design: '+row['id'])
        if row['status']in {'passed','covered-by-evidence'}:
            if not row['evidence']: raise ValueError('case passed without evidence')
            native_batch_contract(row,root)
        if row['status']=='out-of-scope'and not row.get('reason'):raise ValueError('unexplained scope exclusion')
    reviewed=register['surface_review']
    if len({r['id']for r in reviewed})!=len(reviewed)or{r['id']for r in reviewed}!=surface_ids:
        raise ValueError('surface review does not cover discovery exactly')
    for row in reviewed:
        if row['status']not in SURFACE_STATUSES:raise ValueError('invalid surface status')
        if not set(row['case_ids'])<=case_ids:raise ValueError('surface references unknown case')
        if row['status']=='mapped'and not row['case_ids']:raise ValueError('mapped surface without a case')
        if row['status']in {'presentation-only','out-of-scope'}and not row.get('reason'):raise ValueError('unexplained surface exclusion')
    for row in register['pending_doc_entries']:
        if row['status'] not in {'untriaged','mapped','mapped-to-later-gate','out-of-scope'}:
            raise ValueError('invalid document review status')
        if row['status']=='mapped' and not row['case_ids']:
            raise ValueError('mapped document row without cases')
        if row['status']=='mapped-to-later-gate' and (not row.get('reason') or not row.get('later_gates') or
                not set(row['later_gates'])<={'F','R1','R2','R3','R4','R5'}):
            raise ValueError('invalid deferred gate mapping')
        if row['status']=='out-of-scope' and not row.get('reason'):
            raise ValueError('unexplained document exclusion')
        if not set(row['case_ids'])<=case_ids:raise ValueError('doc row references unknown case')
        lines=resolve(root,row['document']).read_text().splitlines()
        if row['line']>len(lines)or hashlib.sha256(lines[row['line']-1].encode()).hexdigest()!=row['text_sha256']:
            raise ValueError('changed pending-document row: '+row['id'])
    for row in register['dependency_review']:
        if row['status'] not in {'untriaged','resolved-stock-dependency','resolved-redundant-reference'}:
            raise ValueError('invalid dependency review status')
        if row['status']=='resolved-stock-dependency':
            path=Path(row['path'])
            if not path.is_file() or sha(path)!=row['sha256']:
                raise ValueError('changed stock dependency: '+row['include'])
        if row['status']=='resolved-redundant-reference':
            refs=row.get('source_references',[])+row.get('evidence',[])
            contract=row.get('evidence_contract',{})
            if not row.get('reason') or not row.get('source_references') or not row.get('evidence'):
                raise ValueError('resolved dependency needs source and runtime evidence')
            for ref in refs:reference(ref)
            if contract.get('log')not in {ref['path']for ref in row['evidence']} or not contract.get('required_literal'):
                raise ValueError('resolved dependency needs a pinned native context proof')
            if contract['required_literal']not in resolve(root,contract['log']).read_text():
                raise ValueError('resolved dependency native context proof missing')
    pending_surfaces=sum(r['status']=='untriaged'for r in reviewed)
    pending_cases=sum(r['status']=='untriaged'for r in cases)
    pending_docs=sum(r['status']=='untriaged'for r in register['pending_doc_entries'])
    pending_deps=sum(r['status']=='untriaged'for r in register['dependency_review'])
    gate=not(pending_surfaces or pending_cases or pending_docs or pending_deps)
    if register.get('gate_G0_passed')is True and not gate:raise ValueError('false G0 pass with unresolved review items')
    return {'valid':True,'gate_G0_passed':gate,'case_statuses':dict(Counter(r['status']for r in cases)),
            'pending_surfaces':pending_surfaces,'pending_case_designs':pending_cases,'pending_document_rows':pending_docs,
            'pending_dependencies':pending_deps,'verified_file_references':len(checked),
            'note':'Surface count is a discovery review count, not the final gameplay-test denominator.'}


def require_ready_case(register, case_id, root=ROOT):
    matches=[row for row in register['cases'] if row['id']==case_id]
    if len(matches)!=1:raise ValueError('unknown/duplicate requested case: '+case_id)
    row=matches[0]
    if row['status']!='ready' or row.get('missing_design'):
        raise ValueError('requested case is not fully designed and ready: '+case_id)
    implementation=row.get('implementation_references',[])
    if not implementation:raise ValueError('ready case lacks pinned implementation/plan: '+case_id)
    for ref in implementation:
        path=resolve(root,ref['path'])
        if not path.is_file() or sha(path)!=ref['sha256']:
            raise ValueError('changed/missing ready-case implementation: '+ref['path'])
    return {'id':case_id,'status':'ready-for-scoped-native-execution','batch':row['batch'],
            'remaining_scope':row.get('implementation_limits',[]),'does_not_establish_global_G0':True}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--register',type=Path,default=ROOT/'docs/macos-gameplay-acceptance-cases.json')
    p.add_argument('--require-g0',action='store_true',help='Fail if any mandatory G0 review remains')
    p.add_argument('--require-ready-case',action='append',default=[],help='Verify one independently specified case without claiming G0 complete')
    a=p.parse_args();register=json.loads(a.register.read_text());report=validate(register)
    report['selected_ready_cases']=[require_ready_case(register,case_id)for case_id in a.require_ready_case]
    print(json.dumps(report,indent=2))
    return 0 if not a.require_g0 or report['gate_G0_passed'] else 1


if __name__=='__main__':
    try:sys.exit(main())
    except (ValueError,KeyError,OSError)as e:sys.exit(str(e))
