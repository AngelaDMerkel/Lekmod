"""Plan validation, durable progress, and same-process checkpoint orchestration."""
import hashlib
import json
import re
from playtest_native_methods import registered_methods, missing_methods, event_arity_errors, receiver_method_errors
import shutil
import signal
import subprocess
import time
from pathlib import Path
from playtest_save import CheckpointCopier, game_save_writer_open

# Only scenarios with reviewed, compatible temporary adapters are admitted.
HOOKS = {
    'exotic-goods': {'UI/Tutorial.lua': 'playtest-tutorial-edge-observer.lua'},
    'aksum-ordinary-heal': {'Civilizations/Lekmod_aksum.lua': 'playtest-aksum-heal-observer.lua'},
    'moors-acquisition': {'@DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua': 'playtest-scenario-diplo-assets-root.lua', 'UI/TradeLogic.lua': 'playtest-scenario-romania-city-gift-popup.lua', '@UI/InGame/LeaderHead/DiploTrade.lua': 'playtest-scenario-trade-context.lua', 'UI/DiscussionDialog.lua': 'playtest-scenario-romania-city-gift-reply.lua'},
    'maori-lifetime': {'UI/prophetreplace.lua': 'playtest-plot-iterator-dependency.lua'},
    'mughal-garrison': {},
    'palmyra-elimination': {'@UI/InGame/Popups/GenericPopup.lua': 'playtest-scenario-city-capture-popup.lua', '@UI/InGame/Popups/AdvisorModal.lua': 'playtest-scenario-advisor-attack-popup.lua'},
    'romania-liberation': {'@UI/InGame/Popups/GenericPopup.lua': 'playtest-scenario-city-capture-popup.lua'},
    'romania-acquisition': {'@DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua': 'playtest-scenario-diplo-assets-root.lua', 'UI/TradeLogic.lua': 'playtest-scenario-romania-city-gift-popup.lua', '@UI/InGame/LeaderHead/DiploTrade.lua': 'playtest-scenario-trade-context.lua', 'UI/DiscussionDialog.lua': 'playtest-scenario-romania-city-gift-reply.lua'},
    'yugoslav-revolution-cycle': {'UI/SocialPolicyPopup.lua': 'playtest-scenario-revolution-popup.lua'},
    'yugoslavia-ideology': {'@DLC/Expansion2/UI/InGame/Popups/ChooseIdeologyPopup.lua': 'playtest-scenario-ideology-popup.lua', 'UI/SocialPolicyPopup.lua': 'playtest-scenario-revolution-popup.lua'},
    'swiss-purchase': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'unique-special-purchase': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'maccabee-faith': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'religious-unique-units': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'israel-college-reward': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'israel-college-gold': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'israel-college-faith': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
    'unique-unit-disband': {'@UI/InGame/Popups/GenericPopup.lua': 'playtest-scenario-unit-confirm.lua'},
    'greatworks': {'@DLC/Expansion2/UI/InGame/Popups/GreatWorkPopup.lua': 'playtest-culture-great-work-popup.lua'},
    'newzealand-defender': {'Civilizations/Lekmod_newzealand.lua': 'playtest-nz-owner-observer.lua'},
    'newzealand-battalion': {'Civilizations/Lekmod_newzealand.lua': 'playtest-nz-owner-observer.lua'},
    'unit-utility': {'@UI/InGame/Popups/GenericPopup.lua': 'playtest-scenario-unit-confirm.lua'},
    'city-basics': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua', 'UI/CityView.lua': 'playtest-scenario-city-sale.lua'},
    'trade-internal': {'UI/ChooseInternationalTradeRoutePopup.lua': 'playtest-scenario-trade-popup.lua', '@DLC/Expansion2/UI/InGame/Popups/ChooseTradeUnitNewHome.lua': 'playtest-scenario-trade-home-popup.lua'},
    'religion-benefits': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
}
# Parameters are data-only and enumerated for each reviewed scenario.
PARAMETERS = {'airlift': {'building': ('BUILDING_AIRPORT','BUILDING_HORDE_YAM_ROUTE','BUILDING_MC_OMANI_MINAA','BUILDING_SERAI')}, 'paradrop': {'unit': ('UNIT_PARATROOPER','UNIT_XCOM_SQUAD')}, 'exotic-goods': {'unit': ('UNIT_IMPRENDITORO','UNIT_IMPRENDITORE','UNIT_PORTUGUESE_NAU')}, 'moors-acquisition-load': {'expected_state': 'snapshot-json'}, 'moors-acquisition': {'mode': ('capture-in','gift-in','capture-out','gift-out'), 'era': ('medieval','renaissance')}, 'maori-lifetime': {'mode': ('upgrade','naval','embark','capture-in','capture-out')}, 'mughal-garrison-load': {'expected_state': 'snapshot-json'}, 'cuba-capital-transfer': {'mode': ('own','foreign','eliminate')}, 'palmyra-elimination': {'mode': ('loss','gain','duplicate')}, 'city-god': {'mode': ('human', 'tibet', 'control')},
              'city-god-repeat': {'mode': ('human', 'tibet', 'control'), 'expected_state': 'snapshot-json'},
              'city-god-reentry': {'mode': ('human', 'control'), 'expected_state': 'snapshot-json'}}

