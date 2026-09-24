-- Supplied Great People build normally on naturally eligible owned plots.
-- Compare each owner's improvement yield delta, keeping terrain/resources intact.
LekmodScenario={name="vatican-great-improvements",items={"great-improvement-native-builds","great-improvement-vatican-bonuses","great-improvement-roman-controls"}}
local phase,records,issued,events="init",{[1]={},[3]={}},{},{}
local cases={{"BUILD_ACADEMY","UNIT_SCIENTIST"},{"BUILD_MANUFACTORY","UNIT_ENGINEER"},{"BUILD_CUSTOMS_HOUSE","UNIT_MERCHANT"},{"BUILD_HOLY_SITE","UNIT_PROPHET"},{"BUILD_CONCERT","UNIT_MUSICIAN"},{"BUILD_DOCK","UNIT_GREAT_ADMIRAL"},{"BUILD_CITADEL","UNIT_GREAT_GENERAL"}}
local yields={YieldTypes.YIELD_FOOD,YieldTypes.YIELD_GOLD,YieldTypes.YIELD_CULTURE}
local function values(q)local result={};for _,y in ipairs(yields)do result[y]=q:CalculateYield(y,false)end;return result end
local function additionalCity(p)
 local chosen,best=nil,-1
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:IsCoastalLand(10)and p:CanFound(q:GetX(),q:GetY())then
   local score,water=0,0;for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d)
    if a and a:GetOwner()==-1 and a:GetNumUnits()==0 and not a:IsMountain()and a:GetFeatureType()==-1 and a:GetResourceType(-1)==-1 then
     if a:IsWater()then water=water+1 else score=score+1 end
    end
   end
   if water>0 and score>best then chosen,best=q,score end
  end
 end
 assert(chosen,"no legal extra coastal city");p:Found(chosen:GetX(),chosen:GetY())
 LekmodScenarioEvent("fixture-setup",{operation="provided-coastal-city-for-great-person-sites",owner=p:GetID(),x=chosen:GetX(),y=chosen:GetY()})
end
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
 if owner==1 or owner==3 then events[owner..":"..x..":"..y]=improvement;LekmodScenarioEvent("native-great-improvement",{owner=owner,x=x,y=y,improvement=improvement})end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="building"or(owner~=1 and owner~=3)or issued[owner]then return end
 local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive()and not p:IsGoldenAge());issued[owner]=true
 local used={}
 for index,case in ipairs(cases)do local build=GameInfoTypes[case[1]];local info=GameInfo.Builds[case[1]];local chosen
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if not used[i]and q:GetOwner()==owner and not q:IsCity()and not q:IsMountain()and q:GetFeatureType()==-1 and q:GetResourceType(-1)==-1 and q:GetImprovementType()==-1 and q:GetNumUnits()==0 and q:CanBuild(build,owner,false,true)then chosen=q;break end
  end
  assert(chosen,"no natural owned site for "..case[1].." owner="..owner);used[chosen:GetPlotIndex()]=true
  local u=assert(p:InitUnit(GameInfoTypes[case[2]],chosen:GetX(),chosen:GetY()))
  local record={plot=chosen:GetPlotIndex(),unit=u:GetID(),before=values(chosen),improvement=GameInfoTypes[info.ImprovementType],build=case[1],resource=chosen:GetResourceType(-1),route=chosen:GetRouteType(),terrain=chosen:GetTerrainType()}
  records[owner][index]=record
  LekmodScenarioEvent("fixture-setup",{operation="provided-great-person-for-normal-build",owner=owner,unit=u:GetID(),type=case[2],plot=record.plot,build=case[1]})
  assert(u:CanStartMission(MissionTypes.MISSION_BUILD,build,-1,u:GetPlot(),0),"normal Great Person build unavailable: "..case[1])
  u:PushMission(MissionTypes.MISSION_BUILD,build,-1,0,0,1)
 end
