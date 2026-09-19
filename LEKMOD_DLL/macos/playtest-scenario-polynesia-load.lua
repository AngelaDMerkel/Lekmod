-- Read the preserved failed upgrade save, then use normal movement if legal.
-- No units, promotions, technologies, coordinates or move budgets are supplied.
LekmodScenario={name="polynesia-load",items={"polynesia-saved-restrictions","polynesia-saved-roman-control","polynesia-saved-ocean-move"}}
local phase,shipID,budget,polyCorrect,romanCorrect="init"
local blocked=GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local units={}
  for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_GALLEASS and not u:IsDelayedDeath()then units[u:GetID()]={owner=owner,x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),blocked=u:IsHasPromotion(blocked)}end end
  owners[owner]={units=units,astronomy=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_ASTRONOMY)}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(Game.GetGameTurn()==83 and player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_POLYNESIA,"requires preserved failed upgrade fixture")
  local human,ai,roman
  for owner=0,2 do for u in Players[owner]:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_GALLEASS and not u:IsDelayedDeath()then
   if owner==0 then human=u elseif owner==1 then ai=u else roman=u end
  end end end
  assert(human and ai and roman and not Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_ASTRONOMY))
  polyCorrect=not human:IsHasPromotion(blocked)and not ai:IsHasPromotion(blocked);romanCorrect=roman:IsHasPromotion(blocked)
  LekmodScenarioEvent("polynesia-saved-ships-loaded",LekmodScenario.snapshot(player))
  assert(human:GetX()==5 and human:GetY()==2,"source ship not at preserved coastal boundary")
  local target=Map.GetPlot(6,2);assert(target:GetTerrainType()==GameInfoTypes.TERRAIN_OCEAN and target:GetNumUnits()==0)
  shipID=human:GetID();budget=human:GetMoves()
  if human:CanMoveOrAttackInto(target)then
   assert(budget>0);UI.SelectUnit(human)
   Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,6,2,0,false,false);phase="moved"
  else phase="blocked"end
  return false
 end
 local moved=phase=="moved";local u=assert(player:GetUnitByID(shipID))
 if moved and not LekmodScenarioAwait("saved-ship-ocean-entry",u:GetX()==6 and u:GetY()==2)then return false end
 if moved then assert(u:GetMoves()<budget and u:GetPlot():GetTerrainType()==GameInfoTypes.TERRAIN_OCEAN)end
 LekmodScenarioRecord("polynesia-saved-restrictions",polyCorrect and"PASS"or"FAIL","loaded human/AI ship restrictions cleared="..tostring(polyCorrect))
 LekmodScenarioRecord("polynesia-saved-roman-control",romanCorrect and"PASS"or"FAIL","Roman saved ship restriction retained")
 LekmodScenarioRecord("polynesia-saved-ocean-move",moved and"PASS"or"FAIL","normal saved-ship ocean move="..tostring(moved).."; no turn or setup mutation")
 return true
end
