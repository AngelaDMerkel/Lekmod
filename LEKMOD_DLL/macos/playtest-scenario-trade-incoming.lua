-- Supplies one legal AI city, range reveal/building and two caravans. Routes
-- execute during the AI's real turn; no route or yield outcome is assigned.
LekmodScenario={name="trade-incoming",items={"incoming-route-creation","incoming-route-identity","incoming-route-accounting","incoming-route-tooltip","incoming-route-tourism"}}
local phase,origin,started,aiError="init"
local requests={}
local function packRoutes(rows)
 local result={}
 for i,r in ipairs(rows)do
  local row={}
  for k,v in pairs(r)do row[k]=(k=="FromCity" or k=="ToCity")and v:GetID()or v end
  result[i]=row
 end
 return result
end
function LekmodScenario.snapshot(player)
 local cities={}
 for c in player:Cities()do cities[c:GetID()]={name=c:GetName(),trade_gold100=c:GetYieldRateTimes100(YieldTypes.YIELD_GOLD,false)-c:GetYieldRateTimes100(YieldTypes.YIELD_GOLD,true)}end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),cities=cities,incoming=packRoutes(player:GetTradeRoutesToYou()),outgoing=packRoutes(player:GetTradeRoutes()),ai_outgoing=packRoutes(Players[1]:GetTradeRoutes()),incoming_tooltip=player:GetTradeToYouRoutesTTString(),outgoing_tooltip=player:GetTradeYourRoutesTTString()}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="pending"then return end
 phase="issued"
 local ok,err=pcall(function()
  local other=Players[1]
  assert(other:IsTurnActive(),"AI route command requires its ordinary active turn")
  for _,r in ipairs(requests)do
   local u=assert(other:GetUnitByID(r.unit));local c=assert(Players[0]:GetCityByID(r.target))
   assert(u:CanMakeTradeRouteAt(u:GetPlot(),c:GetX(),c:GetY(),r.kind),"incoming route lost eligibility before owner turn")
   LekmodScenarioEvent("incoming-route-command",{owner=1,unit=r.unit,target=r.target,kind=r.kind,owner_active=true})
   u:PushMission(GameInfoTypes.MISSION_ESTABLISH_TRADE_ROUTE,c:Plot():GetPlotIndex(),r.kind,0,0,1)
  end
 end)
 if not ok then aiError=tostring(err)end
