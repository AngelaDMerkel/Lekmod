-- Normally selected later-era start, with two supplied land probes. The
-- opening window is measured in elapsed game turns, not the calendar counter.
LekmodScenario={name="maori-era",items={"maori-later-era-opening-window","maori-later-era-expiry"}}
local probes,observed={},{}
local function state(u)
 return {type=u:GetUnitType(),created=u:GetGameTurnCreated(),moves=u:GetMoves(),maximum=u:MaxMoves(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),x=u:GetX(),y=u:GetY()}
end
function LekmodScenario.snapshot(player)
 local units={};for u in player:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),units=units}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI)
 local elapsed=Game.GetElapsedGameTurns();assert(elapsed<=5,"opening-window test exceeded five ordinary turns")
 if #probes==0 then
  assert(elapsed==0 and Game.GetGameTurn()>5,"requires a new normally selected later-era start")
  local start=assert(player:GetStartingPlot())
  for _,kind in ipairs({"UNIT_WARRIOR","UNIT_WORKER"})do
   local plot
   for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
    if p:GetNumUnits()==0 and not p:IsWater() and not p:IsMountain() and p:GetArea()==start:GetArea() and (p:GetOwner()==-1 or p:GetOwner()==player:GetID()) and Map.PlotDistance(start:GetX(),start:GetY(),p:GetX(),p:GetY())<=2 then plot=p;break end
   end
   assert(plot,"no legal probe placement")
   local info=GameInfo.Units[kind];local u=assert(player:InitUnit(info.ID,plot:GetX(),plot:GetY()))
   probes[#probes+1]={id=u:GetID(),moves=info.Moves*GameDefines.MOVE_DENOMINATOR,sight=info.BaseSightRange}
   LekmodScenarioEvent("fixture-setup",{operation="provided-later-era-probe",kind=kind,state=state(u),turn=Game.GetGameTurn(),elapsed=elapsed})
  end
  player:ChangeGold(1000);LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-gold",owner=player:GetID(),amount=1000})
 end
 local wrong=0
 for _,probe in ipairs(probes)do
  local s=state(assert(player:GetUnitByID(probe.id)));local bonus=elapsed<5
  LekmodScenarioEvent("maori-era-probe-state",{turn=Game.GetGameTurn(),elapsed=elapsed,state=s})
  if (s.maori or s.civilian)~=bonus or s.maximum~=probe.moves+(bonus and 120 or 0) or s.sight~=probe.sight+(bonus and 1 or 0)then wrong=wrong+1 end
  if elapsed==5 and s.moves>probe.moves then wrong=wrong+1 end
 end
 if wrong>0 then
  LekmodScenarioRecord("maori-later-era-opening-window","FAIL","calendar-turn="..Game.GetGameTurn().." elapsed="..elapsed.." incorrect-probes="..wrong)
  return true
 end
 observed[elapsed]=true
 if elapsed<5 then return "turn" end
 for t=0,4 do assert(observed[t],"opening observation missing elapsed "..t)end
 LekmodScenarioRecord("maori-later-era-opening-window","PASS","normal-later-era-start bonus-preserved-elapsed=0,1,2,3,4")
 LekmodScenarioRecord("maori-later-era-expiry","PASS","normal-elapsed-turn-five promotions-and-extra-budget-cleared=true")
 return true
end
