-- Native method surface: GameCore
-- Supplied units, tech, legal staging and budgets; native commands and real owner
-- turns determine upgrades, captures, domain changes, movement and bonus expiry.
local mode=assert(LekmodScenarioParameters.mode)
LekmodScenario={name="maori-lifetime",items={"maori-lifetime-inputs","maori-lifetime-native-action","maori-lifetime-birth-accounting","maori-lifetime-owner-expiry","maori-lifetime-repeat-control"}}
local phase,probe,origin,destination,born,turnCount,expiryCount="init",nil,nil,nil,nil,{},nil
local oldID,newID,upgradeTarget,upgradePrice,secondUpgrade=nil,nil,nil,nil,false
local actor,oldOwner,newOwner,oldWorker,createdWorker,prekill,captureState,captureCount=nil,nil,nil,nil,nil,false,nil,nil
local romeShip
local function state(u)
 return {id=u:GetID(),owner=u:GetOwner(),type=u:GetUnitType(),created=u:GetGameTurnCreated(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),allowance=u:MaxMovesWithStack(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),embarked=u:IsEmbarked()}
end
local function bonus(u)return u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI)or u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN)end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,2 do local p=Players[id];local units={};for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
  owners[id]={civilization=p:GetCivilizationType(),gold=p:GetGold(),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function emptyLand(q)
 return q and not q:IsCity()and not q:IsWater()and not q:IsMountain()and not q:IsImpassable()and q:GetNumUnits()==0
end
local function coast(q)
 return q and q:IsWater()and q:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and q:GetFeatureType()==-1 and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==0)
end
local function create(owner,kind,q)
 local u=assert(Players[owner]:InitUnit(GameInfoTypes[kind],q:GetX(),q:GetY()))
 assert(u:GetX()==q:GetX()and u:GetY()==q:GetY())
 LekmodScenarioEvent("fixture-setup",{operation="provided-unit-and-position",kind=kind,state=state(u)})
 return u
end
local function mission(u,kind,q)
 assert(u:GetMoves()>0);UI.SelectUnit(u)
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,kind,q:GetX(),q:GetY(),0,false,false)
end
local function unitAction(u,kind)
 UI.SelectUnit(u)
 for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type==kind then assert(Game.CanHandleAction(i),"native action unavailable: "..kind);Game.HandleAction(i);return end end
 error("missing action "..kind)
end
local function embarkedOracle(u)
 local p=Players[u:GetOwner()];local team=Teams[p:GetTeam()];local techs=team:GetTeamTechs()
 local moves=GameDefines.EMBARKED_UNIT_MOVEMENT+team:GetExtraMoves(DomainTypes.DOMAIN_LAND)
 -- LEK_EMBARK_VISIBILITY_FIX is enabled in the pinned candidate.
 local sight=math.max(1,GameDefines.EMBARKED_VISIBILITY_RANGE)
 assert((GameInfo.Traits.TRAIT_MANA.ExtraEmbarkMoves or 0)==0)
 for info in GameInfo.Technologies()do if techs:HasTech(info.ID)then moves=moves+(info.EmbarkedMoveChange or 0);sight=sight+(info.EmbarkedSightChange or 0)end end
 for info in GameInfo.Policies()do if p:HasPolicy(info.ID)then moves=moves+(info.EmbarkedExtraMoves or 0)end end
 for info in GameInfo.UnitPromotions()do if u:IsHasPromotion(info.ID)then moves=moves+(info.ExtraNavalMovement or 0);sight=sight+(info.EmbarkExtraVisibility or 0)end end
 return moves*GameDefines.MOVE_DENOMINATOR,sight
end
local function ordinary(u)
 local s=state(u);local info=GameInfo.Units[u:GetUnitType()]
 assert(not s.maori and not s.civilian and s.created==born,"bonus or birth changed after expiry")
 local moves,sight=info.Moves*GameDefines.MOVE_DENOMINATOR,info.BaseSightRange
 if s.embarked then moves,sight=embarkedOracle(u)end
 assert(s.maximum==moves and s.moves>=0 and s.moves<=s.allowance,"expired movement allowance differs")
 assert(s.sight==sight,"expired sight differs")
 return s
end
local function capturedAfterMission()
 local p=Players[newOwner];local u=createdWorker and p:GetUnitByID(createdWorker)
 assert(u and prekill,"native worker capture creation/removal was not observed")
 local old=Players[oldOwner]:GetUnitByID(oldWorker)
 assert(not old or old:IsDead()or old:IsDelayedDeath())
 captureState=state(u);born=captureState.created;captureCount=turnCount[newOwner]or 0
 assert(u:GetUnitType()==GameInfoTypes.UNIT_WORKER and born==Game.GetGameTurn()and u:GetMoves()==0,"captured worker birth/movement differs")
 assert(bonus(u)==(newOwner==0),"capture did not use recipient's own birth promotions")
 if newOwner==0 then assert(u:MaxMoves()==240)else assert(u:MaxMoves()==120)end
 LekmodScenarioEvent("native-captured-worker",captureState)
