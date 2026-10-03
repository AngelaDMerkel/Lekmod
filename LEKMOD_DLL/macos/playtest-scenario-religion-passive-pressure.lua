-- Native method surface: GameCore
-- Religions, legal city sites, populations/food, friendship and source buildings
-- are fixture inputs. Forecasts and two ordinary passive-pressure updates are
-- outcomes; pressure counters are never assigned during observation.
LekmodScenario={name="religion-passive-pressure",items={"passive-pressure-data","passive-pressure-baseline","passive-pressure-friend-threshold","passive-pressure-nonfounder-control","passive-pressure-building-catalogue","passive-pressure-removal","passive-pressure-owner-controls","passive-pressure-native-settlement","passive-pressure-persistence"}}
local founderName=assert(LekmodScenarioParameters.founder)
local variant=assert(LekmodScenarioParameters.beliefs)
local owner=assert(({rome=0,czechia=1,aksum=2})[founderName]);local other=(owner+1)%3;local third=(owner+2)%3
local unity=variant=="unity"or variant=="both";local promised=variant=="promised"or variant=="both"
local kinds={"BUILDING_GRAND_TEMPLE","BUILDING_STPETERS","BUILDING_VILNIUS"}
local phase,religionA,religionB,minorID,sourceID,start,tick,index="init",nil,nil,nil,nil,nil,0,1
local before,baseline
local seedID,seedBefore,seedStrength,seedCharges
local reformations,reserved={},{ }
local function has(list,id)for _,v in ipairs(list)do if v==id then return true end end;return false end
local function cities()
 local result={};for id=0,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id]
  if p and p:IsAlive()then for c in p:Cities()do result[#result+1]=c end end
 end;return result
end
local function reformation(p,religion)
 local existing
 for _,id in ipairs(Game.GetBeliefsInReligion(religion))do local row=GameInfo.Beliefs[id]
  if row.Reformation==true or row.Reformation==1 then assert(not existing);existing=id end
 end
 if existing then
  for _,field in ipairs({"FriendlyCityStateSpreadModifier","SpreadModifierOwnedCities","SpreadModifierUnownedCities","SpreadStrengthModifier","SpreadDistanceModifier"})do assert(GameInfo.Beliefs[existing][field]==0,"native reformation needs a pressure oracle extension")end
  reformations[p:GetID()]=existing;reserved[existing]=true
  LekmodScenarioEvent("native-existing-reformation",{owner=p:GetID(),religion=religion,belief=existing,type=GameInfo.Beliefs[existing].Type});return
 end
 assert(p:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_CZECHIA or p:IsHuman(),"AI Czech founding did not choose its native reformation")
 for _,name in ipairs({"BELIEF_WORK_ETHIC","BELIEF_JESUIT_EDUCATION"})do local id=GameInfoTypes[name]
  if not reserved[id]and has(Game.GetAvailableReformationBeliefs(),id)then
   reserved[id]=true;reformations[p:GetID()]=id;Network.SendFoundPantheon(p:GetID(),id)
   LekmodScenarioEvent("fixture-setup",{operation="provided-available-reformation-choice",owner=p:GetID(),religion=religion,belief=name});return
  end
 end
 error("no unused pressure-neutral reformation available")
end
local function convert(c,id)
 c:ConvertPercentFollowers(id,-1,100);c:ConvertPercentFollowers(id,0,100)
 for r in GameInfo.Religions()do if r.ID>0 and r.ID~=id then c:ConvertPercentFollowers(id,r.ID,100)end end
 assert(c:GetReligiousMajority()==id)
end
local function found(p,target,near,label)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(q:GetX(),q:GetY(),target:GetX(),target:GetY())
  if d>=4 and d<=7 and q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()and(not near or Map.PlotDistance(q:GetX(),q:GetY(),near:GetX(),near:GetY())<=8)and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());LekmodScenarioEvent("fixture-setup",{operation="provided-nearby-source-city",label=label,owner=p:GetID(),city=c:GetID(),x=q:GetX(),y=q:GetY()});return c
  end
 end;error("no legal source city site for "..label)
