-- Native method surface: GameCore
-- Units, contact, positions, research and upgrade gold are supplied inputs.
-- Actual synchronized moves, paid upgrade and gift determine the outcomes.
-- No promotions, movement budgets, wait flags or turn numbers are assigned.
LekmodScenario={name="swiss-boundaries",items={"mountaineer-foreign-birth","mountaineer-move-out","mountaineer-move-in","mountaineer-paid-upgrade","mountaineer-upgrade-movement-lock","mountaineer-gift"}}
local phase,id,owner,nearPlot,farPlot,budget,price,gold,upgradeID,giftID,giftOwner,giftBefore="init",nil,0
local base,active=GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER,GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER_ACTIVE
local function near(q)
 if q:IsMountain()or q:GetTerrainType()==GameInfoTypes.TERRAIN_MOUNTAIN then return true end
 for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d);if n and(n:IsMountain()or n:GetTerrainType()==GameInfoTypes.TERRAIN_MOUNTAIN)then return true end end
 return false
end
local function state(u)return {owner=u:GetOwner(),id=u:GetID(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),base=u:IsHasPromotion(base),active=u:IsHasPromotion(active),near=near(u:GetPlot())}end
local function clear(q)return q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and not q:IsHills()and q:GetFeatureType()==-1 and q:GetNumUnits()==0 end
local function action(u,name)
 UI.SelectUnit(u)
 for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type==name then assert(Game.CanHandleAction(i),"normal action unavailable: "..name);Game.HandleAction(i);return end end
 error("missing action: "..name)
end
local function move(u,q)
 assert(u:CanMoveOrAttackInto(q)and u:GetMoves()>0);budget=u:GetMoves();UI.SelectUnit(u)
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,q:GetX(),q:GetY(),0,false,false)
end
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,upgrade)
 if oldOwner==0 and oldID==id then
  if upgrade then assert(newOwner==0);upgradeID=newID else assert(newOwner==giftOwner);giftID=newID end
  LekmodScenarioEvent("native-mountaineer-conversion",{old_owner=oldOwner,new_owner=newOwner,old_id=oldID,new_id=newID,upgrade=upgrade})
 end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for n=0,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[n]
  if p and p:IsAlive()then local units={}
   for u in p:Units()do if u:IsHasPromotion(base)and not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
   if next(units)then owners[n]={civilization=p:GetCivilizationType(),units=units}end
  end
 end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),owners=owners}
