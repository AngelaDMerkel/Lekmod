-- Native method surface: GameCore
-- Research/resources, upkeep and cost-minus-one hammers are supplied inputs.
-- Human/AI production remains unforced on real owner turns. Read-only observers
-- bracket the product handler so ordinary turn income cannot mimic its reward.
LekmodScenario={name="uae-wonder-rewards",items={"uae-nonwonder-control","uae-first-wonder-reward","uae-second-wonder-stack","uae-foreign-wonder-control","uae-native-production-events","uae-wonder-save-state"}}
local phase,ordinal,target,queued,observed,started,completed="init",1,nil,false,nil,nil,0
local kinds={"BUILDING_EIFFEL_TOWER","BUILDING_CRISTO_REDENTOR","BUILDING_GREAT_FIREWALL"}
local function choose(p,wonder)
 local c=assert(p:GetCapitalCity())
 if wonder then
  for _,kind in ipairs(kinds)do local info=assert(GameInfo.Buildings[kind]);assert(GameInfo.BuildingClasses[info.BuildingClass].MaxGlobalInstances==1)
   LekmodScenarioGrantTech(p,info.PrereqTech)
   if c:CanConstruct(info.ID)then return info end
  end
 else
  for info in GameInfo.Buildings()do
   if info.Cost>0 and GameInfo.BuildingClasses[info.BuildingClass].MaxGlobalInstances~=1 and (info.FreeTechs or 0)==0 and (info.FreePolicies or 0)==0 and c:CanConstruct(info.ID)then return info end
  end
 end
 error("no legal "..(wonder and"world wonder"or"ordinary building").." for owner"..p:GetID())
end
local function near(c)
 local cost=c:GetBuildingProductionNeeded(target.building);assert(cost>1);c:SetBuildingProduction(target.building,cost-1);queued=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-building",owner=target.owner,city=c:GetID(),building=target.kind,cost=cost,hammers=cost-1,force=false})
end
LuaEvents.LekmodUaeWonderObserved.Add(function(owner,city,building,gold,faith,goldBefore,goldAfter,kingBefore,kingAfter)
 if not target or owner~=target.owner or city~=target.city or building~=target.building then return end
 assert(queued and not observed and not gold and not faith,"target must be produced once, not purchased")
 observed={owner=owner,city=city,building=building,gold_before=goldBefore,gold_after=goldAfter,king_before=kingBefore,king_after=kingAfter}
 LekmodScenarioEvent("native-UAE-construction-reward",observed)
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="produce"or not target or target.owner~=owner or owner==0 or queued then return end
 local p=Players[owner];local c=assert(p:GetCityByID(target.city));assert(p:IsTurnActive()and not p:IsHuman()and c:CanConstruct(target.building))
 c:PushOrder(OrderTypes.ORDER_CONSTRUCT,target.building,-1,0,true,false,0);assert(c:GetProductionBuilding()==target.building);near(c)
end)
function LekmodScenario.snapshot(p)
 local owners={}
 for owner=0,1 do local q=Players[owner];local cities={}
  for c in q:Cities()do local buildings={};for b in GameInfo.Buildings()do local n=c:GetNumRealBuilding(b.ID);if n>0 then buildings[b.ID]=n end end
   cities[c:GetID()]={x=c:GetX(),y=c:GetY(),king=c:GetWeLoveTheKingDayCounter(),buildings=buildings}
  end
  owners[owner]={gold=q:GetGold(),civ=q:GetCivilizationType(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_UAE and Players[1]:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_UAE)
 if not p:GetCapitalCity()or not Players[1]:GetCapitalCity()then return "turn"end
 if phase=="init"then
  for owner=0,1 do local q=Players[owner];q:ChangeGold(10000);q:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_COAL,5);LekmodScenarioGrantTech(q,"TECH_INDUSTRIALIZATION")end
  phase="choose"
 elseif phase=="choose"then
  local owner=ordinal==4 and 1 or 0;local q=Players[owner];local c=q:GetCapitalCity();local info=choose(q,ordinal~=1)
  target={owner=owner,city=c:GetID(),building=info.ID,kind=info.Type};observed=nil;queued=false;started=Game.GetGameTurn()
  if owner==0 then Game.CityPushOrder(c,OrderTypes.ORDER_CONSTRUCT,info.ID,false,true,true);phase="human-queued"
  else phase="produce";return "turn"end
 elseif phase=="human-queued"then
  local c=assert(p:GetCityByID(target.city));if not LekmodScenarioAwait("UAE-building-order",c:GetProductionBuilding()==target.building)then return false end
  near(c);phase="produce";return "turn"
 elseif phase=="produce"then
  if not observed then assert(Game.GetGameTurn()-started<3,"building production exceeded bounded ordinary turns");return "turn"end
  local c=assert(Players[target.owner]:GetCityByID(target.city));assert(c:GetNumRealBuilding(target.building)==1)
  local rewarded=ordinal==2 or ordinal==3;local gold=rewarded and 100 or 0;local king=rewarded and 15 or 0
  assert(observed.gold_after-observed.gold_before==gold and observed.king_after-observed.king_before==king,"event-time UAE reward differs")
  if ordinal==1 then LekmodScenarioRecord("uae-nonwonder-control","PASS","ordinary human building produces zero trait gold/celebration")
  elseif ordinal==2 then LekmodScenarioRecord("uae-first-wonder-reward","PASS","normal human world-wonder production adds exactly100 gold and15 celebration turns")
  elseif ordinal==3 then assert(observed.king_before>0);LekmodScenarioRecord("uae-second-wonder-stack","PASS","second world wonder adds another100 gold and15 turns to the existing celebration")
  else LekmodScenarioRecord("uae-foreign-wonder-control","PASS","normal Roman AI world-wonder production adds neither UAE reward")end
  completed=completed+1;ordinal=ordinal+1
  if ordinal<=4 then phase="choose"else
   assert(completed==4);LekmodScenarioRecord("uae-native-production-events","PASS","four genuine non-purchase CityConstructed events from normal human and AI queues")
   LekmodScenarioRecord("uae-wonder-save-state","PASS","actual building counts, treasury and celebration counters retained for exact replay");return true
  end
 end
 return false
end
