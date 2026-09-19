-- Supplied coastal cities, Harbor, AI cargo ship and human Privateer. The AI
-- creates a real sea route on its owner turn; the human uses normal war/plunder.
LekmodScenario={name="kilwa-sea-plunder",items={"kilwa-AI-sea-route","kilwa-sea-owner-controls","kilwa-unrelated-war-route","kilwa-sea-plunder","kilwa-sea-plunder-marker"}}
local phase,origin,target,inputID,visualID,raiderID,kind,aiError,started,baseModifier,goldBefore,expectedGold,plunderEvent="init"
local observations=0
local removalEvent
local marker=GameInfoTypes.BUILDING_KILWA_TRAIT
local function sea(plot)
 for d=0,5 do local p=Map.PlotDirection(plot:GetX(),plot:GetY(),d);if p and p:IsWater()and not p:IsLake()then return p:GetArea()end end
end
local function coastalCity(owner,near,water,label)
 local p=Players[owner];local site
 for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
  local dist=Map.PlotDistance(near:GetX(),near:GetY(),plot:GetX(),plot:GetY())
  local area=sea(plot)
  if dist>=4 and dist<=16 and area and(not water or area==water)and plot:GetOwner()==-1 and plot:GetNumUnits()==0 and p:CanFound(plot:GetX(),plot:GetY())then site=plot;break end
 end
 assert(site,"no legal coastal fixture site for "..label);p:Found(site:GetX(),site:GetY());local city=assert(site:GetPlotCity());assert(city:IsCoastal(10),"provided city lacks a navigable coast")
 LekmodScenarioEvent("fixture-setup",{operation="provided-coastal-city",label=label,owner=owner,id=city:GetID(),x=city:GetX(),y=city:GetY()})
 return city
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local cities,routes,units={},{},{}
  for c in p:Cities()do cities[c:GetID()]={marker=c:GetNumRealBuilding(marker),food_base=c:GetBaseYieldRate(YieldTypes.YIELD_FOOD),food_modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD),food_rate=c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD)}end
  for i,r in ipairs(p:GetTradeRoutes())do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,domain=r.Domain,kind=r.ConnectionType,gold=r.FromGPT,left=r.TurnsLeft}end
  for u in p:Units()do if u:IsTrade()or(owner==0 and u:GetUnitType()==GameInfoTypes.UNIT_PRIVATEER)then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end
  owners[owner]={cities=cities,routes=routes,units=units,used=p:GetNumInternationalTradeRoutesUsed(),gold=p:GetGold()}
 end
 return {turn=Game.GetGameTurn(),owners=owners,war01=Teams[0]:IsAtWar(1),war12=Teams[1]:IsAtWar(2)}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="AI-pending"then return end
 phase="AI-issued"
 local ok,err=pcall(function()
  local p=Players[1];local u=assert(p:GetUnitByID(inputID));local c=assert(Players[2]:GetCityByID(target))
  assert(not p:IsHuman()and p:IsTurnActive(),"AI mission requires real nonhuman owner turn")
  assert(u:CanMakeTradeRouteAt(u:GetPlot(),c:GetX(),c:GetY(),kind),"AI sea route lost eligibility")
  LekmodScenarioEvent("AI-sea-route-command",{owner=1,unit=inputID,kind=kind,target=target,owner_active=true})
  u:PushMission(GameInfoTypes.MISSION_ESTABLISH_TRADE_ROUTE,c:Plot():GetPlotIndex(),kind,0,0,1)
 end)
 if not ok then aiError=tostring(err)end
