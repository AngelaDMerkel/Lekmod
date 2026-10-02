-- Native method surface: GameCore
-- @native-receiver u Unit
-- @native-receiver player Player
-- Only the shipped level2 missile exists. Cities, shelter, units, wounds,
-- uranium and launch visibility are inputs; strikes alone produce outcomes.
LekmodScenario={name="nuclear-shelter-units",items={"shelter-unit-config","shelter-unit-direct","shelter-unit-unprotected","shelter-unit-adjacent","shelter-unit-health99","shelter-unit-lethal100","shelter-civilian-threshold","shelter-strike-accounting"}}
local phase,index,probe,ended="init",1,nil,false
local targetCityID,adjacentTarget
local previousWarriors={}
local cases={{item="shelter-unit-direct",shelter=true,wound=0},{item="shelter-unit-unprotected",wound=0},{item="shelter-unit-adjacent",shelter=true,wound=0,adjacent=true},{item="shelter-unit-health99",shelter=true,wound=74},{item="shelter-unit-lethal100",shelter=true,wound=75}}
local function distance(a,b)return Map.PlotDistance(a:GetX(),a:GetY(),b:GetX(),b:GetY())end
local function alive(u)return u and not u:IsDead()and not u:IsDelayedDeath()end
local function found(owner,near)
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetOwner()==-1 and p:GetNumUnits()==0 and p:GetFeatureType()~=GameInfoTypes.FEATURE_FALLOUT and(not near or(distance(p,near)>=4 and distance(p,near)<=10))and Players[owner]:CanFound(p:GetX(),p:GetY())then
   Players[owner]:Found(p:GetX(),p:GetY());local c=assert(p:GetPlotCity())
   LekmodScenarioEvent("fixture-setup",{operation="provided-shelter-test-city",owner=owner,id=c:GetID(),x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no legal isolated nuclear fixture city")
end
Events.EndCombatSim.Add(function(owner,id)if probe and owner==0 and id==probe.missile then ended=true end end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local cities,units={},{}
  for c in Players[owner]:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),damage=c:GetDamage(),modifier=c:GetNukeModifier()}end
  for u in Players[owner]:Units()do if alive(u)then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage()}end end
  owners[owner]={cities=cities,units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners,explosions=Game.GetNukesExploded(),nuke_units=player:GetNumNukeUnits(),war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())}
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(Game.GetWinner()==-1 and Players[1]:IsAlive()and Players[1]:GetCapitalCity())
  local count=0;for row in GameInfo.Units()do if row.NukeDamageLevel>=0 then assert(row.Type=="UNIT_NUCLEAR_MISSILE"and row.NukeDamageLevel==2);count=count+1 end end
  assert(count==1 and GameDefines.MAX_HIT_POINTS==100 and GameDefines.NUKE_NON_COMBAT_DEATH_THRESHOLD==6)
  local resource=GameInfoTypes.RESOURCE_URANIUM;local added=math.max(0,10-player:GetNumResourceAvailable(resource,true));player:ChangeNumResourceTotal(resource,added)
  LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",added=added})
  LekmodScenarioRecord("shelter-unit-config","PASS","one shipped level2 missile;100hit points; civilian death threshold6; no synthesized level1 unit")
  phase="prepare"
 elseif phase=="prepare"then
  local spec=cases[index];local city=targetCityID and Players[1]:GetCityByID(targetCityID)or found(1)
  assert(city);targetCityID=city:GetID()
  -- Preserve prior survivors by staging only those supplied probes outside the
  -- next blast. Reuse one city so map density cannot exhaust fixture space.
  for _,oldID in ipairs(previousWarriors)do local old=Players[1]:GetUnitByID(oldID)
   if alive(old)and distance(old,city)<=3 then
    local safe
    for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
     if not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 and distance(q,city)>=5 then safe=q;break end
    end
    assert(safe);local damage=old:GetDamage();old:SetXY(safe:GetX(),safe:GetY(),false,true,false,false)
    assert(old:GetX()==safe:GetX()and old:GetY()==safe:GetY()and old:GetDamage()==damage)
    LekmodScenarioEvent("fixture-setup",{operation="stage-prior-survivor-outside-blast",unit=oldID,damage=damage,x=old:GetX(),y=old:GetY()})
   end
  end
  city:SetPopulation(12,true);city:SetDamage(0)
  LekmodScenarioEvent("fixture-setup",{operation="reset-reused-target-city-inputs",city=targetCityID,population=12,damage=0})
  city:SetNumRealBuilding(GameInfoTypes.BUILDING_BOMB_SHELTER,spec.shelter and 1 or 0)
  assert(city:GetNukeModifier()==(spec.shelter and -75 or 0))
  local warrior=assert(Players[1]:InitUnit(GameInfoTypes.UNIT_WARRIOR,city:GetX(),city:GetY()));local worker=assert(Players[1]:InitUnit(GameInfoTypes.UNIT_WORKER,city:GetX(),city:GetY()))
  for _,u in ipairs({warrior,worker})do assert(alive(u)and u:GetX()==city:GetX()and u:GetY()==city:GetY()and not u:IsNukeImmune()and u:GetMaxHitPoints()==100)end
  previousWarriors[#previousWarriors+1]=warrior:GetID()
  warrior:SetDamage(spec.wound);assert(worker:GetDamage()==0)
  assert(warrior:NukeDamageLevel()==-1 and not warrior:CanNukeAt(city:GetX(),city:GetY()),"ordinary unit has nuclear capability")
  local launch
  for c in player:Cities()do if distance(c,city)>=4 and distance(c,city)<=10 then launch=c;break end end
  launch=launch or found(0,city:Plot())
  local countBefore=player:GetNumNukeUnits()
  local missile=assert(player:InitUnit(GameInfoTypes.UNIT_NUCLEAR_MISSILE,launch:GetX(),launch:GetY()))
  assert(player:GetNumNukeUnits()==countBefore+1,"nuclear creation count mismatch")
  -- Nuclear targeting has no land-only rule. Choose and check the later
  -- adjacent target before the first strike, including range/diplomacy gates.
  if not adjacentTarget then
   local candidates={}
   for direction=0,5 do local q=Map.PlotDirection(city:GetX(),city:GetY(),direction)
    if q and not q:IsCity()and q:GetNumUnits()==0 then
     q:SetRevealed(player:GetTeam(),true)
     local allowed=missile:CanNukeAt(q:GetX(),q:GetY())
     candidates[#candidates+1]={x=q:GetX(),y=q:GetY(),water=q:IsWater(),allowed=allowed}
     if allowed and not adjacentTarget then adjacentTarget=q end
    end
   end
   LekmodScenarioEvent("shelter-target-preflight",{candidates=candidates})
   assert(adjacentTarget,"no native-eligible adjacent target before any strike")
  end
  local target=spec.adjacent and adjacentTarget or city:Plot()
  target:SetRevealed(player:GetTeam(),true)
  assert(not spec.adjacent or distance(target,city)==1)
  assert(missile:NukeDamageLevel()==2 and missile:CanNukeAt(target:GetX(),target:GetY()),"planned nuclear target no longer eligible")
  local damage=math.floor(100*(100+city:GetNukeModifier())/100)
  probe={nukes_before=countBefore,city=city:GetID(),plot=city:Plot(),target=target,missile=missile:GetID(),warrior=warrior:GetID(),worker=worker:GetID(),damage=damage,before=spec.wound,explosions=Game.GetNukesExploded()};ended=false
  LekmodScenarioEvent("fixture-setup",{operation="provided-shelter-units-and-wounds",case=spec.item,city=probe.city,warrior=probe.warrior,worker=probe.worker,wound=spec.wound,modifier=city:GetNukeModifier(),expected_damage=damage,adjacent=spec.adjacent==true})
  UI.SelectUnit(missile);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_NUKE,target:GetX(),target:GetY(),0,false,false);phase="result"
 elseif phase=="result"then
  if not ended or probe.target:IsFighting()or probe.plot:IsFighting()then return false end
  assert(not alive(player:GetUnitByID(probe.missile))and Game.GetNukesExploded()==probe.explosions+1)
  if not LekmodScenarioAwait("nuclear-count-settled",player:GetNumNukeUnits()==probe.nukes_before)then return false end
  assert(Players[1]:GetCityByID(probe.city),"population12 target city disappeared")
  local warrior=Players[1]:GetUnitByID(probe.warrior);local total=probe.before+probe.damage
  if total>=100 then assert(not alive(warrior),"lethal combined damage left combat unit alive")
  else assert(alive(warrior)and warrior:GetDamage()==total,"shelter combat damage differs from exact arithmetic")end
  assert(probe.damage>=6 and not alive(Players[1]:GetUnitByID(probe.worker)),"civilian threshold result differs")
  assert(Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())and Players[1]:IsNukedBy(0))
  LekmodScenarioRecord(cases[index].item,"PASS","normal missile: prior damage="..probe.before.." blast damage="..probe.damage.." combat survives="..tostring(total<100).." civilian dies at threshold6")
  index=index+1
  if index>#cases then
   LekmodScenarioRecord("shelter-civilian-threshold","PASS","five healthy civilians receive computed25/100 nuclear damage, both above threshold6, and die")
   LekmodScenarioRecord("shelter-strike-accounting","PASS","five real missions/explosions consume missiles, preserve large target cities and record war/nuclear diplomacy")
   return true
  end
  phase="prepare"
 end
 return false
end
