-- Native method surface: GameCore
-- Supplied cities/buildings/units are effect inputs. Unique buildings use their
-- actual civilization. Human missions use network commands; AI missions run only
-- on the actual owner turn. Read-only UnitSetXY records immediate movement use.
local kind=assert(LekmodScenarioParameters.building)
LekmodScenario={name="airlift",items={"airlift-building-capability","airlift-domain-trade-controls","airlift-destination-controls","airlift-enemy-command-rejection","airlift-native-transfer","airlift-movement-repeat"}}
local civs={BUILDING_HORDE_YAM_ROUTE="CIVILIZATION_GOLDEN_HORDE",BUILDING_MC_OMANI_MINAA="CIVILIZATION_OMAN",BUILDING_SERAI="CIVILIZATION_TIMURIDS"}
local phase,owner,enemy,sourceCity,targetCity,source,target,unitID,blockerID,before,waits,arrival="init",nil,nil,nil,nil,nil,nil,nil,nil,nil,0,nil
local function land(q)return q and not q:IsWater()and not q:IsMountain()and not q:IsImpassable()and q:GetNumUnits()==0 end
local function found(p,far)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if land(q)and q:GetOwner()==-1 and p:CanFound(q:GetX(),q:GetY())and Map.PlotDistance(q:GetX(),q:GetY(),far:GetX(),far:GetY())>=8 then p:Found(q:GetX(),q:GetY());return assert(q:GetPlotCity())end
 end
 error("no legal airlift city")
end
local function neighbor(c)
 for d=0,5 do local q=Map.PlotDirection(c:GetX(),c:GetY(),d);if land(q)and not q:IsCity()then return q end end
 error("no adjacent airlift land")
end
local function send(u,q)
 if Players[owner]:IsHuman()then UI.SelectUnit(u);assert(UI.GetHeadSelectedUnit():GetID()==u:GetID());Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_AIRLIFT,q:GetX(),q:GetY(),0,false,false)
 else assert(Players[owner]:IsTurnActive());u:PushMission(MissionTypes.MISSION_AIRLIFT,q:GetX(),q:GetY(),0,0,1)end
end
GameEvents.UnitSetXY.Add(function(id,unit,x,y)
 if id==owner and unit==unitID and phase=="airlift"and x==target:GetX()and y==target:GetY()then
  local u=Players[owner]:GetUnitByID(unit);arrival={owner=id,unit=unit,x=x,y=y,moves=u:GetMoves(),can_repeat=u:CanAirlift(u:GetPlot())}
  LekmodScenarioEvent("native-airlift-arrival",arrival)
 end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
  if p and p:IsAlive()then local units,cities={},{}
   for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={kind=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end
   for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),building=c:GetNumRealBuilding(GameInfoTypes[kind])}end
   owners[id]={units=units,cities=cities}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function liftAfterControl()
 local u=assert(Players[owner]:GetUnitByID(unitID));Players[enemy]:GetUnitByID(blockerID):Kill(false,-1)
 LekmodScenarioEvent("fixture-setup",{operation="removed-provided-blocker",unit=blockerID})
 assert(u:CanAirliftAt(source,target:GetX(),target:GetY()));phase="airlift";send(u,target)
