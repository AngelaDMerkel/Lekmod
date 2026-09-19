-- Supplied units/contact/positions; real gift commands and recipient turns
-- determine ownership and temporary-bonus expiry. No promotion or moves set.
LekmodScenario={name="maori-gift",items={"maori-gift-owner-transfer","maori-gift-maori-expiry","maori-gift-foreign-expiry"}}
local phase,cursor,startTurn="init",1,nil
local requests={{owner=1,kind="UNIT_WARRIOR"},{owner=2,kind="UNIT_WARRIOR"},{owner=2,kind="UNIT_WORKER"}}
local gifts,ownerTurns={},{}
local function state(u)
 return {id=u:GetID(),owner=u:GetOwner(),type=u:GetUnitType(),created=u:GetGameTurnCreated(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN)}
end
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,upgrade)
 for _,g in ipairs(gifts)do
  if oldOwner==0 and oldID==g.original and not g.id and not upgrade then g.owner=newOwner;g.id=newID
  elseif g.id and oldOwner==g.owner and oldID==g.id then g.owner=newOwner;g.id=newID end
 end
 LekmodScenarioEvent("maori-observed-conversion",{old_owner=oldOwner,new_owner=newOwner,old_id=oldID,new_id=newID,upgrade=upgrade})
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==1 or owner==2 then ownerTurns[owner]=Game.GetGameTurn();LekmodScenarioEvent("maori-gift-real-owner-turn",{owner=owner,turn=Game.GetGameTurn()})end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local units={};for u in Players[owner]:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
  owners[owner]={civilization=Players[owner]:GetCivilizationType(),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function action(unit)
 UI.SelectUnit(unit)
 for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="COMMAND_GIFT"then
  assert(Game.CanHandleAction(i),"normal gift action unavailable");Game.HandleAction(i);return
 end end
 error("gift action missing")
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and not Game.IsGameMultiPlayer())
 if phase=="init" then
  assert(Game.GetElapsedGameTurns()>=6);startTurn=Game.GetGameTurn();phase="give"
 end
 if phase=="give" then
  local request=requests[cursor];local recipient=Players[request.owner];local team=Teams[player:GetTeam()];local plot
  assert(not team:IsAtWar(recipient:GetTeam()))
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if p:GetOwner()==request.owner and not p:IsCity() and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0 then plot=p;break end
  end
  assert(plot,"no legal peaceful gift staging tile")
  if not team:IsHasMet(recipient:GetTeam())then team:Meet(recipient:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="provided-contact",recipient=request.owner})end
  local capital=assert(player:GetCapitalCity());local u=assert(player:InitUnit(GameInfoTypes[request.kind],capital:GetX(),capital:GetY()))
  assert(u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI) or u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),"supplied unit lacks birth-turn bonus")
  gifts[cursor]={original=u:GetID(),recipient=request.owner,kind=request.kind}
  u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="provided-unit-and-gift-position",recipient=request.owner,state=state(u)})
  assert(u:CanGift());action(u);phase="transferred";return false
 elseif phase=="transferred" then
  local g=gifts[cursor];if not g.id then return false end
  local u=assert(Players[g.owner]:GetUnitByID(g.id));local old=player:GetUnitByID(g.original)
  assert(g.owner==g.recipient and u:GetUnitType()==GameInfoTypes[g.kind] and (not old or old:IsDead() or old:IsDelayedDeath()),"normal gift did not transfer unit")
  LekmodScenarioEvent("maori-after-real-gift",state(u))
  cursor=cursor+1
  if cursor<=#requests then phase="give";return false end
  LekmodScenarioRecord("maori-gift-owner-transfer","PASS","three-normal-gift-actions ownership-and-source-removal-verified=true")
  phase="expiry";return "turn"
 elseif phase=="expiry" then
  if Game.GetGameTurn()<startTurn+2 then return "turn"end
  assert(Game.GetGameTurn()==startTurn+2 and ownerTurns[1]>=startTurn+1 and ownerTurns[2]>=startTurn+1,"recipient owner turns were not observed")
  local foreignBad,maoriBad=0,0
  for _,g in ipairs(gifts)do
   assert(g.owner==g.recipient,"recipient changed unexpectedly")
   local s=state(assert(Players[g.owner]:GetUnitByID(g.id)));LekmodScenarioEvent("maori-gift-after-owner-turns",s)
   if s.maori or s.civilian then if g.owner==1 then maoriBad=maoriBad+1 else foreignBad=foreignBad+1 end end
  end
  LekmodScenarioRecord("maori-gift-maori-expiry",maoriBad==0 and "PASS"or"FAIL","retained-temporary-promotions="..maoriBad)
  LekmodScenarioRecord("maori-gift-foreign-expiry",foreignBad==0 and "PASS"or"FAIL","retained-temporary-promotions="..foreignBad)
  return true
 end
 return false
end
