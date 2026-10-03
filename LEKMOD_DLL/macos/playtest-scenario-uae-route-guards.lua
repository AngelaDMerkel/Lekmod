-- Native method surface: GameCore
-- Legal coastal cities, prerequisites, cargo ship and guard probes are inputs.
-- Route creation, repeated owner turns and a normal off-route move are outcomes.
LekmodScenario={name="uae-route-guards",items={"uae-guard-route-created","uae-guard-gold","uae-guard-experience","uae-guard-civilian-control","uae-guard-offroute-control","uae-guard-repeat","uae-guard-real-movement","uae-guard-removal","uae-guard-save-state"}}
local phase,origin,target,cargo,kind,moveTo,beforeMove="init"
local probes,unitsSeen,serial,ledger,last={}, {},0,nil,nil
local prefix="LEKMOD_UAE_GUARD:"
local function seaArea(q)
 for d=0,5 do local s=Map.PlotDirection(q:GetX(),q:GetY(),d);if s and s:IsWater()and not s:IsLake()then return s:GetArea()end end
end
local function coastalCity(p,near,area,minimum)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local distance=Map.PlotDistance(near:GetX(),near:GetY(),q:GetX(),q:GetY())
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and distance>=minimum and distance<=12 and seaArea(q)and(not area or seaArea(q)==area)and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());LekmodScenarioEvent("fixture-setup",{operation="provided-human-coastal-city",city=c:GetID(),x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no legal matching coastal city")
end
local function water(q,p)
 return q and q:IsWater()and not q:IsLake()and q:GetFeatureType()==-1 and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==p:GetID())
end
local function create(p,role,kind,q)
 local u=assert(p:InitUnit(GameInfoTypes[kind],q:GetX(),q:GetY()));u:SetScriptData(prefix..role);assert(u:GetX()==q:GetX()and u:GetY()==q:GetY());probes[role]=u:GetID()
 LekmodScenarioEvent("fixture-setup",{operation="provided-guard-probe",role=role,type=kind,unit=u:GetID(),x=q:GetX(),y=q:GetY()});return u
end
LuaEvents.LekmodUaeGuardUnit.Add(function(owner,id,eligible,before,after,tag)
 if owner==0 then unitsSeen[id]={eligible=eligible,before=before,after=after,tag=tag}end
end)
LuaEvents.LekmodUaeGuardOwner.Add(function(owner,count,before,after)
 if owner~=0 then return end
 serial=serial+1;ledger={serial=serial,turn=Game.GetGameTurn(),eligible=count,before=before,after=after,units=unitsSeen};unitsSeen={}
 LekmodScenarioEvent("native-UAE-route-guard",ledger)
end)
local function verify(moved)
 assert(ledger and ledger.serial==last+1,"expected one actual human owner callback")
 assert(ledger.after-ledger.before==3*ledger.eligible,"guard gold differs from eligible-unit count")
 for _,u in pairs(ledger.units)do assert(u.after-u.before==(u.eligible and 1 or 0),"event-time unit XP differs")end
 for role,id in pairs(probes)do
  local u=assert(ledger.units[id]);local eligible=role=="second"or(role=="moving"and not moved)
  assert(u.eligible==eligible and u.after-u.before==(eligible and 1 or 0),"guard control differs: "..role)
 end
 assert(ledger.eligible>=(moved and 1 or 2))
end
function LekmodScenario.snapshot(p)
 local units,routes={},{}
 for u in p:Units()do if string.sub(u:GetScriptData(),1,#prefix)==prefix then units[u:GetID()]={tag=u:GetScriptData(),type=u:GetUnitType(),xp=u:GetExperience(),moves=u:GetMoves(),x=u:GetX(),y=u:GetY(),tooltip_count=#p:GetInternationalTradeRoutePlotToolTip(u:GetPlot())}end end
 for _,r in ipairs(p:GetTradeRoutes())do routes[#routes+1]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),domain=r.Domain,kind=r.ConnectionType}end
 return {turn=Game.GetGameTurn(),gold=p:GetGold(),units=units,routes=routes}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_UAE)
 if phase=="init"then
  assert(#p:GetTradeRoutes()==0 and not Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()))
  p:ChangeGold(10000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_OIL,10);LekmodScenarioGrantTech(p,"TECH_SAILING")
  local home=p:GetCapitalCity();if not home:IsCoastal(10)then home=coastalCity(p,home:Plot(),nil,4)end
  local destination=coastalCity(p,home:Plot(),seaArea(home:Plot()),7);origin,target=home:GetID(),destination:GetID()
  home:SetNumRealBuilding(GameInfoTypes.BUILDING_GRANARY,1);home:SetNumRealBuilding(GameInfoTypes.BUILDING_HARBOR,1)
  local range=p:GetTradeRouteRange(DomainTypes.DOMAIN_SEA,home)
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if Map.PlotDistance(home:GetX(),home:GetY(),q:GetX(),q:GetY())<=range and not q:IsRevealed(p:GetTeam())then q:SetRevealed(p:GetTeam(),true)end end
  assert(p:GetNumInternationalTradeRoutesAvailable()>p:GetNumInternationalTradeRoutesUsed(),"no available human trade slot")
  local u=assert(p:InitUnit(p:GetTradeUnitType(DomainTypes.DOMAIN_SEA),home:GetX(),home:GetY()));cargo=u:GetID()
  for _,r in ipairs(p:GetPotentialInternationalTradeRouteDestinations(u))do if r.X==destination:GetX()and r.Y==destination:GetY()and r.Yields[YieldTypes.YIELD_FOOD+1].Theirs>0 then kind=r.TradeConnectionType;break end end
  assert(kind~=nil and u:CanMakeTradeRouteAt(u:GetPlot(),destination:GetX(),destination:GetY(),kind))
  LekmodScenarioEvent("fixture-setup",{operation="provided-trade-prerequisites-unit-reveal",origin=origin,target=target,unit=cargo,range=range})
  UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,GameInfoTypes.MISSION_ESTABLISH_TRADE_ROUTE,destination:Plot():GetPlotIndex(),kind,0,false,false);phase="route"
 elseif phase=="route"then
  local found=false;for _,r in ipairs(p:GetTradeRoutes())do if r.FromCity:GetID()==origin and r.ToCity:GetID()==target and r.Domain==DomainTypes.DOMAIN_SEA and r.ConnectionType==kind then found=true end end
  if not LekmodScenarioAwait("UAE-internal-sea-route",found)then return false end
  LekmodScenarioRecord("uae-guard-route-created","PASS","normal legal human mission created the internal sea route; no route result assigned")
  local first,second,off
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if water(q,p)and #p:GetInternationalTradeRoutePlotToolTip(q)>0 then
    for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d)
     if water(a,p)and #p:GetInternationalTradeRoutePlotToolTip(a)==0 then first=q;moveTo=a;break end
    end
   end
   if first then break end
  end
  assert(first,"no route plot with a legal off-route neighbor")
  create(p,"moving","UNIT_DESTROYER",first);create(p,"civilian","UNIT_WORKBOAT",first)
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if water(q,p)and q:GetPlotIndex()~=moveTo:GetPlotIndex() then
    if #p:GetInternationalTradeRoutePlotToolTip(q)>0 and not second then second=q
    elseif #p:GetInternationalTradeRoutePlotToolTip(q)==0 and not off then off=q end
   end
   if second and off then break end
  end
  assert(second and off);create(p,"second","UNIT_DESTROYER",second);create(p,"offroute","UNIT_DESTROYER",off)
  last=serial;phase="first-round";return "turn"
 elseif phase=="first-round"then
  if serial<=last then return "turn"end;verify(false)
  LekmodScenarioRecord("uae-guard-gold","PASS","read-only event bracket observes exactly3 gold per eligible combat unit, separate from turn income")
  LekmodScenarioRecord("uae-guard-experience","PASS","both on-route combat probes gain1 XP in the real owner callback")
  LekmodScenarioRecord("uae-guard-civilian-control","PASS","civilian on the same route plot gains no XP or counted guard reward")
  LekmodScenarioRecord("uae-guard-offroute-control","PASS","otherwise matching off-route combat unit gains no guard reward")
  last=serial;phase="repeat";return "turn"
 elseif phase=="repeat"then
  if serial<=last then return "turn"end;verify(false)
  LekmodScenarioRecord("uae-guard-repeat","PASS","a second real owner callback repeats precisely the per-unit award")
  local u=assert(p:GetUnitByID(probes.moving));assert(u:CanMoveOrAttackInto(moveTo));beforeMove=u:GetMoves();UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,moveTo:GetX(),moveTo:GetY(),0,false,false);phase="moved"
 elseif phase=="moved"then
  local u=assert(p:GetUnitByID(probes.moving));if not LekmodScenarioAwait("UAE-guard-off-route",u:GetX()==moveTo:GetX()and u:GetY()==moveTo:GetY()and not u:IsBusy())then return false end
  assert(u:GetMoves()<beforeMove and #p:GetInternationalTradeRoutePlotToolTip(u:GetPlot())==0)
  LekmodScenarioRecord("uae-guard-real-movement","PASS","normal mission spent movement and left the route")
  last=serial;phase="removed";return "turn"
 elseif phase=="removed"then
  if serial<=last then return "turn"end;verify(true)
  LekmodScenarioRecord("uae-guard-removal","PASS","moved combat unit no longer earns reward; remaining on-route guard still does")
  LekmodScenarioRecord("uae-guard-save-state","PASS","route, treasury, probe XP/positions/moves retained for exact reload");return true
 end
 return false
end
