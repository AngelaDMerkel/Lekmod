-- Isolated checks for the scenario supervisor; no Civ V process is started.
assert(loadfile(arg[1]))()
local logs, updates, calls = {}, 0, 0
local active, processing, human = true, false, true
local turn=111
local player={IsTurnActive=function() return active end, IsHuman=function() return human end}
Game={GetActivePlayer=function() return 0 end, GetAIAutoPlay=function() return 0 end,
    GetGameTurn=function() return turn end, IsProcessingMessages=function() return processing end}
Players={[0]=player}
ContextPtr={SetUpdate=function(self,fn) self.update=fn end}
Events={SequenceGameInitComplete={Add=function(fn) Events.ready=fn end}}
LuaEvents={LekmodFunctionalSave=function() error("unexpected save") end}
OnSoftPromptUpdate=function() updates=updates+1 end
local originalPrint=print
print=function(line) logs[#logs+1]=line end
local function has(marker)
    for _,line in ipairs(logs) do if string.find(line,marker,1,true) then return true end end
    return false
end
LekmodScenario={name="test",items={"action"},snapshot=function() return {city="New York", value=42} end,
    step=function() calls=calls+1; return calls==2 end}
__TEST_EXPECTED_STATE__=nil
__TEST_SAVE_NAME__=nil
LekmodScenarioStart()
ContextPtr.update(2)
assert(calls==0, "scenario ran before initialization")
Events.ready()
processing=true; ContextPtr.update(2)
assert(calls==0, "scenario ran during message processing")
processing=false; active=false; ContextPtr.update(2)
assert(calls==0, "scenario ran outside the active human turn")
active=true; ContextPtr.update(2)
assert(calls==1 and not has("event=complete"), "scenario completed prematurely")
ContextPtr.update(2); ContextPtr.update(2)
assert(calls==2 and has("event=complete"), "completion did not stop the scenario")
assert(updates==6, "normal HUD updates were not retained")

logs={}
__TEST_EXPECTED_STATE__=LekmodScenarioJSON(LekmodScenario.snapshot())
LekmodScenario.step=function() error("reload must not repeat gameplay actions") end
LekmodScenarioStart(); Events.ready(); ContextPtr.update(2)
assert(has("item=save-reload status=PASS") and has("event=complete"), "reload state was not checked")
assert(not has("item=action status=PASS"), "reload falsely certified an action")

logs={}
__TEST_EXPECTED_STATE__="different"
LekmodScenarioStart(); Events.ready(); ContextPtr.update(2)
assert(has("status=FAIL") and not has("event=complete"), "state mismatch passed")
local encoded=LekmodScenarioJSON({city="New York",message='quote" newline\n', value=42})
assert(encoded=='{"city":"New York","message":"quote\\u0022 newline\\u000a","value":42}', "snapshot escaping/order changed")
assert(not LekmodScenarioAwait("delayed",false), "unapplied callback result passed")
assert(LekmodScenarioAwait("delayed",true), "applied callback result not recognized")
for i=1,8 do assert(not LekmodScenarioAwait("missing",false)) end
assert(not pcall(function() LekmodScenarioAwait("missing",false) end), "missing result waited without a bound")
logs={}
__TEST_EXPECTED_STATE__=nil
__TEST_SCENARIO_TURN_LIMIT__=1
local driven=0
LekmodScenarioHumanTurn=function() driven=driven+1 end
LekmodScenario.step=function() return "turn" end
LekmodScenarioStart(); Events.ready(); ContextPtr.update(2)
assert(driven==1 and not has("event=complete"), "turn request was treated as completion")
turn=112; ContextPtr.update(2)
assert(driven==1 and has("status=FAIL"), "scenario advanced past its turn bound")
originalPrint("Scenario core: readiness, message/turn guards, completion, HUD preservation, reload, mismatch and JSON checks passed")
