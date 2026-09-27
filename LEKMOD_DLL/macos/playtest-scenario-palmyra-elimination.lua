-- Native method surface: GameCore
-- Inputs: contact/war, a funded Giant Death Robot and legal adjacent staging.
-- Actual combat/capture eliminates the old owner. No city damage, ownership,
-- freshwater, alive state or processing flags are assigned by this scenario.
local mode=assert(LekmodScenarioParameters.mode)
assert(mode=="loss"or mode=="gain"or mode=="duplicate")
LekmodScenario={name="palmyra-elimination",items={"palmyra-elimination-prerequisites","palmyra-elimination-capture","palmyra-elimination-callback-owner","palmyra-elimination-water","palmyra-elimination-next-turn","palmyra-elimination-advisor-path"}}
local phase,oldOwner,newOwner,x,y,attacker,reply,captured,captureTurn="init"
local expected,controls={},{}
local attempts,ownerTurns,captureOwnerTurns=0,0,nil
local selecting,pending=nil,nil
local advisorConfirmed=0
LuaEvents.LekmodAdvisorAttackConfirmed.Add(function(index,owner,unit)
 assert(mode=="loss"and index==Map.GetPlot(x,y):GetPlotIndex()and owner==newOwner and unit==attacker)
 advisorConfirmed=advisorConfirmed+1;LekmodScenarioEvent("original-advisor-confirm-callback",{index=index,owner=owner,unit=unit})
end)
local palmyra=GameInfoTypes.CIVILIZATION_PALMYRA
local function naturalFresh(q)
 if q:IsWater()or q:IsImpassable()or q:IsMountain()then return false end
 if q:IsRiver()then return true end
 local function source(p)
  if not p then return false end
  if p:IsLake()then return true end
  local f=GameInfo.Features[p:GetFeatureType()]
  return f and f.AddsFreshWater or false
 end
 if source(q)then return true end
 for d=0,5 do if source(Map.PlotDirection(q:GetX(),q:GetY(),d))then return true end end
 return false
end
local function neighbors(c)
 local rows={}
 for d=0,5 do local q=Map.PlotDirection(c:GetX(),c:GetY(),d)
  if q then rows[#rows+1]={index=q:GetPlotIndex(),water=q:IsWater(),natural=naturalFresh(q),fresh=q:IsFreshWater()}end
 end
 return rows
end
function LekmodScenario.snapshot(player)
 local owners,plots={},{}
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
  if p and p:IsEverAlive()then
   local cities={}
   for c in p:Cities()do
    cities[c:GetID()]={x=c:GetX(),y=c:GetY(),puppet=c:IsPuppet(),original=c:GetOriginalOwner()}
    for _,q in ipairs(neighbors(c))do plots[q.index]={water=q.water,natural=q.natural,fresh=q.fresh}end
   end
   owners[id]={alive=p:IsAlive(),civilization=p:GetCivilizationType(),cities=cities}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners,plots=plots,winner=Game.GetWinner()}
end
LuaEvents.LekmodCaptureChoiceDone.Add(function(kind,id)reply={kind=kind,id=id}end)
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
 if cx==x and cy==y then
  assert(not captured,"target captured more than once")
  captured={old=old,new=new,capital=capital,conquest=conquest,old_alive=Players[old]:IsAlive(),old_cities=Players[old]:GetNumCities()}
  captureTurn=Game.GetGameTurn();captureOwnerTurns=ownerTurns;LekmodScenarioEvent("native-eliminating-capture",captured)
 end
end)
local function stageAttacker()
 local p=Players[newOwner];local tile
 for d=0,5 do local q=Map.PlotDirection(x,y,d)
  if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end
 end
 assert(tile,"no legal adjacent attack tile")
 p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1);p:ChangeGold(1000)
 local birth=p:IsHuman()and p:GetCapitalCity():Plot()or tile
 local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,birth:GetX(),birth:GetY()));attacker=u:GetID()
 if p:IsHuman()then u:SetXY(tile:GetX(),tile:GetY(),false,true,false,false)end
 assert(u:GetX()==tile:GetX()and u:GetY()==tile:GetY())
 LekmodScenarioEvent("fixture-setup",{operation="provided-adjacent-attacker-and-upkeep",birth_x=birth:GetX(),birth_y=birth:GetY(),owner=newOwner,unit=attacker,x=tile:GetX(),y=tile:GetY(),uranium_added=1,gold_added=1000})
 return u
