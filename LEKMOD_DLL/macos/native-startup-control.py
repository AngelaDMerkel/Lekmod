#!/usr/bin/env python3
"""Explicit foreground control with original UI and no injected library.

A zero exit code alone is not menu/gameplay coverage; retain separate physical
observations. Never starts Steam or changes its channel; it makes no direct binary/cache edits.
"""
import argparse,hashlib,importlib.util,json,os,shutil,subprocess,time
from datetime import datetime,timezone
from pathlib import Path

port=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('playtest',port/'automated-playtest.py')
playtest=importlib.util.module_from_spec(spec);spec.loader.exec_module(playtest)
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--foreground-authorized',action='store_true')
parser.add_argument('--timeout',type=int,default=600)
parser.add_argument('--logging-enabled',type=int,choices=(0,1),help='Optional single-setting startup control; all original bytes are restored')
args=parser.parse_args()
if not args.foreground_authorized or not 30<=args.timeout<=3600:
    parser.error('Explicit foreground authorization and a 30–3600 second bound are required')
if playtest.game_pids():raise SystemExit('Civ V is already open; no settings changed')
playtest.require_unlocked_desktop();playtest.require_existing_steam_session()
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
output=playtest.REPO/'build/macos/native-startup-controls'/stamp;output.mkdir(parents=True)
settings={p:p.read_bytes() for p in (playtest.DATA/'config.ini',playtest.DATA/'UserSettings.ini',playtest.DATA/'GraphicsSettingsDX9.ini') if p.exists()}
for p,data in settings.items():(output/(p.name+'.original')).write_bytes(data)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
saves={p:digest(p) for p in (playtest.DATA/'Saves/single').glob('*.Civ5Save')}
report={'mode':'native-startup-control','started_utc':stamp,'foreground':True,'process_observer':'none','temporary_ui_hooks':False,'settings_modified_before_launch':False,'logging_enabled_override':args.logging_enabled,'manual_saves_before':{str(p):v for p,v in saves.items()}}
environment=os.environ.copy();environment.pop('DYLD_INSERT_LIBRARIES',None)
environment.update(SteamAppId='8930',SteamGameId='8930')
started=time.monotonic();process=None
launch_settings=dict(settings)
try:
    if args.logging_enabled is not None:
        config=playtest.DATA/'config.ini'
        launch_settings[config]=playtest.edit_ini(settings[config].decode(),{('DEBUG','LoggingEnabled'):args.logging_enabled}).encode()
        config.write_bytes(launch_settings[config])
        report['settings_modified_before_launch']=launch_settings[config]!=settings[config]
    report['launch_settings_sha256']={p.name:hashlib.sha256(data).hexdigest() for p,data in launch_settings.items()}
    playtest.require_unlocked_desktop()
    with (output/'process.log').open('w') as log:
        process=subprocess.Popen([str(playtest.APP/'Contents/MacOS/Civilization V')],cwd=playtest.APP/'Contents/MacOS',env=environment,stdin=subprocess.DEVNULL,stdout=log,stderr=subprocess.STDOUT)
        report['pid']=process.pid
        (output/'run-state.json').write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps({'event':'launched-foreground-startup-control' if args.logging_enabled is not None else 'launched-unmodified-foreground-control','pid':process.pid,'evidence':str(output)}),flush=True)
        while process.poll() is None and time.monotonic()-started<args.timeout:time.sleep(1)
        if process.poll() is None:report['timeout']=True
except KeyboardInterrupt:
    report['interrupted']=True
finally:
    if process and process.poll() is None:
        report['termination_signals']=['SIGTERM'];process.terminate()
        try:process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            report['termination_signals'].append('SIGKILL');process.kill();process.wait(timeout=5)
    report['process_returncode']=process.poll() if process else None
    report['settings_changed_by_game']=[p.name for p,data in launch_settings.items() if not p.exists() or p.read_bytes()!=data]
    for p,data in settings.items():p.write_bytes(data)
    report['settings_restored']=all(p.read_bytes()==data for p,data in settings.items())
    report['manual_saves_preserved']=all(p.exists() and digest(p)==value for p,value in saves.items())
    report['duration_seconds']=round(time.monotonic()-started,1)
    if (playtest.DATA/'Logs').exists():shutil.copytree(playtest.DATA/'Logs',output/'logs-after')
    report['status']='ended-native-control' if report['process_returncode']==0 and not report.get('termination_signals') else 'failed-native-control'
    (output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2),flush=True)
raise SystemExit(0 if report['status']=='ended-native-control' and report['settings_restored'] and report['manual_saves_preserved'] else 1)
