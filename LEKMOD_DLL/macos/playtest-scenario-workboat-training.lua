-- Native method surface: GameCore
-- Legal cities, research, upkeep and cost-minus-one production are inputs.
-- The AI must finish a normal unforced production queue; no boat is initialized.
LekmodScenario={name="workboat-training",items={"workboat-tech-gate","workboat-human-AI-gate","workboat-inland-control","workboat-other-unit-control","workboat-native-production","workboat-native-continuation"}}
local phase,cityIDs,queued,trained,err="init",{},false,nil,nil
local birth,loss=nil,nil
local built,beforeWater={},{}
local boat=GameInfoTypes.UNIT_WORKBOAT
local function city(p,coastal)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:IsCoastalLand(10)==coastal and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity())
   LekmodScenarioEvent("fixture-setup",{operation="provided-legal-production-city",owner=p:GetID(),city=c:GetID(),coastal=coastal,x=q:GetX(),y=q:GetY()});return c:GetID()
  end
 end
 error("no legal city site for coast="..tostring(coastal))
end
GameEvents.CityTrained.Add(function(owner,cityID,id,gold,faith)
 if owner==1 and cityIDs[1]and cityID==cityIDs[1].coast then local u=Players[owner]:GetUnitByID(id)
  if u and u:GetUnitType()==boat then assert(queued and not trained and not gold and not faith);trained=id;birth={owner=u:GetOwner(),type=u:GetUnitType(),domain=u:GetDomainType(),x=u:GetX(),y=u:GetY()};assert(birth.owner==1 and birth.type==boat and birth.domain==DomainTypes.DOMAIN_SEA);LekmodScenarioEvent("native-workboat-produced",{owner=owner,city=cityID,unit=id,state=birth})end
 end
end)
GameEvents.UnitPrekill.Add(function(owner,id,kind,x,y,delay,killer)
 if owner==1 and id==trained then assert(kind==boat);loss={x=x,y=y,killer=killer};LekmodScenarioEvent("native-produced-workboat-prekill",loss)end
end)
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
 if owner==1 then built[x..":"..y]=improvement;LekmodScenarioEvent("native-AI-build",{owner=owner,x=x,y=y,improvement=improvement})end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="produce"or queued then return end
 local ok,e=pcall(function()
  local p=Players[1];assert(p:IsTurnActive()and not p:IsHuman());local c=assert(p:GetCityByID(cityIDs[1].coast));p:ChangeGold(1000)
  assert(c:CanTrain(boat));c:PushOrder(OrderTypes.ORDER_TRAIN,boat,-1,0,true,false,0);assert(c:GetProductionUnit()==boat)
  local cost=c:GetUnitProductionNeeded(boat);assert(cost>1);c:SetUnitProduction(boat,cost-1);queued=true
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-workboat",owner=1,city=c:GetID(),cost=cost,production=cost-1,force=false})
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner];local cities,units,water={},{},{}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),boat_eligible=c:CanTrain(boat),production=c:GetProductionUnit(),hammers=c:GetProduction()}end
  for u in p:Units()do if u:GetUnitType()==boat then units[u:GetID()]={owner=u:GetOwner(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),domain=u:GetDomainType()}end end
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:IsWater()and q:GetOwner()==owner and q:GetImprovementType()~=-1 then water[i]={x=q:GetX(),y=q:GetY(),improvement=q:GetImprovementType(),resource=q:GetResourceType(-1),pillaged=q:IsImprovementPillaged()}end
  end
  owners[owner]={water_improvements=water,human=p:IsHuman(),sailing=Teams[p:GetTeam()]:IsHasTech(GameInfoTypes.TECH_SAILING),cities=cities,boats=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not err,err);assert(p:GetID()==0 and p:IsHuman()and not Players[1]:IsHuman())
 if phase=="init"then
  for owner=0,1 do local q=Players[owner]
   assert(not Teams[q:GetTeam()]:IsHasTech(GameInfoTypes.TECH_SAILING),"starting fixture already has Sailing")
   cityIDs[owner]={coast=city(q,true),inland=city(q,false)}
   assert(not q:GetCityByID(cityIDs[owner].coast):CanTrain(boat))
  end
  LekmodScenarioRecord("workboat-tech-gate","PASS","both owners reject Workboat before Sailing")
  for owner=0,1 do LekmodScenarioGrantTech(Players[owner],"TECH_SAILING")end
  assert(not p:GetCityByID(cityIDs[0].coast):CanTrain(boat)and Players[1]:GetCityByID(cityIDs[1].coast):CanTrain(boat))
  LekmodScenarioRecord("workboat-human-AI-gate","PASS","same coastal/research prerequisites: human rejected, AI allowed")
  for owner=0,1 do assert(not Players[owner]:GetCityByID(cityIDs[owner].inland):CanTrain(boat))end
  LekmodScenarioRecord("workboat-inland-control","PASS","inland location still rejects the sea unit")
  assert(p:GetCityByID(cityIDs[0].inland):CanTrain(GameInfoTypes.UNIT_WARRIOR))
  LekmodScenarioRecord("workboat-other-unit-control","PASS","ordinary human Warrior remains eligible")
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:IsWater()then beforeWater[q:GetX()..":"..q:GetY()]=q:GetImprovementType()end end
  phase="produce";return "turn"
 elseif phase=="produce"then
  if not trained then return "turn"end
  assert(birth and birth.owner==1 and birth.type==boat and birth.domain==DomainTypes.DOMAIN_SEA)
  local u=Players[1]:GetUnitByID(trained)
  if u and not u:IsDead()and not u:IsDelayedDeath()then
   assert(u:GetUnitType()==boat and u:GetOwner()==1 and u:GetDomainType()==DomainTypes.DOMAIN_SEA)
   LekmodScenarioRecord("workboat-native-continuation","PASS","produced AI boat survives; exact replay records unit state")
  else
   assert(loss and loss.killer==-1,"produced boat disappeared without a noncombat prekill")
   local q=assert(Map.GetPlot(loss.x,loss.y));local key=loss.x..":"..loss.y;local fishing=GameInfoTypes.IMPROVEMENT_FISHING_BOATS
   assert(beforeWater[key]~=fishing and built[key]==fishing and q:GetImprovementType()==fishing and q:GetOwner()==1 and not q:IsImprovementPillaged(),"missing matched native Fishing Boats construction/consumption")
   LekmodScenarioRecord("workboat-native-continuation","PASS","AI naturally consumed the produced boat in a matching BuildFinished Fishing Boats action; exact replay records the improvement")
  end
  assert(not p:GetCityByID(cityIDs[0].coast):CanTrain(boat))
  LekmodScenarioRecord("workboat-native-production","PASS","actual AI owner-turn unforced queue, native non-purchase CityTrained and correct birth identity/domain; human remains blocked")
  return true
 end
 return false
end
