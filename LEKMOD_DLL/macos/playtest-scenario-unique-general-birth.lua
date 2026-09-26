-- Native method surface: GameCore
-- Combatants, war, upkeep/resources and threshold-minus-one combat XP are inputs.
-- A normal attack must earn the crossing XP and cause the native general award.
LekmodScenario={name="unique-general-birth",items={"general-birth-prerequisites","general-unique-combat-birth","general-default-combat-control","general-experience-accounting"}}
local phase,targets,enemy,started,prekill="init",{},nil,nil,{}
local function replacement(p)
 local kind=GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.DefaultUnit
 for row in GameInfo.Civilization_UnitClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type,UnitClassType="UNITCLASS_GREAT_GENERAL"}do kind=row.UnitType end
 return kind
end
local function clear(q)
 if not q or q:GetOwner()~=-1 or q:IsWater()or q:IsMountain()or q:IsHills()or q:IsCity()or q:GetFeatureType()~=-1 or q:GetNumUnits()~=0 then return false end
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner];if p and p:IsAlive()then for c in p:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<5 then return false end end end end
 return true
end
GameEvents.UnitPrekill.Add(function(owner,id)if owner==enemy then prekill[id]=true end end)
GameEvents.UnitCreated.Add(function(owner,id)
 local t=targets[owner];if not t then return end
 local p=Players[owner];local u=p:GetUnitByID(id);if not u or u:GetUnitType()~=GameInfoTypes[t.kind]then return end
 assert(phase=="combat"and t.armed and p:IsTurnActive(),"general appeared outside the staged native combat")
 assert(not t.born and u:GetOwner()==owner and u:IsHasPromotion(GameInfoTypes.PROMOTION_GREAT_GENERAL),"general identity/duplicate differs")
 local fighter=assert(p:GetUnitByID(t.attacker))
 -- Global general points are processed before the attacker's own XP assignment.
 -- Its earned XP is checked after combat settles, not inside UnitCreated.
 assert(p:GetCombatExperience()>=t.threshold,"general birth lacks crossing global combat points")
 t.born=id;LekmodScenarioEvent("native-combat-general-birth",{owner=owner,kind=t.kind,id=id,control=t.control,turn=Game.GetGameTurn(),attacker=t.attacker,attacker_xp=fighter:GetExperience(),x=u:GetX(),y=u:GetY()})
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 local t=targets[owner];if phase~="combat"or not t or t.armed then return end
 local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive());local source,destination
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if clear(q)then for d=0,5 do local other=Map.PlotDirection(q:GetX(),q:GetY(),d);if clear(other)then source,destination=q,other;break end end end
  if source then break end
 end
 assert(source and destination,"no legal separated combat pair")
 local a=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,source:GetX(),source:GetY()))
 local b=assert(Players[enemy]:InitUnit(GameInfoTypes.UNIT_WARRIOR,destination:GetX(),destination:GetY()))
 t.threshold=p:GreatGeneralThreshold();t.count=p:GetGreatGeneralsCreated();assert(t.threshold>1)
 p:SetCombatExperience(t.threshold-1);assert(not t.born and p:GetGreatGeneralsCreated()==t.count)
 t.before=p:GetCombatExperience();t.lifetime=p:GetLifetimeCombatExperience();t.attacker=a:GetID();t.defender=b:GetID();t.x=destination:GetX();t.y=destination:GetY();t.armed=true
 assert(a:GetExperience()==0 and a:GetDamage()==0 and b:GetDamage()==0 and a:CanMoveOrAttackInto(destination))
 LekmodScenarioEvent("fixture-setup",{operation="provided-combat-pair-and-below-threshold-global-XP",owner=owner,attacker=t.attacker,defender=t.defender,enemy=enemy,x=t.x,y=t.y,meter=t.before,threshold=t.threshold,lifetime=t.lifetime})
 a:PushMission(MissionTypes.MISSION_MOVE_TO,t.x,t.y,0,0,1)
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then local units,wars={},{}
   for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={kind=GameInfo.Units[u:GetUnitType()].Type,x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),experience=u:GetExperience(),general=u:IsHasPromotion(GameInfoTypes.PROMOTION_GREAT_GENERAL)}end end
   for other=0,GameDefines.MAX_MAJOR_CIVS-1 do if Players[other]and Players[other]:IsAlive()then wars[other]=Teams[p:GetTeam()]:IsAtWar(Players[other]:GetTeam())end end
   owners[owner]={civilization=p:GetCivilizationType(),gold=p:GetGold(),combat_xp=p:GetCombatExperience(),lifetime_xp=p:GetLifetimeCombatExperience(),generals=p:GetGreatGeneralsCreated(),threshold=p:GreatGeneralThreshold(),units=units,wars=wars}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local owner
  for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
   if p and p:IsAlive()and(replacement(p)=="UNIT_HETAIROI"or replacement(p)=="UNIT_MONGOLIAN_KHAN")then assert(not owner);owner=id end
  end
  assert(owner and not Players[owner]:IsHuman(),"requires reviewed AI general owner")
  local control
  for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
   if p and p:IsAlive()and not p:IsHuman()and id~=owner then
    if not control and replacement(p)==GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.DefaultUnit then control=id
    elseif not enemy then enemy=id end
   end
  end
  assert(control and enemy)
  for _,id in ipairs({owner,control})do local p=Players[id]
   local t={owner=id,kind=replacement(p),control=id==control};targets[id]=t
   assert(not p:GetCapitalCity():CanTrain(GameInfoTypes[t.kind]));p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,4)
   Teams[p:GetTeam()]:Meet(Players[enemy]:GetTeam(),true);Teams[p:GetTeam()]:DeclareWar(Players[enemy]:GetTeam(),false)
   assert(Teams[p:GetTeam()]:IsAtWar(Players[enemy]:GetTeam()))
   LekmodScenarioEvent("fixture-setup",{operation="provided-war-upkeep-and-uranium",owner=id,enemy=enemy,gold=1000,uranium=4})
  end
  LekmodScenarioRecord("general-birth-prerequisites","PASS","unique/default replacements selected; production rejected; combat XP will be supplied below threshold on actual owner turns")
  phase="combat";started=Game.GetGameTurn();return "turn"
 elseif phase=="combat"then
  for _,t in pairs(targets)do
   if not t.armed then assert(Game.GetGameTurn()-started<3);return "turn"end
   local p=Players[t.owner];local a=p:GetUnitByID(t.attacker);local b=Players[enemy]:GetUnitByID(t.defender)
   if Map.GetPlot(t.x,t.y):IsFighting()or(a and a:IsBusy())then return false end
   if not LekmodScenarioAwait("general-combat-"..t.owner,t.born and prekill[t.defender]and(not b or b:IsDead()or b:IsDelayedDeath()))then return false end
   assert(a and a:GetExperience()>0 and not a:IsDead()and not a:IsDelayedDeath())
   local gained=p:GetLifetimeCombatExperience()-t.lifetime
   assert(gained>0 and p:GetGreatGeneralsCreated()==t.count+1 and p:GreatGeneralThreshold()>t.threshold)
   assert(p:GetCombatExperience()==t.before+gained-t.threshold,"combat XP debit/overflow differs")
   if not t.checked then
    LekmodScenarioEvent("general-combat-accounting",{owner=t.owner,kind=t.kind,earned_global_xp=gained,before=t.before,after=p:GetCombatExperience(),spent_threshold=t.threshold,next_threshold=p:GreatGeneralThreshold(),generals_before=t.count,generals_after=p:GetGreatGeneralsCreated()})
    LekmodScenarioRecord(t.control and"general-default-combat-control"or"general-unique-combat-birth","PASS","normal attack/real XP/UnitCreated yields "..t.kind.." owner="..t.owner);t.checked=true
   end
  end
  LekmodScenarioRecord("general-experience-accounting","PASS","each actual combat award spends one previous threshold, preserves overflow and raises the next threshold")
  return true
 end
 return false
end