end
local function world()
 local religion=Players[owner]:GetReligionCreatedByPlayer();local rows={}
 for _,c in ipairs(cities())do
  local counts,modifier={},0
  for b in GameInfo.Buildings()do local n=c:GetNumActiveBuilding(b.ID)
   if n>0 and b.ReligiousPressureModifier~=0 then counts[b.Type]=n;modifier=modifier+n*b.ReligiousPressureModifier end
  end
  local rate,trades=c:GetPressurePerTurn(religion);local p=Players[c:GetOwner()]
  rows[c:GetOwner()..":"..c:GetID()]={owner=c:GetOwner(),id=c:GetID(),x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),food=c:GetFoodTimes100(),majority=c:GetReligiousMajority(),holy=c:IsHolyCityForReligion(religion),pressure=c:GetReligionPressure(religion),rate=rate,trades=trades,buildings=counts,modifier=modifier,minor=p:IsMinorCiv(),friend=p:IsMinorCiv()and p:IsFriends(owner)or false,influence100=p:IsMinorCiv()and Game.ReadMinorInfluenceForTest(p:GetID(),owner)or 0}
 end
 return {turn=Game.GetGameTurn(),founder=owner,beliefs=variant,religion=religion,rows=rows}
end
function LekmodScenario.snapshot(player)return world()end
local function oracle(w,key)
 local target=w.rows[key];local base=GameInfo.GameSpeeds[Game.GetGameSpeedType()].ReligiousPressureAdjacentCity;local total=target.holy and base*GameDefines.RELIGION_PER_TURN_FOUNDING_CITY_PRESSURE or 0
 local terms={}
 for sourceKey,s in pairs(w.rows)do
  local distance=Map.PlotDistance(s.x,s.y,target.x,target.y)
  if sourceKey~=key and s.majority==w.religion and distance<=GameDefines.RELIGION_ADJACENT_CITY_DISTANCE then
   local value=base
   if unity and target.minor and target.friend then value=math.floor(value*200/100)end
   if target.owner==owner then value=math.floor(value*(100+(promised and 100 or 0)+(owner==1 and 100 or 0))/100)
   elseif owner==2 then value=0 end
   value=math.floor(value*(100+s.modifier)/100);total=total+value
   terms[sourceKey]={distance=distance,pressure=value}
  end
 end
 return total,terms
end
local function audit(label)
 local w=world();local expected={}
 for key,row in pairs(w.rows)do local rate,terms=oracle(w,key);assert(row.trades==0 and row.rate==rate,label.." pressure mismatch "..key.." got="..row.rate.." wanted="..rate);expected[key]={rate=rate,sources=terms}end
 LekmodScenarioEvent("native-passive-pressure-quotes",{label=label,world=w,expected=expected});return w
