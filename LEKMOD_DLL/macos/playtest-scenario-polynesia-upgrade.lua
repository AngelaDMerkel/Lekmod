-- Supplied coastal homes, Compass/resources/gold and Galleys. Upgrades use
-- normal human/AI commands; promotion state and ocean movement are outcomes.
LekmodScenario={name="polynesia-upgrade",items={"polynesia-fresh-ocean-access","polynesia-paid-upgrades","polynesia-converted-ocean-access","polynesia-roman-ocean-control","polynesia-ocean-movement"}}
local phase,aiError,turn,humanGold,humanPrice,freshCorrect,upgradeCorrect,romanCorrect,moveTarget,moveBudget="init"
local ships,homes,pending={},{},{}
local blocked=GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE
local function shipState(u)return {id=u:GetID(),owner=u:GetOwner(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),blocked=u:IsHasPromotion(blocked),astronomy_block=u:IsHasPromotion(GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE_UNTIL_ASTRONOMY)}end
local function coastalCity(owner,near)
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if Map.PlotDistance(near:GetX(),near:GetY(),p:GetX(),p:GetY())<=16 and p:GetOwner()==-1 and p:GetNumUnits()==0 and Players[owner]:CanFound(p:GetX(),p:GetY())then
   local water=false;for d=0,5 do local n=Map.PlotDirection(p:GetX(),p:GetY(),d);if n and n:IsWater()and not n:IsLake()and n:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then water=true end end
   if water then Players[owner]:Found(p:GetX(),p:GetY());local c=assert(p:GetPlotCity());assert(c:IsCoastal(10));LekmodScenarioEvent("fixture-setup",{operation="provided-coastal-city",owner=owner,id=c:GetID(),x=c:GetX(),y=c:GetY()});return c end
  end
 end
 error("no legal supplied coastal home")
