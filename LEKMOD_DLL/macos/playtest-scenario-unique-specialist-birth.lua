-- Native method surface: GameCore
-- Buildings and threshold-minus-0.01 GPP are inputs. Ordinary city turns must
-- generate the civilization replacement and a separate owner's default control.
-- No target InitUnit/DoSpawnGreatPerson call or completed threshold is supplied.
LekmodScenario={name="unique-specialist-birth",items={"specialist-birth-prerequisites","specialist-unique-birth","specialist-default-control","specialist-progress-accounting"}}
local configs={
 {civ="CIVILIZATION_BOLIVIA",kind="UNIT_LEU_COMPARSA_FOLKLORICA",specialist="SPECIALIST_MUSICIAN",building="BUILDING_MUSICIANS_GUILD"},
 {civ="CIVILIZATION_ITALY",kind="UNIT_ITALARTIST",specialist="SPECIALIST_ARTIST",building="BUILDING_ARTISTS_GUILD"},
 {civ="CIVILIZATION_VENEZ",kind="UNIT_VENETIAN_MERCHANT",specialist="SPECIALIST_MERCHANT",building="BUILDING_MAUSOLEUM_HALICARNASSUS"}}
local phase,targets,started="init",{},nil
local function replacement(p,class)
 local kind=GameInfo.UnitClasses[class].DefaultUnit
 for row in GameInfo.Civilization_UnitClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type,UnitClassType=class}do kind=row.UnitType end
 return kind
end
local function prepare(t)
 local p=Players[t.owner];local c=assert(p:GetCapitalCity());local info=GameInfo.Buildings[t.building]
 assert(info.SpecialistType==t.specialist and info.GreatPeopleRateChange>0)
 assert(not c:CanTrain(GameInfoTypes[t.kind]),"special unit unexpectedly has production path")
 t.city=c:GetID();t.threshold=c:GetSpecialistUpgradeThreshold(GameInfoTypes[t.class]);assert(t.threshold>1)
 for u in p:Units()do assert(u:GetUnitType()~=GameInfoTypes[t.kind],"target already exists in fixture")end
 c:SetNumRealBuilding(info.ID,1)
 local before=c:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes[t.specialist]);local amount=t.threshold*100-1
 c:ChangeSpecialistGreatPersonProgressTimes100(GameInfoTypes[t.specialist],amount-before)
 assert(c:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes[t.specialist])==amount and not t.born)
 LekmodScenarioEvent("fixture-setup",{operation="provided-building-and-near-threshold-specialist-points",owner=t.owner,kind=t.kind,city=t.city,building=t.building,building_base_gpp=info.GreatPeopleRateChange,before100=before,after100=amount,threshold=t.threshold})
end
GameEvents.UnitCreated.Add(function(owner,id)
 local t=targets[owner];if not t then return end
 local u=Players[owner]:GetUnitByID(id);if not u or u:GetUnitType()~=GameInfoTypes[t.kind]then return end
 assert(phase=="waiting"and Players[owner]:IsTurnActive(),"target born outside its ordinary owner turn")
 assert(not t.born,"duplicate special birth");t.born=id
 assert(u:GetOwner()==owner and not u:IsDead()and not u:IsDelayedDeath())
 local c=Players[owner]:GetCityByID(t.city)
 assert(c:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes[t.specialist])==0,"native GP generation did not reset its specialist progress")
 LekmodScenarioEvent("native-specialist-birth",{owner=owner,civilization=GameInfo.Civilizations[Players[owner]:GetCivilizationType()].Type,unit=id,kind=t.kind,control=t.control,turn=Game.GetGameTurn(),x=u:GetX(),y=u:GetY(),progress100=0})
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then local cities,units={},{}
   for c in p:Cities()do
    local progress,thresholds,buildings={},{},{}
    for _,cfg in ipairs(configs)do local sp=GameInfo.Specialists[cfg.specialist];progress[cfg.specialist]=c:GetSpecialistGreatPersonProgressTimes100(sp.ID);thresholds[cfg.specialist]=c:GetSpecialistUpgradeThreshold(GameInfoTypes[sp.GreatPeopleUnitClass]);buildings[cfg.building]=c:GetNumRealBuilding(GameInfoTypes[cfg.building])end
    cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),progress100=progress,thresholds=thresholds,buildings=buildings}
   end
   for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={kind=GameInfo.Units[u:GetUnitType()].Type,x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),experience=u:GetExperience()}end end
   owners[owner]={civ=p:GetCivilizationType(),gold=p:GetGold(),faith=p:GetFaith(),golden=p:GetGoldenAgeTurns(),greatworks=p:GetNumGreatWorks(),cities=cities,units=units}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local chosen,owner
  for _,cfg in ipairs(configs)do for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
   if p and p:IsAlive()and p:GetCivilizationType()==GameInfoTypes[cfg.civ]then assert(not chosen,"requires one unique specialist target per saved group");chosen=cfg;owner=id end
  end end
  assert(chosen,"no reviewed specialist unique in fixture")
  local class=GameInfo.Units[chosen.kind].Class;local default=GameInfo.UnitClasses[class].DefaultUnit;assert(replacement(Players[owner],class)==chosen.kind)
  local control
  for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if id~=owner and p and p:IsAlive()and p:GetCapitalCity()and replacement(p,class)==default then control=id;break end end
  assert(control,"no default-class control owner")
  for _,id in ipairs({owner,control})do
   targets[id]={owner=id,kind=id==owner and chosen.kind or default,class=class,specialist=chosen.specialist,building=chosen.building,control=id==control};prepare(targets[id])
  end
  LekmodScenarioRecord("specialist-birth-prerequisites","PASS","unique and default owners below threshold; positive building GPP; production rejected; no target supplied")
  started=Game.GetGameTurn();phase="waiting";return "turn"
 elseif phase=="waiting"then
  local complete=true
  for _,t in pairs(targets)do if not t.born then complete=false end end
  if not complete then assert(Game.GetGameTurn()-started<3,"specialist birth exceeded ordinary turn bound");return "turn"end
  for _,t in pairs(targets)do local c=Players[t.owner]:GetCityByID(t.city);local threshold=c:GetSpecialistUpgradeThreshold(GameInfoTypes[t.class]);local progress=c:GetSpecialistGreatPersonProgressTimes100(GameInfoTypes[t.specialist])
   assert(threshold>t.threshold and progress<t.threshold*100,"birth threshold/progress accounting differs")
   LekmodScenarioEvent("specialist-birth-accounting",{owner=t.owner,kind=t.kind,threshold_before=t.threshold,threshold_after=threshold,progress100=progress})
   LekmodScenarioRecord(t.control and"specialist-default-control"or"specialist-unique-birth","PASS","ordinary city turns/UnitCreated: "..t.kind.." owner="..t.owner)
  end
  LekmodScenarioRecord("specialist-progress-accounting","PASS","real birth resets each progress meter and increases next class threshold")
  return true
 end
 return false
end
