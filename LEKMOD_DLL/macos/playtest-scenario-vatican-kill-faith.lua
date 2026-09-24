-- Full-health units, staging, uranium/upkeep and a non-combat religion are inputs.
-- Ordinary owner-turn attacks must cause deaths/capture and faith rewards.
LekmodScenario={name="vatican-kill-faith",items={"vatican-kill-faith-low","vatican-kill-faith-ranged","vatican-kill-faith-cap","vatican-civilian-no-faith","roman-kill-faith-control"}}
local phase,round,active,prekill="init",1,{},{}
local cases={{unit="UNIT_WARRIOR",item="vatican-kill-faith-low"},{unit="UNIT_ARCHER",item="vatican-kill-faith-ranged"},{unit="UNIT_RIFLEMAN",item="vatican-kill-faith-cap"},{unit="UNIT_WORKER",item="vatican-civilian-no-faith",civilian=true}}
GameEvents.UnitPrekill.Add(function(owner,id,kind,x,y,delay,killer)
 if owner==0 then prekill[id]=true;LekmodScenarioEvent("native-kill-faith-prekill",{owner=owner,unit=id,type=kind,x=x,y=y,killer=killer,delay=delay})end
end)
local function clear(q)
 if not q or q:GetOwner()~=-1 or q:IsWater()or q:IsMountain()or q:IsHills()or q:IsCity()or q:GetFeatureType()~=-1 or q:GetNumUnits()~=0 then return false end
 for owner=0,3 do for c in Players[owner]:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<5 then return false end end end
 return true
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="combat"or(owner~=1 and owner~=3)or active[owner]then return end
 local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman());local source,target
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if clear(q)then for d=0,5 do local other=Map.PlotDirection(q:GetX(),q:GetY(),d);if clear(other)then source,target=q,other;break end end end
  if source then break end
 end
 assert(source and target,"no safe natural combat pair")
 local case=cases[round];local defender=assert(Players[0]:InitUnit(GameInfoTypes[case.unit],target:GetX(),target:GetY()))
 local attacker=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,source:GetX(),source:GetY()))
 assert(defender:GetDamage()==0 and attacker:GetDamage()==0)
 local info=GameInfo.Units[case.unit];local strength=math.max(info.Combat,info.RangedCombat)
 local r={defender=defender:GetID(),attacker=attacker:GetID(),x=target:GetX(),y=target:GetY(),faith=p:GetFaith(),strength=strength,expected=owner==1 and math.min(strength,30)or 0}
 active[owner]=r
 LekmodScenarioEvent("fixture-setup",{operation="provided-full-health-combat-pair",owner=owner,attacker=r.attacker,defender=r.defender,type=case.unit,x=r.x,y=r.y,strength=strength,faith_before=r.faith})
 assert(attacker:CanMoveOrAttackInto(target));attacker:PushMission(MissionTypes.MISSION_MOVE_TO,r.x,r.y,0,0,1)
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,3 do local p=Players[owner];local units={}
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),experience=u:GetExperience()}end end
  owners[owner]={faith=p:GetFaith(),religion=p:GetReligionCreatedByPlayer(),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners,war_vatican=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),war_rome=Teams[player:GetTeam()]:IsAtWar(Players[3]:GetTeam())}
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VATICAN and Players[3]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
  local p=Players[1];assert(not p:HasCreatedReligion());local religion
  for info in GameInfo.Religions()do if info.ID>0 then religion=info.ID;break end end
  Game.FoundReligion(1,religion,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_FEED_WORLD,-1,-1,p:GetCapitalCity())
  LekmodScenarioEvent("fixture-setup",{operation="provided-noncombat-religion-to-avoid-pantheon-selection",owner=1,religion=religion})
  for _,owner in ipairs({1,3})do local other=Players[owner];other:ChangeGold(1000);other:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,4)
   Teams[player:GetTeam()]:Meet(other:GetTeam(),true);Network.SendChangeWar(other:GetTeam(),true)
   LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-and-uranium",owner=owner,gold_added=1000,uranium_added=4})
  end
  phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("faith-kill-wars",Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())and Teams[player:GetTeam()]:IsAtWar(Players[3]:GetTeam()))then return false end
  phase="combat";return "turn"
 elseif phase=="combat"then
  if not active[1]or not active[3]then return "turn"end
  local case=cases[round]
  for _,owner in ipairs({1,3})do local r=active[owner];local p=Players[owner];local victim=Players[0]:GetUnitByID(r.defender);local attacker=p:GetUnitByID(r.attacker);local plot=Map.GetPlot(r.x,r.y)
   if plot:IsFighting()or(attacker and attacker:IsBusy())then return false end
   if not LekmodScenarioAwait(owner.."-faith-kill-"..round,prekill[r.defender]and(not victim or victim:IsDead()or victim:IsDelayedDeath()))then return false end
   assert(attacker and not attacker:IsDelayedDeath(),"supplied overwhelming attacker did not survive")
   if case.civilian then
    local worker=false;for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_WORKER and u:GetX()==r.x and u:GetY()==r.y then worker=true end end;assert(worker,"normal capture did not transfer Worker")
   else assert(attacker:GetExperience()>0,"real combat awarded no XP")end
   local delta=p:GetFaith()-r.faith;LekmodScenarioEvent("native-kill-faith-result",{owner=owner,type=case.unit,strength=r.strength,faith_before=r.faith,faith_after=p:GetFaith(),delta=delta,expected=r.expected})
   assert(delta==r.expected,"faith kill reward mismatch owner="..owner.." expected="..r.expected.." actual="..delta)
  end
  LekmodScenarioRecord(case.item,"PASS","normal AI attack/capture; Vatican faith delta="..active[1].expected.."; matching Roman control=0")
  round=round+1
  if round>#cases then LekmodScenarioRecord("roman-kill-faith-control","PASS","Roman controls receive zero faith for the same three military kills and civilian capture");return true end
  active={};return "turn"
 end
 return false
end
