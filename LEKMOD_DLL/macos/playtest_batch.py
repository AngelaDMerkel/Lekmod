"""Plan validation, durable progress, and same-process checkpoint orchestration."""
import hashlib
import json
import re
import shutil
import time
from pathlib import Path

# Only scenarios with reviewed, compatible temporary adapters are admitted.
HOOKS = {
    'greatworks': {'@DLC/Expansion2/UI/InGame/Popups/GreatWorkPopup.lua': 'playtest-culture-great-work-popup.lua'},
    'newzealand-defender': {'Civilizations/Lekmod_newzealand.lua': 'playtest-nz-owner-observer.lua'},
    'newzealand-battalion': {'Civilizations/Lekmod_newzealand.lua': 'playtest-nz-owner-observer.lua'},
    'unit-utility': {'@UI/InGame/Popups/GenericPopup.lua': 'playtest-scenario-unit-confirm.lua'},
    'city-basics': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua', 'UI/CityView.lua': 'playtest-scenario-city-sale.lua'},
    'trade-internal': {'UI/ChooseInternationalTradeRoutePopup.lua': 'playtest-scenario-trade-popup.lua', '@DLC/Expansion2/UI/InGame/Popups/ChooseTradeUnitNewHome.lua': 'playtest-scenario-trade-home-popup.lua'},
    'religion-benefits': {'UI/ProductionPopup.lua': 'playtest-scenario-purchase-popup.lua'},
}
PREFIXES = {'playtest-nz-owner-observer.lua': 'playtest-nz-owner-before-observer.lua'}

SUPPORTED = set(HOOKS) | {'inventory', 'admiral-repair', 'worker', 'unit-actions', 'great-person-builds', 'budget-settlement', 'nuclear', 'air-operations', 'greatworks', 'trade-tooltip', 'trade-countdown', 'nabatea-farms', 'nabatea-tomb', 'newzealand-science-completion'}

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
        turns=row.get('max_turns',0)
        if isinstance(turns,bool) or not isinstance(turns,int) or not 0 <= turns <= 19: raise ValueError('Invalid stage turn limit')
        total+=turns
        original=repo/row['fixture']
        fixture=original.resolve()
        if not fixture.is_file() or fixture.suffix.lower()!='.civ5save' or original.is_symlink(): raise ValueError('Missing/invalid fixture: '+str(fixture))
        if not re.fullmatch('[a-f0-9]{64}',row.get('sha256','')) or sha(fixture)!=row['sha256']: raise ValueError('Fixture hash mismatch: '+ident)
        code_path=repo/'LEKMOD_DLL/macos'/('playtest-scenario-'+scenario+'.lua')
        code=code_path.read_text()
        for target,adapter in HOOKS.get(scenario,{}).items():
            if target in hooks and hooks[target]!=adapter: raise ValueError('Conflicting adapters at '+target)
            hooks[target]=adapter
        result.append(dict(id=ident,scenario=scenario,fixture=str(fixture),sha256=row['sha256'],max_turns=turns,
                           items=sorted(items[scenario]),code=code,source_sha256=sha(code_path)))
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
    def __init__(self,plan,output,app,data,stamp):
        self.plan=plan;self.output=output;self.app=app;self.data=data;self.stamp=stamp
        self.control=app/'Contents/Assets/Assets/DLC/LEKMOD/Lua/UI/LekmodBatchControl.lua'
        self.index=1;self.mode='run';self.command=0;self.seen=set();self.results=[];self.done=False;self.failed=False
        self.transcript='';previous_log=data/'Logs/Lua.log'
        self.last_lua=previous_log.read_text(errors='replace')if previous_log.exists()else''
        self.epoch_offset=0;self.transitioning=False
        self.pending_expected=None;self.turns=0;self.started=time.monotonic();self.stage_started={}
        (output/'batch-plan.json').write_text(json.dumps({**plan,'stages':[{k:v for k,v in s.items()if k!='code'}for s in plan['stages']]},indent=2)+'\n')
    def initial_control(self):
        return 'LekmodBatchControl='+lua(dict(run=self.stamp,command=0,index=1,mode='run'))+'\n'
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
                # Advance only after the normal SaveGame callback returned and a file exists.
                ack='event=saved value='+json.dumps(value['save_name'])
                if ack not in text or not save.is_file() or save.stat().st_size==0:continue
                self.seen.add(key);progress=True
                target=self.output/'checkpoints'/save.name;target.parent.mkdir(exist_ok=True);shutil.copy2(save,target)
                begin=self.stage_started.get((self.index,self.mode))
                row={**value,'saved_copy':str(target),'saved_sha256':sha(target),'elapsed_seconds':round(time.monotonic()-begin,2)if begin is not None else None}
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
                        command=dict(index=self.index,mode='run',path=stage['fixture'])
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
