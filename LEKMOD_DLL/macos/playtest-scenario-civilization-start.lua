-- Normal single-player setup and first owner turns only. No city, unit, yield,
-- technology, policy or elapsed-turn value is supplied by this scenario.
LekmodScenario={name="civilization-start",items={"civilization-roster","civilization-player-colors","civilization-starting-units","civilization-owner-round","civilization-native-founding"}}
local began,owners,founded=nil,{},{}
GameEvents.PlayerDoTurn.Add(function(owner)owners[owner]=(owners[owner]or 0)+1 end)
GameEvents.PlayerCityFounded.Add(function(owner)founded[owner]=(founded[owner]or 0)+1 end)
function LekmodScenario.snapshot(player)
 local players={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then
   local cities,units={},{}
   for c in p:Cities()do
    local buildings,yields={},{}
    for b in GameInfo.Buildings()do local n=c:GetNumRealBuilding(b.ID);if n>0 then buildings[b.ID]=n end end
    for _,name in ipairs({"YIELD_FOOD","YIELD_PRODUCTION","YIELD_GOLD","YIELD_SCIENCE","YIELD_CULTURE","YIELD_FAITH"})do yields[name]=c:GetYieldRateTimes100(GameInfoTypes[name])end
    cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),food=c:GetFoodTimes100(),production=c:GetProductionTimes100(),buildings=buildings,yields=yields}
   end
   for u in p:Units()do if not u:IsDelayedDeath()then
    local promotions={};for info in GameInfo.UnitPromotions()do if u:IsHasPromotion(info.ID)then promotions[info.ID]=true end end
    units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),promotions=promotions}
   end end
   players[owner]={civilization=p:GetCivilizationType(),leader=p:GetLeaderType(),color=p:GetPlayerColor(),team=p:GetTeam(),gold=p:GetGold(),faith=p:GetFaith(),culture=p:GetJONSCulture(),happiness=p:GetExcessHappiness(),cities=cities,units=units}
  end
 end
 return {turn=Game.GetGameTurn(),elapsed=Game.GetElapsedGameTurns(),world=Map.GetWorldSize(),speed=Game.GetGameSpeedType(),era=Game.GetStartEra(),players=players}
end
function LekmodScenario.step(player)
 if not began then
  began=Game.GetGameTurn()
  assert(not Game.IsGameMultiPlayer()and Game.GetAIAutoPlay()==0)
  local expected={[0]="__TEST_CIVILIZATION__"};for slot,kind in pairs(__TEST_SLOT_CIVILIZATIONS__)do expected[slot]=kind end
  local expectedTeams=__TEST_SLOT_TEAMS__
  local count,colors=0,{}
  for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
   if p and p:IsAlive()then
    count=count+1;local kind=assert(expected[owner],"unexpected living major slot")
    assert(p:GetCivilizationType()==GameInfoTypes[kind],"native civilization differs from requested slot")
    assert(p:IsHuman()==(owner==0),"human/AI ownership changed")
    assert(p:GetTeam()==(expectedTeams[owner]or owner),"native team differs from reviewed normal setup")
    local leader=assert(GameInfo.Leaders[p:GetLeaderType()]);assert(leader.ArtDefineTag,"leader scene undefined")
    local color=p:GetPlayerColor();local entry=assert(GameInfo.PlayerColors[color],"native color row missing")
    assert(GameInfo.Colors[entry.PrimaryColor]and GameInfo.Colors[entry.SecondaryColor]and GameInfo.Colors[entry.TextColor])
    assert(not colors[color],"resolved player colors collide");colors[color]=true
    assert(p:GetNumUnits()>0,"normal starting units missing")
   end
  end
  assert(count==__TEST_MAJORS__,"requested living major roster differs")
  LekmodScenarioEvent("civilization-initialization",{expected=expected,state=LekmodScenario.snapshot(player)})
  LekmodScenarioRecord("civilization-roster","PASS","all requested civilizations/leaders and human/AI roles match normal setup")
  LekmodScenarioRecord("civilization-player-colors","PASS","distinct existing native color rows and components")
  LekmodScenarioRecord("civilization-starting-units","PASS","every living major has ordinary generated starting units")
 end
 if Game.GetGameTurn()<began+2 then return "turn"end
 local ready=true
 for owner=0,__TEST_MAJORS__-1 do
  assert(owners[owner]and owners[owner]>0,"real owner turn missing")
  if not Players[owner]:GetCapitalCity()or not founded[owner]then ready=false end
 end
 if not ready and Game.GetGameTurn()<began+3 then return "turn"end
 assert(ready,"a civilization has not founded its capital in this bounded fixture; review AI/start conditions")
 assert(Game.GetWinner()==-1)
 LekmodScenarioRecord("civilization-owner-round","PASS","real owner turns observed for every major; ordinary turns="..(Game.GetGameTurn()-began))
 LekmodScenarioRecord("civilization-native-founding","PASS","PlayerCityFounded and surviving capitals observed for every major; no city/unit/yield setup")
 return true
end