end)
function LekmodScenario.snapshot(player)
 local types={};for _,c in ipairs(cases)do types[GameInfoTypes[GameInfo.Builds[c[1]].ImprovementType]]=true end
 local plots,owners={},{}
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if(q:GetOwner()==1 or q:GetOwner()==3)and types[q:GetImprovementType()]then plots[i]={owner=q:GetOwner(),improvement=q:GetImprovementType(),yields=values(q),resource=q:GetResourceType(-1),route=q:GetRouteType(),pillaged=q:IsImprovementPillaged()}end
 end
 for _,owner in ipairs({1,3})do local p=Players[owner];local cities,units,policies={},{},{}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation()}end
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft()}end end
  for info in GameInfo.Policies()do if p:HasPolicy(info.ID)then policies[info.Type]=true end end
  owners[owner]={cities=cities,units=units,policies=policies,era=p:GetCurrentEra()}
 end
 return {turn=Game.GetGameTurn(),plots=plots,owners=owners}
end
function LekmodScenario.step(player)
 assert(Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VATICAN and Players[3]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  for _,owner in ipairs({1,3})do local p=Players[owner]
   LekmodScenarioGrantTech(p,"TECH_THEOLOGY");additionalCity(p);additionalCity(p)
  end
  for _,owner in ipairs({1,3})do
   local land,water=0,0
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if q:GetOwner()==owner and not q:IsCity()and not q:IsMountain()and q:GetFeatureType()==-1 and q:GetResourceType(-1)==-1 and q:GetImprovementType()==-1 and q:GetNumUnits()==0 then
     if q:CanBuild(GameInfoTypes.BUILD_DOCK,owner,false,true)then water=water+1 end
     if q:CanBuild(GameInfoTypes.BUILD_ACADEMY,owner,false,true)then land=land+1 end
    end
   end
   LekmodScenarioEvent("great-person-site-inventory",{owner=owner,land=land,water=water})
   assert(land>=6 and water>=1,"fixture lacks six land and one water site before any build")
  end
  phase="building";return "turn"
 elseif phase=="building"then
  if not issued[1]or not issued[3]then return "turn"end
  for _,owner in ipairs({1,3})do
   for _,r in ipairs(records[owner])do local q=Map.GetPlotByIndex(r.plot);local u=Players[owner]:GetUnitByID(r.unit)
    if not LekmodScenarioAwait(owner.."-"..r.build,q:GetImprovementType()==r.improvement and(not u or u:IsDead()or u:IsDelayedDeath()))then return false end
    assert(events[owner..":"..q:GetX()..":"..q:GetY()]==r.improvement,"native BuildFinished missing")
    assert(q:GetResourceType(-1)==r.resource and q:GetRouteType()==r.route and q:GetTerrainType()==r.terrain and not q:IsImprovementPillaged())
    r.after=values(q)
   end
  end
  assert(#records[1]==7 and #records[3]==7)
  LekmodScenarioRecord("great-improvement-native-builds","PASS","14 normal AI owner-turn builds, real BuildFinished, supplied Great People consumed, terrain/resource/route unchanged")
  for index,case in ipairs(cases)do local v,r=records[1][index],records[3][index]
   LekmodScenarioEvent("great-improvement-yield-comparison",{kind=case[1],Vatican=v,Rome=r})
   for _,y in ipairs(yields)do local expected=y==YieldTypes.YIELD_FOOD and 2 or 1
    assert(v.after[y]-v.before[y]==r.after[y]-r.before[y]+expected,"Vatican extra yield differs: "..case[1].." yield="..y)
   end
   LekmodScenarioRecord("yield-"..case[1],"PASS","Vatican improvement delta versus Roman control: food +2, gold +1, culture +1")
  end
  LekmodScenarioRecord("great-improvement-vatican-bonuses","PASS","all seven Great Person improvement types match the three stated trait bonuses")
  LekmodScenarioRecord("great-improvement-roman-controls","PASS","same-build Roman controls isolate terrain baseline through before/after deltas")
  return true
 end
 return false
end
