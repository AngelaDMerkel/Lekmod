-- One game process, explicit fixture loads, scoped callbacks, and host-verified saves.
include("LekmodBatchPlan.lua")
include("LekmodBatchControl.lua")
local current,waiting,applied=nil,false,-1
local pendingSave=nil
local globalRecord=LekmodScenarioRecord
local function emit(event,value)
 print("[LEKMOD_BATCH] run=__TEST_RUN__ event="..event.." value="..LekmodScenarioJSON(value))
end
local function cleanup()
 if not current then return end
 current.active=false
 local removed=0
 for _,entry in ipairs(current.callbacks)do
  entry.event.Remove(entry.fn);removed=removed+1
 end
 current.callbacks={}
 emit("callbacks-removed",{index=current.index,mode=current.mode,count=removed})
end
local function fail(item,message)
 current.failed=true
 globalRecord(current.spec.id.."::"..item,"FAIL",message)
end
local function eventsProxy(native)
 local cache={}
 return setmetatable({},{__index=function(_,name)
  if not cache[name]then
   local event=native[name]
   cache[name]=setmetatable({Add=function(fn)
    local stage=current
    local wrapped=function(...)
     if not stage.active then return end
     local values={pcall(fn,...)}
     if not values[1]then
      stage.callbackError=tostring(values[2]);return
     end
     return unpack(values,2)
    end
    assert(event.Remove,"batch requires removable event subscriptions")
    event.Add(wrapped)
    stage.callbacks[#stage.callbacks+1]={event=event,fn=wrapped}
   end},{__call=function(_,...)return event(...)end})
  end
  return cache[name]
 end})
end
local function start(control)
 local spec=assert(LekmodBatchPlan.stages[control.index],"unknown batch stage")
 current={index=control.index,mode=control.mode,spec=spec,callbacks={},active=true,outcomes={},failed=false,startTurn=Game.GetGameTurn(),reads=0}
 local env=setmetatable({},{__index=_G});env._G=env;current.env=env
 env.GameEvents=eventsProxy(GameEvents);env.LuaEvents=eventsProxy(LuaEvents);env.Events=eventsProxy(Events)
 local waits={}
 env.LekmodScenarioAwait=function(key,ready)
  if ready then waits[key]=nil;return true end
  waits[key]=(waits[key]or 0)+1;assert(waits[key]<=8,"synchronized result did not arrive: "..key);return false
 end
 env.LekmodScenarioRecord=function(item,status,detail)
  assert(status=="PASS"or status=="FAIL"or status=="SKIP","invalid verdict")
  current.outcomes[item]=status
  if status~="PASS"then current.failed=true end
  globalRecord(spec.id.."::"..item,status,detail)
 end
 env.LekmodScenarioEvent=function(event,value)
  emit("observation",{index=current.index,mode=current.mode,event=event,value=value})
 end
 -- Only reviewed standalone modules are admitted by the host plan validator.
 env.include=function(name)error("undeclared batch helper: "..tostring(name))end
 local prefix="return function(api)\nlocal GameEvents,LuaEvents,Events=api.GameEvents,api.LuaEvents,api.Events\nlocal LekmodScenarioRecord,LekmodScenarioEvent,LekmodScenarioAwait=api.LekmodScenarioRecord,api.LekmodScenarioEvent,api.LekmodScenarioAwait\nlocal include=api.include\nlocal LekmodScenario,LekmodScenarioBeforeEndTurn\n"
 local factory=assert(loadstring(prefix..spec.code.."\nreturn LekmodScenario,LekmodScenarioBeforeEndTurn\nend","batch/"..spec.id))()
 current.scenario,current.beforeTurn=factory(env)
 assert(current.scenario,"stage did not define scenario")
 assert(type(current.scenario.step)=="function"and type(current.scenario.snapshot)=="function","stage contract missing step/snapshot")
 current.expected=control.expected
 waiting=false
 emit("stage-start",{index=current.index,mode=current.mode,id=spec.id,scenario=spec.scenario,turn=current.startTurn})
end
local function checkpoint()
 local ok,state=pcall(function()return current.scenario and current.scenario.snapshot and current.scenario.snapshot(Players[Game.GetActivePlayer()])or{}end)
 if not ok then fail("snapshot",tostring(state));state={}end
 local name="Lekmod-Batch-__TEST_RUN__-"..current.spec.id.."-"..current.mode
 local row={index=current.index,mode=current.mode,id=current.spec.id,failed=current.failed,turns=Game.GetGameTurn()-current.startTurn,
            outcomes=current.outcomes,state=LekmodScenarioJSON(state),save_name=name}
 cleanup();waiting=true;pendingSave=name
 emit("checkpoint",row)
 LuaEvents.LekmodFunctionalSave(name)
end
LuaEvents.LekmodBatchAssertion.Add(function(item,status,detail)
 if current and current.active and current.mode=="run"then
  current.env.LekmodScenarioRecord(item,status,detail)
 end
end)
LuaEvents.LekmodBatchSaved.Add(function(name)
 if pendingSave==name then pendingSave=nil end
end)
LekmodScenarioBeforeEndTurn=function(...)
 local fn=current and current.beforeTurn
 if fn then return fn(...)end
end
LekmodScenario={name="batch",items={"batch-complete"}}
function LekmodScenario.snapshot(player)
 return current and current.scenario.snapshot(player)or{}
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer(),"batch is single-player only")
 include("LekmodBatchControl.lua")
 local control=assert(LekmodBatchControl)
 assert(control.run=="__TEST_RUN__","stale batch control")
 if control.command~=applied then
  applied=control.command
  if control.mode=="finish"then
   cleanup();globalRecord("batch-complete",control.failed and"FAIL"or"PASS","all scheduled stages resolved; individual failures retained")
   print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=batch")
   LuaEvents.LekmodFunctionalExit();waiting=true;return false
  end
  if current and control.path then
   assert(waiting and not pendingSave,"host requested load before save acknowledgement")
   cleanup();emit("fixture-load",{index=control.index,mode=control.mode,path=control.path})
   UIManager:SetUICursor(1)
   Events.PlayerChoseToLoadGame(control.path)
   return false
  end
  local ok,err=pcall(start,control)
  if not ok then fail("setup",tostring(err));checkpoint();return false end
 end
 if waiting then return false end
 if current.callbackError then fail("callback",current.callbackError);checkpoint();return false end
 local ok,result=pcall(function()
  assert(Game.GetGameTurn()-current.startTurn<=current.spec.max_turns,"stage exceeded bounded turns")
  if current.mode=="reload"then
   local actual=LekmodScenarioJSON(current.scenario.snapshot(player))
   assert(actual==current.expected,"checkpoint state differs after same-process reload")
   globalRecord(current.spec.id.."::save-reload","PASS","exact stage snapshot after in-process load")
   current.outcomes["save-reload"]="PASS";return true
  end
  return current.scenario.step(player)
 end)
 if not ok then fail("driver",tostring(result));checkpoint();return false end
 if result==true then
  if current.mode=="run"then
   for _,item in ipairs(current.spec.items)do if current.outcomes[item]~="PASS"then fail(item,"required stage assertion missing or failed")end end
  end
  checkpoint();return false
 elseif result=="turn"then
  if Game.GetGameTurn()-current.startTurn>=current.spec.max_turns then fail("turn-bound","stage requested turn beyond bound");checkpoint();return false end
  return "turn"
 end
 assert(result==false or result==nil,"invalid stage return")
 return false
end
