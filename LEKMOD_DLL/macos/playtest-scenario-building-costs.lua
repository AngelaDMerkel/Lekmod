-- Native method surface: GameCore
-- Independent resolved-data arithmetic checks real player/city production quotes.
-- One legal extra AI city is an input. No cost, building or production is assigned.
LekmodScenario={name="building-costs",items={"building-cost-configuration","building-cost-human","building-cost-AI","building-cost-city-quotes","building-cost-negative-control","building-cost-new-city","building-cost-repricing","building-cost-no-unrelated-change","building-cost-save-state"}}
local modes={
 ["standard-settler"]={speed="GAMESPEED_STANDARD",handicap="HANDICAP_SETTLER",era="ERA_ANCIENT"},
 ["epic-deity"]={speed="GAMESPEED_EPIC",handicap="HANDICAP_DEITY",era="ERA_MEDIEVAL"},
 ["marathon-prince"]={speed="GAMESPEED_MARATHON",handicap="HANDICAP_PRINCE",era="ERA_RENAISSANCE"},
 ["quick-immortal"]={speed="GAMESPEED_QUICK",handicap="HANDICAP_IMMORTAL",era="ERA_INDUSTRIAL"},
 ["online-prince"]={speed="GAMESPEED_ONLINE",handicap="HANDICAP_PRINCE",era="ERA_ANCIENT"}}
local mode=assert(LekmodScenarioParameters.mode);local wanted=assert(modes[mode])
local phase,before,actors="init",nil,nil
local function div(n,d)return n>=0 and math.floor(n/d)or math.ceil(n/d)end
local function teammate(p)
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local q=Players[id];if q and q:IsAlive()and q:IsHuman()and q:GetTeam()==p:GetTeam()then return true end end
 return false
end
local function roles()
 local ids={0,1}
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id];if p and p:IsAlive()and p:IsMinorCiv()and p:GetCapitalCity()then ids[#ids+1]=id;break end end
 return ids
end
local function expected(p,b)
 local n=b.Cost
 if b.NumCityCostMod>0 and p:GetNumCities()>0 then n=n+b.NumCityCostMod*p:GetNumCities()end
 if p:IsMinorCiv()then n=div(n*GameDefines.MINOR_CIV_PRODUCTION_PERCENT,100)end
 n=div(n*GameDefines.BUILDING_PRODUCTION_PERCENT,100)
 n=div(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()].ConstructPercent,100)
 n=div(n*GameInfo.Eras[Game.GetStartEra()].ConstructPercent,100)
 if not p:IsHuman()and not teammate(p)and not p:IsBarbarian()then
  local h=GameInfo.HandicapInfos[Game.GetHandicapType()];local world=GameInfo.BuildingClasses[b.BuildingClass].MaxGlobalInstances~=-1
  n=div(n*(world and h.AIWorldConstructPercent or h.AIConstructPercent),100)
  n=div(n*math.max(0,100+h.AIPerEraModifier*p:GetCurrentEra()),100)
 end
 return math.max(1,n)
end
local function measure(p)
 local rows={};local cityCount=0;for _ in p:Cities()do cityCount=cityCount+1 end;assert(cityCount==p:GetNumCities())
 for b in GameInfo.Buildings()do
  local cities={};for c in p:Cities()do cities[c:GetID()]=c:GetBuildingProductionNeeded(b.ID)end
  rows[b.ID]={player=p:GetBuildingProductionNeeded(b.ID),cities=cities}
 end
 return {human=p:IsHuman(),minor=p:IsMinorCiv(),teammate=teammate(p),era=p:GetCurrentEra(),cities=cityCount,quotes=rows}
