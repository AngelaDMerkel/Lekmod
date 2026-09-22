-- Cities/population/shelter/launch sites/missiles/uranium are explicit inputs.
-- Every damage, death, population loss and diplomatic consequence is produced by
-- a real MISSION_NUKE, followed by the actual combat-end event before saving.
LekmodScenario={name="nuclear-cities",items={"nuclear-original-capital-survival","nuclear-small-city-destruction","nuclear-large-city-damage","nuclear-shelter-population","nuclear-war-and-diplomacy"}}
local phase,index,probe,ended="init",1,nil,false
local cases={{item="nuclear-original-capital-survival",population=4,capital=true},{item="nuclear-small-city-destruction",population=4,destroy=true},{item="nuclear-large-city-damage",population=12},{item="nuclear-shelter-population",population=12,shelter=true}}
Events.EndCombatSim.Add(function(owner,id)if probe and owner==0 and id==probe.missile then ended=true end end)
local function dist(a,b)return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY())end
local function found(owner,near)
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetOwner()==-1 and p:GetNumUnits()==0 and p:GetFeatureType()~=GameInfoTypes.FEATURE_FALLOUT and (not near or(dist(p,near)>=4 and dist(p,near)<=10))and Players[owner]:CanFound(p:GetX(),p:GetY())then
   Players[owner]:Found(p:GetX(),p:GetY());local c=assert(p:GetPlotCity())
   LekmodScenarioEvent("fixture-setup",{operation="provided-nuclear-test-city",owner=owner,id=c:GetID(),x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no legal city staging site for owner "..owner)
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local cities,units={},{}
  for c in Players[owner]:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),damage=c:GetDamage(),capital=c:IsOriginalCapital(),nuke_modifier=c:GetNukeModifier()}end
  for u in Players[owner]:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_NUCLEAR_MISSILE and not u:IsDelayedDeath()then units[u:GetID()]={x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end
  owners[owner]={cities=cities,missiles=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners,war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),nuked=Players[1]:IsNukedBy(0),explosions=Game.GetNukesExploded()}
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(Players[1]:IsAlive()and Players[1]:GetCapitalCity(),"living rival capital required")
  assert(Game.GetWinner()==-1)
  local resource=GameInfoTypes.RESOURCE_URANIUM;local added=math.max(0,10-player:GetNumResourceAvailable(resource,true));player:ChangeNumResourceTotal(resource,added)
  LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",amount=added})
  phase="prepare"
 elseif phase=="prepare"then
  local spec=cases[index];local target=spec.capital and Players[1]:GetCapitalCity()or found(1)
  assert(target:IsOriginalCapital()==(spec.capital==true))
  target:SetPopulation(spec.population,true);target:SetDamage(0)
  local shelter=GameInfoTypes.BUILDING_BOMB_SHELTER;assert(shelter)
  target:SetNumRealBuilding(shelter,spec.shelter and 1 or 0)
  local modifier=target:GetNukeModifier();assert(modifier==(spec.shelter and -75 or 0),"unexpected city shelter modifier")
  local launch
  for c in player:Cities()do if dist(c,target)>=4 and dist(c,target)<=12 then launch=c;break end end
  launch=launch or found(0,target)
  local missile=assert(player:InitUnit(GameInfoTypes.UNIT_NUCLEAR_MISSILE,launch:GetX(),launch:GetY()))
  assert(missile:GetX()==launch:GetX()and missile:GetY()==launch:GetY()and missile:NukeDamageLevel()==2)
  target:Plot():SetRevealed(player:GetTeam(),true)
  assert(missile:CanNukeAt(target:GetX(),target:GetY()),"target city cannot legally be nuked")
  probe={city=target:GetID(),plot=target:Plot(),missile=missile:GetID(),population=target:GetPopulation(),modifier=modifier,maxHP=target:GetMaxHitPoints(),explosions=Game.GetNukesExploded()}
  ended=false
  LekmodScenarioEvent("fixture-setup",{operation="provided-nuclear-city-inputs",case=spec.item,population=probe.population,modifier=modifier,launch={x=launch:GetX(),y=launch:GetY()},target={x=target:GetX(),y=target:GetY()},missile=probe.missile})
  UI.SelectUnit(missile);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_NUKE,target:GetX(),target:GetY(),0,false,false)
  phase="resolved"
 elseif phase=="resolved"then
  if not ended or probe.plot:IsFighting()then return false end
  local m=player:GetUnitByID(probe.missile);assert(not m or m:IsDead()or m:IsDelayedDeath(),"missile not consumed")
  assert(Game.GetNukesExploded()==probe.explosions+1)
  local spec=cases[index];local c=Players[1]:GetCityByID(probe.city)
  if spec.destroy then assert(not c and not probe.plot:IsCity(),"sub-threshold noncapital survived level-two strike")
  else
   assert(c,"protected/large city was destroyed")
   local damage=math.min(math.floor(probe.maxHP*GameDefines.NUKE_CITY_HIT_POINT_DAMAGE/100),probe.maxHP-1)
   assert(c:GetDamage()==damage,"city HP damage differs from configured strike")
   local base=GameDefines.NUKE_LEVEL2_POPULATION_DEATH_BASE
   local max=base+GameDefines.NUKE_LEVEL2_POPULATION_DEATH_RAND_1-1+GameDefines.NUKE_LEVEL2_POPULATION_DEATH_RAND_2-1
   local function deaths(percent)return math.min(probe.population-1,math.floor(math.floor(probe.population*percent/100)*(100+probe.modifier)/100))end
   local lost=probe.population-c:GetPopulation()
   assert(lost>=deaths(base)and lost<=deaths(max),"population loss outside configured random/shelter bounds")
   LekmodScenarioEvent("nuclear-city-outcome",{case=spec.item,population=c:GetPopulation(),lost=lost,minimum=deaths(base),maximum=deaths(max),damage=c:GetDamage(),modifier=probe.modifier})
  end
  assert(Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())and Players[1]:IsNukedBy(0),"strike did not record war/nuclear diplomatic consequence")
  LekmodScenarioRecord(spec.item,"PASS","normal nuclear mission and combat-end; supplied population="..probe.population.." modifier="..probe.modifier)
  index=index+1
  if index>#cases then LekmodScenarioRecord("nuclear-war-and-diplomacy","PASS","native war and IsNukedBy recorded; four real explosions/missiles consumed");return true end
  phase="prepare"
 end
 return false
end
