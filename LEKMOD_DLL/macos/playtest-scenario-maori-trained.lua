-- Near-complete production is supplied; legal city orders and native training
-- must determine the unit's first playable turn and next-turn expiry.
LekmodScenario={name="maori-trained",items={"maori-trained-first-turn","maori-trained-next-turn"}}
local phase,kind,trained,startTurn,readyTurn="init"
local function state(u)
 return {id=u:GetID(),type=u:GetUnitType(),created=u:GetGameTurnCreated(),moves=u:GetMoves(),maximum=u:MaxMoves(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),x=u:GetX(),y=u:GetY()}
end
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 if owner==Game.GetActivePlayer()then local u=Players[owner]:GetUnitByID(id)
  if u and u:GetUnitType()==kind then
   assert(not gold and not faith);trained=id
   LekmodScenarioEvent("maori-actual-CityTrained",{turn=Game.GetGameTurn(),owner=owner,city=city,state=state(u)})
  end
 end
end)
function LekmodScenario.snapshot(player)
 local units={};for u in player:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),units=units}
end
function LekmodScenario.step(player)
 local city=assert(player:GetCapitalCity());assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Game.GetGameTurn()>=6)
 if phase=="init" then
  for _,name in ipairs({"UNIT_POLYNESIAN_MAORI_WARRIOR","UNIT_WORKER","UNIT_SPEARMAN"})do local info=GameInfo.Units[name]
   if info and city:CanTrain(info.ID)then kind=info.ID;break end
  end
  assert(kind,"no eligible legal training unit")
  Game.CityPushOrder(city,OrderTypes.ORDER_TRAIN,kind,false,true,true);phase="queued"
 elseif phase=="queued" then
  if not LekmodScenarioAwait("maori-training-order",city:GetProductionUnit()==kind)then return false end
  local cost=city:GetUnitProductionNeeded(kind);city:SetUnitProduction(kind,cost-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-production",unit=kind,production=cost-1,needed=cost})
  startTurn=Game.GetGameTurn();phase="trained";return "turn"
 elseif phase=="trained" then
  if Game.GetGameTurn()==startTurn then return "turn" end
  assert(Game.GetGameTurn()==startTurn+1 and trained,"normal production did not train the expected unit")
  local u=assert(player:GetUnitByID(trained));local s=state(u);local info=GameInfo.Units[kind]
  LekmodScenarioEvent("maori-trained-first-playable-state",{turn=Game.GetGameTurn(),state=s})
  local passed=(s.maori or s.civilian) and s.maximum==(info.Moves+2)*GameDefines.MOVE_DENOMINATOR and s.sight==info.BaseSightRange+1
  LekmodScenarioRecord("maori-trained-first-turn",passed and "PASS" or "FAIL","path=normal-city-production type="..info.Type.." created="..s.created.." observed="..Game.GetGameTurn().." maximum="..s.maximum.." sight="..s.sight)
  if not passed then return true end
  readyTurn=Game.GetGameTurn();phase="expired";return "turn"
 elseif phase=="expired" then
  if Game.GetGameTurn()==readyTurn then return "turn" end;assert(Game.GetGameTurn()==readyTurn+1)
  local s=state(assert(player:GetUnitByID(trained)));local info=GameInfo.Units[kind]
  LekmodScenarioEvent("maori-trained-next-turn-state",{turn=Game.GetGameTurn(),state=s})
  assert(not s.maori and not s.civilian and s.maximum==info.Moves*GameDefines.MOVE_DENOMINATOR and s.sight==info.BaseSightRange and s.moves<=s.maximum,"trained unit retained a late bonus")
  LekmodScenarioRecord("maori-trained-next-turn","PASS","normal-next-owner-turn expired=true no-excess-movement=true")
  return true
 end
 return false
end