end
local function attack()
 local p=Players[newOwner]
 if not attacker then stageAttacker();if p:IsHuman()then return false end end
 local u=p:GetUnitByID(attacker)
 assert(u and not u:IsDead(),"provided attacker was lost")
 local target=Map.GetPlot(x,y)
 if u:IsBusy()or target:IsFighting()then return false end
 if u:GetMoves()<=0 or not u:IsCanAttackWithMoveNow()then return "turn"end
 if p:IsHuman()then
  if pending then
   local last=u:LastMissionPlot()
   LekmodScenarioEvent("human-attack-observation",{active_player=Game.GetActivePlayer(),turn_active=p:IsTurnActive(),unit=attacker,x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),city_damage=target:GetPlotCity():GetDamage(),can_start=u:CanStartMission(MissionTypes.MISSION_MOVE_TO,x,y),last_x=last and last:GetX()or -1,last_y=last and last:GetY()or -1})
   local changed=u:GetMoves()~=pending.moves or u:GetDamage()~=pending.damage or target:GetPlotCity():GetDamage()~=pending.city_damage
   if not LekmodScenarioAwait("palmyra-human-attack-result",changed)then return false end
   pending=nil;selecting=nil
  end
  if not selecting then UI.SelectUnit(u);selecting=true;return false end
  local selected=UI.GetHeadSelectedUnit()
  if not LekmodScenarioAwait("palmyra-human-selection",selected and selected:GetOwner()==newOwner and selected:GetID()==attacker)then return false end
  assert(target:IsVisible(p:GetTeam(),false),"staged attacker has not revealed target")
 end
 attempts=attempts+1;assert(attempts<=4,"bounded capture exceeded four normal attacks")
 assert(u:CanMoveOrAttackInto(target),"capture attack is illegal")
 if p:IsHuman()then
  LuaEvents.LekmodCaptureChoice("puppet")
  LuaEvents.LekmodAdvisorAttackConfirm(target:GetPlotIndex(),newOwner,attacker)
  pending={moves=u:GetMoves(),damage=u:GetDamage(),city_damage=target:GetPlotCity():GetDamage()}
  LekmodScenarioEvent("normal-human-attack-command",{unit=attacker,attempt=attempts,turn=Game.GetGameTurn(),before=pending,active_player=Game.GetActivePlayer(),turn_active=p:IsTurnActive(),can_start=u:CanStartMission(MissionTypes.MISSION_MOVE_TO,x,y)})
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,x,y,0,false,false)
 else
  assert(p:IsTurnActive());u:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
 end
 return false
