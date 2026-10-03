-- Native method surface: GameCore
-- Controlled valid religious inputs; actual Prophet/Missionary/purge outcomes.
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
LekmodScenario={name="religion-strength-retention",items={"religion-strength-inputs","prophet-strength-owner-controls","prophet-native-pressure","prophet-preview-holy-retention","retention-foreign-native-spread","retention-inquisitor-boundaries","retention-inquisitor-outcome"}}
local boost=assert(LekmodScenarioParameters.boost);local retain=assert(LekmodScenarioParameters.retention)
boost=boost=="messiah";retain=retain=="unity"
local phase,which,actor,foreignID,pendingForeign,foreignDone,err,prior,inqID="init",1,nil,nil,false,false,nil,nil,nil
local targetKinds={"ordinary","holy"}
local function currentTarget()return which==1 and target()or Players[1]:GetCapitalCity()end
local function expectedStrength()return math.floor(GameInfo.Units.UNIT_PROPHET.ReligiousStrength*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER*(boost and 125 or 100)/100)end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or not pendingForeign then return end;pendingForeign=false
 local ok,e=pcall(function()
  local u=assert(Players[1]:GetUnitByID(foreignID));local c=target();assert(Players[1]:IsTurnActive()and u:GetReligion()==religionB and u:GetMoves()>0)
  local pressure=c:GetReligionPressure(religionB);local charges=u:GetSpreadsLeft();local strength=u:GetConversionStrength()
  assert(u:CanStartMission(MissionTypes.MISSION_SPREAD_RELIGION,-1,-1,u:GetPlot(),0));u:PushMission(MissionTypes.MISSION_SPREAD_RELIGION,-1,-1,0,0,1)
  assert(u:GetSpreadsLeft()==charges-1 and c:GetReligionPressure(religionB)==pressure+strength)
  LekmodScenarioEvent("native-retention-foreign-spread",{before=pressure,after=c:GetReligionPressure(religionB),strength=strength,charges_before=charges,charges_after=u:GetSpreadsLeft()});foreignDone=true
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(p)local s=world();s.boost=boost;s.retention=retain;return s end
function LekmodScenario.step(p)
 assert(not err,err);assert(not Game.IsGameMultiPlayer()and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MALI)
 if phase=="init"then
  assert(GameInfo.Beliefs.BELIEF_MESSIAH.ProphetStrengthModifier==25 and GameInfo.Beliefs.BELIEF_UNITY_OF_PROPHETS.InquisitorPressureRetention==50)
  setupReligions(boost and GameInfoTypes.BELIEF_MESSIAH or GameInfoTypes.BELIEF_TITHE,retain);phase="ready"
 elseif phase=="ready"then
  if not LekmodScenarioAwait("strength-religion-inputs",ready())then return false end
  local cap=p:GetCapitalCity();local fc=Players[1]:GetCityByID(foreignControlCity)
  local foreignProphet=assert(Players[1]:InitUnit(GameInfoTypes.UNIT_PROPHET,fc:GetX(),fc:GetY()));assert(foreignProphet:GetReligion()==religionA and foreignProphet:GetConversionStrength()==expectedStrength());foreignProphet:Kill(false,-1)
  local missionary=assert(p:InitUnit(GameInfoTypes.UNIT_MISSIONARY,cap:GetX(),cap:GetY()));assert(missionary:GetConversionStrength()==GameInfo.Units.UNIT_MISSIONARY.ReligiousStrength*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER);missionary:Kill(false,-1)
  local otherCap=Players[1]:GetCapitalCity();local foreign=assert(Players[1]:InitUnit(GameInfoTypes.UNIT_MISSIONARY,otherCap:GetX(),otherCap:GetY()));foreignID=foreign:GetID();assert(foreign:GetReligion()==religionB);stage(foreign,target(),false)
  LekmodScenarioRecord("prophet-strength-owner-controls","PASS","same-religion foreign-owner Prophet has identical strength; ordinary Missionary excludes the Prophet modifier")
  LekmodScenarioRecord("religion-strength-inputs","PASS","valid native religion/wonder-free inputs, two targets, retained/nonretained religion and explicit unit/city staging prepared")
  phase="seed"
 elseif phase=="seed"then
  local cap=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes.UNIT_MISSIONARY,cap:GetX(),cap:GetY()));actor=u:GetID();local c=currentTarget();stage(u,c,false)
  prior={a=c:GetReligionPressure(religionA),b=c:GetReligionPressure(religionB),strength=u:GetConversionStrength()};act(u,"MISSION_SPREAD_RELIGION");phase="seed-check"
 elseif phase=="seed-check"then
  local c=currentTarget();local u=p:GetUnitByID(actor);if not LekmodScenarioAwait("retention-seed-charge",u and u:GetSpreadsLeft()==1)then return false end
  assert(c:GetReligionPressure(religionA)==prior.a+prior.strength and c:GetReligionPressure(religionB)==prior.b);u:Kill(false,-1);phase="prophet"
 elseif phase=="prophet"then
  local cap=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes.UNIT_PROPHET,cap:GetX(),cap:GetY()));actor=u:GetID();local c=currentTarget();stage(u,c,false)
  assert(u:GetReligion()==religionA and u:GetSpreadsLeft()==4 and u:GetConversionStrength()==expectedStrength())
  prior={a=c:GetReligionPressure(religionA),b=c:GetReligionPressure(religionB),strength=u:GetConversionStrength(),followers=u:GetNumFollowersAfterSpread(),majority=u:GetMajorityReligionAfterSpread(),holy=c:IsHolyCityForReligion(religionB)};assert(prior.a>0 and prior.b>0)
  act(u,"MISSION_SPREAD_RELIGION");phase="prophet-check"
 elseif phase=="prophet-check"then
  local c=currentTarget();local u=p:GetUnitByID(actor);if not LekmodScenarioAwait("retention-prophet-charge",u and u:GetSpreadsLeft()==3)then return false end
  local retained=retain and math.floor(prior.b/2)or 0
  assert(c:GetReligionPressure(religionA)==prior.a+prior.strength and c:GetReligionPressure(religionB)==retained)
  assert(c:GetNumFollowers(religionA)==prior.followers and c:GetReligiousMajority()==prior.majority and c:IsHolyCityForReligion(religionB)==prior.holy)
  LekmodScenarioEvent("native-prophet-strength-retention",{boost=boost,retention=retain,target=targetKinds[which],before=prior,after=pressures(c),religion_a=religionA,religion_b=religionB,unit=actor,charges=3})
  if which==1 then which=2;phase="seed"else
   LekmodScenarioRecord("prophet-native-pressure","PASS","both actual Prophet missions add exact base/25%-boosted pressure to existing own pressure and consume one charge")
   LekmodScenarioRecord("prophet-preview-holy-retention","PASS","other religion retains exactly0/50%; follower/majority previews match, and foreign Holy City flag survives without extra pressure")
   pendingForeign=true;phase="foreign";return "turn"
  end
 elseif phase=="foreign"then
  if not foreignDone then return "turn"end
  assert(target():GetNumFollowers(religionB)>0)
  LekmodScenarioRecord("retention-foreign-native-spread","PASS","real AI owner-turn Missionary reintroduces foreign pressure and spends one charge")
  local cap=p:GetCapitalCity();local inq=assert(p:InitUnit(GameInfoTypes.UNIT_INQUISITOR,cap:GetX(),cap:GetY()));inqID=inq:GetID();assert(inq:GetReligion()==religionA)
  local other=Players[1]:GetCapitalCity();assert(not inq:CanStartMission(MissionTypes.MISSION_REMOVE_HERESY,-1,-1,other:Plot(),0))
  local neighbor;for d=0,5 do local q=Map.PlotDirection(other:GetX(),other:GetY(),d);if q and not q:IsCity()and not q:IsWater()and not q:IsMountain()then neighbor=q;break end end;assert(neighbor and not inq:CanStartMission(MissionTypes.MISSION_REMOVE_HERESY,-1,-1,neighbor,0))
  stage(inq,target(),true);assert(inq:CanStartMission(MissionTypes.MISSION_REMOVE_HERESY,-1,-1,inq:GetPlot(),0));prior=pressures(target())
  LekmodScenarioRecord("retention-inquisitor-boundaries","PASS","foreign center/adjacent purge queries reject; owned polluted city accepts")
  act(inq,"MISSION_REMOVE_HERESY");phase="purged"
 elseif phase=="purged"then
  local inq=p:GetUnitByID(inqID);if not LekmodScenarioAwait("retention-inquisitor-consumed",not inq or inq:IsDead()or inq:IsDelayedDeath())then return false end
  local c=target();local expected=retain and math.floor(prior.religions[religionB].pressure/2)or 0
  assert(c:GetReligionPressure(religionA)==prior.religions[religionA].pressure and c:GetReligionPressure(religionB)==expected)
  if not retain then assert(c:GetNumFollowers(religionB)==0)end
  LekmodScenarioEvent("native-inquisitor-retention",{boost=boost,retention=retain,before=prior,after=pressures(c),religion_a=religionA,religion_b=religionB})
  LekmodScenarioRecord("retention-inquisitor-outcome","PASS","actual Remove Heresy consumes Inquisitor, preserves own pressure and retains exactly0/50%foreign pressure");return true
 end
 return false
end