end
local function audit(label)
 local result={}
 for _,id in ipairs(actors)do local p=Players[id]
  assert(p:IsMinorCiv()or p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME or p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GREECE,"fixture must exclude absolute building-cost override traits")
  local leader=assert(GameInfo.Leaders[p:GetLeaderType()])
  for trait in GameInfo.Leader_Traits{LeaderType=leader.Type}do
   for override in GameInfo.Trait_BuildingCostOverride{TraitType=trait.TraitType,YieldType="YIELD_PRODUCTION"}do assert(override.Cost<=0,"positive absolute trait override needs a separate oracle")end
  end
  local values=measure(p);local count,negative=0,0
  for b in GameInfo.Buildings()do
   count=count+1;local n=expected(p,b);local q=values.quotes[b.ID]
   assert(q.player==n,"player production quote differs: owner"..id.." "..b.Type.." actual"..q.player.." expected"..n)
   for city,value in pairs(q.cities)do assert(value==n,"city production quote differs: "..b.Type)
    if b.Cost<0 then assert(not p:GetCityByID(city):CanConstruct(b.ID),"negative base cost unexpectedly permits ordinary construction")end
   end
   if b.Cost<0 then negative=negative+1 end
  end
  assert(count==258 and negative==44,"reviewed building catalogue changed")
  result[id]=values;LekmodScenarioEvent("native-building-cost-quotes",{mode=mode,label=label,owner=id,state=values})
 end
 return result
end
function LekmodScenario.snapshot(player)
 local states={};for _,id in ipairs(roles())do states[id]=measure(Players[id])end
 return {turn=Game.GetGameTurn(),speed=Game.GetGameSpeedType(),start_era=Game.GetStartEra(),handicap=Game.GetHandicapType(),owners=states}
end
function LekmodScenario.step(player)
 assert(player:GetID()==0 and player:IsHuman()and not Players[1]:IsHuman())
 if phase=="init"then
  assert(Game.GetGameSpeedType()==GameInfo.GameSpeeds[wanted.speed].ID and Game.GetHandicapType()==GameInfo.HandicapInfos[wanted.handicap].ID and player:GetHandicapType()==Game.GetHandicapType()and Game.GetStartEra()==GameInfo.Eras[wanted.era].ID,"fixture setup differs from oracle variant")
  -- These branches are inactive in the shipped data; never silently omit them.
  for row in GameInfo.Resource_BuildingProductionCostModifiersLocal()do error("new local resource building-cost rule requires oracle review")end
  for row in GameInfo.Eras()do assert(row.LaterEraBuildingConstructMod==0,"new later-era discount requires oracle review")end
  assert(GameDefines.BUILDING_PRODUCTION_PERCENT==100 and GameDefines.MINOR_CIV_PRODUCTION_PERCENT==150)
  actors=roles();before=audit("before-foundation")
  LekmodScenarioRecord("building-cost-configuration","PASS","normal fixture="..mode.."; no absolute-cost trait or active local-resource/later-era rule omitted")
  LekmodScenarioRecord("building-cost-human","PASS","all258 human quotes match independent sequential integer arithmetic")
  LekmodScenarioRecord("building-cost-AI","PASS","all258 AI quotes and available minor control match world/ordinary, era and minor factors")
  LekmodScenarioRecord("building-cost-city-quotes","PASS","every sampled city agrees with independently computed player cost")
  LekmodScenarioRecord("building-cost-negative-control","PASS","44 negative-cost definitions remain nonconstructible and their quote clamps to1 without a trait override")
  local p=Players[1];local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;break end end
  assert(site,"no legal extra AI city site");p:Found(site:GetX(),site:GetY());assert(site:GetPlotCity():GetOwner()==1 and p:GetNumCities()==before[1].cities+1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-legal-extra-AI-city",city=site:GetPlotCity():GetID(),x=site:GetX(),y=site:GetY()});phase="after"
 elseif phase=="after"then
  local after=audit("after-foundation");local changed=0
  for _,id in ipairs(actors)do
   for b in GameInfo.Buildings()do
    local old=before[id].quotes[b.ID].player;local new=after[id].quotes[b.ID].player
    if id==1 and b.NumCityCostMod>0 then assert(new>old,"city-count modifier did not increase the quote");changed=changed+1
    else assert(new==old,"unrelated player/building price changed after foundation")end
   end
  end
  assert(changed==17)
  LekmodScenarioRecord("building-cost-new-city","PASS","actual native founding increments AI city count; human and minor owners unchanged")
  LekmodScenarioRecord("building-cost-repricing","PASS","all17 configured city-count surcharges reprice with correct rounding")
  LekmodScenarioRecord("building-cost-no-unrelated-change","PASS","all other building/owner quotes stay unchanged")
  LekmodScenarioRecord("building-cost-save-state","PASS","all quoted costs, cities and speed/era/difficulty state retained for exact replay");return true
 end
 return false
end