end)
GameEvents.TradeRouteRemoved.Add(function(owner,destination)
 if owner==1 then removalEvent={owner=owner,destination=destination,remaining=#Players[1]:GetTradeRoutes()};LekmodScenarioEvent("native-trade-route-removed",removalEvent)end
end)
GameEvents.UnitPlundered.Add(function(owner,id,x,y)
 if owner==0 and id==raiderID then plunderEvent={owner=owner,unit=id,x=x,y=y};LekmodScenarioEvent("native-sea-plunder-event",plunderEvent)end
end)
function LekmodScenario.step(player)
 assert(not aiError,aiError)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_KILWA and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires humanRome/AIKilwa/AI Rome slots0/1/2")
 local other=Players[1];local capital=player:GetCapitalCity()
 if phase=="init"and not capital then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false end end
  end end;error("no normal starting Found action")
 end
 if phase=="founding"then if not LekmodScenarioAwait("roman-capital-founded",capital~=nil)then return false end;phase="init"end
 if phase=="init"then
  assert(not Game.IsOption(GameInfoTypes.GAMEOPTION_ALWAYS_PEACE),"plunder fixture must permit war")
  local from=coastalCity(1,capital,nil,"Kilwa-sea-origin");origin=from:GetID()
  local to=coastalCity(2,from,sea(from:Plot()),"Roman-sea-destination");target=to:GetID()
  for a=0,2 do for b=a+1,2 do if not Teams[Players[a]:GetTeam()]:IsHasMet(Players[b]:GetTeam())then Teams[Players[a]:GetTeam()]:Meet(Players[b]:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="provided-contact",owner=a,other=b})end end end
  if from:GetNumBuilding(GameInfoTypes.BUILDING_HARBOR)==0 then from:SetNumRealBuilding(GameInfoTypes.BUILDING_HARBOR,1);LekmodScenarioEvent("fixture-setup",{operation="provided-Harbor",owner=1,city=origin})end
  local range=other:GetTradeRouteRange(DomainTypes.DOMAIN_SEA,from);local revealed=0
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if Map.PlotDistance(from:GetX(),from:GetY(),p:GetX(),p:GetY())<=range then
    for _,owner in ipairs({0,1})do if not p:IsRevealed(Players[owner]:GetTeam())then p:SetRevealed(Players[owner]:GetTeam(),true);revealed=revealed+1 end end
   end
  end
  LekmodScenarioEvent("fixture-setup",{operation="provided-human-AI-sea-range-reveal",range=range,plots=revealed})
  assert(other:GetNumInternationalTradeRoutesAvailable()>other:GetNumInternationalTradeRoutesUsed(),"AI has no free trade capacity")
  local u=assert(other:InitUnit(other:GetTradeUnitType(DomainTypes.DOMAIN_SEA),from:GetX(),from:GetY()));inputID=u:GetID();LekmodScenarioEvent("fixture-setup",{operation="provided-AI-cargo-ship",id=inputID})
  for _,r in ipairs(other:GetPotentialInternationalTradeRouteDestinations(u))do if r.X==to:GetX()and r.Y==to:GetY()then kind=r.TradeConnectionType;break end end
  assert(kind and u:CanMakeTradeRouteAt(u:GetPlot(),to:GetX(),to:GetY(),kind),"no legal sea route between supplied coasts")
  baseModifier=from:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD);started=Game.GetGameTurn();phase="AI-pending";return "turn"
 elseif phase=="AI-pending"or phase=="AI-issued"then
  local routes=other:GetTradeRoutes()
  if #routes==0 then assert(Game.GetGameTurn()-started<2,"AI route did not complete during ordinary owner processing");return "turn"end
  assert(#routes==1 and routes[1].Domain==DomainTypes.DOMAIN_SEA and routes[1].ToID==2 and routes[1].FromCity:GetID()==origin,"unexpected AI route")
  local c=assert(other:GetCityByID(origin));assert(c:GetNumRealBuilding(marker)==1 and c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD)==baseModifier+5,"AI sea route lacks one 5 percent food bonus")
  assert(c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD)==c:GetBaseYieldRate(YieldTypes.YIELD_FOOD)*c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD),"AI gross food differs from native modifier")
  LekmodScenarioRecord("kilwa-AI-sea-route","PASS","real AI owner-turn sea mission; marker1 and foodmodifier+5")
  for owner=0,2 do for city in Players[owner]:Cities()do if owner~=1 or city:GetID()~=origin then assert(city:GetNumRealBuilding(marker)==0,"unrelated city/owner gained Kilwa food marker")end end end
  LekmodScenarioRecord("kilwa-sea-owner-controls","PASS","other Kilwa cities and both Roman owners retain zero markers")
  for unit in other:Units()do if unit:IsTrade()and unit:GetDomainType()==DomainTypes.DOMAIN_SEA then visualID=unit:GetID();break end end
  assert(visualID,"active AI cargo visualization missing");phase="stage";return false
 elseif phase=="stage"then
  local visual=assert(other:GetUnitByID(visualID));local plot=visual:GetPlot()
  if not plot:IsWater()or plot:IsCity()or plot:GetNumUnits()>0 or(plot:GetOwner()~= -1 and plot:GetOwner()~=1)then assert(Game.GetGameTurn()-started<5,"no legal naval plunder staging position within bound");return "turn"end
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_PRIVATEER,capital:GetX(),capital:GetY()));raiderID=u:GetID();LekmodScenarioEvent("fixture-setup",{operation="provided-human-Privateer",id=raiderID})
  assert(not u:CanStartMission(GameInfoTypes.MISSION_PLUNDER_TRADE_ROUTE,-1,-1,plot,0),"peaceful foreign route is plunderable")
  expectedGold=100
  for row in GameInfo.TradeConnections_DomainYieldModifiers{TradeConnectionType=GameInfo.TradeConnections[kind].Type,DomainType="DOMAIN_SEA",YieldType="YIELD_GOLD"}do expectedGold=expectedGold+row.Modifier end
  Network.SendChangeWar(other:GetTeam(),true);phase="war";return false
 elseif phase=="war"then
  if not LekmodScenarioAwait("naval-war",Teams[player:GetTeam()]:IsAtWar(other:GetTeam()))then return false end
  assert(#other:GetTradeRoutes()==1 and other:GetCityByID(origin):GetNumRealBuilding(marker)==1,"war with human removed unrelated AI-to-AI route or bonus")
  LekmodScenarioRecord("kilwa-unrelated-war-route","PASS","AI route to third player and its food bonus preserved")
  local plot=assert(other:GetUnitByID(visualID)):GetPlot();local u=assert(player:GetUnitByID(raiderID))
  assert(plot:IsWater()and not plot:IsCity()and plot:GetNumUnits()==0,"staging plot changed")
  u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false);LekmodScenarioEvent("fixture-setup",{operation="position-Privateer",id=raiderID,x=plot:GetX(),y=plot:GetY()})
  UI.SelectUnit(u);goldBefore=player:GetGold()
  for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_PLUNDER_TRADE_ROUTE"then assert(Game.CanHandleAction(i),"normal naval plunder action unavailable");Game.HandleAction(i);phase="plundered";return false end end
  error("plunder action missing")
 elseif phase=="plundered"then
  if not LekmodScenarioAwait("sea-route-plundered",#other:GetTradeRoutes()==0)then return false end
  assert(removalEvent and removalEvent.owner==1 and removalEvent.destination==2 and removalEvent.remaining==0,"post-removal event did not observe the cleared AI route")
  assert(plunderEvent and player:GetGold()==goldBefore+expectedGold,"native plunder event or quoted gold reward missing")
  assert(not other:GetUnitByID(visualID)and other:GetNumInternationalTradeRoutesUsed()==0,"plundered cargo unit/capacity remains")
  observations=observations+1;local c=other:GetCityByID(origin)
  LekmodScenarioEvent("kilwa-sea-after-plunder",{observation=observations,gold_delta=player:GetGold()-goldBefore,expected_gold=expectedGold,state=LekmodScenario.snapshot(player)})
  if observations<3 then return false end
  LekmodScenarioRecord("kilwa-sea-plunder","PASS","real human action/native event; gold="..expectedGold.."; AI route/cargo removed")
  LekmodScenarioRecord("kilwa-sea-plunder-marker",c:GetNumRealBuilding(marker)==0 and"PASS"or"FAIL","three stable observations; marker="..c:GetNumRealBuilding(marker))
  return true
 end
 return false
end
