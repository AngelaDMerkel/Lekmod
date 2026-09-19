-- Real human/AI gift commands with explicitly supplied coastal positions and
-- one fresh Roman AI gift ship. Never set promotions or movement budgets.
LekmodScenario={name="polynesia-gifts",items={"polynesia-gift-away","polynesia-gift-incoming","polynesia-gift-ocean-move"}}
local phase,humanID,outgoingID,incomingSource,incomingID,aiError,turn,target,moves="init"
local blocked=GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE
local function state(u)return {id=u:GetID(),owner=u:GetOwner(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),blocked=u:IsHasPromotion(blocked)}end
local function ownedCoast(owner)
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetOwner()==owner and p:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and not p:IsLake()and not p:IsCity()and p:GetNumUnits()==0 and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then return p end
 end
 error("no empty owned coastal gift staging tile")
end
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,upgrade)
 if oldOwner==0 and oldID==humanID and newOwner==2 and not upgrade then outgoingID=newID end
 if oldOwner==2 and oldID==incomingSource and newOwner==0 and not upgrade then incomingID=newID end
 LekmodScenarioEvent("polynesia-gift-conversion",{old_owner=oldOwner,new_owner=newOwner,old_id=oldID,new_id=newID,upgrade=upgrade})
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=2 or phase~="AI-gift-pending"then return end
 phase="AI-gift-issued"
 local ok,err=pcall(function()
  local p=Players[2];assert(not p:IsHuman()and p:IsTurnActive(),"Roman gift requires its real AI turn")
  local c=assert(p:GetCapitalCity());local u=assert(p:InitUnit(GameInfoTypes.UNIT_GALLEASS,c:GetX(),c:GetY()));incomingSource=u:GetID()
  assert(u:IsHasPromotion(blocked),"fresh Roman gift ship must carry its normal ocean restriction")
  local plot=ownedCoast(0);u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="provided-Roman-owner-turn-gift-ship-and-position",state=state(u)})
  assert(u:CanGift(),"normal Roman AI gift is ineligible")
  u:DoCommand(CommandTypes.COMMAND_GIFT,-1,-1)
  assert(incomingID,"normal AI gift conversion not observed")
 end)
 if not ok then aiError=tostring(err)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local units={}
  for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_GALLEASS and not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
  owners[owner]={civilization=p:GetCivilizationType(),astronomy=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_ASTRONOMY),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 assert(not aiError,aiError)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_POLYNESIA and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires prepared Polynesian upgrade fixture")
 if phase=="init"then
  local u
  for v in player:Units()do if v:GetUnitType()==GameInfoTypes.UNIT_GALLEASS and not v:IsDelayedDeath()then u=v;break end end
  assert(u and not u:IsHasPromotion(blocked),"requires corrected ocean-capable human Galleass");humanID=u:GetID()
  local team=Teams[player:GetTeam()];if not team:IsHasMet(Players[2]:GetTeam())then team:Meet(Players[2]:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="provided-contact",other=2})end
  assert(not team:IsAtWar(Players[2]:GetTeam()),"gifts require peace")
  local plot=ownedCoast(2);u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="position-human-gift-ship",state=state(u)})
  assert(u:CanGift(),"normal human gift unavailable");UI.SelectUnit(u)
  for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="COMMAND_GIFT"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="given-away";return false end end
  error("normal gift action missing")
 elseif phase=="given-away"then
  if not LekmodScenarioAwait("human-gift-transferred",outgoingID~=nil)then return false end
  local u=assert(Players[2]:GetUnitByID(outgoingID));local old=player:GetUnitByID(humanID)
  assert(u:GetOwner()==2 and u:IsHasPromotion(blocked)and(not old or old:IsDead()or old:IsDelayedDeath()),"foreign gift recipient inherited inappropriate Polynesian ocean access")
  LekmodScenarioEvent("polynesia-gift-away-observed",state(u));LekmodScenarioRecord("polynesia-gift-away","PASS","normal human gift; Roman recipient restores standard ocean restriction")
  turn=Game.GetGameTurn();phase="AI-gift-pending";return "turn"
 elseif phase=="AI-gift-pending"or phase=="AI-gift-issued"then
  if not incomingID then assert(Game.GetGameTurn()-turn<2,"Roman gift did not finish within ordinary owner-turn bound");return "turn"end
  local u=assert(player:GetUnitByID(incomingID));assert(not u:IsHasPromotion(blocked)and u:GetOwner()==0,"received Roman ship retained ocean restriction")
  assert(not Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_ASTRONOMY),"gift test unexpectedly acquired Astronomy")
  LekmodScenarioEvent("polynesia-incoming-gift-observed",state(u));LekmodScenarioRecord("polynesia-gift-incoming","PASS","normal AI-owner-turn gift; new Polynesian owner clears inherited restriction")
  local coast,ocean
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if p:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and not p:IsLake()and p:GetOwner()==-1 and p:GetNumUnits()==0 and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then
    for d=0,5 do local n=Map.PlotDirection(p:GetX(),p:GetY(),d)
     if n and n:GetTerrainType()==GameInfoTypes.TERRAIN_OCEAN and n:GetOwner()==-1 and n:GetNumUnits()==0 and n:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then coast=p;ocean=n;break end
    end
   end
   if coast then break end
  end
  assert(coast and ocean);coast:SetRevealed(player:GetTeam(),true);ocean:SetRevealed(player:GetTeam(),true);u:SetXY(coast:GetX(),coast:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="position-received-ship-and-reveal-ocean-boundary",coast_x=coast:GetX(),coast_y=coast:GetY(),ocean_x=ocean:GetX(),ocean_y=ocean:GetY()})
  assert(u:CanMoveOrAttackInto(ocean)and u:GetMoves()>0,"received ship cannot legally enter ocean after normal move refresh")
  target={x=ocean:GetX(),y=ocean:GetY()};moves=u:GetMoves();UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,ocean:GetX(),ocean:GetY(),0,false,false);phase="moved";return false
 elseif phase=="moved"then
  local u=assert(player:GetUnitByID(incomingID))
  if not LekmodScenarioAwait("gift-ship-ocean-move",u:GetX()==target.x and u:GetY()==target.y)then return false end
  assert(u:GetPlot():GetTerrainType()==GameInfoTypes.TERRAIN_OCEAN and u:GetMoves()<moves and not u:IsHasPromotion(blocked),"received ship movement outcome differs")
  LekmodScenarioRecord("polynesia-gift-ocean-move","PASS","normal synchronized received-ship ocean entry spent movement; no Astronomy")
  LekmodScenarioEvent("polynesia-gifts-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
