-- Native method surface: GameCore
-- A legal third-party city, its foreign occupation, contact and a staged unit /
-- uranium are explicit inputs. Human attack and the original Liberate closure
-- determine both ownership changes. No damage, golden-age points or turns set.
LekmodScenario={name="romania-liberation",items={"romania-liberation-peace-gate","romania-liberation-conquest","romania-liberator-reward","romania-liberation-return","romania-liberated-recipient-control"}}
local phase,recipient,enemy,target,unitID,reply,before,captureState,returnState="init"
local function meters()return {actor=Players[0]:GetGoldenAgeProgressMeter(),recipient=Players[recipient]:GetGoldenAgeProgressMeter(),enemy=Players[enemy]:GetGoldenAgeProgressMeter()}end
LuaEvents.LekmodCaptureChoiceDone.Add(function(kind,id)assert(kind=="liberate");reply=true end)
GameEvents.CityCaptureComplete.Add(function(old,capital,x,y,new,pop,conquest)
 if not target or x~=target.x or y~=target.y then return end
 if old==enemy and new==0 then assert(conquest);captureState=meters();LekmodScenarioEvent("native-liberating-conquest",{old=old,new=new,conquest=conquest,points=captureState})
 elseif old==0 and new==recipient then assert(not conquest);returnState=meters();LekmodScenarioEvent("native-liberation-return",{old=old,new=new,conquest=conquest,points=returnState})end
end)
local function owners(player)
 if player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROMANIA then return 1,2 end
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_POLAND and Players[4]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROMANIA);return 4,5
end
function LekmodScenario.snapshot(player)
 local r,e=owners(player);local players={}
 for _,owner in ipairs({0,r,e})do local p=Players[owner];local cities={}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),original=c:GetOriginalOwner(),population=c:GetPopulation(),puppet=c:IsPuppet(),occupied=c:IsOccupied(),resistance=c:GetResistanceTurns()}end
  players[owner]={civilization=p:GetCivilizationType(),points=p:GetGoldenAgeProgressMeter(),golden_turns=p:GetGoldenAgeTurns(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),players=players,winner=Game.GetWinner()}
end
function LekmodScenario.step(player)
 assert(Game.GetWinner()==-1 and not Game.IsOption(GameInfoTypes.GAMEOPTION_AI_GIMP_NO_LIBERATION),"requires single-player AI-city liberation enabled")
 if phase=="init"then
  recipient,enemy=owners(player);assert(Players[enemy]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
  local original=Players[recipient];local opponent=Players[enemy];local home=player:GetCapitalCity();local q
  assert(original:IsAlive()and original:GetCapitalCity()and opponent:GetCapitalCity())
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if p:GetOwner()==-1 and p:GetNumUnits()==0 and Map.PlotDistance(home:GetX(),home:GetY(),p:GetX(),p:GetY())<=12 and original:CanFound(p:GetX(),p:GetY())then q=p;break end
  end
  assert(q);original:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(not c:IsCapital());opponent:AcquireCity(c,false,true)
  c=assert(q:GetPlotCity());assert(c:GetOwner()==enemy and c:GetOriginalOwner()==recipient)
  target={x=q:GetX(),y=q:GetY()};Teams[player:GetTeam()]:Meet(original:GetTeam(),true);Teams[player:GetTeam()]:Meet(opponent:GetTeam(),true)
  assert(not Teams[player:GetTeam()]:IsAtWar(original:GetTeam())and not Teams[player:GetTeam()]:IsAtWar(opponent:GetTeam()))
  local staging
  for d=0,5 do local n=Map.PlotDirection(target.x,target.y,d)
   if n and not n:IsWater()and not n:IsMountain()and not n:IsCity()and n:GetNumUnits()==0 then staging=n;break end
  end
  assert(staging,"no initial attack preview position")
  player:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1);local u=assert(player:InitUnit(GameInfoTypes.UNIT_MECH,staging:GetX(),staging:GetY()));unitID=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-foreign-held-major-city-unit-uranium-contact",original=recipient,occupier=enemy,x=target.x,y=target.y,unit=unitID,unit_x=u:GetX(),unit_y=u:GetY()})
  assert(q:IsVisible(player:GetTeam())and not u:CanMoveOrAttackInto(q,0,1),"revealed foreign city destination must reject peaceful entry");LekmodScenarioRecord("romania-liberation-peace-gate","PASS","normal city attack rejected before declaration of war")
  Network.SendChangeWar(opponent:GetTeam(),true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("liberation-war",Teams[player:GetTeam()]:IsAtWar(Players[enemy]:GetTeam()))then return false end
  local u=assert(player:GetUnitByID(unitID));local q
  for d=0,5 do local p=Map.PlotDirection(target.x,target.y,d)
   if p and not p:IsWater()and not p:IsMountain()and not p:IsCity()and p:GetNumUnits()==0 then q=p;break end
  end
  assert(q);u:SetXY(q:GetX(),q:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="provided-legal-adjacent-attack-position",unit=unitID,x=u:GetX(),y=u:GetY()})
  assert(u:CanMoveOrAttackInto(Map.GetPlot(target.x,target.y))and u:GetMoves()>0)
  before=meters();LuaEvents.LekmodCaptureChoice("liberate");UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,target.x,target.y,0,false,false);phase="liberated"
 elseif phase=="liberated"then
  if not reply or not returnState then return false end
  local c=assert(Map.GetPlot(target.x,target.y):GetPlotCity());assert(captureState and c:GetOwner()==recipient and c:GetOriginalOwner()==recipient and Players[recipient]:IsAlive())
  LekmodScenarioRecord("romania-liberation-conquest","PASS","real human attack produced the conquest event before the liberation choice")
  local expected=player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROMANIA and math.floor(125*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldenAgePercent/100)or 0
  assert(captureState.actor-before.actor==expected and captureState.recipient==before.recipient)
  LekmodScenarioRecord("romania-liberator-reward","PASS","capturing liberator reward follows its own civilization; exact points="..expected)
  assert(returnState.actor==captureState.actor and returnState.recipient==captureState.recipient)
  LekmodScenarioRecord("romania-liberation-return","PASS","original Liberate closure/native return restores the original living major owner")
  LekmodScenarioRecord("romania-liberated-recipient-control","PASS","peaceful liberated recipient gets no capture reward, including Romanian recipient; actor's earned points are preserved")
  LekmodScenarioEvent("liberation-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
