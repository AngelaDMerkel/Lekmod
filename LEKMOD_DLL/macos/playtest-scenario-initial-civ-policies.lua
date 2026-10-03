-- Native method surface: GameCore
-- Observe native initialization; supplied Workers and held free choices are
-- inputs. No target policy or promotion is assigned by the scenario.
LekmodScenario={name="initial-civ-policies",items={"initial-policy-owner","initial-policy-native-civilian","initial-policy-foreign-control","initial-policy-held-choice"}}
local mode=assert(LekmodScenarioParameters.civ)
local civ=GameInfoTypes[mode]
local policy=GameInfoTypes[mode=="CIVILIZATION_MAORI"and"POLICY_DUMMY_MAORI"or"POLICY_DUMMY_VIETNAM"]
local promotion=GameInfoTypes[mode=="CIVILIZATION_MAORI"and"PROMOTION_MAORI_CIVILIAN"or"PROMOTION_VIETNAM_CIVILIAN"]
local controlTag="LEKMOD_INITIAL_POLICY_CONTROL:"..mode
local phase,owners,control,workers,foreignWorker="init",nil,nil,{},nil
local function staging(p)
 local start=p:GetCapitalCity()and p:GetCapitalCity():Plot()or p:GetStartingPlot()
 if not start then return nil end
 for d=0,5 do local t=Map.PlotDirection(start:GetX(),start:GetY(),d)
  if t and not t:IsWater()and not t:IsMountain()and t:GetNumUnits()==0 then return t end
 end
end
local function roles()
 local targets,other,tagged={},nil,nil
 for id=0,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
  if p and p:IsAlive()and not p:IsBarbarian()then
   for u in p:Units()do if u:GetScriptData()==controlTag then assert(not tagged or tagged==id);tagged=id end end
   if p:GetCivilizationType()==civ then targets[#targets+1]=id
   elseif p:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_MAORI and p:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_VIETNAM and not other and staging(p)then other=id end
  end
 end
 assert(#targets>0,"target civilization absent");return targets,assert(tagged or other,"no foreign control with a legal Worker site")
end
local function create(p)
 local q=staging(p)
 assert(q,"no legal empty Worker staging tile")
 local u=assert(p:InitUnit(GameInfoTypes.UNIT_WORKER,q:GetX(),q:GetY()))
 LekmodScenarioEvent("fixture-setup",{operation="provided-Worker",owner=p:GetID(),unit=u:GetID(),x=q:GetX(),y=q:GetY()})
 return u:GetID()
end
function LekmodScenario.snapshot(player)
 local targets,other=roles();local owners={};local observed={other};for _,id in ipairs(targets)do observed[#observed+1]=id end
 for _,id in ipairs(observed)do local p=Players[id];local units={}
  for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_WORKER then units[u:GetID()]={type=u:GetUnitType(),promotion=u:IsHasPromotion(promotion),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),script=u:GetScriptData()}end end
  owners[id]={civ=p:GetCivilizationType(),policy=p:HasPolicy(policy),free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),culture=p:GetJONSCulture(),cost=p:GetNextPolicyCost(),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  owners,control=roles();assert(not Players[control]:HasPolicy(policy),"foreign owner received target policy")
  for _,owner in ipairs(owners)do local p=Players[owner]
   assert(p:HasPolicy(policy),"initialization policy missing for owner="..owner)
   assert(p:GetNextPolicyCost()>0,"initial policy history has nonpositive cost")
   workers[owner]=create(p)
  end
  LekmodScenarioRecord("initial-policy-owner","PASS","native initialization/load grants the configured policy to all matching owners, including duplicate civilizations")
  foreignWorker=create(Players[control]);Players[control]:GetUnitByID(foreignWorker):SetScriptData(controlTag)
  LekmodScenarioEvent("fixture-setup",{operation="tagged-provided-control-Worker",owner=control,unit=foreignWorker,tag=controlTag});phase="created"
 elseif phase=="created"then
  local other=assert(Players[control]:GetUnitByID(foreignWorker));assert(not other:IsHasPromotion(promotion))
  for _,owner in ipairs(owners)do local p=Players[owner];local u=assert(p:GetUnitByID(workers[owner]));assert(u:IsHasPromotion(promotion))end
  LekmodScenarioRecord("initial-policy-native-civilian","PASS","native-created Workers inherit the configured policy promotion for every matching owner")
  LekmodScenarioRecord("initial-policy-foreign-control","PASS","same unit type under unrelated civilization lacks that promotion; control owner="..control)
  for _,owner in ipairs(owners)do local p=Players[owner]
   local before={free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),culture=p:GetJONSCulture(),cost=p:GetNextPolicyCost()}
   p:SetNumFreePolicies(before.free+3)
   LekmodScenarioEvent("fixture-setup",{operation="provided-three-unspent-policy-choices",owner=owner,before=before.free,after=p:GetNumFreePolicies()})
   assert(p:GetNumFreePolicies()==before.free+3 and p:GetNumFreeTenets()==before.tenets and p:GetJONSCulture()==before.culture and p:GetNextPolicyCost()==before.cost)
  end
  LekmodScenarioRecord("initial-policy-held-choice","PASS","three additional held choices per matching owner preserve culture/tenets/positive cost; exact replay checks the real initialization hook")
  return true
 end
 return false
end