end
GameEvents.PlayerDoTurn.Add(function(id)
 if id==newOwner then
  ownerTurns=ownerTurns+1
  if phase=="capture"and not captured and not Players[id]:IsHuman()then attack()end
 end
end)
local function verifyWater()
 for _,row in ipairs(expected)do
  local q=Map.GetPlotByIndex(row.index)
  local want=mode~="loss"and not row.water or row.natural
  assert(q:IsFreshWater()==want,"freshwater differs at plot "..row.index.." expected="..tostring(want).." actual="..tostring(q:IsFreshWater()))
 end
 for index,want in pairs(controls)do assert(Map.GetPlotByIndex(index):IsFreshWater()==want,"unrelated freshwater changed")end
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(player:GetID()==0)
  if mode=="duplicate"then assert(Players[1]:GetCivilizationType()==palmyra and Players[2]:GetCivilizationType()==palmyra)
  else assert(Players[8]:GetCivilizationType()==palmyra)end
  assert(not Game.IsOption(GameOptionTypes.GAMEOPTION_COMPLETE_KILLS))
  newOwner=mode=="duplicate"and 2 or(mode=="loss"and 0 or 8)
  oldOwner=mode=="duplicate"and 1 or 8
  if mode=="gain"then
   oldOwner=nil
   for id=1,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
    if id~=8 and p and p:IsAlive()and p:GetNumCities()==1 then
     local rows=neighbors(p:GetCapitalCity());local dry,natural=0,0
     for _,q in ipairs(rows)do if not q.water and not q.natural then dry=dry+1 end;if q.natural then natural=natural+1 end end
     if dry>0 and natural>0 then oldOwner=id;break end
    end
   end
  end
  assert(oldOwner,"no one-city foreign target with dry and natural-fresh neighbors")
  local old=Players[oldOwner];assert(old:GetNumCities()==1 and old:IsAlive())
  local c=assert(old:GetCapitalCity());x,y=c:GetX(),c:GetY();expected=neighbors(c)
  local dry,natural,water=0,0,0
  for _,q in ipairs(expected)do
   if q.water then water=water+1 elseif not q.natural then dry=dry+1 end
   if q.natural then natural=natural+1 end
   assert(q.fresh==(mode~="gain"and not q.water or q.natural),"starting freshwater mismatches fixture owner")
  end
  assert(dry>0,"no naturally dry target neighbors")
  for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
   if p and p:IsAlive()and id~=oldOwner then for city in p:Cities()do
    if Map.PlotDistance(x,y,city:GetX(),city:GetY())>3 then for _,q in ipairs(neighbors(city))do controls[q.index]=q.fresh end end
   end end
  end
  LekmodScenarioRecord("palmyra-elimination-prerequisites","PASS","old="..oldOwner.." new="..newOwner.." dry="..dry.." natural="..natural.." water="..water)
  local team=Teams[Players[newOwner]:GetTeam()];local other=old:GetTeam()
  team:Meet(other,true);assert(team:CanDeclareWar(other))
  if newOwner==0 then Network.SendChangeWar(other,true)
  else team:DeclareWar(other);LekmodScenarioEvent("fixture-setup",{operation="provided-AI-war",new_owner=newOwner,old_owner=oldOwner})end
  phase="war";return false
 elseif phase=="war"then
  if not LekmodScenarioAwait("palmyra-elimination-war",Teams[Players[newOwner]:GetTeam()]:IsAtWar(Players[oldOwner]:GetTeam()))then return false end
  phase="capture"
 elseif phase=="capture"then
  if not captured then
   if newOwner~=0 then return "turn"end
   return attack()
  end
  if newOwner==0 and not reply then return false end
  local c=assert(Map.GetPlot(x,y):GetPlotCity())
  assert(c:GetOwner()==newOwner and captured.old==oldOwner and captured.new==newOwner and captured.capital and captured.conquest)
  if newOwner==0 then assert(reply.kind=="puppet"and c:IsPuppet())end
  assert(not Players[oldOwner]:IsAlive()and Players[oldOwner]:GetNumCities()==0 and Game.GetWinner()==-1)
  LekmodScenarioRecord("palmyra-elimination-capture","PASS","normal combat captured the last original capital; other civilizations keep the game active")
  assert(not captured.old_alive and captured.old_cities==0,"old owner was not eliminated at the capture callback")
  LekmodScenarioRecord("palmyra-elimination-callback-owner","PASS","old owner already dead at native CityCaptureComplete; current owner alive")
  assert(advisorConfirmed==(mode=="loss"and 1 or 0),"advisor callback count differs")
  LekmodScenarioRecord("palmyra-elimination-advisor-path","PASS",mode=="loss"and "original city-attack Confirm callback; DontShowAgain remains unchecked"or "AI capture needs no human advisor callback")
  verifyWater();LekmodScenarioRecord("palmyra-elimination-water","PASS","trait follows current owner; natural freshwater and unrelated-city controls preserved")
  phase="settle";return "turn"
 elseif phase=="settle"then
  if ownerTurns<=captureOwnerTurns then return "turn"end
  assert(Game.GetGameTurn()>captureTurn,"normal post-capture owner turn not observed")
  assert(Map.GetPlot(x,y):GetPlotCity():GetOwner()==newOwner and not Players[oldOwner]:IsAlive())
  verifyWater();LekmodScenarioRecord("palmyra-elimination-next-turn","PASS","water and elimination remain correct after ordinary turn; no manual handler invocation")
  return true
 end
 return false
end