end
function LekmodScenario.step(player)
 assert(player:GetID()==0 and player:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_SWISS)
 if phase=="init"then
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if clear(q)and q:GetOwner()==-1 and near(q)then
    for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d)
     if clear(n)and n:GetOwner()==-1 and not near(n)then nearPlot=q;farPlot=n;break end
    end
   end
   if nearPlot then break end
  end
  assert(nearPlot and farPlot,"no clear natural mountain boundary")
  nearPlot:SetRevealed(player:GetTeam(),true);farPlot:SetRevealed(player:GetTeam(),true)
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_SWISS_REISLAUFER,nearPlot:GetX(),nearPlot:GetY()));id=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-foreign-owned-Reislaufer-and-boundary-reveal",state=state(u),outside_x=farPlot:GetX(),outside_y=farPlot:GetY()})
  assert(u:IsHasPromotion(base)and u:IsHasPromotion(active)and u:GetMoves()==240 and u:MaxMoves()==240)
  LekmodScenarioRecord("mountaineer-foreign-birth","PASS","supplied Spanish-owned Reislaufer receives full native mountain ability at creation")
  move(u,farPlot);phase="outside"
 elseif phase=="outside"then
  local u=assert(player:GetUnitByID(id));if not LekmodScenarioAwait("mountaineer-outside",u:GetX()==farPlot:GetX()and u:GetY()==farPlot:GetY())then return false end
  assert(not u:IsHasPromotion(active)and u:IsHasPromotion(base)and u:MaxMoves()==180 and u:GetMoves()<budget)
  LekmodScenarioEvent("mountaineer-after-move-out",state(u));LekmodScenarioRecord("mountaineer-move-out","PASS","normal movement leaves mountain range, removes bonus and spends movement")
  assert(u:GetMoves()>0,"boundary route used the entire allowance");move(u,nearPlot);phase="inside"
 elseif phase=="inside"then
  local u=assert(player:GetUnitByID(id));if not LekmodScenarioAwait("mountaineer-inside",u:GetX()==nearPlot:GetX()and u:GetY()==nearPlot:GetY())then return false end
  assert(u:IsHasPromotion(active)and u:MaxMoves()==240 and u:GetMoves()<budget)
  LekmodScenarioEvent("mountaineer-after-move-in",state(u));LekmodScenarioRecord("mountaineer-move-in","PASS","normal return restores bonus without refunding spent movement")
  LekmodScenarioGrantTech(player,"TECH_RIFLING")
  local plot;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==0 and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then plot=q;break end
  end
  assert(plot,"no empty owned land upgrade position");u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
  assert(u:GetUpgradeUnitType()==GameInfoTypes.UNIT_RIFLEMAN)
  price=u:UpgradePrice(GameInfoTypes.UNIT_RIFLEMAN);assert(price>0);player:ChangeGold(price+500-player:GetGold());gold=player:GetGold()
  LekmodScenarioEvent("fixture-setup",{operation="provided-friendly-upgrade-position-and-budget",state=state(u),gold=gold,price=price})
  phase="upgrade-ready"
 elseif phase=="upgrade-ready"then
  local u=assert(player:GetUnitByID(id));if u:GetMoves()==0 then return "turn"end
  price=u:UpgradePrice(GameInfoTypes.UNIT_RIFLEMAN);player:ChangeGold(price+500-player:GetGold());gold=player:GetGold()
  LekmodScenarioEvent("fixture-setup",{operation="provided-current-upgrade-budget",gold=gold,price=price})
  assert(u:CanUpgradeRightNow());action(u,"COMMAND_UPGRADE");phase="upgraded"
 elseif phase=="upgraded"then
  if not LekmodScenarioAwait("mountaineer-upgrade",upgradeID~=nil)then return false end
  local old=player:GetUnitByID(id);local u=assert(player:GetUnitByID(upgradeID));id=upgradeID
  assert((not old or old:IsDead()or old:IsDelayedDeath())and u:GetUnitType()==GameInfoTypes.UNIT_RIFLEMAN and player:GetGold()==gold-price)
  assert(u:IsHasPromotion(base)and u:IsHasPromotion(active)==near(u:GetPlot()))
  LekmodScenarioRecord("mountaineer-paid-upgrade","PASS","normal paid Rifleman upgrade retains base promotion and derives terrain state")
  assert(u:GetMoves()==0);LekmodScenarioRecord("mountaineer-upgrade-movement-lock","PASS","promotion refresh preserves zero movement after upgrade")
  phase="gift-ready";return "turn"
 elseif phase=="gift-ready"then
  local u=assert(player:GetUnitByID(id));local plot
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local n=q:GetOwner();local p=n>=0 and Players[n]
   if not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 and p and n~=0 and p:IsAlive()and not p:IsMinorCiv()and not p:IsBarbarian()and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam())then plot=q;giftOwner=n;break end
  end
  assert(plot);local team=Teams[player:GetTeam()];local recipient=Players[giftOwner]
  if not team:IsHasMet(recipient:GetTeam())then team:Meet(recipient:GetTeam(),true)end
  u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false);giftBefore=state(u)
  LekmodScenarioEvent("fixture-setup",{operation="provided-contact-and-gift-position",recipient=giftOwner,state=giftBefore})
  assert(u:CanGift());action(u,"COMMAND_GIFT");phase="gifted"
 elseif phase=="gifted"then
  if not LekmodScenarioAwait("mountaineer-gift",giftID~=nil)then return false end
  local old=player:GetUnitByID(id);local u=assert(Players[giftOwner]:GetUnitByID(giftID))
  assert((not old or old:IsDead()or old:IsDelayedDeath())and u:IsHasPromotion(base)and u:IsHasPromotion(active)==near(u:GetPlot()))
  assert(u:GetMoves()<=giftBefore.moves,"gift conversion refunded movement")
  LekmodScenarioEvent("mountaineer-after-gift",state(u));LekmodScenarioRecord("mountaineer-gift","PASS","normal gift transfers promotion, derives recipient terrain state and does not refund moves")
  return true
 end
 return false
end