end
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,upgrade)
 local r=ships[oldOwner]
 if r and r.id==oldID then assert(oldOwner==newOwner and upgrade,"unexpected conversion instead of upgrade");r.id=newID;r.upgraded=true;LekmodScenarioEvent("polynesia-native-upgrade",{owner=newOwner,old_id=oldID,new_id=newID,upgrade=upgrade})end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if not pending[owner]then return end;pending[owner]=nil
 local ok,err=pcall(function()
  local p=Players[owner];local r=ships[owner];local u=assert(p:GetUnitByID(r.id))
  if u:IsDead()or u:IsDelayedDeath()then
   local old=r.id;local site
   for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
    if plot:GetOwner()==owner and plot:IsWater()and not plot:IsLake()and plot:GetNumUnits()==0 and plot:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then site=plot;break end
   end
   assert(site,"no empty owned coastal site for fresh AI upgrade input")
   u=assert(p:InitUnit(GameInfoTypes.UNIT_GALLEY,site:GetX(),site:GetY()));r.id=u:GetID()
   LekmodScenarioEvent("fixture-setup",{operation="provided-AI-owner-turn-upgrade-Galley",owner=owner,old_pending_deletion=old,state=shipState(u)})
  end
  local occupants={};local plot=u:GetPlot()
  for i=0,plot:GetNumUnits()-1 do local v=plot:GetUnit(i);occupants[#occupants+1]={owner=v:GetOwner(),id=v:GetID(),type=v:GetUnitType(),domain=v:GetDomainType()}end
  local resources={}
  for resource in GameInfo.Resources()do
   local needed=u:GetNumResourceNeededToUpgrade(resource.ID);local available=p:GetNumResourceAvailable(resource.ID,true)
   if needed>0 or available~=0 then resources[resource.Type]={needed=needed,available=available}end
  end
  LekmodScenarioEvent("AI-upgrade-detailed-gates",{owner=owner,player_team=p:GetTeam(),unit_team=u:GetTeam(),direct_compass=Teams[u:GetTeam()]:IsHasTech(GameInfoTypes.TECH_COMPASS),visible=u:CanUpgradeRightNow(1),dead=u:IsDead(),delayed=u:IsDelayedDeath(),friendly_stack=plot:GetNumFriendlyUnitsOfType(u),stack_limit=GameDefines.PLOT_UNIT_LIMIT,resources=resources})
  LekmodScenarioEvent("AI-upgrade-eligibility",{owner=owner,active=p:IsTurnActive(),can_upgrade=u:CanUpgradeRightNow(),gold=p:GetGold(),price=u:UpgradePrice(GameInfoTypes.UNIT_GALLEASS),target=u:GetUpgradeUnitType(),compass=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_COMPASS),plot_owner=plot:GetOwner(),occupants=occupants,state=shipState(u)})
  assert(not p:IsHuman()and p:IsTurnActive()and u:CanUpgradeRightNow(),"AI paid upgrade unavailable on real owner turn")
  local price=u:UpgradePrice(GameInfoTypes.UNIT_GALLEASS);local gold=p:GetGold()
  u:DoCommand(CommandTypes.COMMAND_UPGRADE,-1,-1)
  assert(r.upgraded and p:GetGold()==gold-price,"AI conversion or exact upgrade payment missing")
  r.blocked_after_upgrade=p:GetUnitByID(r.id):IsHasPromotion(blocked)
  LekmodScenarioEvent("AI-paid-ship-upgrade",{owner=owner,price=price,before=gold,after=p:GetGold(),state=shipState(assert(p:GetUnitByID(r.id)))})
 end)
 if not ok then aiError=tostring(err)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local units={}
  for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_GALLEY or u:GetUnitType()==GameInfoTypes.UNIT_GALLEASS then units[u:GetID()]=shipState(u)end end
  owners[owner]={civilization=p:GetCivilizationType(),gold=p:GetGold(),astronomy=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_ASTRONOMY),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 assert(not aiError,aiError)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_POLYNESIA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_POLYNESIA and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires humanPolynesia/AI Polynesia/AI Rome")
 local capital=player:GetCapitalCity()
 if phase=="init"and not capital then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false end end
  end end;error("normal initial Found action unavailable")
 end
 if phase=="founding"then if not LekmodScenarioAwait("polynesian-capital-founded",capital~=nil)then return false end;phase="init"end
 if phase=="init"then
  homes[0]=capital:IsCoastal(10)and capital:GetID()or coastalCity(0,capital):GetID()
  homes[1]=coastalCity(1,capital):GetID();homes[2]=coastalCity(2,capital):GetID()
  for owner=0,2 do
   local p=Players[owner];LekmodScenarioGrantTech(p,"TECH_COMPASS")
   assert(not Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_ASTRONOMY),"ocean test must precede Astronomy")
   for row in GameInfo.Unit_ResourceQuantityRequirements{UnitType="UNIT_GALLEASS"}do
    local resource=GameInfoTypes[row.ResourceType];local amount=row.Cost-p:GetNumResourceAvailable(resource,true)
    if amount>0 then p:ChangeNumResourceTotal(resource,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-upgrade-resource",owner=owner,type=row.ResourceType,added=amount})end
   end
   local c=p:GetCityByID(homes[owner]);local u=assert(p:InitUnit(GameInfoTypes.UNIT_GALLEY,c:GetX(),c:GetY()));ships[owner]={id=u:GetID()}
   assert(u:GetUpgradeUnitType()==GameInfoTypes.UNIT_GALLEASS,"Galley upgrade target differs")
   local price=u:UpgradePrice(GameInfoTypes.UNIT_GALLEASS);p:ChangeGold(price+100)
   LekmodScenarioEvent("fixture-setup",{operation="provided-Galley-and-upgrade-gold",owner=owner,added_gold=price+100,state=shipState(u)})
  end
  for c in player:Cities()do Game.CityPushOrder(c,OrderTypes.ORDER_MAINTAIN,GameInfoTypes.PROCESS_WEALTH,false,true,true)end
  freshCorrect=not player:GetUnitByID(ships[0].id):IsHasPromotion(blocked)and not Players[1]:GetUnitByID(ships[1].id):IsHasPromotion(blocked)and Players[2]:GetUnitByID(ships[2].id):IsHasPromotion(blocked)
  LekmodScenarioEvent("polynesia-fresh-ships",LekmodScenario.snapshot(player));phase="human-upgrade";return false
 elseif phase=="human-upgrade"then
  local u=assert(player:GetUnitByID(ships[0].id));assert(u:CanUpgradeRightNow(),"normal human paid upgrade unavailable")
  humanPrice=u:UpgradePrice(GameInfoTypes.UNIT_GALLEASS);humanGold=player:GetGold();UI.SelectUnit(u)
  for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="COMMAND_UPGRADE"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="human-upgraded";return false end end
  error("human upgrade action missing")
 elseif phase=="human-upgraded"then
  if not LekmodScenarioAwait("human-ship-upgraded",ships[0].upgraded)then return false end
  assert(player:GetGold()==humanGold-humanPrice,"human upgrade cost mismatch")
  ships[0].blocked_after_upgrade=player:GetUnitByID(ships[0].id):IsHasPromotion(blocked)
  LekmodScenarioEvent("human-paid-ship-upgrade",{price=humanPrice,before=humanGold,after=player:GetGold(),state=shipState(player:GetUnitByID(ships[0].id))})
  pending[1]=true;pending[2]=true;turn=Game.GetGameTurn();phase="AI-upgrades";return "turn"
 elseif phase=="AI-upgrades"then
  if not ships[1].upgraded or not ships[2].upgraded then assert(Game.GetGameTurn()-turn<2,"AI upgrades did not run within owner-turn bound");return "turn"end
  local a=assert(player:GetUnitByID(ships[0].id));local b=assert(Players[1]:GetUnitByID(ships[1].id));local c=assert(Players[2]:GetUnitByID(ships[2].id))
  assert(a:GetUnitType()==GameInfoTypes.UNIT_GALLEASS and b:GetUnitType()==GameInfoTypes.UNIT_GALLEASS and c:GetUnitType()==GameInfoTypes.UNIT_GALLEASS,"converted unit type mismatch")
  upgradeCorrect=not ships[0].blocked_after_upgrade and not ships[1].blocked_after_upgrade;romanCorrect=ships[2].blocked_after_upgrade and c:IsHasPromotion(blocked)
  LekmodScenarioEvent("polynesia-after-upgrades",LekmodScenario.snapshot(player))
  local coast,ocean
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if p:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and not p:IsLake()and p:GetOwner()==-1 and p:GetNumUnits()==0 and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then
    for d=0,5 do local n=Map.PlotDirection(p:GetX(),p:GetY(),d)
     if n and n:GetTerrainType()==GameInfoTypes.TERRAIN_OCEAN and n:GetOwner()==-1 and n:GetNumUnits()==0 and n:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then coast=p;ocean=n;break end
    end
   end
   if coast then break end
  end
  assert(coast and ocean,"no legal ocean boundary for movement")
  coast:SetRevealed(player:GetTeam(),true);ocean:SetRevealed(player:GetTeam(),true);a:SetXY(coast:GetX(),coast:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="position-upgraded-ship-and-reveal-ocean-boundary",coast_x=coast:GetX(),coast_y=coast:GetY(),ocean_x=ocean:GetX(),ocean_y=ocean:GetY()})
  moveTarget={x=ocean:GetX(),y=ocean:GetY()};moveBudget=a:GetMoves()
  if a:CanMoveOrAttackInto(ocean)then
   assert(moveBudget>0,"normal owner turn did not refresh upgraded ship moves")
   UI.SelectUnit(a);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,ocean:GetX(),ocean:GetY(),0,false,false);phase="moved";return false
  end
  phase="blocked";return false
 elseif phase=="moved"or phase=="blocked"then
  local a=assert(player:GetUnitByID(ships[0].id));local moved=phase=="moved"
  if moved and not LekmodScenarioAwait("real-ocean-entry",a:GetX()==moveTarget.x and a:GetY()==moveTarget.y)then return false end
  if moved then assert(a:GetPlot():GetTerrainType()==GameInfoTypes.TERRAIN_OCEAN and a:GetMoves()<moveBudget,"movement did not enter ocean and spend movement")end
  LekmodScenarioRecord("polynesia-fresh-ocean-access",freshCorrect and"PASS"or"FAIL","native fresh human/AI Polynesia clear; Roman restriction retained")
  LekmodScenarioRecord("polynesia-paid-upgrades","PASS","three real human/AI paid Galley-to-Galleass upgrades, conversions and prices verified")
  LekmodScenarioRecord("polynesia-converted-ocean-access",upgradeCorrect and"PASS"or"FAIL","post-conversion human/AI restrictions cleared="..tostring(upgradeCorrect))
  LekmodScenarioRecord("polynesia-roman-ocean-control",romanCorrect and"PASS"or"FAIL","Roman upgraded ship remains restricted")
  LekmodScenarioRecord("polynesia-ocean-movement",moved and"PASS"or"FAIL","normal synchronized movement into ocean="..tostring(moved).."; no Astronomy")
  LekmodScenarioEvent("polynesia-upgrade-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
