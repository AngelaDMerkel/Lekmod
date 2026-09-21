#!/usr/bin/env python3
"""Run a reviewed single-player suite in one Civ V process, with hashed checkpoints."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import playtest_batch

ROOT=Path(__file__).resolve().parents[2]
PORT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('native_runner',PORT/'automated-playtest.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--plan',default='comprehensive',help='pilot, comprehensive, or a plan JSON path')
    p.add_argument('--minutes',type=int,default=60,help='total wall-clock limit, 2–60 minutes; finishes early when complete')
    p.add_argument('--from-stage',help='start at this independent fixture stage, preserving the original plan order')
    p.add_argument('--preflight-only',action='store_true',help='validate hashes, adapters and Lua syntax; do not touch the game')
    p.add_argument('--package',type=Path,help='optional verified native package; requires stock and restores stock afterward')
    p.add_argument('--sha256',help='required package SHA256 when --package is supplied')
    p.add_argument('--installer',type=Path,default=ROOT.parent/'Civ5ModDlcPacker/civ5_dlc_installer.py')
    a=p.parse_args()
    if not 2<=a.minutes<=60:p.error('Use 2–60 minutes')
    if bool(a.package)!=bool(a.sha256):p.error('--package and --sha256 must be supplied together')
    path=PORT/'batch-plans'/(a.plan+'.json') if a.plan in ('pilot','comprehensive') else Path(a.plan)
    plan=playtest_batch.load_plan(path,ROOT,runner.SCENARIO_ITEMS)
    if a.from_stage:
        ids=[s['id']for s in plan['stages']]
        if a.from_stage not in ids:p.error('Unknown stage id')
        raw=json.loads(path.read_text());raw['stages']=raw['stages'][ids.index(a.from_stage):]
    else:raw=json.loads(path.read_text())
    with tempfile.TemporaryDirectory(prefix='lekmod-batch-plan-') as directory:
        actual=Path(directory)/'plan.json';actual.write_text(json.dumps(raw))
        plan=playtest_batch.load_plan(actual,ROOT,runner.SCENARIO_ITEMS)
        luac=ROOT/'build/macos/test-deps/lua-5.1.4/src/luac'
        if not luac.is_file():p.error('Build the committed Lua test dependency before running a batch')
        subprocess.run([str(luac),'-p',*[str(PORT/('playtest-scenario-'+s['scenario']+'.lua'))for s in plan['stages']]],check=True)
        print(json.dumps({'plan':plan['name'],'stages':len(plan['stages']),'assertions':sum(len(s['items'])for s in plan['stages']),
              'reload_checks':len(plan['stages']),'maximum_functional_turns':plan['max_turns'],'time_limit_minutes':a.minutes},indent=2),flush=True)
        if a.package and playtest_batch.sha(a.package)!=a.sha256:p.error('Package hash mismatch')
        if a.preflight_only:return 0
        runner.require_unlocked_desktop();runner.require_existing_steam_session()
        if runner.game_pids():p.error('Quit Civ V before starting the batch')
        installed=False
        try:
            if a.package:
                sys.path.insert(0,str(a.installer.parent))
                import civ5_gamecore
                status=civ5_gamecore.ProductManager(runner.APP,runner.DATA).status()
                if status.get('product')!='stock':p.error('Package-managed batches require stock initially; existing product left unchanged')
                subprocess.run([sys.executable,str(a.installer),'--gamecore','lekmod','--gamecore-package',str(a.package.resolve()),'--gamecore-sha256',a.sha256,'--yes'],check=True)
                installed=True
            returncode=playtest_batch.run_owned_runner([sys.executable,str(PORT/'automated-playtest.py'),'--mode','single-player-smoke','--turns','3',
                '--timeout',str(a.minutes*60),'--stall-seconds','240','--scenario','batch','--scenario-turns','30',
                '--batch-plan',str(actual),'--load-save',plan['stages'][0]['fixture'],'--save-and-exit'],cwd=ROOT)
            return returncode
        finally:
            if installed:
                subprocess.run([sys.executable,str(a.installer),'--gamecore','stock','--yes'],check=True)

if __name__=='__main__':raise SystemExit(main())