end
local function friendship(major,value,label)
 local m=Players[minorID];local raw=Game.ReadMinorInfluenceForTest(minorID,major);assert(raw%100==0)
 m:ChangeMinorCivFriendshipWithMajor(major,value-raw/100);assert(Game.ReadMinorInfluenceForTest(minorID,major)==value*100)
 LekmodScenarioEvent("fixture-setup",{operation="provided-friendship",minor=minorID,major=major,points=value,label=label})
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer()and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION))
 assert(Players[0]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_CZECHIA and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_AKSUM)
 if phase=="init"then
  assert(GameDefines.RELIGION_ADJACENT_CITY_DISTANCE==10 and GameDefines.FRIENDSHIP_THRESHOLD_FRIENDS==30 and GameDefines.RELIGION_PER_TURN_FOUNDING_CITY_PRESSURE==5)
  assert(GameInfo.Traits.TRAIT_CZECHIA.SelfReligiousPressureModifier==100 and GameInfo.Traits.TRAIT_AKSUM.ForeignRelgionPressureModifier==-100 and GameInfo.Beliefs.BELIEF_PROMISED_LAND.SpreadModifierOwnedCities==100 and GameInfo.Beliefs.BELIEF_RELIGIOUS_UNITY.FriendlyCityStateSpreadModifier==100)
  local configured=0;for b in GameInfo.Buildings()do if b.ReligiousPressureModifier~=0 then assert(has(kinds,b.Type)and b.ReligiousPressureModifier==100);configured=configured+1 end end;assert(configured==3)
  for id=0,2 do assert(Players[id]:GetNumCities()==1 and not Players[id]:HasCreatedReligion()and #Players[id]:GetTradeRoutes()==0)end
  local ids={};for r in GameInfo.Religions()do if r.ID>0 then ids[#ids+1]=r.ID end end;religionA,religionB=ids[1],ids[2]
  Game.FoundReligion(owner,religionA,nil,promised and GameInfoTypes.BELIEF_PROMISED_LAND or GameInfoTypes.BELIEF_TITHE,GameInfoTypes.BELIEF_MANDIRS,-1,-1,Players[owner]:GetCapitalCity())
  Game.EnhanceReligion(owner,religionA,GameInfoTypes.BELIEF_HOLY_WARRIORS,unity and GameInfoTypes.BELIEF_RELIGIOUS_UNITY or GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS)
  Game.FoundReligion(other,religionB,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_PAGODAS,-1,-1,Players[other]:GetCapitalCity());Game.EnhanceReligion(other,religionB,GameInfoTypes.BELIEF_MOSQUES,GameInfoTypes.BELIEF_CRAFTWORKS)
  for _,rid in ipairs({religionA,religionB})do for _,id in ipairs(Game.GetBeliefsInReligion(rid))do local row=GameInfo.Beliefs[id];if row.Reformation==true or row.Reformation==1 then reserved[id]=true end end end
  reformation(Players[owner],religionA);reformation(Players[other],religionB)
  for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id];if p and p:IsAlive()and p:IsMinorCiv()and p:GetCapitalCity()then minorID=minorID or id end end
  local target=assert(Players[minorID]):GetCapitalCity();local source=found(Players[owner],target,nil,"founder-source");sourceID=source:GetID();local foreign=found(Players[other],target,source,"foreign-source-of-same-religion")
  for _,c in ipairs(cities())do c:SetPopulation(Players[c:GetOwner()]:IsMinorCiv()and 16 or 8,true);convert(c,religionB)end
  convert(Players[owner]:GetCapitalCity(),religionA);convert(source,religionA);convert(foreign,religionA)
  LekmodScenarioEvent("fixture-setup",{operation="provided-two-religions-populations-and-conversions",founder=owner,other=other,a=religionA,b=religionB,source=sourceID,minor=minorID})
  LekmodScenarioRecord("passive-pressure-data","PASS","all configured100building modifiers,100friendly/owned belief andCzech100/Aksum-100 trait values checked")
  phase="religions"
 elseif phase=="religions"then
  if not LekmodScenarioAwait("passive-reformations",has(Game.GetBeliefsInReligion(religionA),reformations[owner])and has(Game.GetBeliefsInReligion(religionB),reformations[other]))then return false end
  local human=Players[0];local home=owner==0 and human:GetCityByID(sourceID)or human:GetCapitalCity();local old=home:GetReligiousMajority()
  if old~=religionB then convert(home,religionB)end
  local u=assert(human:InitUnit(GameInfoTypes.UNIT_MISSIONARY,home:GetX(),home:GetY()));assert(u:GetReligion()==religionB)
  if old~=religionB then convert(home,old)end
  seedID=u:GetID();local target=Players[minorID]:GetCapitalCity();local plot
  for direction=0,5 do local q=Map.PlotDirection(target:GetX(),target:GetY(),direction);if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then plot=q;break end end;assert(plot)
  u:SetXY(plot:GetX(),plot:GetY(),false,true,true);seedBefore=target:GetReligionPressure(religionB);seedStrength=u:GetConversionStrength();seedCharges=u:GetSpreadsLeft()
  assert(seedStrength==GameInfo.Units.UNIT_MISSIONARY.ReligiousStrength*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER)
  LekmodScenarioEvent("fixture-setup",{operation="provided-buffer-missionary-and-position",owner=0,unit=seedID,religion=religionB,pressure_before=seedBefore,strength=seedStrength,x=plot:GetX(),y=plot:GetY()})
  UI.SelectUnit(u);local action
  for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type=="MISSION_SPREAD_RELIGION"then action=id;break end end
  assert(action and Game.CanHandleAction(action),"normal buffer spread action is not legal");Game.HandleAction(action);phase="buffered";return false
 elseif phase=="buffered"then
  local target=Players[minorID]:GetCapitalCity();local unit=assert(Players[0]:GetUnitByID(seedID))
  if not LekmodScenarioAwait("native-pressure-buffer",target:GetReligionPressure(religionB)==seedBefore+seedStrength and unit:GetSpreadsLeft()==seedCharges-1)then return false end
  assert(target:GetReligiousMajority()==religionB and target:GetReligionPressure(religionB)>=10000)
  LekmodScenarioEvent("native-provided-pressure-buffer",{minor=minorID,religion=religionB,before=seedBefore,added=seedStrength,after=target:GetReligionPressure(religionB),charges=unit:GetSpreadsLeft()})
  friendship(owner,29,"below-friends");baseline=audit("below-friends")
  friendship(third,60,"friendly-nonfounder");local unchanged=audit("nonfounder-friend")
  for key,row in pairs(baseline.rows)do assert(unchanged.rows[key].rate==row.rate)end
  LekmodScenarioRecord("passive-pressure-nonfounder-control","PASS","friendship with a different major cannot activate this religion founder's bonus")
  friendship(owner,30,"at-friends");local friendly=audit("at-friends")
  local key=minorID..":"..Players[minorID]:GetCapitalCity():GetID();local old=baseline.rows[key].rate;local new=friendly.rows[key].rate
  assert(new==(unity and old*2 or old));if owner~=2 then assert(old>0)else assert(old==0 and new==0)end
  friendship(owner,29,"friendship-removed");local removed=audit("friendship-removed");assert(removed.rows[key].rate==old)
  friendship(owner,60,"friendly-observation-budget");baseline=audit("friendly-restored")
  LekmodScenarioRecord("passive-pressure-friend-threshold","PASS","29/30 threshold andremoval/reentry use founderfriendship; Aksum foreignzero remainszero")
  LekmodScenarioRecord("passive-pressure-baseline","PASS","all city forecasts match summed nearby sources plus ownholy pressure, with no trade connections")
  phase="building-add"
 elseif phase=="building-add"then
  local c=assert(Players[owner]:GetCityByID(sourceID));local id=GameInfoTypes[kinds[index]];assert(c:GetNumBuilding(id)==0);c:SetNumRealBuilding(id,1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-pressure-building",owner=owner,city=sourceID,building=kinds[index],count=1});audit("add-"..kinds[index]);phase="building-remove"
 elseif phase=="building-remove"then
  local c=Players[owner]:GetCityByID(sourceID);c:SetNumRealBuilding(GameInfoTypes[kinds[index]],0);local removed=audit("remove-"..kinds[index])
  for key,row in pairs(baseline.rows)do assert(removed.rows[key].rate==row.rate)end
  index=index+1;if index<=#kinds then phase="building-add"else phase="prepare-turns"end
 elseif phase=="prepare-turns"then
  local c=Players[owner]:GetCityByID(sourceID);local kind=kinds[owner+1];c:SetNumRealBuilding(GameInfoTypes[kind],1)
  for id=0,2 do local p=Players[id];p:ChangeFaith(-p:GetFaith());local remove={}
   for u in p:Units()do local info=GameInfo.Units[u:GetUnitType()];if info.SpreadReligion==true or info.SpreadReligion==1 or info.FoundReligion==true or info.FoundReligion==1 then remove[#remove+1]=u:GetID()end end
   for _,uid in ipairs(remove)do local u=p:GetUnitByID(uid);LekmodScenarioEvent("fixture-setup",{operation="provided-no-active-religious-units",owner=id,unit=uid,type=u:GetUnitType()});u:Kill(false,-1)end
  end
  for _,city in ipairs(cities())do local threshold=city:GrowthThreshold();city:SetFood(math.floor(threshold/2));assert(city:GetFood()>2*math.abs(city:FoodDifference()),"two-turn population buffer is insufficient")end
  LekmodScenarioEvent("fixture-setup",{operation="provided-positive-building-food-buffers-and-zero-faith",building=kind,source=sourceID})
  LekmodScenarioRecord("passive-pressure-building-catalogue","PASS","all three shipped100pressure buildings independently applied through native city counts and forecasts")
  LekmodScenarioRecord("passive-pressure-removal","PASS","removal ofeach supplied building returns every forecast to its prebuilding baseline")
  LekmodScenarioRecord("passive-pressure-owner-controls","PASS","founder-owned versusforeign recipients, foreign-owned source, HolyCity and Aksumzero effects match the independent oracle")
  before=audit("before-ordinary-turns");start=Game.GetGameTurn();phase="turns";return "turn"
 elseif phase=="turns"then
  if Game.GetGameTurn()==start+tick then return "turn"end;assert(Game.GetGameTurn()==start+tick+1);tick=tick+1
  local after=audit("ordinary-turn-"..tick)
  for key,old in pairs(before.rows)do local now=assert(after.rows[key]);assert(now.population==old.population and now.majority==old.majority,"population/religion input changed during observation")
   assert(now.pressure==old.pressure+old.rate,"native passive pressure delta differs for "..key)
  end
  LekmodScenarioEvent("native-passive-pressure-settlement",{founder=owner,beliefs=variant,tick=tick,before=before,after=after});before=after
  if tick<2 then return "turn"end
  LekmodScenarioRecord("passive-pressure-native-settlement","PASS","two normal updates add the exact independently forecast pressure in every city; no pressure assignment")
  LekmodScenarioRecord("passive-pressure-persistence","PASS","positive building/pressure/friendship/majority/owner state retained for exact replay")
  return true
 end
 return false
end
