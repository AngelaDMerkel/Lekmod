#!/usr/bin/env python3
"""Bounded cold-launch/load/save/exit cycles, retaining cache evidence without repair."""
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import playtest_batch

PORT=Path(__file__).resolve().parent
ROOT=PORT.parents[1]
spec=importlib.util.spec_from_file_location('native_runner',PORT/'automated-playtest.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def cache_snapshot(out):
    out.mkdir(parents=True)
    cache=runner.DATA/'cache';rows={}
    if runner.game_pids():raise RuntimeError('Cache snapshots require Civ V closed')
    for p in sorted(cache.glob('*')):
        if p.is_file():
            rows[p.name]={'size':p.stat().st_size,'sha256':digest(p),'mtime_ns':p.stat().st_mtime_ns}
            if p.name.startswith('Localization-Merged.db'):shutil.copy2(p,out/p.name)
    (out/'manifest.json').write_text(json.dumps(rows,indent=2)+'\n')
    return rows

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--cycles',type=int,default=3)
    p.add_argument('--fixture',type=Path,required=True)
    p.add_argument('--fixture-sha256',required=True)
    p.add_argument('--package',type=Path,required=True)
    p.add_argument('--package-sha256',required=True)
    p.add_argument('--installer',type=Path,default=ROOT.parent/'Civ5ModDlcPacker/civ5_dlc_installer.py')
    a=p.parse_args()
    if not 1<=a.cycles<=5:p.error('Use 1–5 lifecycle cycles; this is not a gameplay campaign')
    if digest(a.fixture)!=a.fixture_sha256 or digest(a.package)!=a.package_sha256:p.error('Fixture/package hash mismatch')
    runner.require_unlocked_desktop();runner.require_existing_steam_session()
    if runner.game_pids():p.error('Civ V must be closed')
    sys.path.insert(0,str(a.installer.parent));import civ5_gamecore
    if civ5_gamecore.ProductManager(runner.APP,runner.DATA).status().get('product')!='stock':p.error('Lifecycle wrapper requires stock initially')
    stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ');out=ROOT/'build/macos/lifecycle-tests'/stamp;out.mkdir(parents=True)
    result={'started_utc':stamp,'package':str(a.package.resolve()),'package_sha256':a.package_sha256,'fixture':str(a.fixture.resolve()),'fixture_sha256':a.fixture_sha256,'cycles':[],'cache_policy':'read-only hashes and merged-cache copies; no repairs or removals by this tool','instrumentation':'existing full diagnostic/activation guard plus dyld image trace; identical for all cycles'}
    installed=False;expected=None
    print(json.dumps({'event':'lifecycle-start','evidence':str(out),'cycles':a.cycles}),flush=True)
    try:
        cache_snapshot(out/'before-install')
        subprocess.run([sys.executable,str(a.installer),'--gamecore','lekmod','--gamecore-package',str(a.package.resolve()),'--gamecore-sha256',a.package_sha256,'--yes'],check=True)
        installed=True
        for cycle in range(1,a.cycles+1):
            # An unlocked session is required independently for every launch.
            runner.require_unlocked_desktop();runner.require_existing_steam_session()
            before=cache_snapshot(out/('cycle-%02d-before'%cycle))
            old=set((ROOT/'build/macos/playtests').iterdir())
            cmd=[sys.executable,str(PORT/'automated-playtest.py'),'--mode','single-player-smoke','--turns','3','--timeout','300','--stall-seconds','180','--scenario','inventory','--scenario-turns','0','--trace-loaded-libraries','--load-save',str(a.fixture.resolve()),'--save-and-exit']
            if expected:cmd.extend(['--expected-state',str(expected)])
            with (out/('cycle-%02d.log'%cycle)).open('w')as log:returncode=playtest_batch.run_owned_runner(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
            new=[q for q in set((ROOT/'build/macos/playtests').iterdir())-old if (q/'report.json').is_file()]
            if len(new)!=1:raise RuntimeError('Could not uniquely identify owned cycle report')
            report=new[0]/'report.json';r=json.loads(report.read_text());after=cache_snapshot(out/('cycle-%02d-after'%cycle))
            passed=returncode==0 and r.get('normal_exit_verified')is True and r.get('settings_restored')is True and r.get('temporary_ui_hooks_restored')is True and r.get('manual_saves_preserved')is True
            row={'cycle':cycle,'cache_condition':'first launch after managed install'if cycle==1 else'unchanged installed product; prior generated cache retained','report':str(report),'status':r['status'],'normal_exit_verified':r.get('normal_exit_verified'),'passed':passed,'duration_seconds':r['duration_seconds'],'before_merged':before.get('Localization-Merged.db'),'after_merged':after.get('Localization-Merged.db')}
            result['cycles'].append(row);(out/'report.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'event':'lifecycle-cycle','cycle':cycle,'passed':passed,'status':r['status'],'report':str(report)}),flush=True)
            if not passed:break
            if expected is None:expected=report
        result['passed']=len(result['cycles'])==a.cycles and all(x['passed']for x in result['cycles'])
    except (Exception, KeyboardInterrupt) as error:
        result['passed']=False
        result['error']=type(error).__name__+': '+str(error)
        raise
    finally:
        if installed:
            restore=subprocess.run([sys.executable,str(a.installer),'--gamecore','stock','--yes'])
            result['stock_restore_returncode']=restore.returncode
        result['finished_utc']=datetime.now(timezone.utc).isoformat()
        (out/'report.json').write_text(json.dumps(result,indent=2)+'\n')
    return 0 if result.get('passed')and result.get('stock_restore_returncode')==0 else 1
if __name__=='__main__':raise SystemExit(main())