end
GameEvents.UnitUpgraded.Add(function(owner,old,id,ruin)
 if owner==0 and old==oldID then assert(not ruin);newID=id end
end)
GameEvents.UnitPrekill.Add(function(owner,id)if owner==oldOwner and id==oldWorker then prekill=true end end)
GameEvents.UnitCreated.Add(function(owner,id,x,y)
 if phase=="capturing"and owner==newOwner and x==destination:GetX()and y==destination:GetY()then
  local u=Players[owner]:GetUnitByID(id)
  if u and u:GetUnitType()==GameInfoTypes.UNIT_WORKER then assert(not createdWorker);createdWorker=id end
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 turnCount[owner]=(turnCount[owner]or 0)+1
 if mode=="capture-out"and phase=="capturing"and owner==2 and not captureState then
  assert(Players[2]:IsTurnActive());local u=assert(Players[2]:GetUnitByID(actor));assert(u:CanMoveOrAttackInto(destination))
  u:PushMission(MissionTypes.MISSION_MOVE_TO,destination:GetX(),destination:GetY(),0,0,1)
  capturedAfterMission()
 end
end)
local function prepareUpgrade(p,u,target)
 upgradeTarget=assert(GameInfo.Units[target]);LekmodScenarioGrantTech(p,upgradeTarget.PrereqTech)
 for row in GameInfo.Unit_ResourceQuantityRequirements{UnitType=target}do local res=GameInfoTypes[row.ResourceType];local n=math.max(0,row.Cost-p:GetNumResourceAvailable(res,true));if n>0 then p:ChangeNumResourceTotal(res,n)end end
 assert(u:GetUpgradeUnitType()==upgradeTarget.ID)
 oldID=u:GetID();newID=nil;phase="upgrade-ready"
 LekmodScenarioEvent("fixture-setup",{operation="provided-upgrade-tech-resources",unit=oldID,target=target,second=secondUpgrade})
