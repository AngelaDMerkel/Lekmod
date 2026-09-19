-- Supply one Zabonah under a non-Nabataean owner, then use the real delete
-- action/confirmation. Normal off-map removal must not cause a Lua error.
LekmodScenario={name="nabatea-disband",items={"zabonah-disband"}}
local phase,id,gold,refund,confirmation="init"
LuaEvents.LekmodUnitCommandConfirmed.Add(function(kind,unit,choice)confirmation={kind=kind,id=unit,choice=choice}end)
function LekmodScenario.snapshot(player)
 local units={};for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_MC_ZABONAH and not u:IsDelayedDeath()then units[u:GetID()]={x=u:GetX(),y=u:GetY()}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),zabonahs=units}
end
function LekmodScenario.step(player)
 local city=player:GetCapitalCity()
 if phase=="init"and not city then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false end end
  end end;error("no normal initial Found action")
 end
 if phase=="founding"then if not LekmodScenarioAwait("roman-capital-founded",city~=nil)then return false end;phase="init"end
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"Roman owner verifies unique-unit handler without Nabatea active")
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_MC_ZABONAH,city:GetX(),city:GetY()));id=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-Zabonah",owner=player:GetID(),id=id})
  assert(u:CanScrap(),"normal disband unavailable");gold=player:GetGold();refund=u:GetScrapGold();UI.SelectUnit(u)
  LuaEvents.LekmodConfirmUnitAction("COMMAND_DELETE",id,"yes")
  for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="COMMAND_DELETE"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="deleted";return false end end
  error("delete action missing")
 end
 local u=player:GetUnitByID(id)
 if not LekmodScenarioAwait("Zabonah-removed",u==nil)then return false end
 assert(confirmation and confirmation.id==id and confirmation.choice=="yes"and player:GetGold()==gold+refund,"normal confirmation/refund missing")
 LekmodScenarioRecord("zabonah-disband","PASS","normal action/confirmation removed unit; refund="..refund.."; runner must also report no Lua errors")
 return true
end