end)
function LekmodScenario.step(player)
 assert(not aiError,aiError)
 local other=assert(Players[1]);assert(other:IsAlive()and not other:IsHuman(),"requires living AI slot1")
 if phase=="init" and #player:GetTradeRoutesToYou()>0 then
  local rows=player:GetTradeRoutesToYou();assert(#rows==2,"existing fixture needs two incoming routes")
  origin=rows[1].FromCity:GetID();started=Game.GetGameTurn();phase="issued"
  LekmodScenarioEvent("existing-incoming-fixture",{origin=origin,count=#rows,read_only=true})
 end
 if phase=="init"then
  assert(player:GetID()==0 and #player:GetTradeRoutesToYou()==0,"requires empty incoming human slot0 fixture")
  assert(not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()),"requires peace")
  assert(other:GetNumInternationalTradeRoutesAvailable()-other:GetNumInternationalTradeRoutesUsed()>=2,"AI requires two free trade slots")
  if not Teams[other:GetTeam()]:IsHasMet(player:GetTeam())then
   Teams[other:GetTeam()]:Meet(player:GetTeam(),false)
   LekmodScenarioEvent("fixture-setup",{operation="provided-contact",owner=1,other=0})
  end
  local site,best
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if p:GetOwner()==-1 and p:GetNumUnits()==0 and other:CanFound(p:GetX(),p:GetY())then
    local nearby=0
    for c in player:Cities()do if c:Plot():GetArea()==p:GetArea()and Map.PlotDistance(c:GetX(),c:GetY(),p:GetX(),p:GetY())<=8 then nearby=nearby+1 end end
    if nearby>=2 and (not best or nearby>best)then site=p;best=nearby end
   end
  end
  assert(site,"no legal AI city site near two human cities")
  other:Found(site:GetX(),site:GetY());local city=assert(site:GetPlotCity());origin=city:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-legal-AI-city",owner=1,id=origin,name=city:GetName(),x=city:GetX(),y=city:GetY()})
  city:SetNumRealBuilding(GameInfoTypes.BUILDING_CARAVANSARY,1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-range-building",owner=1,city=origin,type="BUILDING_CARAVANSARY"})
  local range=other:GetTradeRouteRange(DomainTypes.DOMAIN_LAND,city);local reveal=0
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())<=range and not p:IsRevealed(other:GetTeam())then p:SetRevealed(other:GetTeam(),true);reveal=reveal+1 end
  end
  LekmodScenarioEvent("fixture-setup",{operation="provided-AI-trade-range-reveal",range=range,plots=reveal})
  local picked={}
  for n=1,2 do
   local u=assert(other:InitUnit(other:GetTradeUnitType(DomainTypes.DOMAIN_LAND),city:GetX(),city:GetY()))
   LekmodScenarioEvent("fixture-setup",{operation="provided-AI-caravan",owner=1,id=u:GetID()})
   local option,target
   for _,r in ipairs(other:GetPotentialInternationalTradeRouteDestinations(u))do
    local c=Map.GetPlot(r.X,r.Y):GetPlotCity()
    if c and c:GetOwner()==0 and not picked[c:GetID()]then option=r;target=c;break end
   end
   assert(option,"AI origin lacks two distinct legal human destinations")
   assert(u:CanMakeTradeRouteAt(city:Plot(),target:GetX(),target:GetY(),option.TradeConnectionType),"queried incoming route is ineligible")
   picked[target:GetID()]=true;requests[#requests+1]={unit=u:GetID(),target=target:GetID(),kind=option.TradeConnectionType}
  end
  started=Game.GetGameTurn();phase="pending";return "turn"
 elseif phase=="pending" or phase=="issued"then
  local rows=player:GetTradeRoutesToYou()
  if #rows<2 then assert(Game.GetGameTurn()-started<2,"AI did not create both routes on its ordinary turn");return "turn"end
  assert(#rows==2,"unexpected extra incoming routes")
  local tourism={};local tourismMatches=true;local nonzero=0
  local totals={};local tooltip=player:GetTradeToYouRoutesTTString()
  for _,r in ipairs(rows)do
   assert(r.FromID==1 and r.ToID==0 and r.FromCity:GetID()==origin,"incoming route has unexpected owner or origin")
   local match
   for _,a in ipairs(other:GetTradeRoutes())do if a.FromCity:GetID()==r.FromCity:GetID()and a.ToID==0 and a.ToCity:GetID()==r.ToCity:GetID()then match=a;break end end
   assert(match and r.TurnsLeft>0 and r.TurnsLeft==match.TurnsLeft and r.FromGPT==match.FromGPT and r.ToGPT==match.ToGPT and r.ToScience==match.ToScience,"incoming/outgoing API values differ")
   assert(r.FromCivilizationType==other:GetCivilizationType() and r.FromCivilizationType==match.FromCivilizationType and r.ToCivilizationType==player:GetCivilizationType() and r.ToCivilizationType==match.ToCivilizationType,"incoming route civilization identity differs from its real owners")
   tourism[#tourism+1]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),incoming_from=r.FromTourism,outgoing_from=match.FromTourism,incoming_to=r.ToTourism,outgoing_to=match.ToTourism,origin_base=r.FromCity:GetBaseTourism(),destination_base=r.ToCity:GetBaseTourism()}
   if r.FromTourism~=match.FromTourism or r.ToTourism~=match.ToTourism then tourismMatches=false end
   if r.FromTourism~=0 or r.ToTourism~=0 or match.FromTourism~=0 or match.ToTourism~=0 then nonzero=nonzero+1 end
   totals[r.ToCity:GetID()]=(totals[r.ToCity:GetID()]or 0)+r.ToGPT
   assert(string.find(tooltip,r.FromCity:GetName(),1,true)and string.find(tooltip,r.ToCity:GetName(),1,true),"tooltip lacks route city names")
   for _,field in ipairs({{"ToGPT","GOLD"},{"ToScience","SCIENCE"},{"ToFood","FOOD"},{"ToProduction","PRODUCTION"}})do
    local raw=r[field[1]]or 0
    if raw~=0 then local text=Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_ITR_"..field[2].."_YIELD_TT",raw/100);assert(string.find(tooltip,text,1,true),"incoming tooltip lost "..field[1].." value "..raw)end
   end
  end
  for c in player:Cities()do
   local actual=c:GetYieldRateTimes100(YieldTypes.YIELD_GOLD,false)-c:GetYieldRateTimes100(YieldTypes.YIELD_GOLD,true)
   assert(actual==(totals[c:GetID()]or 0),"incoming gold does not match recipient city trade contribution")
  end
  LekmodScenarioEvent("incoming-tourism-comparison",{routes=tourism,nonzero_rows=nonzero})
  LekmodScenarioEvent("incoming-route-observed",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("incoming-route-creation","PASS","two native AI routes; setup command events distinguish fresh creation from read-only saved-fixture checks")
  LekmodScenarioRecord("incoming-route-identity","PASS","both civilization types match actual owners and outgoing rows")
  LekmodScenarioRecord("incoming-route-accounting","PASS","incoming/outgoing count, gold, science and countdown agree; recipient city gold contributions match")
  LekmodScenarioRecord("incoming-route-tooltip","PASS","actual localized names and available nonzero gold/science/food/production values")
  LekmodScenarioRecord("incoming-route-tourism",tourismMatches and "PASS"or "FAIL","incoming/outgoing tourism agreement; nonzero_rows="..nonzero)
  return true
 end
end