end
function LekmodScenario.step(p)
 assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 assert(Game.GetElapsedGameTurns()>=6)
 if phase=="init"then
  p:ChangeGold(1000);Players[2]:ChangeGold(1000)
  LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-budgets",human_added=1000,Roman_added=1000,mode=mode})
  if mode=="upgrade"then
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if emptyLand(q)and q:GetOwner()==0 then origin=q;break end end
   assert(origin);local u=create(0,"UNIT_WARRIOR",origin);probe=u:GetID();born=u:GetGameTurnCreated();assert(bonus(u)and u:MaxMoves()==240 and u:GetMoves()==240)
   LekmodScenarioRecord("maori-lifetime-inputs","PASS","fresh native Maori Warrior has +2 moves/+1 sight; no promotion or movement set")
   prepareUpgrade(p,u,"UNIT_SWORDSMAN");return false
  elseif mode=="naval"then
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if coast(q)then for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d);if coast(a)then origin=q;destination=a;break end end end
    if origin then break end
   end
   assert(origin);local u=create(0,"UNIT_TRIREME",origin);probe=u:GetID();born=u:GetGameTurnCreated();local info=GameInfo.Units.UNIT_TRIREME
   assert(bonus(u)and u:MaxMoves()==(info.Moves+2)*60 and u:GetMoves()==u:MaxMoves()and u:VisibilityRange()==info.BaseSightRange+1)
   local control;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if coast(q)and q:GetPlotIndex()~=destination:GetPlotIndex()then control=q;break end end
   assert(control);local foreign=create(2,"UNIT_TRIREME",control);romeShip=foreign:GetID();assert(not bonus(foreign)and foreign:MaxMoves()==info.Moves*60)
   LekmodScenarioRecord("maori-lifetime-inputs","PASS","native Maori naval birth +2 moves/+1 sight; Roman naval control has no bonus")
   phase="naval-move";return false
  elseif mode=="embark"then
   LekmodScenarioGrantTech(p,"TECH_OPTICS")
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if emptyLand(q)and(q:GetOwner()==0 or q:GetOwner()==-1)then for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d);if coast(a)then origin=q;destination=a;break end end end
    if origin then break end
   end
   assert(origin);local u=create(0,"UNIT_WARRIOR",origin);probe=u:GetID();born=u:GetGameTurnCreated();assert(bonus(u)and not u:IsEmbarked()and u:MaxMoves()==240)
   LekmodScenarioRecord("maori-lifetime-inputs","PASS","supplied Optics and coastal Warrior; native land birth bonus present")
   phase="embark-move";return false
  else
   assert(mode=="capture-in"or mode=="capture-out")
   oldOwner=mode=="capture-in"and 2 or 0;newOwner=mode=="capture-in"and 0 or 2
   Teams[p:GetTeam()]:Meet(Players[2]:GetTeam(),true);Network.SendChangeWar(Players[2]:GetTeam(),true)
   phase="capture-war";return false
  end
 elseif phase=="upgrade-ready"then
  local u=assert(p:GetUnitByID(oldID));upgradePrice=u:UpgradePrice(upgradeTarget.ID);assert(upgradePrice>0)
  p:SetGold(upgradePrice-1);assert(not u:CanUpgradeRightNow());p:ChangeGold(1);assert(u:CanUpgradeRightNow())
  LekmodScenarioEvent("fixture-setup",{operation="provided-exact-upgrade-budget",price=upgradePrice,unit=oldID,second=secondUpgrade})
  unitAction(u,"COMMAND_UPGRADE");phase="upgraded";return false
 elseif phase=="upgraded"then
  if not newID then return false end
  local u=assert(p:GetUnitByID(newID));local old=p:GetUnitByID(oldID)
  assert(not old or old:IsDead()or old:IsDelayedDeath());assert(u:GetUnitType()==upgradeTarget.ID and u:GetGameTurnCreated()==born and u:GetMoves()==0 and p:GetGold()==0)
  assert(bonus(u)==not secondUpgrade,"upgrade revived or dropped the wrong temporary bonus")
  probe=newID;p:ChangeGold(1000);LekmodScenarioEvent("fixture-setup",{operation="provided-post-upgrade-upkeep",added=1000})
  if not secondUpgrade then
   LekmodScenarioRecord("maori-lifetime-native-action","PASS","ordinary paid upgrade/native UnitUpgraded; cost-minus-one rejected; exact cost charged")
   LekmodScenarioRecord("maori-lifetime-birth-accounting","PASS","birth-turn upgrade retains original creation turn and bonus but has zero remaining movement")
   expiryCount=turnCount[0]or 0;phase="upgrade-expiry";return "turn"
  end
  ordinary(u);expiryCount=turnCount[0]or 0;phase="upgrade-final";return "turn"
 elseif phase=="upgrade-expiry"then
  if(turnCount[0]or 0)<=expiryCount then return "turn"end
  local u=assert(p:GetUnitByID(probe));local s=ordinary(u);assert(s.moves==120)
  LekmodScenarioRecord("maori-lifetime-owner-expiry","PASS","next actual owner turn removes bonus and clamps refreshed moves to120")
  secondUpgrade=true;prepareUpgrade(p,u,"UNIT_LONGSWORDSMAN");return false
 elseif phase=="upgrade-final"then
  if(turnCount[0]or 0)<=expiryCount then return "turn"end
  ordinary(assert(p:GetUnitByID(probe)))
  LekmodScenarioRecord("maori-lifetime-repeat-control","PASS","second paid upgrade of an older unit preserves original birth/no bonus/no move refund; next owner turn remains ordinary")
  return true
 elseif phase=="naval-move"or phase=="embark-move"then
  local u=assert(p:GetUnitByID(probe))
  if mode=="embark"then assert(u:CanEmbarkOnto(origin,destination),"native embark eligibility rejected fixture")
  else assert(u:CanMoveOrAttackInto(destination))end
  mission(u,mode=="naval"and MissionTypes.MISSION_MOVE_TO or MissionTypes.MISSION_EMBARK,destination)
  phase="domain-moved";return false
 elseif phase=="domain-moved"then
  local u=assert(p:GetUnitByID(probe))
  if not LekmodScenarioAwait("Maori-domain-move",u:GetX()==destination:GetX()and u:GetY()==destination:GetY())then return false end
  assert(bonus(u)and u:GetGameTurnCreated()==born)
  if mode=="naval"then assert(not u:IsEmbarked()and u:GetMoves()==u:MaxMoves()-60)
  else local moves,sight=embarkedOracle(u);assert(u:IsEmbarked()and u:MaxMoves()==moves and u:GetMoves()==0 and u:VisibilityRange()==sight);LekmodScenarioEvent("embarked-data-oracle",{moves=moves,sight=sight})end
  LekmodScenarioRecord("maori-lifetime-native-action","PASS","normal "..mode.." mission reached its legal destination")
  LekmodScenarioRecord("maori-lifetime-birth-accounting","PASS","creation turn and temporary promotion retained; correct domain movement/cost without a refund")
  expiryCount=turnCount[0]or 0;phase="domain-expiry";return "turn"
 elseif phase=="domain-expiry"then
  if(turnCount[0]or 0)<=expiryCount then return "turn"end
  local u=assert(p:GetUnitByID(probe));local s=ordinary(u);assert(s.moves==s.allowance)
  LekmodScenarioRecord("maori-lifetime-owner-expiry","PASS","actual next owner turn clears temporary promotion and obeys the native domain allowance")
  if mode=="embark"then assert(u:CanDisembarkOnto(origin,true));mission(u,MissionTypes.MISSION_DISEMBARK,origin);phase="disembarked";return false end
  local foreign=assert(Players[2]:GetUnitByID(romeShip));assert(not bonus(foreign)and foreign:MaxMoves()==GameInfo.Units.UNIT_TRIREME.Moves*60)
  expiryCount=turnCount[0]or 0;phase="domain-final";return "turn"
 elseif phase=="disembarked"then
  local u=assert(p:GetUnitByID(probe))
  if not LekmodScenarioAwait("Maori-disembark",not u:IsEmbarked()and u:GetX()==origin:GetX()and u:GetY()==origin:GetY())then return false end
  ordinary(u);expiryCount=turnCount[0]or 0;phase="domain-final";return "turn"
 elseif phase=="domain-final"then
  if(turnCount[0]or 0)<=expiryCount then return "turn"end
  ordinary(assert(p:GetUnitByID(probe)))
  LekmodScenarioRecord("maori-lifetime-repeat-control","PASS",mode=="embark"and"normal disembark and further owner turn keep ordinary land budget"or"further naval owner turn and Roman control retain ordinary allowances")
  return true
 elseif phase=="capture-war"then
  if not LekmodScenarioAwait("Maori-capture-war",Teams[p:GetTeam()]:IsAtWar(Players[2]:GetTeam()))then return false end
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if emptyLand(q)and q:GetOwner()==newOwner then for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d)
    if emptyLand(a)and(a:GetOwner()==newOwner or a:GetOwner()==-1)then destination=q;origin=a;break end
   end end
   if origin then break end
  end
  assert(origin,"no legal capture pair in recipient territory")
  local victim
  if mode=="capture-in"then
   for u in Players[2]:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_WORKER and not u:IsDead()and not u:IsDelayedDeath()then victim=u;break end end
   assert(victim and victim:GetGameTurnCreated()<Game.GetGameTurn());victim:SetXY(destination:GetX(),destination:GetY(),false,true,false,false)
   LekmodScenarioEvent("fixture-setup",{operation="position-existing-older-Roman-worker",state=state(victim)})
  else victim=create(0,"UNIT_WORKER",destination);assert(bonus(victim))end
  oldWorker=victim:GetID();local u=create(newOwner,"UNIT_WARRIOR",origin);actor=u:GetID()
  LekmodScenarioRecord("maori-lifetime-inputs","PASS","legal war/recipient-owned capture pair; original worker and native birth flags recorded")
  phase="capturing"
  if newOwner==0 then mission(u,MissionTypes.MISSION_MOVE_TO,destination);return false end
  return "turn"
 elseif phase=="capturing"then
  if newOwner==0 and not captureState then
   if not LekmodScenarioAwait("Maori-capture-native-events",createdWorker and prekill)then return false end
   capturedAfterMission()
  end
  if not captureState then if newOwner==2 then return "turn"end;return false end
  LekmodScenarioRecord("maori-lifetime-native-action","PASS","normal capture produced old UnitPrekill and recipient UnitCreated; source removed")
  LekmodScenarioRecord("maori-lifetime-birth-accounting","PASS","captured worker is born on capture turn, starts at zero moves and gets recipient-specific bonus only")
  phase="capture-expiry";return "turn"
 elseif phase=="capture-expiry"then
  if(turnCount[newOwner]or 0)<=captureCount then return "turn"end
  ordinary(assert(Players[newOwner]:GetUnitByID(createdWorker)))
  LekmodScenarioRecord("maori-lifetime-owner-expiry","PASS","actual next recipient turn gives ordinary worker budget; no inherited foreign bonus")
  expiryCount=turnCount[newOwner];phase="capture-final";return "turn"
 elseif phase=="capture-final"then
  if(turnCount[newOwner]or 0)<=expiryCount then return "turn"end
  ordinary(assert(Players[newOwner]:GetUnitByID(createdWorker)))
  LekmodScenarioRecord("maori-lifetime-repeat-control","PASS","further recipient owner turn retains ordinary captured worker without renewed bonus")
  return true
 end
 return false
end
