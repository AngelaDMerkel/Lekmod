-- Native method surface: GameCore
-- Read the normal-start fixture only. No reward or setup mutation.
LekmodScenario={name="global-team-initial",items={"global-initial-capital-award","global-initial-owner-tech-controls"}}
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local cities={}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),ulug=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ULUG),wales=c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT),mongol=c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT),union=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ECONOMIC_UNION_GOLD)}end
  owners[owner]={team=p:GetTeam(),civilization=p:GetCivilizationType(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer()and player:GetID()==0 and player:IsHuman()and not Players[1]:IsHuman()and not Players[2]:IsHuman())
 assert(player:GetTeam()==7 and Players[1]:GetTeam()==7 and Players[2]:GetTeam()==0)
 assert(Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TIMURIDS)
 local n=Players[2]:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_ULUG)
 LekmodScenarioRecord("global-initial-capital-award",n==1 and"PASS"or"FAIL","ordinary Timurids owner2/team0 capital requires Ulug1; actual="..n)
 assert(not Teams[7]:IsHasTech(GameInfoTypes.TECH_ANIMAL_HUSBANDRY)and not Teams[7]:IsHasTech(GameInfoTypes.TECH_CHIVALRY))
 for owner=0,2 do local c=Players[owner]:GetCapitalCity()
  assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT)==0 and c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT)==0 and c:GetNumRealBuilding(GameInfoTypes.BUILDING_ECONOMIC_UNION_GOLD)==0)
  if owner~=2 then assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_ULUG)==0)end
 end
 LekmodScenarioRecord("global-initial-owner-tech-controls","PASS","no required tech/policy and foreign-civilization capitals do not receive other configured markers")
 return true
end
