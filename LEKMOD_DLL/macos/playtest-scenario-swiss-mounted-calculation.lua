-- Native combat-calculation coverage only: supplied full-health defender types
-- isolate the purchased Swiss Guard's mounted/melee and mounted/ranged bonuses.
-- No attacks, damage, kills or mouse interaction are claimed in this scenario.
LekmodScenario={name="swiss-mounted-calculation",items={"swiss-mounted-melee-calculation","swiss-mounted-ranged-calculation"}}
local phase="init"
local function sum(rows)local n=0;for _,r in ipairs(rows)do if r.IsPercent and not r.IsMiscellaneous then n=n+r.Value end end;return n end
function LekmodScenario.snapshot(player)
 local owners={}
 for _,owner in ipairs({0,3})do local units={}
  for u in Players[owner]:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),base=u:GetBaseCombatStrength()}end end
  owners[owner]=units
 end
 return {turn=Game.GetGameTurn(),units=owners}
end
function LekmodScenario.step(player)
 assert(phase=="init");phase="done"
 local swiss;for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_SWITZ then assert(not swiss);swiss=u end end
 assert(swiss and swiss:IsHasPromotion(GameInfoTypes.PROMOTION_ANTI_MOUNTED_I))
 local results={};local used={}
 for _,kind in ipairs({"UNIT_WARRIOR","UNIT_HORSEMAN","UNIT_CHARIOT_ARCHER"})do
  local q
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if not used[i]and p:GetOwner()==-1 and not p:IsCity()and not p:IsWater()and not p:IsMountain()and not p:IsHills()and p:GetFeatureType()==-1 and p:GetNumUnits()==0 then
    local near=false;for owner=0,3 do for c in Players[owner]:Cities()do if Map.PlotDistance(p:GetX(),p:GetY(),c:GetX(),c:GetY())<5 then near=true end end end
    if not near then q=p;break end
   end
  end
  assert(q);used[q:GetPlotIndex()]=true
  local defender=assert(Players[3]:InitUnit(GameInfoTypes[kind],q:GetX(),q:GetY()));assert(defender:GetDamage()==0)
  local rows=swiss:GetAttackModifierList(q,defender,nil,nil,false,false,false,0,q)
  results[kind]={modifiers=rows,sum=sum(rows),strength=swiss:GetMaxAttackStrength(q,defender,nil,nil,false,false,false,q)}
  LekmodScenarioEvent("fixture-setup",{operation="provided-defender-for-calculation-only",type=kind,unit=defender:GetID(),x=q:GetX(),y=q:GetY()})
 end
 LekmodScenarioEvent("Swiss-mounted-native-calculations",results)
 local base=results.UNIT_WARRIOR
 for _,entry in ipairs({{"UNIT_HORSEMAN","swiss-mounted-melee-calculation"},{"UNIT_CHARIOT_ARCHER","swiss-mounted-ranged-calculation"}})do local r=results[entry[1]]
  assert(r.sum==base.sum+50 and r.strength>base.strength,"mounted combat calculation differs from +50%")
  LekmodScenarioRecord(entry[2],"PASS","native modifier-list sum +50 percentage points and greater attack strength versus ordinary melee control; calculation-only")
 end
 return true
end
