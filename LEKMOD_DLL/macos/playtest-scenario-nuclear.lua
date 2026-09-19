-- Game-only combat test. Missiles, targets, uranium, target visibility and one
-- compatible farm are provided. Damage/death/fallout must come from a mission.
LekmodScenario={name="nuclear",items={"nuclear-range-restrictions","nuclear-unit-blast-radius","nuclear-immunity","nuclear-fallout-pillage","nuclear-missile-consumption"}}
local phase,missileID,barbarian,target,immuneID,outerID="init"
local victims={}
local settleUpdates,combatEnds=0,0
Events.EndCombatSim.Add(function(owner,id)
 LekmodScenarioEvent("nuclear-combat-ended",{owner=owner,id=id,expected_missile=missileID or -1})
 if owner==0 and id==missileID then combatEnds=combatEnds+1 end
end)
local function live(owner,id)
 local u=Players[owner]:GetUnitByID(id);return u and not u:IsDead() and not u:IsDelayedDeath() and u or nil
end
local function unitState(u)
 return {type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves(),immune=u:IsNukeImmune()}
end
function LekmodScenario.snapshot(player)
 local owners,plots={},{}
 for _,owner in ipairs({0,GameDefines.BARBARIAN_PLAYER})do local units={};for u in Players[owner]:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=unitState(u)end end;owners[owner]=units end
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetFeatureType()==GameInfoTypes.FEATURE_FALLOUT or p:IsImprovementPillaged()then plots[i]={feature=p:GetFeatureType(),improvement=p:GetImprovementType(),pillaged=p:IsImprovementPillaged()}end
 end
 return {turn=Game.GetGameTurn(),units=owners,affected_plots=plots}
end
local function emptyLand(p)
 return p and not p:IsWater() and not p:IsMountain() and not p:IsCity() and p:GetOwner()==-1 and p:GetNumUnits()==0
end
local function supply(owner,kind,p)
 local u=assert(Players[owner]:InitUnit(GameInfoTypes[kind],p:GetX(),p:GetY()));assert(u:GetDamage()==0)
 LekmodScenarioEvent("fixture-setup",{operation="provided-full-health-unit",owner=owner,id=u:GetID(),state=unitState(u)})
 return u
