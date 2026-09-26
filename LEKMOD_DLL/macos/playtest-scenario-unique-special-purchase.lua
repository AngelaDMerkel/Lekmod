-- Native method surface: GameCore
-- Research, religion/enhancement, empty legal cities and exact budgets are inputs.
-- The real ProductionPopup callbacks must acquire each special unit; follow-up
-- state is checked after native purchase bookkeeping, not inside CityTrained.
LekmodScenario={name="unique-special-purchase",items={"special-purchase-prerequisites","special-purchase-owner-control","special-purchase-budget","special-purchase-native-event","special-purchase-properties","special-purchase-movement"}}
local configs={CIVILIZATION_CZECHIA={kind="UNIT_CZECHIA_FOREIGN_LEGION",currency="gold"},CIVILIZATION_MAURYA={kind="UNIT_MAURYA_MISSIONARY",currency="faith"},CIVILIZATION_MADAGASCAR={kind="UNIT_MPIAMBINA",currency="faith",enhance=true}}
local phase,cfg,cityID,controlID,controlCity,unitID,cost,before,reply,trained,created,religionID,destination,moves="init"
local function emptyCity(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());LekmodScenarioEvent("fixture-setup",{operation="provided-legal-empty-purchase-city",owner=p:GetID(),city=c:GetID(),x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no legal empty purchase city")
end
local function can(c,spend)return c:IsCanPurchase(spend,true,GameInfoTypes[cfg.kind],-1,-1,cfg.currency=="gold"and YieldTypes.YIELD_GOLD or YieldTypes.YIELD_FAITH)end
local function budget(p,value)
 if cfg.currency=="gold"then p:ChangeGold(value-p:GetGold())else p:ChangeFaith(value-p:GetFaith())end
end
local function provideReligion(p)
 local used={};for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local other=Players[owner];if other and other:IsAlive()and other:HasCreatedReligion()then used[other:GetReligionCreatedByPlayer()]=true end end
 local id;for info in GameInfo.Religions()do if info.ID>0 and not used[info.ID]then id=info.ID;break end end
 assert(id and not p:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>0)
 local founder=assert(Game.GetAvailableFounderBeliefs()[1]);local follower=GameInfoTypes.BELIEF_FEED_WORLD;local found=false
 for _,v in ipairs(Game.GetAvailableFollowerBeliefs())do if v==follower then found=true end end;assert(found)
 Game.FoundReligion(p:GetID(),id,nil,founder,follower,-1,-1,p:GetCapitalCity());assert(p:GetReligionCreatedByPlayer()==id)
 LekmodScenarioEvent("fixture-setup",{operation="provided-founded-religion",owner=p:GetID(),religion=id,founder=founder,follower=follower});return id
end
LuaEvents.LekmodScenarioTradeResponse.Add(function(action,id)if cfg and action=="purchase"and id==GameInfoTypes[cfg.kind]then reply=true end end)
LuaEvents.LekmodScenarioReligionResponse.Add(function(action,id)if cfg and action=="purchase"and id==GameInfoTypes[cfg.kind]then reply=true end end)
GameEvents.UnitCreated.Add(function(owner,id)
 if cfg and owner==Game.GetActivePlayer()then local u=Players[owner]:GetUnitByID(id);if u and u:GetUnitType()==GameInfoTypes[cfg.kind]then assert(phase=="purchasing"and not created);created=id;unitID=id end end
end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 if cfg and owner==Game.GetActivePlayer()and city==cityID then local u=Players[owner]:GetUnitByID(id)
  if u and u:GetUnitType()==GameInfoTypes[cfg.kind]then assert(phase=="purchasing"and gold==(cfg.currency=="gold")and faith==(cfg.currency=="faith"));trained=id;LekmodScenarioEvent("native-special-unit-purchased",{owner=owner,city=city,id=id,kind=cfg.kind,gold=gold,faith=faith})end
 end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then local cities,units={},{}
   for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),religion=c:GetReligiousMajority()}end
   for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then
    local promotions={};for info in GameInfo.UnitPromotions()do if u:IsHasPromotion(info.ID)then promotions[info.ID]=true end end
    units[u:GetID()]={kind=GameInfo.Units[u:GetUnitType()].Type,x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),conversion_strength=u:GetConversionStrength(),promotions=promotions}
   end end
   owners[owner]={civilization=p:GetCivilizationType(),gold=p:GetGold(),faith=p:GetFaith(),religion=p:GetReligionCreatedByPlayer(),cities=cities,units=units}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  cfg=assert(configs[GameInfo.Civilizations[player:GetCivilizationType()].Type],"requires reviewed special-purchase human civilization")
  local info=GameInfo.Units[cfg.kind];local city=emptyCity(player);cityID=city:GetID()
  for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner];if p and p:IsAlive()and owner~=player:GetID()then controlID=owner;break end end
  local other=Players[controlID];local control=emptyCity(other);controlCity=control:GetID()
  assert(not city:CanTrain(info.ID)and not can(city,false),"production or unmet prerequisite gate unexpectedly open")
  if cfg.currency=="gold"then
   assert(info.PurchaseOnly and info.PrereqTech);LekmodScenarioGrantTech(player,info.PrereqTech);LekmodScenarioGrantTech(other,info.PrereqTech)
  else
   religionID=provideReligion(player);city:ConvertPercentFollowers(religionID,-1,100);control:ConvertPercentFollowers(religionID,-1,100)
   assert(city:GetReligiousMajority()==religionID and control:GetReligiousMajority()==religionID)
   if cfg.enhance then
    assert(not can(city,false),"enhancement gate unexpectedly open")
    local follower=assert(Game.GetAvailableFollowerBeliefs()[1]);local enhancer=assert(Game.GetAvailableEnhancerBeliefs()[1]);local count=#Game.GetBeliefsInReligion(religionID)
    Game.EnhanceReligion(player:GetID(),religionID,follower,enhancer)
    assert(#Game.GetBeliefsInReligion(religionID)==count+2)
    LekmodScenarioEvent("fixture-setup",{operation="provided-religion-enhancement",religion=religionID,follower=follower,enhancer=enhancer})
   end
   LekmodScenarioEvent("fixture-setup",{operation="provided-matching-purchase-majorities",religion=religionID,human_city=cityID,control_city=controlCity})
  end
  assert(not city:CanTrain(info.ID)and can(city,false),"special purchase remains unavailable after reviewed prerequisites: "..cfg.kind)
  assert(not can(control,false),"foreign owner can purchase another civilization's unique")
  LekmodScenarioRecord("special-purchase-prerequisites","PASS","production rejected; missing research/religion and applicable enhancement rejected; prepared purchase eligible")
  LekmodScenarioRecord("special-purchase-owner-control","PASS","same technology or religious majority: foreign owner rejects "..cfg.kind)
  cost=cfg.currency=="gold"and city:GetUnitPurchaseCost(info.ID)or city:GetUnitFaithPurchaseCost(info.ID,true);assert(cost>1)
  budget(player,cost-1);assert(not can(city,true));budget(player,cost);assert(can(city,true))
  LekmodScenarioEvent("fixture-setup",{operation="provided-exact-purchase-budget",currency=cfg.currency,cost=cost})
  LekmodScenarioRecord("special-purchase-budget","PASS","quoted cost-1 rejected; exact budget accepted: "..cost.." "..cfg.currency)
  before=LekmodScenario.snapshot(player);phase="purchasing"
  if cfg.currency=="gold"then LuaEvents.LekmodScenarioGoldPurchase(cityID,info.ID)else LuaEvents.LekmodScenarioFaithPurchase(cityID,info.ID)end
 elseif phase=="purchasing"then
  if not reply then return false end
  if not LekmodScenarioAwait("special-purchase-complete",created and trained==created)then return false end
  local u=assert(player:GetUnitByID(unitID));local info=GameInfo.Units[cfg.kind];local c=player:GetCityByID(cityID)
  assert(u:GetUnitType()==info.ID and u:GetOwner()==player:GetID()and u:GetX()==c:GetX()and u:GetY()==c:GetY())
  if cfg.currency=="gold"then assert(player:GetGold()==0 and player:GetFaith()==before.owners[player:GetID()].faith)
  else assert(player:GetFaith()==0 and player:GetGold()==before.owners[player:GetID()].gold);assert(u:GetReligion()==religionID and u:GetSpreadsLeft()==info.ReligionSpreads)
   if info.ReligionSpreads>0 then
    local modifier=0;for _,belief in ipairs(Game.GetBeliefsInReligion(religionID))do modifier=modifier+(GameInfo.Beliefs[belief].MissionaryStrengthModifier or 0)end
    local expected=math.floor(info.ReligiousStrength*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER*(100+modifier)/100)
    LekmodScenarioEvent("purchased-missionary-strength",{raw=info.ReligiousStrength,multiplier=GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER,belief_modifier=modifier,expected=expected,actual=u:GetConversionStrength()})
    assert(u:GetConversionStrength()==expected,"conversion strength differs from native pressure units")
   end
  end
  assert(LekmodScenarioJSON(LekmodScenario.snapshot(player).owners[controlID])==LekmodScenarioJSON(before.owners[controlID]))
  for row in GameInfo.Unit_FreePromotions{UnitType=cfg.kind}do assert(u:IsHasPromotion(GameInfoTypes[row.PromotionType]),"missing purchased-unit promotion "..row.PromotionType)end
  LekmodScenarioRecord("special-purchase-native-event","PASS","real ProductionPopup callback, UnitCreated and correct CityTrained purchase flags; exact debit; other currency/control unchanged")
  LekmodScenarioRecord("special-purchase-properties","PASS","correct type/owner/city/free promotions and applicable religion/charges/strength after native bookkeeping")
  if not info.MoveAfterPurchase then assert(u:GetMoves()==0);LekmodScenarioRecord("special-purchase-movement","PASS","data-defined purchase movement restriction: zero moves");return true end
  assert(u:GetMoves()==u:MaxMoves()and u:GetMoves()>0);moves=u:GetMoves()
  for d=0,5 do local q=Map.PlotDirection(u:GetX(),u:GetY(),d);if q and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 and u:CanMoveOrAttackInto(q)then destination=q;break end end
  assert(destination,"no legal immediate-purchase movement destination");UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,destination:GetX(),destination:GetY(),0,false,false);phase="moving"
 elseif phase=="moving"then
  local u=assert(player:GetUnitByID(unitID));if not LekmodScenarioAwait("purchased-unit-moved",u:GetX()==destination:GetX()and u:GetY()==destination:GetY()and not u:IsBusy())then return false end
  assert(u:GetMoves()<moves and Game.GetGameTurn()==before.turn)
  LekmodScenarioRecord("special-purchase-movement","PASS","normal movement succeeds immediately after purchase, spends movement, and advances no turn")
  return true
 end
 return false
end