PREFIXES = {'playtest-aksum-heal-observer.lua': 'playtest-aksum-heal-before.lua', 'playtest-nz-owner-observer.lua': 'playtest-nz-owner-before-observer.lua'}

SUPPORTED = set(HOOKS) | {'engineer-rewards', 'merchant-rewards', 'info-cache', 'airlift','paradrop','exotic-goods', 'moors-acquisition-load', 'maori-movement', 'mughal-garrison-load', 'cuba-capital-transfer', 'city-god-reentry', 'city-god-repeat', 'city-god', 'swiss-migration-load', 'swiss-human-training', 'swiss-legacy-load', 'swiss-boundaries', 'swiss-armory', 'unique-prophet-birth', 'unique-general-birth', 'unique-specialist-birth', 'unique-unit-production', 'religious-unit-upgrades', 'swiss-enemy-heal', 'swiss-city-plunder-funded', 'swiss-city-plunder-empty', 'swiss-city-plunder-control', 'swiss-mounted-calculation', 'swiss-utility', 'crusader-borders', 'vatican-kill-faith', 'religious-terrain', 'vatican-great-improvements', 'vatican-pressure-votes', 'vatican-courthouse', 'vatican-stpeters', 'jerusalem-outremer', 'unique-building-catalogue', 'unique-building-pilot', 'civilization-start', 'unique-units', 'counterspy', 'nuclear-cities', 'nuclear-production', 'nuclear-cleanup', 'defender-zoc', 'inventory', 'admiral-repair', 'worker', 'unit-actions', 'great-person-builds', 'budget-settlement', 'nuclear', 'air-operations', 'greatworks', 'trade-tooltip', 'trade-countdown', 'nabatea-farms', 'nabatea-tomb', 'newzealand-science-completion'}

def validate_lua_syntax(plan, repo, compiler):
    """Parse every selected scenario and injected UI adapter before installation."""
    port = repo / 'LEKMOD_DLL/macos'
    names = {'playtest-scenario-' + stage['scenario'] + '.lua' for stage in plan['stages']}
    adapters = set(plan['hooks'].values())
    adapters.update(PREFIXES[name] for name in list(adapters) if name in PREFIXES)
    names.update(adapters)
    result = subprocess.run([str(compiler), '-p', *(str(port / name) for name in sorted(names))],
                            capture_output=True, text=True)
    if result.returncode:
        raise ValueError('Lua syntax preflight failed: ' + result.stderr.strip())


def run_owned_runner(command, **kwargs):
    """Let the child restore its UI/settings when this wrapper is interrupted."""
    # A terminal Ctrl-C must reach the child only once, through this owner.
    child = subprocess.Popen(command, start_new_session=True, **kwargs)
    try:
        return child.wait()
    except KeyboardInterrupt:
        if child.poll() is None:
            child.send_signal(signal.SIGINT)
        deadline = time.monotonic() + 60
        while True:
            try:
                return child.wait(timeout=max(0.1, deadline - time.monotonic()))
            except KeyboardInterrupt:
                # Repeated interrupts must not SIGKILL the restoration owner.
                if time.monotonic() >= deadline:
                    raise RuntimeError("Owned runner cleanup did not finish; PID " + str(child.pid))
            except subprocess.TimeoutExpired as error:
                raise RuntimeError("Owned runner cleanup did not finish; PID " + str(child.pid)) from error

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def lua(value):
    if value is None: return 'nil'
    if isinstance(value, bool): return 'true' if value else 'false'
    if isinstance(value, (float, int)): return str(value)
    if isinstance(value, str):
        # Lua 5.1 accepts decimal escapes, not JSON's Unicode escape syntax.
        return '"' + ''.join('\\%03d' % b if b < 32 or b >= 127 or b in (34, 92) else chr(b) for b in value.encode()) + '"'
    if isinstance(value, list): return '{' + ','.join(lua(v) for v in value) + '}'
    if isinstance(value, dict): return '{' + ','.join('['+lua(str(k))+']='+lua(v) for k,v in sorted(value.items())) + '}'
    raise ValueError('unsupported Lua value')

