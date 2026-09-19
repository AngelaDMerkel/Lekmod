-- Unit positions, damage and one embarked-state input are supplied explicitly.
-- Only the normal Repair Fleet action may heal targets and consume the Admiral.
LekmodScenario={name="admiral-repair",items={"admiral-fleet-heal","admiral-embarked-heal","admiral-owner-domain-radius-controls","admiral-consumption"}}
local phase,admiralID="init",nil
local probes={}
local function state(u)
 return {type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves(),embarked=u:IsEmbarked()}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local units={};for u in Players[owner]:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end;owners[owner]=units end
 return {turn=Game.GetGameTurn(),units=owners}
end
local function supply(owner,kind,plot,damage,label,embarked)
 local u=assert(Players[owner]:InitUnit(GameInfoTypes[kind],plot:GetX(),plot:GetY()))
 if embarked then u:SetEmbarked(true)end
 if damage>0 then u:SetDamage(damage)end
 LekmodScenarioEvent("fixture-setup",{operation="provided-unit-health-position-and-domain",owner=owner,kind=kind,label=label,id=u:GetID(),state=state(u)})
 if label then probes[label]={owner=owner,id=u:GetID()}end
 return u
end
function LekmodScenario.step(player)
 assert(player:GetID()==0 and Players[1]:IsAlive())
 if phase=="init" then
  local center,waters,land,far
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if p:IsWater() and not p:IsLake() and p:GetNumUnits()==0 and (p:GetOwner()==-1 or p:GetOwner()==0)then
    local w,l={},nil
    for d=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),d)
     if q and q:GetNumUnits()==0 and (q:GetOwner()==-1 or q:GetOwner()==0)then
      if q:IsWater() and not q:IsLake()then w[#w+1]=q
      elseif not q:IsWater() and not q:IsMountain() and not q:IsCity()then l=q end
     end
    end
    if #w>=4 and l then
     for j=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(j)
      if q:IsWater() and not q:IsLake() and q:GetNumUnits()==0 and q:GetArea()==p:GetArea() and Map.PlotDistance(p:GetX(),p:GetY(),q:GetX(),q:GetY())==2 and (q:GetOwner()==-1 or q:GetOwner()==0)then far=q;break end
     end
     if far then center,waters,land=p,w,l;break end
    end
   end
  end
  assert(center and far,"no legal coastal repair-control geometry")
  local admiral=supply(0,"UNIT_GREAT_ADMIRAL",center,0,nil);admiralID=admiral:GetID()
  local same=supply(0,"UNIT_TRIREME",center,50,"same-tile")
  supply(0,"UNIT_TRIREME",waters[1],50,"adjacent-sea")
  supply(0,"UNIT_WORKER",waters[2],50,"embarked",true)
  supply(1,"UNIT_TRIREME",waters[3],50,"foreign-sea")
  supply(0,"UNIT_TRIREME",waters[4],0,"healthy-sea")
  supply(0,"UNIT_WARRIOR",land,50,"land")
  supply(0,"UNIT_TRIREME",far,50,"distance-two")
  assert(admiral:CanRepairFleet(center) and not same:CanRepairFleet(center),"Admiral/non-Admiral eligibility differs")
  UI.SelectUnit(admiral)
  for id=0,#GameInfoActions do if GameInfoActions[id] and GameInfoActions[id].Type=="MISSION_REPAIR_FLEET"then
   assert(Game.CanHandleAction(id),"normal Repair Fleet action unavailable");Game.HandleAction(id);phase="repaired";return false
  end end
  error("Repair Fleet action missing")
 end
 local admiral=player:GetUnitByID(admiralID)
 if not LekmodScenarioAwait("Admiral-consumed",not admiral or admiral:IsDead() or admiral:IsDelayedDeath())then return false end
 for label,probe in pairs(probes)do
  local u=assert(Players[probe.owner]:GetUnitByID(probe.id));local s=state(u)
  LekmodScenarioEvent("admiral-native-repair-outcome",{label=label,owner=probe.owner,state=s})
  local healed=(label=="same-tile" or label=="adjacent-sea" or label=="embarked" or label=="healthy-sea")
  assert(s.damage==(healed and 0 or 50),"incorrect repair boundary: "..label)
 end
 if admiral then assert(not admiral:CanRepairFleet(admiral:GetPlot()),"consumed Admiral can repair again")end
 LekmodScenarioRecord("admiral-fleet-heal","PASS","normal-Repair-Fleet same-tile-and-adjacent-owned-sea damage50-to0=true")
 LekmodScenarioRecord("admiral-embarked-heal","PASS","provided-embarked-Worker damage50-to0=true")
 LekmodScenarioRecord("admiral-owner-domain-radius-controls","PASS","foreign-sea/unembarked-land/distance-two damage50-preserved healthy-sea=0")
 LekmodScenarioRecord("admiral-consumption","PASS","Admiral-consumed non-Admiral-action-ineligible=true")
 return true
end
