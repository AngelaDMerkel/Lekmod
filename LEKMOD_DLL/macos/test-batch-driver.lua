-- Execute the real dispatcher with event, game, save and load stand-ins.
local root=assert(arg[1]);local function source(name)local f=assert(io.open(root..'/'..name));local t=f:read('*a');f:close();return t end
local function fixture(code,maxTurns,mode,expected)
 local e=setmetatable({},{__index=_G});e._G=e;e.logs={};e.saved={};e.loads={};e.turn=0;e.callbacks={};e.control={run='test',command=0,index=1,mode=mode or'run',expected=expected}
 e.print=function(t)e.logs[#e.logs+1]=t end
 e.setfenv=false;e.loadstring=function(text,name)local chunk,err=loadstring(text,name);if chunk then setfenv(chunk,e)end;return chunk,err end
 local p={};e.Players={[0]=p};e.Game={GetGameTurn=function()return e.turn end,GetActivePlayer=function()return 0 end,IsGameMultiPlayer=function()return false end}
 local function event(name)
  local handlers={};e.callbacks[name]=handlers
  return setmetatable({Add=function(fn)handlers[#handlers+1]=fn end,Remove=function(fn)for i=#handlers,1,-1 do if handlers[i]==fn then table.remove(handlers,i)end end end},{__call=function(_,...)for _,fn in ipairs(handlers)do fn(...)end end})
 end
 local function events()return setmetatable({},{__index=function(t,k)local v=event(k);rawset(t,k,v);return v end})end
 e.GameEvents=events();e.LuaEvents=events();e.Events=events()
 e.Events.PlayerChoseToLoadGame.Add(function(path)e.loads[#e.loads+1]=path end)
 e.LuaEvents.LekmodFunctionalSave.Add(function(name)e.saved[#e.saved+1]=name end)
 e.LuaEvents.LekmodFunctionalExit.Add(function()e.exited=true end)
 e.UIManager={SetUICursor=function()end}
 e.include=function(name)
  if name=='LekmodBatchPlan.lua'then e.LekmodBatchPlan={stages={{id='case',scenario='mock',items={'ok'},max_turns=maxTurns or 0,code=code}}}
  elseif name=='LekmodBatchControl.lua'then e.LekmodBatchControl=e.control
  else error(name)end
 end
 local core=assert(loadstring(source('playtest-scenario-core.lua'):gsub('__TEST_SCENARIO_TURN_LIMIT__','30'):gsub('__TEST_EXPECTED_STATE__','nil'):gsub('__TEST_SAVE_NAME__','nil'):gsub('__TEST_RUN__','test')));setfenv(core,e);core()
 local driver=assert(loadstring(source('playtest-scenario-batch.lua'):gsub('__TEST_RUN__','test')));setfenv(driver,e);driver()
 function e:step()return self.LekmodScenario.step(p)end
 function e:has(text)return table.concat(self.logs,'\n'):find(text,1,true)~=nil end
 return e
end
local passed=0
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));passed=passed+1;print('PASS '..name)end
local success='LekmodScenario={snapshot=function()return {turn=Game.GetGameTurn()}end,step=function()LekmodScenarioRecord("ok","PASS");return true end}'
test('success checkpoints without exiting',function()local e=fixture(success);e:step();assert(#e.saved==1 and not e.exited and e:has('case::ok status=PASS'));e:step();assert(#e.saved==1)end)
test('callback lifecycle removes completed stage handlers',function()
 local e=fixture('GameEvents.PlayerDoTurn.Add(function()error("stale callback ran")end)\n'..success);e:step();assert(#e.callbacks.PlayerDoTurn==0);e.GameEvents.PlayerDoTurn(0);assert(not e:has('status=FAIL'))
end)
test('fail then pass remains failed',function()
 local e=fixture(success:gsub('LekmodScenarioRecord%("ok","PASS"%)','LekmodScenarioRecord("ok","FAIL");LekmodScenarioRecord("ok","PASS")'));e:step();assert(e:has('"failed":true')and #e.saved==1)
end)
test('driver exception becomes saved failed stage',function()local e=fixture(success:gsub('return true end','error("driver bug")end'));e:step();assert(e:has('case::driver status=FAIL')and#e.saved==1)end)
test('snapshot exception does not block failure evidence',function()local e=fixture('LekmodScenario={snapshot=function()error("snapshot bug")end,step=function()LekmodScenarioRecord("ok","PASS");return true end}');e:step();assert(e:has('case::snapshot status=FAIL')and#e.saved==1)end)
test('missing assertion cannot pass',function()local e=fixture(success:gsub('LekmodScenarioRecord%("ok","PASS"%);',''));e:step();assert(e:has('case::ok status=FAIL'))end)
test('turn bound is enforced',function()local e=fixture(success:gsub('return true end','return "turn" end'),0);e:step();assert(e:has('case::turn-bound status=FAIL')and#e.saved==1)end)
test('reload compares exact snapshot before any action',function()local e=fixture(success,0,'reload','{"turn":0}');e:step();assert(e:has('case::save-reload status=PASS')and not e:has('case::ok'))end)
test('reload mismatch fails',function()local e=fixture(success,0,'reload','{"turn":1}');e:step();assert(e:has('case::driver status=FAIL'))end)
test('host cannot load before save callback returns',function()
 local e=fixture(success);e:step();e.control={run='test',command=1,index=1,mode='reload',path='checkpoint'};local ok=pcall(function()e:step()end);assert(not ok and #e.loads==0)
end)
test('acknowledged checkpoint uses one normal load event',function()
 local e=fixture(success);e:step();e.LuaEvents.LekmodBatchSaved(e.saved[1]);e.control={run='test',command=1,index=1,mode='reload',path='checkpoint'};e:step();e:step();assert(#e.loads==1 and e.loads[1]=='checkpoint')
end)
test('stage exports do not replace dispatcher globals',function()local e=fixture(success);e:step();assert(e.LekmodScenario.name=='batch')end)
test('callback exception is a saved failure',function()
 local e=fixture('GameEvents.PlayerDoTurn.Add(function()error("callback bug")end)\nLekmodScenario={snapshot=function()return{}end,step=function()return false end}')
 e:step();e.GameEvents.PlayerDoTurn(0);e:step();assert(e:has('case::callback status=FAIL')and#e.saved==1 and#e.callbacks.PlayerDoTurn==0)
end)
test('setup exception still produces failure checkpoint',function()local e=fixture('error("setup bug")');e:step();assert(e:has('case::setup status=FAIL')and#e.saved==1)end)
test('multiplayer is rejected without saving or loading',function()local e=fixture(success);e.Game.IsGameMultiPlayer=function()return true end;assert(not pcall(function()e:step()end)and#e.saved==0 and#e.loads==0)end)
test('separate UI assertion contributes to current stage',function()
 local e=fixture('local first=true;LekmodScenario={snapshot=function()return{}end,step=function()if first then first=false;return false end;return true end}')
 e:step();e.LuaEvents.LekmodBatchAssertion('ok','PASS','popup callback');e:step()
 assert(e:has('case::ok status=PASS')and not e:has('status=FAIL'))
 local n=#e.logs;e.LuaEvents.LekmodBatchAssertion('late','FAIL','stale');assert(#e.logs==n)
end)
test('UI failure cannot be erased by a later UI pass',function()
 local e=fixture('local first=true;LekmodScenario={snapshot=function()return{}end,step=function()if first then first=false;return false end;return true end}')
 e:step();e.LuaEvents.LekmodBatchAssertion('ok','FAIL','popup failure');e.LuaEvents.LekmodBatchAssertion('ok','PASS','later');e:step();assert(e:has('"failed":true'))
end)
test('late stage observes before and after the actual owner handler',function()
 local code='local before,after;LuaEvents.LekmodNZBeforeOwnerTurn.Add(function()before=Players[0].value end);LuaEvents.LekmodNZAfterOwnerTurn.Add(function()after=Players[0].value end);LekmodScenario={snapshot=function()return{}end,step=function()if after==nil then return false end;assert(before==0 and after==1);LekmodScenarioRecord("ok","PASS");return true end}'
 local e=fixture(code);e.Players[0].value=0
 local pre=assert(loadstring(source('playtest-nz-owner-before-observer.lua')));setfenv(pre,e);pre()
 e.GameEvents.PlayerDoTurn.Add(function()e.Players[0].value=e.Players[0].value+1 end)
 local post=assert(loadstring(source('playtest-nz-owner-observer.lua')));setfenv(post,e);post()
 e:step();e.GameEvents.PlayerDoTurn(0);e:step()
 assert(e:has('case::ok status=PASS')and not e:has('status=FAIL'))
 assert(#e.callbacks.LekmodNZBeforeOwnerTurn==0 and #e.callbacks.LekmodNZAfterOwnerTurn==0)
end)
print(passed..' batch dispatcher cases passed')
