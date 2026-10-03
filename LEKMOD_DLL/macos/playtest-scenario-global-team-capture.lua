-- Native method surface: GameCore
-- The starting checkpoint supplies previously earned policy/tech fixture state.
-- Upkeep, uranium and an adjacent GDR are inputs; war, attack/capture, capital
-- replacement and marker refresh must be native, with no damage/owner assignment.
LekmodScenario={name="global-team-capture",items={"global-capture-prerequisites","global-native-capital-capture","global-old-owner-capital-refresh","global-new-owner-cleanup","global-teammate-control","global-capture-next-round"}}
local attackerID
local phase,x,y,sent,captured,err,turn,teammate="init",nil,nil,false,false,nil,nil,nil
local union,wales,mongol,ulug=GameInfoTypes.BUILDING_ECONOMIC_UNION_GOLD,GameInfoTypes.BUILDING_WALES_TRAIT,GameInfoTypes.BUILDING_MONGOL_TRAIT,GameInfoTypes.BUILDING_ULUG
local function markers(p)
 local result={};for c in p:Cities()do result[c:GetID()]={capital=c:IsCapital(),wales=c:GetNumRealBuilding(wales),mongol=c:GetNumRealBuilding(mongol),ulug=c:GetNumRealBuilding(ulug),union=c:GetNumRealBuilding(union)}end;return result
end
local function target()return assert(Map.GetPlot(x,y):GetPlotCity())end
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
 if old==0 and new==2 and cx==x and cy==y then
  assert(sent and capital and conquest);captured=true;LekmodScenarioEvent("native-team-capital-capture",{old=old,new=new,x=cx,y=cy,population=pop})
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=2 or phase~="capture"or captured then return end
 local ok,e=pcall(function()
  local p=Players[2];assert(p:IsTurnActive()and not p:IsHuman());local q,u
  if attackerID then u=assert(p:GetUnitByID(attackerID),"provided attacker lost before capture")else
  for d=0,5 do local t=Map.PlotDirection(x,y,d);if t and not t:IsWater()and not t:IsMountain()and not t:IsCity()and t:GetNumUnits()==0 then q=t;break end end
  assert(q,"no empty adjacent attack tile");p:ChangeGold(10000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
  u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,q:GetX(),q:GetY()));attackerID=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-GDR-upkeep-uranium-staging",owner=2,unit=u:GetID(),x=q:GetX(),y=q:GetY()})
  end
  assert(not u:IsBusy()and u:CanMoveOrAttackInto(target():Plot()),"normal repeated owner-turn attack is unavailable")
  sent=true;u:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local cities={};for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),owner=c:GetOwner(),original=c:GetOriginalOwner(),capital=c:IsCapital(),population=c:GetPopulation(),puppet=c:IsPuppet(),occupied=c:IsOccupied(),wales=c:GetNumRealBuilding(wales),mongol=c:GetNumRealBuilding(mongol),ulug=c:GetNumRealBuilding(ulug),union=c:GetNumRealBuilding(union)}end
  owners[owner]={alive=p:IsAlive(),team=p:GetTeam(),cities=cities,policy=p:HasPolicy(GameInfoTypes.POLICY_ECONOMIC_UNION)}
 end
 return {turn=Game.GetGameTurn(),owners=owners,war=Teams[7]:IsAtWar(0)}
end
local function verify(p)
 assert(p:IsAlive()and p:GetNumCities()==1);local c=assert(p:GetCapitalCity());assert(c:GetX()~=x or c:GetY()~=y)
 assert(c:GetNumRealBuilding(wales)==1 and c:GetNumRealBuilding(union)==1 and c:GetNumRealBuilding(mongol)==0 and c:GetNumRealBuilding(ulug)==0,"surviving new Wales capital lost its eligible markers")
 local capturedCity=target();assert(capturedCity:GetOwner()==2 and capturedCity:GetOriginalOwner()==0 and not capturedCity:IsCapital())
 assert(capturedCity:GetNumRealBuilding(wales)==0 and capturedCity:GetNumRealBuilding(union)==0 and capturedCity:GetNumRealBuilding(mongol)==0 and capturedCity:GetNumRealBuilding(ulug)==0,"captured noncapital retained foreign/capital-only markers")
 assert(Players[2]:GetCapitalCity():GetNumRealBuilding(ulug)==1)
 assert(LekmodScenarioJSON(markers(Players[1]))==teammate,"unrelated teammate marker state changed")
end
function LekmodScenario.step(p)
 assert(not err,err);assert(not Game.IsGameMultiPlayer()and p:GetID()==0 and p:GetTeam()==7 and Players[1]:GetTeam()==7 and Players[2]:GetTeam()==0)
 if phase=="init"then
  assert(p:GetNextPolicyCost()>0,"capture fixture has invalid policy history")
  assert(p:GetNumCities()==2 and p:HasPolicy(GameInfoTypes.POLICY_ECONOMIC_UNION));local c=p:GetCapitalCity();x,y=c:GetX(),c:GetY()
  assert(c:GetNumRealBuilding(wales)==1 and c:GetNumRealBuilding(union)==1 and p:CountNumBuildings(union)==2 and p:CountNumBuildings(wales)==1)
  assert(Players[1]:GetCapitalCity():GetNumRealBuilding(mongol)==1 and Players[2]:GetCapitalCity():GetNumRealBuilding(ulug)==1)
  teammate=LekmodScenarioJSON(markers(Players[1]));LekmodScenarioRecord("global-capture-prerequisites","PASS","repaired starting markers correct; two human cities keep human alive; real teams7/7/0")
  Teams[7]:Meet(0,true);Network.SendChangeWar(0,true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("team-capture-war",Teams[7]:IsAtWar(0))then return false end
  phase="capture";return "turn"
 elseif phase=="capture"then
  if not captured then return "turn"end
  verify(p)
  LekmodScenarioRecord("global-native-capital-capture","PASS","real AI2 owner-turn move/attack captures human0 original capital without assigned damage or ownership")
  LekmodScenarioRecord("global-old-owner-capital-refresh","PASS","surviving Wales capital gets its capital-only marker and retains Economic Union")
  LekmodScenarioRecord("global-new-owner-cleanup","PASS","Timurids keeps own-capital Ulug; captured noncapital has no foreign/capital-only markers")
  LekmodScenarioRecord("global-teammate-control","PASS","Mongol teammate's per-city markers remain exact across the capture")
  turn=Game.GetGameTurn();phase="next";return "turn"
 elseif phase=="next"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1);verify(p);LekmodScenarioRecord("global-capture-next-round","PASS","one subsequent ordinary round keeps correct owner/capital markers");return true
 end
 return false
end