end
function LekmodScenario.step(player)
 local city=assert(player:GetCapitalCity())
 if phase=="init" then
  barbarian=GameDefines.BARBARIAN_PLAYER;assert(Players[barbarian] and Teams[player:GetTeam()]:IsAtWar(Players[barbarian]:GetTeam()))
  local radius=GameDefines.NUKE_BLAST_RADIUS;assert(radius==2,"fixture expects shipped two-tile blast radius")
  local near,boundary,outside
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   local d=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
   if emptyLand(p) and not p:IsHills() and p:GetFeatureType()==-1 and p:GetImprovementType()==-1 and p:GetResourceType(-1)==-1 and (p:GetTerrainType()==GameInfoTypes.TERRAIN_GRASS or p:GetTerrainType()==GameInfoTypes.TERRAIN_PLAINS) and d>=4 and d<=10 then
    local safe=true;local slots={}
    for j=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(j);local r=Map.PlotDistance(p:GetX(),p:GetY(),q:GetX(),q:GetY())
     if r<=radius and (q:GetOwner()~=-1 or q:GetNumUnits()>0 or q:IsCity())then safe=false;break end
     if r>=1 and r<=3 and not slots[r] and emptyLand(q)then slots[r]=q end
    end
    if safe and slots[1] and slots[2] and slots[3]then target,near,boundary,outside=p,slots[1],slots[2],slots[3];break end
   end
  end
  assert(target,"no isolated natural nuclear test area in capital range")
  local uranium=GameInfoTypes.RESOURCE_URANIUM;local amount=math.max(0,4-player:GetNumResourceAvailable(uranium,true))
  if amount>0 then player:ChangeNumResourceTotal(uranium,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",amount=amount})end
  local missile=supply(0,"UNIT_NUCLEAR_MISSILE",city:Plot());missileID=missile:GetID();assert(missile:NukeDamageLevel()==2 and missile:Range()==12)
  victims={supply(barbarian,"UNIT_WARRIOR",target):GetID(),supply(barbarian,"UNIT_WARRIOR",boundary):GetID()}
  local immune=supply(barbarian,"UNIT_MECH",near);immuneID=immune:GetID();assert(immune:IsNukeImmune(),"shipped GDR lost nuclear immunity")
  outerID=supply(barbarian,"UNIT_WARRIOR",outside):GetID()
  target:SetImprovementType(GameInfoTypes.IMPROVEMENT_FARM)
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);if Map.PlotDistance(target:GetX(),target:GetY(),p:GetX(),p:GetY())<=3 then p:SetRevealed(player:GetTeam(),true)end end
  LekmodScenarioEvent("fixture-setup",{operation="provided-target-farm-and-visibility",x=target:GetX(),y=target:GetY(),radius=3})
  assert(missile:CanNuke() and not missile:CanNukeAt(city:GetX(),city:GetY()))
  assert(not Players[barbarian]:GetUnitByID(victims[1]):CanNuke())
  local far
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);if Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())>missile:Range()then far=p;break end end
  assert(far and not missile:CanNukeAt(far:GetX(),far:GetY()),"out-of-range strike allowed")
  local friendly=assert(Map.PlotDirection(city:GetX(),city:GetY(),0));assert(missile:CanNukeAt(friendly:GetX(),friendly:GetY()),"own-overlap query differs from native victim-team rule")
  LekmodScenarioEvent("nuclear-own-overlap-query",{allowed=true,executed=false})
  assert(missile:CanNukeAt(target:GetX(),target:GetY()),"isolated enemy blast target is ineligible")
  LekmodScenarioRecord("nuclear-range-restrictions","PASS","self-target/out-of-range/non-nuclear-unit rejected=true own-overlap-query-allowed=true not-executed=true")
  UI.SelectUnit(missile)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_NUKE,target:GetX(),target:GetY(),0,false,false)
  phase="resolved";return false
 end
 if not LekmodScenarioAwait("nuclear-mission-resolved",not live(0,missileID) and not live(barbarian,victims[1]))then return false end
 for _,id in ipairs(victims)do assert(not live(barbarian,id),"level-two blast failed to kill in-radius target")end
 local immune=assert(live(barbarian,immuneID));local outer=assert(live(barbarian,outerID))
 assert(immune:GetDamage()==0 and immune:IsNukeImmune(),"immune unit was damaged")
 assert(outer:GetDamage()==0,"distance-three control was damaged")
 assert(target:GetFeatureType()==GameInfoTypes.FEATURE_FALLOUT and target:IsImprovementPillaged(),"direct target did not receive fallout/pillage")
 settleUpdates=settleUpdates+1
 if settleUpdates==1 or combatEnds>0 then
  local missile=player:GetUnitByID(missileID)
  LekmodScenarioEvent("nuclear-save-settling",{updates=settleUpdates,combat_end_events=combatEnds,target_fighting=target:IsFighting(),missile_present=missile~=nil,missile_delayed=missile and missile:IsDelayedDeath() or false,immune_busy=immune:IsBusy(),outside_busy=outer:IsBusy()})
 end
 if combatEnds==0 or target:IsFighting() or immune:IsBusy() or outer:IsBusy()then return false end
 LekmodScenarioEvent("nuclear-resolved-state",{immune=unitState(immune),outside=unitState(outer),target_feature=target:GetFeatureType(),target_pillaged=target:IsImprovementPillaged()})
 LekmodScenarioRecord("nuclear-unit-blast-radius","PASS","normal-mission center-and-radius-two-targets-killed radius-three-unharmed=true")
 LekmodScenarioRecord("nuclear-immunity","PASS","shipped-GDR-immunity preserves-full-health=true")
 LekmodScenarioRecord("nuclear-fallout-pillage","PASS","native-direct-target fallout-and-farm-pillage=true")
 LekmodScenarioRecord("nuclear-missile-consumption","PASS","normal-nuclear-mission consumed-missile=true")
 return true
end
