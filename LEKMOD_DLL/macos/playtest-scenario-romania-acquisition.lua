-- Native method surface: GameCore
-- Supplied legal cities, contact, an AI attacker/uranium/upkeep budget are inputs.
-- A real single-player AI city-gift deal and actual owner-turn combat drive the
-- two acquisition paths. Golden-age points, damage and ownership are not assigned.
LekmodScenario={name="romania-acquisition",items={"romania-city-gift","romania-gift-no-capture-reward","romania-conquest","romania-conquest-reward","romania-previous-owner-control"}}
local phase,giftCity,targetCity,giftBefore,oldBefore,accepted,proposed,closed,conquestBefore,conquestOldBefore,captured,sent,started="init"
local recipient=4
local observations={}
LuaEvents.LekmodRomaniaCityGiftAccepted.Add(function()accepted=true end)
LuaEvents.LekmodRomaniaCityGiftProposed.Add(function()proposed=true end)
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind)if kind=="closed"then closed=true end end)
local function cityAt(t)return assert(Map.GetPlot(t.x,t.y):GetPlotCity())end
local function found(p,near)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and Map.PlotDistance(near:GetX(),near:GetY(),q:GetX(),q:GetY())<=12 and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(not c:IsCapital());local t={id=c:GetID(),x=c:GetX(),y=c:GetY()}
   LekmodScenarioEvent("fixture-setup",{operation="provided-legal-transfer-test-city",owner=p:GetID(),city=t.id,x=t.x,y=t.y});return t
  end
 end
 error("no legal test city near Romanian territory")
end
GameEvents.CityCaptureComplete.Add(function(old,capital,x,y,new,pop,conquest)
 if old~=0 or new~=recipient then return end
 local kind=giftCity and x==giftCity.x and y==giftCity.y and"gift"or(targetCity and x==targetCity.x and y==targetCity.y and"conquest")
 if not kind then return end
 assert(not capital);local p=Players[recipient]
 observations[kind]={old=old,new=new,population=pop,conquest=conquest,points=p:GetGoldenAgeProgressMeter(),old_points=Players[0]:GetGoldenAgeProgressMeter()}
 LekmodScenarioEvent("native-Romanian-city-acquisition",{kind=kind,state=observations[kind]})
 if kind=="conquest"then assert(sent and conquest);captured=true else assert(not conquest)end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=recipient or phase~="capture"or sent then return end
 local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman());local c=cityAt(targetCity);local q
 for d=0,5 do local n=Map.PlotDirection(c:GetX(),c:GetY(),d)
  if n and not n:IsWater()and not n:IsMountain()and not n:IsCity()and n:GetNumUnits()==0 then q=n;break end
 end
 assert(q);p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
 local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,q:GetX(),q:GetY()));assert(u:CanMoveOrAttackInto(c:Plot()))
 LekmodScenarioEvent("fixture-setup",{operation="provided-Romanian-attacker-uranium-upkeep",unit=u:GetID(),x=u:GetX(),y=u:GetY(),gold_added=1000,uranium_added=1})
 conquestBefore=p:GetGoldenAgeProgressMeter();conquestOldBefore=Players[0]:GetGoldenAgeProgressMeter();sent=true
 u:PushMission(MissionTypes.MISSION_MOVE_TO,c:GetX(),c:GetY(),0,0,1)
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for _,owner in ipairs({0,recipient})do local p=Players[owner];local cities={}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),original=c:GetOriginalOwner(),population=c:GetPopulation(),puppet=c:IsPuppet(),occupied=c:IsOccupied(),resistance=c:GetResistanceTurns()}end
  owners[owner]={civilization=p:GetCivilizationType(),gold=p:GetGold(),points=p:GetGoldenAgeProgressMeter(),golden_turns=p:GetGoldenAgeTurns(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),owners=owners,war=Teams[player:GetTeam()]:IsAtWar(Players[recipient]:GetTeam())}
end
function LekmodScenario.step(player)
 local p=Players[recipient];assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_POLAND and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROMANIA and Game.GetWinner()==-1)
 if phase=="init"then
  assert(not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()));Teams[player:GetTeam()]:Meet(p:GetTeam(),true)
  local home=assert(p:GetCapitalCity());giftCity=found(player,home);targetCity=found(player,home)
  giftBefore=p:GetGoldenAgeProgressMeter();oldBefore=player:GetGoldenAgeProgressMeter()
  LuaEvents.LekmodRomaniaCityGift({player=recipient,city=giftCity.id,x=giftCity.x,y=giftCity.y});LuaEvents.LekmodScenarioDiplomacyOpen(recipient);phase="gift"
 elseif phase=="gift"then
  if not closed then return false end
  assert(accepted and proposed and observations.gift and cityAt(giftCity):GetOwner()==recipient)
  LekmodScenarioRecord("romania-city-gift","PASS","normal city/propose/AI-reply callbacks transfer the human city without conquest")
  local delta=observations.gift.points-giftBefore
  LekmodScenarioRecord("romania-gift-no-capture-reward",delta==0 and"PASS"or"FAIL","non-conquest city gift golden-age points expected=0 actual="..delta)
  assert(observations.gift.old_points==oldBefore)
  Network.SendChangeWar(p:GetTeam(),true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("Romanian-war",Teams[player:GetTeam()]:IsAtWar(p:GetTeam()))then return false end
  phase="capture";started=Game.GetGameTurn();return "turn"
 elseif phase=="capture"then
  if not captured then assert(Game.GetGameTurn()-started<3,"Romanian normal capture did not complete");return "turn"end
  assert(cityAt(targetCity):GetOwner()==recipient and player:IsAlive())
  LekmodScenarioRecord("romania-conquest","PASS","actual AI-owner-turn attack captures the supplied city; human survives")
  local e=observations.conquest;local expected=math.floor(125*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldenAgePercent/100)
  assert(e.points-conquestBefore==expected,"Romanian capture reward differs from game-speed scale")
  LekmodScenarioRecord("romania-conquest-reward","PASS","real conquest awards exactly"..expected.." golden-age points at native capture event")
  assert(e.old_points==conquestOldBefore)
  LekmodScenarioRecord("romania-previous-owner-control","PASS","previous Polish owner gets no Romanian reward on gift or conquest")
  return true
 end
 return false
end