def wrap_adapter(code):
    # Route test assertions from separate UI contexts without changing product print().
    return r'''do
local originalPrint=print
local function print(message,...)
 originalPrint(message,...)
 if type(message)=="string"then
  local item,status,detail=string.match(message,"^%[LEKMOD_FUNCTIONAL%] run=__TEST_RUN__ item=(%S+) status=(%S+)%s*(.*)$")
  if item then LuaEvents.LekmodBatchAssertion(item,status,detail)end
 end
end
''' + code + '\nend\n'

def load_plan(path, repo, items):
    source = json.loads(path.read_text())
    if source.get('schema') != 1 or not re.fullmatch(r'[a-z0-9-]{1,48}', source.get('name', '')):
        raise ValueError('Batch requires schema 1 and a short lowercase name')
    stages = source.get('stages', [])
    if not 1 <= len(stages) <= 24: raise ValueError('Batch requires 1–24 stages')
    seen=set(); hooks={}; total=0; result=[]
    for row in stages:
        row=dict(row); ident=row.get('id',''); scenario=row.get('scenario')
        if not re.fullmatch(r'[a-z0-9-]{1,24}',ident) or ident in seen: raise ValueError('Invalid/duplicate stage id')
        seen.add(ident)
        if scenario not in SUPPORTED or scenario not in items: raise ValueError('Unsupported batch scenario: '+str(scenario))
        parameters = row.get('parameters', {})
        permitted = PARAMETERS.get(scenario, {})
        if not isinstance(parameters, dict) or set(parameters) != set(permitted):
            raise ValueError('Invalid/missing reviewed scenario parameters: ' + ident)
        for key, values in permitted.items():
            value=parameters[key]
            if values=='snapshot-json':
                if not isinstance(value,str) or len(value)>131072:
                    raise ValueError('Invalid snapshot parameter: '+ident)
                try: snapshot=json.loads(value)
                except (ValueError,TypeError) as error:
                    raise ValueError('Invalid snapshot parameter: '+ident) from error
                if not isinstance(snapshot,dict) or set(snapshot)!={'turn','owners'} or not isinstance(snapshot['owners'],dict):
                    raise ValueError('Invalid snapshot parameter shape: '+ident)
            elif not isinstance(value,str) or value not in values:
                raise ValueError('Invalid reviewed scenario parameter value: '+ident)
        turns=row.get('max_turns',0)
        if isinstance(turns,bool) or not isinstance(turns,int) or not 0 <= turns <= 19: raise ValueError('Invalid stage turn limit')
        total+=turns
        original=repo/row['fixture']
        fixture=original.resolve()
        if not fixture.is_file() or fixture.suffix.lower()!='.civ5save' or original.is_symlink(): raise ValueError('Missing/invalid fixture: '+str(fixture))
        if not re.fullmatch('[a-f0-9]{64}',row.get('sha256','')) or sha(fixture)!=row['sha256']: raise ValueError('Fixture hash mismatch: '+ident)
        expected=None;report_path=None
        if bool(row.get('expected_report')) != bool(row.get('expected_report_sha256')):
            raise ValueError('Replay requires both expected report and hash')
        if row.get('expected_report'):
            if turns!=0:raise ValueError('Replay-only stages require zero turns')
            report_path=repo/row['expected_report']
            if report_path.is_symlink()or not report_path.is_file():raise ValueError('Missing/invalid expected report')
            report_bytes=report_path.read_bytes()
            if hashlib.sha256(report_bytes).hexdigest()!=row['expected_report_sha256']:raise ValueError('Expected report hash mismatch')
            report=json.loads(report_bytes)
            if not str(report.get('status','')).startswith('passed-')or report.get('normal_exit_verified')is not True:
                raise ValueError('Expected report is not a verified passing native run')
            if report.get('scenario')!=scenario or report.get('saved_sha256')!=row['sha256']:
                raise ValueError('Expected report scenario/save mismatch')
            expected=report.get('saved_state')
            if not isinstance(expected,str)or not isinstance(json.loads(expected),dict):raise ValueError('Expected report lacks a snapshot object')
        if scenario=='civilization-start'and expected is None:raise ValueError('Civilization starts use the standalone runner; batch supports their exact replay only')
        code_path=repo/'LEKMOD_DLL/macos'/('playtest-scenario-'+scenario+'.lua')
        code=code_path.read_text()
        if '-- Native method surface: GameCore' in code:
            missing=missing_methods(code,registered_methods())
            if missing:raise ValueError('Unregistered native methods in '+scenario+': '+', '.join(missing))
            arity=event_arity_errors(code)
            if arity:raise ValueError('Native callback signature in '+scenario+': '+', '.join(arity))
        receiver_errors=receiver_method_errors(code)
        if receiver_errors:raise ValueError('Native receiver in '+scenario+': '+', '.join(receiver_errors))
        for target,adapter in HOOKS.get(scenario,{}).items():
            if target in hooks and hooks[target]!=adapter: raise ValueError('Conflicting adapters at '+target)
            hooks[target]=adapter
        result.append(dict(id=ident,scenario=scenario,parameters=dict(parameters),fixture=str(fixture),sha256=row['sha256'],max_turns=turns,
                           items=[]if expected is not None else sorted(items[scenario]),code=code,source_sha256=sha(code_path),
                           replay_only=expected is not None,expected=expected,expected_report=str(report_path.resolve())if report_path else None,
                           expected_report_sha256=row.get('expected_report_sha256')))
    adapters=set(hooks.values());adapters.update(PREFIXES[a]for a in list(adapters)if a in PREFIXES)
    providers='\n'.join((repo/'LEKMOD_DLL/macos'/adapter).read_text() for adapter in adapters)
    for stage in result:
        listeners=set(re.findall(r'LuaEvents\.(Lekmod\w+)\.Add',stage['code']))
        emitters=set(re.findall(r'LuaEvents\.(Lekmod\w+)\s*\(',providers+'\n'+stage['code']))
        missing=listeners-emitters
        if missing:raise ValueError('Missing UI response adapter for '+stage['id']+': '+', '.join(sorted(missing)))
    if total>30: raise ValueError('Batch exceeds 30 total bounded functional turns; no long campaign')
    return dict(schema=1,name=source['name'],stages=result,hooks=hooks,max_turns=total)

