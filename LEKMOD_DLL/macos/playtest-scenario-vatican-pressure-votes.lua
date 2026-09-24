-- Research/contact, religion founding, Temple, target city and hammers are inputs.
-- Congress formation, St Peter's production, pressure settlement and votes are outcomes.
LekmodScenario={name="vatican-pressure-votes",items={"vatican-natural-congress","stpeters-pressure-double","stpeters-extra-delegates","stpeters-pressure-control","stpeters-pressure-settlement"}}
local phase,targetID,religion,queued,built,instant,ledger="init",nil,nil,false,false,nil,nil
local building=GameInfoTypes.BUILDING_STPETERS
local function target()return assert(Players[0]:GetCityByID(targetID))end
local function measures()
 local league=assert(Game.GetActiveLeague());local t=target();local pressure,routes=t:GetPressurePerTurn(religion)
 return {pressure=pressure,routes=routes,stored=t:GetReligionPressure(religion),votes=league:CalculateStartingVotesForMember(1),human_votes=league:CalculateStartingVotesForMember(0),control=Players[0]:GetCapitalCity():GetPressurePerTurn(religion),host=league:GetHostMember()}
end
function LekmodScenario.snapshot(player)
 local own=Players[1]:GetReligionCreatedByPlayer();local cities={};local league=Game.GetActiveLeague();local votes={}
 for owner=0,3 do local p=Players[owner]
  if league then votes[owner]=league:CalculateStartingVotesForMember(owner)end
  for c in p:Cities()do cities[owner..":"..c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),majority=c:GetReligiousMajority(),pressure=own>0 and c:GetReligionPressure(own)or 0,rate=own>0 and c:GetPressurePerTurn(own)or 0,stpeters=c:GetNumRealBuilding(building)}end
 end
 return {turn=Game.GetGameTurn(),religion=own,cities=cities,league=league and{host=league:GetHostMember(),votes=votes,session=league:IsInSession(),turns=league:GetTurnsUntilSession()}or false}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="production"or queued then return end
 local p=Players[1];assert(p:IsTurnActive()and not p:IsHuman());local c=p:GetCapitalCity();assert(c:CanConstruct(building))
 instant={before=measures()};c:PushOrder(OrderTypes.ORDER_CONSTRUCT,building,-1,0,true,false,0)
 assert(c:GetProductionBuilding()==building);local cost=c:GetBuildingProductionNeeded(building);c:SetBuildingProduction(building,cost-1);queued=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-St-Peters",owner=1,city=c:GetID(),hammers=cost-1})
end)
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)
 if owner==1 and b==building then assert(not gold and not faith and queued);built=true;instant.after=measures();LekmodScenarioEvent("native-St-Peters-pressure-votes",instant)end
end)
function LekmodScenario.step(player)
 local p=Players[1];assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VATICAN)
 if phase=="init"then
  local holy=p:GetCapitalCity();LekmodScenarioGrantTech(p,"TECH_THEOLOGY");holy:SetNumRealBuilding(GameInfoTypes.BUILDING_TEMPLE,1)
  assert(not p:HasCreatedReligion());for info in GameInfo.Religions()do if info.ID>0 then religion=info.ID;break end end
  Game.FoundReligion(1,religion,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_FEED_WORLD,-1,-1,holy)
  assert(p:GetReligionCreatedByPlayer()==religion and holy:IsHolyCityForReligion(religion))
  local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(holy:GetX(),holy:GetY(),q:GetX(),q:GetY())
   if d>=8 and d<=10 and q:GetOwner()==-1 and q:GetNumUnits()==0 and player:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site,"no legal pressure target 8-10 tiles away");player:Found(site:GetX(),site:GetY());targetID=assert(site:GetPlotCity()):GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-religion-Temple-and-pressure-target",religion=religion,city=targetID,distance=Map.PlotDistance(holy:GetX(),holy:GetY(),site:GetX(),site:GetY())})
  assert(target():GetPressurePerTurn(religion)>0 and player:GetCapitalCity():GetPressurePerTurn(religion)==0,"pressure source/range controls invalid")
  LekmodScenarioGrantTech(player,"TECH_PRINTING_PRESS")
  for owner=1,3 do Teams[player:GetTeam()]:Meet(Players[owner]:GetTeam(),false)end
  LekmodScenarioEvent("fixture-setup",{operation="provided-Printing-Press-and-all-major-contacts"})
  phase="league";return "turn"
 elseif phase=="league"then
  local league=Game.GetActiveLeague();if not league then return "turn"end
  assert(league:IsMember(1)and league:IsMember(0));LekmodScenarioRecord("vatican-natural-congress","PASS","Congress formed through ordinary eligibility after supplied technology/contacts")
  phase="production";return "turn"
 elseif phase=="production"then
  if not built then return "turn"end
  local a,b=instant.after,instant.before
  assert(b.pressure>0 and a.pressure==2*b.pressure and a.routes==0 and b.routes==0,"St Peters did not double direct pressure")
  LekmodScenarioRecord("stpeters-pressure-double","PASS","native construction changed nontrade pressure "..b.pressure.." -> "..a.pressure)
  assert(a.votes==b.votes+2 and a.host==b.host and a.human_votes==b.human_votes,"delegate changes differ from +2 owner-only")
  LekmodScenarioRecord("stpeters-extra-delegates","PASS","native calculated starting delegates +2; host and human delegates unchanged")
  assert(a.control==0 and b.control==0);LekmodScenarioRecord("stpeters-pressure-control","PASS","out-of-range human capital remains at zero; no trade connection")
  ledger=measures();ledger.turn=Game.GetGameTurn();assert(target():GetReligiousMajority()~=religion,"target became majority too soon for isolated settlement")
  LekmodScenarioEvent("pressure-ledger-before",ledger);phase="settlement";return "turn"
 elseif phase=="settlement"then
  if Game.GetGameTurn()==ledger.turn then return "turn"end
  assert(Game.GetGameTurn()==ledger.turn+1,"pressure ledger skipped a full turn");local after=measures();LekmodScenarioEvent("pressure-ledger-after",after)
  assert(after.stored==ledger.stored+ledger.pressure,"ordinary pressure settlement differs from native per-turn quote")
  LekmodScenarioRecord("stpeters-pressure-settlement","PASS","stored religion pressure increased by quoted "..ledger.pressure.." over one ordinary turn")
  return true
 end
 return false
end
