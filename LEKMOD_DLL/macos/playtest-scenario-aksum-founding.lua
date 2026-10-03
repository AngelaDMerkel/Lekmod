-- Native method surface: GameCore
-- Extra cities/population, faith and Prophets are supplied inputs. Founding uses
-- the normal Prophet action and original religion confirmation callbacks.
LekmodScenario={name="aksum-founding",items={"aksum-founding-prerequisites","aksum-native-found-event","aksum-all-owned-followers","aksum-foreign-control","aksum-repeat-rejection"}}
local phase,response,prophet,religion,foreignBefore,event="init",nil,nil,nil,nil,nil
LuaEvents.LekmodScenarioReligionResponse.Add(function(kind,value)response={kind=kind,value=value}end)
GameEvents.ReligionFounded.Add(function(owner,holy,kind)
 if owner==0 then event={owner=owner,holy=holy,religion=kind};LekmodScenarioEvent("native-Aksum-religion-founded",event)end
end)
local function action(u,name)
 UI.SelectUnit(u)
 for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type==name then assert(Game.CanHandleAction(id));Game.HandleAction(id);return end end
 error("normal religion action missing: "..name)
end
local function create(p)
 local c=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes.UNIT_PROPHET,c:GetX(),c:GetY()))
 LekmodScenarioEvent("fixture-setup",{operation="provided-Prophet",owner=p:GetID(),unit=u:GetID()});return u:GetID()
end
local function cityState(c,kind)
 return {x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),majority=c:GetReligiousMajority(),followers=kind and c:GetNumFollowers(kind)or 0,holy=kind and c:IsHolyCityForReligion(kind)or false}
end
local function foreign(kind)
 local cities={};for c in Players[1]:Cities()do cities[c:GetID()]=cityState(c,kind)end;return cities
end
function LekmodScenario.snapshot(p)
 local kind=p:GetReligionCreatedByPlayer();local cities,units={},{}
 for c in p:Cities()do cities[c:GetID()]=cityState(c,kind>0 and kind or nil)end
 for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_PROPHET then units[u:GetID()]={religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY()}end end
 return {turn=Game.GetGameTurn(),religion=kind,pantheon=p:GetBeliefInPantheon(),faith=p:GetFaith(),cities=cities,foreign=foreign(kind>0 and kind or nil),prophets=units}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_AKSUM and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION))
 local cap=p:GetCapitalCity()
 if not cap or not Players[1]:GetCapitalCity()then return "turn"end
 if phase=="init"then
  assert(not p:HasCreatedPantheon()and not p:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>0)
  for n=1,2 do local chosen
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then chosen=q;break end
   end
   assert(chosen);p:Found(chosen:GetX(),chosen:GetY());local c=assert(chosen:GetPlotCity());c:SetPopulation(n==1 and 3 or 5,true)
   LekmodScenarioEvent("fixture-setup",{operation="provided-extra-Aksum-city",city=c:GetID(),population=c:GetPopulation()})
  end
  local amount=Game.GetMinimumFaithNextPantheon()+1;p:ChangeFaith(amount)
  LekmodScenarioEvent("fixture-setup",{operation="provided-pantheon-faith",amount=amount});assert(p:CanCreatePantheon(true))
  response=nil;LuaEvents.LekmodScenarioPantheon();phase="pantheon"
 elseif phase=="pantheon"then
  if not response then return false end
  if not LekmodScenarioAwait("Aksum-pantheon",p:HasCreatedPantheon())then return false end
  assert(response.kind=="pantheon");foreignBefore=foreign(nil);prophet=create(p)
  LekmodScenarioRecord("aksum-founding-prerequisites","PASS","normal pantheon callback and supplied legal cities/Prophet; religion not preassigned")
  phase="mission"
 elseif phase=="mission"then
  action(assert(p:GetUnitByID(prophet)),"MISSION_FOUND_RELIGION");phase="consumed"
 elseif phase=="consumed"then
  local u=p:GetUnitByID(prophet);if u and not u:IsDead()and not u:IsDelayedDeath()then return false end
  response=nil;LuaEvents.LekmodScenarioReligionChoice("found",cap:GetX(),cap:GetY());phase="found"
 elseif phase=="found"then
  if not response then return false end
  if not LekmodScenarioAwait("Aksum-religion",p:HasCreatedReligion()and event)then return false end
  religion=p:GetReligionCreatedByPlayer();assert(response.kind=="found"and response.value==religion and event.holy==cap:GetID()and event.religion==religion)
  assert(cap:IsHolyCityForReligion(religion))
  LekmodScenarioRecord("aksum-native-found-event","PASS","normal consumed Prophet and original confirmation emitted player/holy-city-ID/religion event")
  local count=0;for c in p:Cities()do count=count+1;assert(c:GetReligiousMajority()==religion and c:GetNumFollowers(religion)==c:GetPopulation(),"owned city was not fully converted")end;assert(count>=3)
  LekmodScenarioRecord("aksum-all-owned-followers","PASS","holy city and two supplied population3/5 cities fully follow the founded religion")
  for id,before in pairs(foreignBefore)do local c=assert(Players[1]:GetCityByID(id));assert(c:GetReligiousMajority()==before.majority and c:GetPopulation()==before.population and c:GetNumFollowers(religion)==0)end
  LekmodScenarioRecord("aksum-foreign-control","PASS","foreign cities retain their prior majority/population and gain zero followers")
  local probe=assert(p:GetUnitByID(create(p)));assert(not probe:CanStartMission(GameInfoTypes.MISSION_FOUND_RELIGION,-1,-1,probe:GetPlot(),0))
  LekmodScenarioRecord("aksum-repeat-rejection","PASS","new supplied Prophet cannot found another religion after the first")
  return true
 end
 return false
end
