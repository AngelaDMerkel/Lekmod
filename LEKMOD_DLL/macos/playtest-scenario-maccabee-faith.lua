-- Research, iron, religious majorities and faith are supplied inputs.
-- A real faith-purchase callback must create the owner-specific unit and spend faith.
LekmodScenario={name="maccabee-faith",items={"maccabee-religion-gate","maccabee-belief-gate","maccabee-owner-gate","maccabee-faith-budget","maccabee-faith-purchase"}}
local phase,cityID,unitID,cost,before,reply="init",nil,nil,nil,nil,false
local unit=GameInfoTypes.UNIT_ISRAEL_MACCABEE
local function city(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());LekmodScenarioEvent("fixture-setup",{operation="provided-empty-purchase-city",owner=p:GetID(),city=c:GetID(),x=q:GetX(),y=q:GetY()});return c end
 end
 error("no legal purchase-city input")
end
local function religion(p,follower)
 local used={};for owner=0,3 do local other=Players[owner];if other:HasCreatedReligion()then used[other:GetReligionCreatedByPlayer()]=true end end
 local id;for info in GameInfo.Religions()do if info.ID>0 and not used[info.ID]then id=info.ID;break end end
 local founder=assert(Game.GetAvailableFounderBeliefs()[1]);local available=false
 for _,belief in ipairs(Game.GetAvailableFollowerBeliefs())do if belief==follower then available=true end end;assert(available and id and Game.GetNumReligionsStillToFound()>0)
 Game.FoundReligion(p:GetID(),id,nil,founder,follower,-1,-1,p:GetCapitalCity());assert(p:GetReligionCreatedByPlayer()==id)
 LekmodScenarioEvent("fixture-setup",{operation="provided-religion",owner=p:GetID(),religion=id,founder=founder,follower=follower});return id
end
local function can(c,kind,spend)return c:IsCanPurchase(spend,true,kind,-1,-1,YieldTypes.YIELD_FAITH)end
function LekmodScenario.snapshot(player)
 local owners={}
 for _,owner in ipairs({0,3})do local p=Players[owner];local cities,units={},{ }
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),majority=c:GetReligiousMajority(),followers=c:GetNumFollowers(c:GetReligiousMajority())}end
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),combat=u:GetBaseCombatStrength()}end end
  owners[owner]={faith=p:GetFaith(),gold=p:GetGold(),religion=p:GetReligionCreatedByPlayer(),cities=cities,units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
LuaEvents.LekmodScenarioReligionResponse.Add(function(action,id)if action=="purchase"and id==unit then reply=true end end)
GameEvents.UnitCreated.Add(function(owner,id)if owner==0 then local u=Players[owner]:GetUnitByID(id);if u and u:GetUnitType()==unit then assert(not unitID);unitID=id end end end)
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ISRAEL)
 if phase=="init"then
  for _,owner in ipairs({0,3})do local p=Players[owner];LekmodScenarioGrantTech(p,"TECH_IRON_WORKING");p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_IRON,2);LekmodScenarioEvent("fixture-setup",{operation="provided-iron",owner=owner,amount=2})end
  local c=city(player);cityID=c:GetID();assert(c:CanTrain(unit)and not can(c,unit,false))
  LekmodScenarioRecord("maccabee-religion-gate","PASS","production prerequisites met; no religion still rejects faith purchase")
  local foreign=religion(Players[3],GameInfoTypes.BELIEF_FEED_WORLD);c:ConvertPercentFollowers(foreign,-1,100)
  assert(c:GetReligiousMajority()==foreign and not can(c,unit,false))
  LekmodScenarioRecord("maccabee-belief-gate","PASS","foreign majority without military-faith belief rejects purchase")
  local own=religion(player,GameInfoTypes.BELIEF_HOLY_WARRIORS);c:ConvertPercentFollowers(own,foreign,100)
  assert(c:GetReligiousMajority()==own and can(c,unit,false))
  local roman=city(Players[3]);roman:ConvertPercentFollowers(own,-1,100)
  local class=GameInfo.Units.UNIT_ISRAEL_MACCABEE.Class
  local romanKind=GameInfo.UnitClasses[class].DefaultUnit
  for row in GameInfo.Civilization_UnitClassOverrides{CivilizationType=GameInfo.Civilizations[Players[3]:GetCivilizationType()].Type,UnitClassType=class}do romanKind=row.UnitType end
  assert(romanKind and romanKind~="UNIT_ISRAEL_MACCABEE")
  LekmodScenarioEvent("faith-owner-control",{Roman_unit=romanKind,majority=roman:GetReligiousMajority(),expected_majority=own,Roman_eligible=can(roman,GameInfoTypes[romanKind],false),Maccabee_eligible=can(roman,unit,false)})
  assert(roman:GetReligiousMajority()==own and can(roman,GameInfoTypes[romanKind],false)and not can(roman,unit,false),"owner replacement control differs")
  LekmodScenarioEvent("fixture-setup",{operation="provided-purchase-majorities",human_city=cityID,Roman_city=roman:GetID(),religion=own})
  LekmodScenarioRecord("maccabee-owner-gate","PASS","same religion/research/resources: Israel unique eligible; Roman data-defined replacement eligible and Maccabee rejected")
  cost=c:GetUnitFaithPurchaseCost(unit,true);assert(cost>1);local previous=player:GetFaith();player:ChangeFaith(cost-1-previous);assert(not can(c,unit,true));player:ChangeFaith(1);assert(can(c,unit,true))
  LekmodScenarioEvent("fixture-setup",{operation="provided-exact-faith-budget",before=previous,faith=cost})
  LekmodScenarioRecord("maccabee-faith-budget","PASS","cost-1 rejected; exact quoted faith accepted; price="..cost)
  before=LekmodScenario.snapshot(player);LuaEvents.LekmodScenarioFaithPurchase(cityID,unit);phase="purchased"
 elseif phase=="purchased"then
  if not reply then return false end
  if not LekmodScenarioAwait("Maccabee-faith-created",unitID~=nil)then return false end
  local u=assert(player:GetUnitByID(unitID));local c=player:GetCityByID(cityID)
  assert(player:GetFaith()==0 and player:GetGold()==before.owners[0].gold and u:GetOwner()==0 and u:GetUnitType()==unit and u:GetX()==c:GetX()and u:GetY()==c:GetY()and u:GetMoves()==0)
  assert(LekmodScenarioJSON(LekmodScenario.snapshot(player).owners[3])==LekmodScenarioJSON(before.owners[3]))
  LekmodScenarioRecord("maccabee-faith-purchase","PASS","real ProductionPopup faith callback/UnitCreated; exact faith debit; gold and Roman control unchanged; movement0")
  return true
 end
 return false
end
