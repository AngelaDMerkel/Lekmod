#!/usr/bin/env python3
"""Bounded normal starts for groups of civilizations; emit one pinned replay plan."""
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time
import zipfile
import playtest_batch

PORT=Path(__file__).resolve().parent;ROOT=PORT.parents[1]
spec=importlib.util.spec_from_file_location('runner',PORT/'automated-playtest.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    choice=p.add_mutually_exclusive_group();choice.add_argument('--group',type=int);choice.add_argument('--all',action='store_true');choice.add_argument('--roster',action='append',help='explicit comma-separated single-player roster, human first; repeat for independent fixtures')
    p.add_argument('--from-group',type=int,default=1,help='with --all, start at the first unfinished one-based group')
    p.add_argument('--minutes',type=int,default=45)
    p.add_argument('--preflight-only',action='store_true')
    p.add_argument('--trace-loaded-libraries',action='store_true')
    p.add_argument('--package',type=Path)
    p.add_argument('--sha256')
    p.add_argument('--installer',type=Path,default=ROOT.parent/'Civ5ModDlcPacker/civ5_dlc_installer.py')
    a=p.parse_args();plan=json.loads((PORT/'civilization-startup-groups.json').read_text())
    if not 5<=a.minutes<=120:p.error('Use 5–120 minutes for the bounded group matrix')
    if hashlib.sha256((ROOT/'LEKMOD/Override/CIV5Units.xml').read_bytes()).hexdigest()!=plan['source_xml_sha256']:p.error('Gameplay XML changed; review and regenerate groups')
    flat=[c for g in plan['groups']for c in g]
    if len(flat)!=114 or len(set(flat))!=114 or any(not 2<=len(g)<=12 for g in plan['groups']):p.error('Invalid civilization group inventory')
    if a.roster:
        known=set(flat);rosters=[row.split(',')for row in a.roster]
        if len(rosters)>10 or any(not 2<=len(g)<=12 or len(set(g))!=len(g)or any(c not in known for c in g)for g in rosters):
            p.error('Custom rosters require 1–10 independent groups of 2–12 distinct reviewed playable civilizations')
        plan={**plan,'groups':rosters}
    if not 1<=a.from_group<=len(plan['groups']):p.error('Invalid starting group')
    if a.group is not None and not 1<=a.group<=len(plan['groups']):p.error('Invalid group')
    if a.group is not None and a.from_group!=1:p.error('--from-group is for --all')
    selected=[a.group]if a.group is not None else list(range(a.from_group,len(plan['groups'])+1))
    subprocess.run([str(ROOT/'build/macos/test-deps/lua-5.1.4/src/luac'),'-p',str(PORT/'playtest-scenario-civilization-start.lua')],check=True)
    print(json.dumps({'groups':selected,'civilizations':sum(len(plan['groups'][i-1])for i in selected),'maximum_functional_turns':3*len(selected),'replay':'separate single-process plan emitted after verified saves'},indent=2),flush=True)
    if a.preflight_only:return 0
    if not a.all and a.group is None and not a.roster:p.error('Choose --group, --all or --roster explicitly')
    if not a.package or not a.sha256 or playtest_batch.sha(a.package)!=a.sha256:p.error('Verified package/hash required')
    with zipfile.ZipFile(a.package)as archive:
        if hashlib.sha256(archive.read('payload/LEKMOD/Override/CIV5Units.xml')).hexdigest()!=plan['source_xml_sha256']:p.error('Package gameplay XML differs from the reviewed groups')
    runner.require_unlocked_desktop();runner.require_existing_steam_session()
    if runner.game_pids():p.error('Civ V must be closed')
    sys.path.insert(0,str(a.installer.parent));import civ5_gamecore
    if civ5_gamecore.ProductManager(runner.APP,runner.DATA).status().get('product')!='stock':p.error('Matrix requires stock initially')
    stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ');out=ROOT/'build/macos/civilization-matrices'/stamp;out.mkdir(parents=True)
    result={'started_utc':stamp,'package_sha256':a.sha256,'selected_groups':selected,'requested_rosters':plan['groups'],'custom_rosters':bool(a.roster),'groups':[],'passed':False}
    replays={'schema':1,'name':'civilization-start-state-replays','stages':[]}
    installed=False;deadline=time.monotonic()+60*a.minutes
    try:
        subprocess.run([sys.executable,str(a.installer),'--gamecore','lekmod','--gamecore-package',str(a.package.resolve()),'--gamecore-sha256',a.sha256,'--yes'],check=True);installed=True
        for number in selected:
            runner.require_unlocked_desktop();runner.require_existing_steam_session()
            remaining=int(deadline-time.monotonic())
            if remaining<180:result['stop_reason']='matrix wall-clock budget before next launch';break
            group=plan['groups'][number-1];old=set((ROOT/'build/macos/playtests').iterdir())
            cmd=[sys.executable,str(PORT/'automated-playtest.py'),'--mode','single-player-smoke','--turns','3','--timeout',str(min(600,remaining)),'--stall-seconds','180','--scenario','civilization-start','--scenario-turns','3','--save-and-exit','--majors',str(len(group)),'--minors','0','--world-size',plan['world'],'--map-script',plan['map'],'--start-era',plan['era'],'--game-speed',plan['speed'],'--handicap',plan['human_handicap'],'--civilization',group[0],'--game-option','GAMEOPTION_NO_BARBARIANS=1','--game-option','GAMEOPTION_NO_GOODY_HUTS=1']
            if a.trace_loaded_libraries:cmd+=['--trace-loaded-libraries']
            for slot,civ in enumerate(group[1:],1):cmd+=['--slot-civilization',str(slot)+'='+civ]
            with (out/('group-%02d.log'%number)).open('w')as log:code=playtest_batch.run_owned_runner(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
            paths=[q/'report.json'for q in set((ROOT/'build/macos/playtests').iterdir())-old if(q/'report.json').is_file()]
            if len(paths)!=1:raise RuntimeError('Cannot identify owned group report')
            report=paths[0];r=json.loads(report.read_text());passed=code==0 and r.get('normal_exit_verified')is True and r.get('functional_checks',{}).get('verified')is True and all(r.get(k)is True for k in ('settings_restored','temporary_ui_hooks_restored','manual_saves_preserved'))
            result['groups'].append({'group':number,'civilizations':group,'report':str(report),'status':r['status'],'passed':passed})
            print(json.dumps(result['groups'][-1]),flush=True)
            if passed:
                saved=Path(r['saved_copy']);assert playtest_batch.sha(saved)==r['saved_sha256']
                replays['stages'].append({'id':'civ-group-%02d'%number,'scenario':'civilization-start','fixture':str(saved.relative_to(ROOT)),'sha256':r['saved_sha256'],'expected_report':str(report.relative_to(ROOT)),'expected_report_sha256':playtest_batch.sha(report),'max_turns':0})
                (out/'replay-plan.json').write_text(json.dumps(replays,indent=2)+'\n')
            (out/'report.json').write_text(json.dumps(result,indent=2)+'\n')
            if not passed:break
        result['passed']=len(result['groups'])==len(selected)and all(q['passed']for q in result['groups'])
    except (Exception,KeyboardInterrupt,SystemExit)as error:
        result['error']=type(error).__name__+': '+str(error);raise
    finally:
        if installed:result['stock_restore_returncode']=subprocess.run([sys.executable,str(a.installer),'--gamecore','stock','--yes']).returncode
        result['finished_utc']=datetime.now(timezone.utc).isoformat();(out/'report.json').write_text(json.dumps(result,indent=2)+'\n')
    return 0 if result['passed']and result.get('stock_restore_returncode')==0 else 1
if __name__=='__main__':raise SystemExit(main())
