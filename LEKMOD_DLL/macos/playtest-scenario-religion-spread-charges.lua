-- Native method surface: GameCore
-- Religion/city/unit/wonder inputs; actual full-charge spread missions.
local religionA,religionB,targetID,foreignControlCity
local readyReformations={}
local function has(list,id)for _,v in ipairs(list)do if v==id then return true end end;return false end
local function newCity(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and p:CanFound(q:GetX(),q:GetY())then
   local far=true;for owner=0,1 do for c in Players[owner]:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<=8 then far=false end end end
   if far then p:Found(q:GetX(),q:GetY());return assert(q:GetPlotCity())end
  end
 end
 error("no separated legal city site")
end
local function convert(c,id)
 c:ConvertPercentFollowers(id,-1,100);c:ConvertPercentFollowers(id,0,100)
 for row in GameInfo.Religions()do if row.ID>0 and row.ID~=id then c:ConvertPercentFollowers(id,row.ID,100)end end
 assert(c:GetReligiousMajority()==id)
end
local function setupReligions(founderA,retain)
 local ids={};for r in GameInfo.Religions()do if r.ID>0 then ids[#ids+1]=r.ID end end
 assert(not Players[0]:HasCreatedReligion()and not Players[1]:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>=2)
 religionA,religionB=ids[1],ids[2]
 assert(has(Game.GetAvailableFounderBeliefs(),founderA)and has(Game.GetAvailableFollowerBeliefs(),GameInfoTypes.BELIEF_MANDIRS))
 Game.FoundReligion(0,religionA,nil,founderA,GameInfoTypes.BELIEF_MANDIRS,-1,-1,Players[0]:GetCapitalCity())
 Game.EnhanceReligion(0,religionA,GameInfoTypes.BELIEF_HOLY_WARRIORS,GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS)
 assert(has(Game.GetAvailableFounderBeliefs(),GameInfoTypes.BELIEF_CHURCH_PROPERTY))
 Game.FoundReligion(1,religionB,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_PAGODAS,-1,-1,Players[1]:GetCapitalCity())
 Game.EnhanceReligion(1,religionB,GameInfoTypes.BELIEF_MOSQUES,retain and GameInfoTypes.BELIEF_UNITY_OF_PROPHETS or GameInfoTypes.BELIEF_CRAFTWORKS)
 assert(Players[0]:GetReligionCreatedByPlayer()==religionA and Players[1]:GetReligionCreatedByPlayer()==religionB)
 local target=newCity(Players[0]);targetID=target:GetID();target:SetPopulation(8,true);convert(target,religionB)
 local foreign=newCity(Players[1]);foreignControlCity=foreign:GetID();convert(foreign,religionA)
 assert(has(Game.GetAvailableReformationBeliefs(),GameInfoTypes.BELIEF_WORK_ETHIC)and has(Game.GetAvailableReformationBeliefs(),GameInfoTypes.BELIEF_JESUIT_EDUCATION))
 Network.SendFoundPantheon(0,GameInfoTypes.BELIEF_WORK_ETHIC);Network.SendFoundPantheon(1,GameInfoTypes.BELIEF_JESUIT_EDUCATION)
 LekmodScenarioEvent("fixture-setup",{operation="native-religions-enhancement-extra-cities-conversions-and-reformations",own=religionA,foreign=religionB,target=targetID,foreign_control=foreignControlCity,retention=retain})
end
GameEvents.ReformationAdded.Add(function(owner,id,belief)
 if owner==0 or owner==1 then readyReformations[owner]=true;LekmodScenarioEvent("native-input-reformation",{owner=owner,religion=id,belief=belief})end
end)
local function ready()
 return readyReformations[0]and readyReformations[1]and has(Game.GetBeliefsInReligion(religionA),GameInfoTypes.BELIEF_WORK_ETHIC)and has(Game.GetBeliefsInReligion(religionB),GameInfoTypes.BELIEF_JESUIT_EDUCATION)
end
local function target()return assert(Players[0]:GetCityByID(targetID))end
local function stage(u,c,center)
 local q=center and c:Plot()or nil
 if not q then for d=0,5 do local a=Map.PlotDirection(c:GetX(),c:GetY(),d);if a and not a:IsWater()and not a:IsMountain()and not a:IsCity()and a:GetNumUnits()==0 then q=a;break end end end
 assert(q);u:SetXY(q:GetX(),q:GetY(),false,true,true);assert(u:GetPlot():GetPlotIndex()==q:GetPlotIndex())
 LekmodScenarioEvent("fixture-setup",{operation="positioned-religious-unit",unit=u:GetID(),owner=u:GetOwner(),x=q:GetX(),y=q:GetY(),target_owner=c:GetOwner(),target=c:GetID()});return q
end
local function act(u,name)
 UI.SelectUnit(u);for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type==name then assert(Game.CanHandleAction(id),"normal religious action unavailable: "..name);Game.HandleAction(id);return end end;error("religious action missing")
end
local function pressures(c)
 local r={};for row in GameInfo.Religions()do r[row.ID]={pressure=c:GetReligionPressure(row.ID),followers=c:GetNumFollowers(row.ID),holy=c:IsHolyCityForReligion(row.ID)}end
 return {majority=c:GetReligiousMajority(),population=c:GetPopulation(),religions=r}
end
local function world()
 local owners={};for owner=0,1 do local p=Players[owner];local cities,units={},{}
  for c in p:Cities()do cities[c:GetID()]=pressures(c)end
  for u in p:Units()do local info=GameInfo.Units[u:GetUnitType()];if info.SpreadReligion or info.RemoveHeresy then units[u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),strength=u:GetConversionStrength(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end
  owners[owner]={civilization=p:GetCivilizationType(),religion=p:GetReligionCreatedByPlayer(),faith=p:GetFaith(),cities=cities,units=units}
 end;return {turn=Game.GetGameTurn(),owners=owners}
end
LekmodScenario={name="religion-spread-charges",items={"spread-charge-inputs","spread-constructor-bonuses","spread-founder-control","spread-prophet-inquisitor-controls","spread-native-purchase","spread-pressure-preview","spread-complete-charge-life","spread-final-consumption"}}
local mode=assert(LekmodScenarioParameters.mode);local zeal=mode=="zeal"or mode=="both";local mosque=mode=="mosque"or mode=="both"
local phase,unitID,reply,trained,faithCost,before,issued,total,expected="init",nil,nil,nil,nil,nil,0,0,2+(zeal and 1 or 0)+(mosque and 1 or 0)
LuaEvents.LekmodScenarioReligionResponse.Add(function(kind,value)reply={kind=kind,value=value}end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)if owner==0 and phase=="buy"then local u=Players[0]:GetUnitByID(id);if u and u:GetUnitType()==GameInfoTypes.UNIT_MISSIONARY then assert(not gold and faith and not trained);trained=id end end end)
function LekmodScenario.snapshot(p)local s=world();s.mode=mode;return s end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MALI)
 if phase=="init"then
  assert(GameInfo.Beliefs.BELIEF_MISSIONARY_ZEAL.MissionaryExtraSpreads==1 and GameInfo.Buildings.BUILDING_MOSQUE_OF_DJENNE.ExtraMissionarySpreads==1)
  setupReligions(zeal and GameInfoTypes.BELIEF_MISSIONARY_ZEAL or GameInfoTypes.BELIEF_TITHE,false);phase="ready"
 elseif phase=="ready"then
  if not LekmodScenarioAwait("spread-religion-inputs",ready())then return false end
  local c=p:GetCapitalCity();assert(c:GetNumBuilding(GameInfoTypes.BUILDING_MOSQUE_OF_DJENNE)==0);if mosque then c:SetNumRealBuilding(GameInfoTypes.BUILDING_MOSQUE_OF_DJENNE,1)end
  local missionary=assert(p:InitUnit(GameInfoTypes.UNIT_MISSIONARY,c:GetX(),c:GetY()));assert(missionary:GetSpreadsLeft()==expected and missionary:GetReligion()==religionA);missionary:Kill(false,-1)
  LekmodScenarioRecord("spread-constructor-bonuses","PASS","native constructor gives base2 plus configured founder/wonder bonuses="..expected)
  local other=Players[1];local fc=assert(other:GetCityByID(foreignControlCity));local foreign=assert(other:InitUnit(GameInfoTypes.UNIT_MISSIONARY,fc:GetX(),fc:GetY()));assert(foreign:GetReligion()==religionA and foreign:GetSpreadsLeft()==2);foreign:Kill(false,-1)
  LekmodScenarioRecord("spread-founder-control","PASS","foreign owner using the same religion receives no founder-specific extra spread; no duplicate wonder supplied")
  local prophet=assert(p:InitUnit(GameInfoTypes.UNIT_PROPHET,c:GetX(),c:GetY()));assert(prophet:GetSpreadsLeft()==4);prophet:Kill(false,-1)
  local inq=assert(p:InitUnit(GameInfoTypes.UNIT_INQUISITOR,c:GetX(),c:GetY()));assert(inq:GetSpreadsLeft()==expected-2 and not inq:CanStartMission(MissionTypes.MISSION_SPREAD_RELIGION,-1,-1,c:Plot(),0));inq:Kill(false,-1)
  LekmodScenarioRecord("spread-prophet-inquisitor-controls","PASS","Prophet keeps4charges; Inquisitor may store extra counter but has no spread mission")
  faithCost=c:GetUnitFaithPurchaseCost(GameInfoTypes.UNIT_MISSIONARY,true);assert(faithCost>0);p:ChangeFaith(faithCost-p:GetFaith());assert(c:IsCanPurchase(true,true,GameInfoTypes.UNIT_MISSIONARY,-1,-1,YieldTypes.YIELD_FAITH))
  LekmodScenarioRecord("spread-charge-inputs","PASS","religions/cities/conversions/wonder and exact faith budget are supplied; no spread counter or final pressure assigned")
  phase="buy";LuaEvents.LekmodScenarioFaithPurchase(c:GetID(),GameInfoTypes.UNIT_MISSIONARY)
 elseif phase=="buy"then
  if not LekmodScenarioAwait("spread-missionary-purchase",reply and trained)then return false end
  unitID=trained;local u=assert(p:GetUnitByID(unitID));assert(reply.kind=="purchase"and reply.value==GameInfoTypes.UNIT_MISSIONARY and p:GetFaith()==0 and u:GetReligion()==religionA and u:GetSpreadsLeft()==expected)
  LekmodScenarioRecord("spread-native-purchase","PASS","original faith purchase creates one missionary, spends exact cost and applies bonuses once")
  stage(u,target(),false);phase="spread"
 elseif phase=="spread"then
  local u=assert(p:GetUnitByID(unitID));if u:GetMoves()<=0 then return "turn"end
  local c=target();assert(u:GetConversionStrength()==GameInfo.Units.UNIT_MISSIONARY.ReligiousStrength*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER)
  before={pressure=c:GetReligionPressure(religionA),followers=u:GetNumFollowersAfterSpread(),majority=u:GetMajorityReligionAfterSpread(),spreads=u:GetSpreadsLeft(),strength=u:GetConversionStrength(),turn=Game.GetGameTurn()}
  assert(before.spreads==expected-issued);act(u,"MISSION_SPREAD_RELIGION");phase="verify"
 elseif phase=="verify"then
  local c=target();local u=p:GetUnitByID(unitID);local gone=not u or u:IsDead()or u:IsDelayedDeath()
  if not LekmodScenarioAwait("spread-charge-consumed",gone or u:GetSpreadsLeft()==before.spreads-1)then return false end
  assert(c:GetReligionPressure(religionA)==before.pressure+before.strength and c:GetNumFollowers(religionA)==before.followers and c:GetReligiousMajority()==before.majority)
  issued=issued+1;total=total+before.strength;LekmodScenarioEvent("native-full-charge-spread",{mode=mode,ordinal=issued,before=before,after_pressure=c:GetReligionPressure(religionA),after_followers=c:GetNumFollowers(religionA),consumed=gone})
  if issued<expected then assert(not gone and u:GetSpreadsLeft()==expected-issued and u:GetMoves()==0);phase="spread";return false end
  assert(gone);LekmodScenarioRecord("spread-pressure-preview","PASS","every real spread adds exactly native strength and matches follower/majority previews")
  LekmodScenarioRecord("spread-complete-charge-life","PASS","all "..expected.." actual spread charges were usable over ordinary owner rounds; total delivered pressure="..total)
  LekmodScenarioRecord("spread-final-consumption","PASS","each nonfinal action removes1charge and exhausts moves; final charge consumes the purchased unit");return true
 end
 return false
end
