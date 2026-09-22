-- The fallout and pillage are retained outcomes of the earlier real nuclear
-- mission. A worker and removal technology are supplied; surviving blast enemies are staged
-- away from the work site. Cleanup/repair are earned.
LekmodScenario={name="nuclear-cleanup",items={"nuclear-cleanup-restrictions","nuclear-fallout-cleanup","nuclear-farm-repair"}}
local phase,plotID,workerID,started="init",nil,nil,nil
local scrub=GameInfoTypes.BUILD_SCRUB_FALLOUT
local function action(u,kind)
 UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type==kind then assert(Game.CanHandleAction(i),"action unavailable: "..kind);Game.HandleAction(i);return end end;error("action missing: "..kind)
end
function LekmodScenario.snapshot(player)
 local plots,units={},{}
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetFeatureType()==GameInfoTypes.FEATURE_FALLOUT or p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM then plots[i]={feature=p:GetFeatureType(),improvement=p:GetImprovementType(),pillaged=p:IsImprovementPillaged(),food=p:CalculateYield(YieldTypes.YIELD_FOOD,true)}end
 end
 for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_WORKER then units[u:GetID()]={x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage()}end end
 return {turn=Game.GetGameTurn(),plots=plots,workers=units}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local p
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetFeatureType()==GameInfoTypes.FEATURE_FALLOUT and q:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM and q:IsImprovementPillaged()and q:GetNumUnits()==0 then p=q;plotID=i;break end
  end
  assert(p,"requires saved real blast fallout/pillaged farm")
  -- The blast fixture intentionally retains an immune GDR and an outside-radius
  -- barbarian. Keep their AI turns real, but stage them beyond the work site.
  for enemy in Players[GameDefines.BARBARIAN_PLAYER]:Units()do
   if Map.PlotDistance(p:GetX(),p:GetY(),enemy:GetX(),enemy:GetY())<12 then
    local target
    for j=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(j)
     if not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetOwner()==-1 and q:GetNumUnits()==0 and Map.PlotDistance(p:GetX(),p:GetY(),q:GetX(),q:GetY())>=25 then target=q;break end
    end
    assert(target,"no distant staging tile for surviving blast enemy")
    local before={x=enemy:GetX(),y=enemy:GetY()};enemy:SetXY(target:GetX(),target:GetY(),false,true,false,false)
    assert(enemy:GetX()==target:GetX()and enemy:GetY()==target:GetY())
    LekmodScenarioEvent("fixture-setup",{operation="stage-surviving-enemy-away-from-worker",id=enemy:GetID(),before=before,x=enemy:GetX(),y=enemy:GetY()})
   end
  end
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_WORKER,p:GetX(),p:GetY()));workerID=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-cleanup-worker",id=workerID,plot=plotID})
  -- Technology may live on the feature-removal row rather than Builds.
  for row in GameInfo.BuildFeatures{BuildType="BUILD_SCRUB_FALLOUT"}do if row.PrereqTech then LekmodScenarioGrantTech(player,row.PrereqTech)end end
  if GameInfo.Builds[scrub].PrereqTech then LekmodScenarioGrantTech(player,GameInfo.Builds[scrub].PrereqTech)end
  assert(u:CanBuild(p,scrub),"fallout removal not eligible")
  assert(not u:CanBuild(player:GetCapitalCity():Plot(),scrub),"scrub allowed on clean capital")
  LekmodScenarioRecord("nuclear-cleanup-restrictions","PASS","native scrub allowed on actual fallout; rejected on clean city")
  action(u,"BUILD_SCRUB_FALLOUT");started=Game.GetGameTurn();phase="cleaning";return "turn"
 elseif phase=="cleaning"then
  local p=Map.GetPlotByIndex(plotID)
  if p:GetFeatureType()==GameInfoTypes.FEATURE_FALLOUT then assert(Game.GetGameTurn()-started<10,"scrub exceeded bounded turns");return "turn"end
  assert(p:GetFeatureType()==-1 and p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM and p:IsImprovementPillaged(),"cleanup altered farm/pillage unexpectedly")
  local u=assert(player:GetUnitByID(workerID),"cleanup worker disappeared during real AI turn");assert(not u:CanBuild(p,scrub),"repeat fallout removal eligible")
  LekmodScenarioRecord("nuclear-fallout-cleanup","PASS","normal worker action/turns removed native fallout; pillaged farm retained; repeat scrub rejected")
  phase="repair-order"
 elseif phase=="repair-order"then
  local u=assert(player:GetUnitByID(workerID),"cleanup worker disappeared during real AI turn");if u:GetMoves()<=0 then return "turn"end
  assert(u:CanBuild(Map.GetPlotByIndex(plotID),GameInfoTypes.BUILD_REPAIR),"surviving worker cannot repair blast-pillaged farm");action(u,"BUILD_REPAIR");phase="repair";return "turn"
 elseif phase=="repair"then
  local p=Map.GetPlotByIndex(plotID);if p:IsImprovementPillaged()then return "turn"end
  assert(p:GetFeatureType()==-1 and p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM)
  LekmodScenarioRecord("nuclear-farm-repair","PASS","normal worker repair restored blast-pillaged farm; fallout remains absent; food="..p:CalculateYield(YieldTypes.YIELD_FOOD,true))
  return true
 end
 return false
end