class Session:
    def __init__(self,plan,output,app,data,stamp,save_writer_open=None,save_settle_seconds=2.0):
        self.plan=plan;self.output=output;self.app=app;self.data=data;self.stamp=stamp
        self.game_pid=None
        self.save_copier=CheckpointCopier(save_writer_open or (lambda path:game_save_writer_open(self.game_pid,path)),save_settle_seconds)
        self.control=app/'Contents/Assets/Assets/DLC/LEKMOD/Lua/UI/LekmodBatchControl.lua'
        self.index=1;self.mode='run';self.command=0;self.seen=set();self.results=[];self.done=False;self.failed=False
        self.progress_items=set()
        self.transcript='';previous_log=data/'Logs/Lua.log'
        self.last_lua=previous_log.read_text(errors='replace')if previous_log.exists()else''
        self.epoch_offset=0;self.transitioning=False
        self.pending_expected=plan['stages'][0].get('expected');self.turns=0;self.started=time.monotonic();self.stage_started={}
        if plan['stages'][0].get('replay_only'):self.mode='reload'
        (output/'batch-plan.json').write_text(json.dumps({**plan,'stages':[{k:v for k,v in s.items()if k!='code'}for s in plan['stages']]},indent=2)+'\n')
    def initial_control(self):
        return 'LekmodBatchControl='+lua(dict(run=self.stamp,command=0,index=1,mode=self.mode,expected=self.pending_expected))+'\n'
    def plan_code(self):
        return 'LekmodBatchPlan='+lua(self.plan)+'\n'
    def write_control(self,value):
        self.command+=1;value.update(run=self.stamp,command=self.command)
        content='LekmodBatchControl='+lua(value)+'\n'
        tmp=self.control.with_name(self.control.name+'.'+self.stamp+'.tmp')
        created=False
        try:
            with tmp.open('x') as stream:
                created=True;stream.write(content)
            tmp.replace(self.control)
        finally:
            if created and tmp.exists():tmp.unlink()
        (self.output/'batch-control.json').write_text(json.dumps(value,indent=2)+'\n')
    def collect(self,text):
        # Lua.log can restart when a saved game is loaded in the same process.
        if text.startswith(self.last_lua): fresh=text[len(self.last_lua):]
        elif text==self.last_lua: fresh=''
        else: fresh='\n'+text
        self.last_lua=text
        if fresh:
            self.transcript+=fresh
            with (self.output/'batch-lua.log').open('a') as stream:stream.write(fresh)
        return self.transcript
    def update(self,text,render_text):
        progress=False
        # Long zero-turn stages can finish many real checks before checkpointing.
        # Only a new successful assertion in this run/current stage is progress;
        # repeated messages, observations, other stages and FAIL are not keepalives.
        if not self.done:
            stage=self.plan['stages'][self.index-1]['id']
            checks=r'\[LEKMOD_FUNCTIONAL\] run='+re.escape(self.stamp)+r' item=('+re.escape(stage)+r'::\S+) status=PASS(?:\s|$)'
            for item in re.findall(checks,text):
                if item not in self.progress_items:
                    self.progress_items.add(item);progress=True
        pattern=r'\[LEKMOD_BATCH\] run='+re.escape(self.stamp)+r' event=(\S+) value=(\{[^\n]*\})'
        for match in re.finditer(pattern,text):
            event=match[1];value=json.loads(match[2]);key=(event,value.get('index'),value.get('mode'))
            if key in self.seen:continue
            if event=='stage-start':
                self.seen.add(key);self.transitioning=False;progress=True
                self.stage_started[(value['index'],value['mode'])]=time.monotonic()
            elif event=='checkpoint':
                if value['index']!=self.index or value['mode']!=self.mode:raise ValueError('Unexpected batch checkpoint')
                expected_name='Lekmod-Batch-'+self.stamp+'-'+self.plan['stages'][self.index-1]['id']+'-'+self.mode
                if value['save_name']!=expected_name:raise ValueError('Unexpected checkpoint filename')
                save=self.data/'Saves/single'/(value['save_name']+'.Civ5Save')
                # The callback returns before asynchronous disk writing finishes.
                # Require the game writer to close, stable metadata, and equal source/copy bytes.
                ack='event=saved value='+json.dumps(value['save_name'])
                if ack not in text or not save.is_file() or save.stat().st_size==0:continue
                target=self.output/'checkpoints'/save.name
                verification=self.save_copier.copy_if_ready(save,target)
                if verification is None:continue
                self.seen.add(key);progress=True
                begin=self.stage_started.get((self.index,self.mode))
                row={**value,'save_verification':verification,'saved_copy':str(target),'saved_sha256':verification['sha256'],'elapsed_seconds':round(time.monotonic()-begin,2)if begin is not None else None}
                self.results.append(row);self.failed |= value['failed']
                if self.mode=='run':self.turns+=value['turns']
                if self.turns>30:raise ValueError('Batch exceeded total functional turn limit')
                if self.mode=='run' and not value['failed']:
                    self.mode='reload';self.pending_expected=value['state']
                    command=dict(index=self.index,mode='reload',path=str(target),expected=value['state'])
                else:
                    self.index+=1;self.mode='run';self.pending_expected=None
                    if self.index>len(self.plan['stages']):
                        self.done=True;command=dict(index=self.index,mode='finish',failed=self.failed)
                    else:
                        stage=self.plan['stages'][self.index-1]
                        if sha(Path(stage['fixture']))!=stage['sha256']:raise ValueError('Fixture changed during batch')
                        if stage.get('replay_only'):self.mode='reload';self.pending_expected=stage['expected']
                        command=dict(index=self.index,mode=self.mode,path=stage['fixture'],expected=self.pending_expected)
                self.epoch_offset=len(render_text);self.transitioning=not self.done
                self.write_control(command)
                self.persist()
        return progress
    def epoch_text(self,text):
        if self.epoch_offset>len(text):
            if not self.transitioning:raise ValueError('Render log reset without an authorized fixture load')
            self.epoch_offset=0
        return text[self.epoch_offset:]
    def persist(self,final_status=None):
        (self.output/'batch-report.json').write_text(json.dumps(dict(name=self.plan['name'],complete=self.done,failed=self.failed,
             index=self.index,mode=self.mode,turns=self.turns,elapsed_seconds=round(time.monotonic()-self.started,2),final_status=final_status,results=self.results),indent=2)+'\n')