end
local function exercise(p)
 local b=GameInfoTypes[kind];local u=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,source:GetX(),source:GetY()));unitID=u:GetID()
 assert(not u:CanAirlift(source));sourceCity:SetNumRealBuilding(b,1)
 assert(u:CanAirlift(source)and not u:CanAirliftAt(source,target:GetX(),target:GetY()),"source/destination capability mismatch")
 targetCity:SetNumRealBuilding(b,1);assert(u:CanAirliftAt(source,target:GetX(),target:GetY()))
 LekmodScenarioRecord("airlift-building-capability","PASS",kind..": actual civilization; absent source/destination reject; both permit")
 local caravan=assert(p:InitUnit(GameInfoTypes.UNIT_CARAVAN,source:GetX(),source:GetY()));assert(not caravan:CanAirlift(source))
 local water;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:IsWater()and q:GetFeatureType()==-1 and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==owner)then water=q;break end end
 assert(water);local ship=assert(p:InitUnit(GameInfoTypes.UNIT_TRIREME,water:GetX(),water:GetY()));assert(not ship:CanAirlift(water))
 LekmodScenarioRecord("airlift-domain-trade-controls","PASS","trade and sea units rejected by native source predicate")
 assert(not u:CanAirliftAt(source,sourceCity:GetX(),sourceCity:GetY())and not u:CanAirliftAt(source,water:GetX(),water:GetY()))
 local foreign=assert(Players[enemy]:GetCapitalCity());foreign:SetNumRealBuilding(GameInfoTypes.BUILDING_AIRPORT,1);assert(not u:CanAirliftAt(source,foreign:GetX(),foreign:GetY()))
 local occupied=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,target:GetX(),target:GetY()));assert(not u:CanAirliftAt(source,target:GetX(),target:GetY()));occupied:Kill(false,-1)
 LekmodScenarioRecord("airlift-destination-controls","PASS","same city, water, foreign city and occupied destination rejected")
 local q;for d=0,5 do local n=Map.PlotDirection(target:GetX(),target:GetY(),d);if land(n)and not n:IsCity()then q=n;break end end
 assert(q);local blocker=assert(Players[enemy]:InitUnit(GameInfoTypes.UNIT_WARRIOR,q:GetX(),q:GetY()));blockerID=blocker:GetID()
 assert(blocker:GetX()==q:GetX()and blocker:GetY()==q:GetY())
 LekmodScenarioEvent("fixture-setup",{operation="provided-blocker-after-war",owner=enemy,unit=blockerID,x=q:GetX(),y=q:GetY()})
 assert(not u:CanAirliftAt(source,target:GetX(),target:GetY()))
 if p:IsHuman()then before=u:GetMoves();send(u,target);phase="rejected"
 else
  LekmodScenarioRecord("airlift-enemy-command-rejection","PASS","AI path: native target predicate rejects adjacent enemy; no invalid AI command claimed")
  liftAfterControl()
 end
end
GameEvents.PlayerDoTurn.Add(function(id)
 if id==owner and phase=="owner-ready"and not Players[id]:IsHuman()then assert(Players[id]:IsTurnActive());exercise(Players[id])end
end)
function LekmodScenario.step(player)
 if phase=="init"then
  assert(GameInfo.Buildings[kind].Airlift);owner=0
  if civs[kind]then owner=nil;for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive()and p:GetCivilizationType()==GameInfoTypes[civs[kind]]then owner=id;break end end end
  assert(owner,"fixture lacks owning civilization");enemy=owner==1 and 2 or 1
  local p=Players[owner];sourceCity=found(p,assert(p:GetCapitalCity()));targetCity=found(p,sourceCity)
  source=(kind=="BUILDING_HORDE_YAM_ROUTE"or kind=="BUILDING_SERAI")and neighbor(sourceCity)or sourceCity:Plot()
  target=(kind=="BUILDING_HORDE_YAM_ROUTE"or kind=="BUILDING_MC_OMANI_MINAA")and neighbor(targetCity)or targetCity:Plot()
  p:ChangeGold(3000);Teams[p:GetTeam()]:Meet(Players[enemy]:GetTeam(),true)
  if p:IsHuman()then Network.SendChangeWar(Players[enemy]:GetTeam(),true)else Teams[p:GetTeam()]:DeclareWar(Players[enemy]:GetTeam())end
  LekmodScenarioEvent("fixture-setup",{operation="provided-owner-cities-upkeep-and-war",owner=owner,building=kind,source=sourceCity:GetID(),destination=targetCity:GetID(),gold_added=3000})
  phase="war";return false
 elseif phase=="war"then
  if not LekmodScenarioAwait("airlift-war",Teams[Players[owner]:GetTeam()]:IsAtWar(Players[enemy]:GetTeam()))then return false end
  if owner==0 then exercise(Players[owner]);return false end
  phase="owner-ready";return "turn"
 elseif phase=="owner-ready"then return "turn"
 elseif phase=="rejected"then
  waits=waits+1;if waits<3 then return false end
  local u=assert(Players[owner]:GetUnitByID(unitID));assert(u:GetX()==source:GetX()and u:GetY()==source:GetY()and u:GetMoves()==before)
  LekmodScenarioRecord("airlift-enemy-command-rejection","PASS","human native blocked-target request preserves position/movement")
  liftAfterControl();return false
 elseif phase=="airlift"then
  if not arrival then return false end
  assert(arrival.owner==owner and arrival.x==target:GetX()and arrival.y==target:GetY())
  LekmodScenarioRecord("airlift-native-transfer","PASS","actual mission and UnitSetXY reached exact city/adjacent destination")
  assert(arrival.moves==0 and not arrival.can_repeat)
  LekmodScenarioRecord("airlift-movement-repeat","PASS","immediate native arrival has zero movement and rejects repeat; AI end-turn refresh is separate")
  return true
 end
 return false
end
