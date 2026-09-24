-- Use the actually produced Crusader. Peace, positioning and an ordinary unit
-- control are inputs. Border entry is a real owner-turn mission; strength/list
-- comparisons are explicitly native calculation checks, not damage outcomes.
LekmodScenario={name="crusader-borders",items={"crusader-foreign-modifier","crusader-peace-border-gate","crusader-rival-territory-move"}}
local phase,id,target,source,controlID,sent="init",nil,nil,nil,nil,false
function LekmodScenario.snapshot(player)
 local p=Players[2];local units={}
 for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),owner=u:GetOwner(),plot_owner=u:GetPlot():GetOwner(),moves=u:GetMoves(),outside=u:GetOutsideFriendlyLandsModifier(),rival=u:IsHasPromotion(GameInfoTypes.PROMOTION_RIVAL_TERRITORY)}end end
 return {turn=Game.GetGameTurn(),war=Teams[p:GetTeam()]:IsAtWar(Players[3]:GetTeam()),units=units}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=2 or phase~="move"or sent then return end
 local p=Players[2];local u=assert(p:GetUnitByID(id));assert(p:IsTurnActive()and not p:IsHuman()and u:GetMoves()>0)
 assert(u:CanMoveOrAttackInto(target));sent=true;u:PushMission(MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,0,1)
end)
local function sum(rows)local n=0;for _,r in ipairs(rows)do if r.IsPercent and not r.IsMiscellaneous then n=n+r.Value end end;return n end
function LekmodScenario.step(player)
 local p=Players[2];assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_JERUSALEM)
 if not id then for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_CRUSADER then assert(not id);id=u:GetID()end end end
 local u=assert(p:GetUnitByID(id),"requires the produced Crusader fixture")
 if phase=="init"then
  assert(u:GetOutsideFriendlyLandsModifier()==20 and u:IsHasPromotion(GameInfoTypes.PROMOTION_RIVAL_TERRITORY))
  local own,neutral
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if not q:IsWater()and not q:IsMountain()and not q:IsHills()and not q:IsCity()and q:GetFeatureType()==-1 and q:GetNumUnits()==0 then
    if q:GetOwner()==2 and not own then own=q elseif q:GetOwner()==-1 and not neutral then neutral=q end
   end
   if own and neutral then break end
  end
  assert(own and neutral)
  local home=u:GetAttackModifierList(own,nil,nil,nil,false,false,false,0,own)
  local away=u:GetAttackModifierList(neutral,nil,nil,nil,false,false,false,0,neutral)
  local a=u:GetMaxAttackStrength(own,nil,nil,nil,false,false,false,own)
  local b=u:GetMaxAttackStrength(neutral,nil,nil,nil,false,false,false,neutral)
  LekmodScenarioEvent("Crusader-native-strength-comparison",{own_strength=a,neutral_strength=b,own_modifiers=home,neutral_modifiers=away})
  assert(sum(away)==sum(home)+20 and b>a,"foreign-land native calculation differs")
  LekmodScenarioRecord("crusader-foreign-modifier","PASS","native modifier-list sum +20 percentage points outside friendly land; native strength increases; calculation-only scope")
  Teams[p:GetTeam()]:MakePeace(Players[3]:GetTeam());assert(not Teams[p:GetTeam()]:IsAtWar(Players[3]:GetTeam()))
  local controlPlot
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==3 and not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 then
    local adjacent={};for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d)
     if a and a:GetOwner()==-1 and not a:IsWater()and not a:IsMountain()and a:GetNumUnits()==0 then adjacent[#adjacent+1]=a end
    end
    if #adjacent>=2 then target,source,controlPlot=q,adjacent[1],adjacent[2];break end
   end
  end
  assert(target and source and controlPlot)
  u:SetXY(source:GetX(),source:GetY(),false,true,false,false)
  local control=assert(p:InitUnit(GameInfoTypes.UNIT_LONGSWORDSMAN,controlPlot:GetX(),controlPlot:GetY()));controlID=control:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-peace-and-border-staging",Crusader=id,control=controlID,target_x=target:GetX(),target_y=target:GetY()})
  assert(u:CanMoveOrAttackInto(target)and not control:CanMoveOrAttackInto(target),"rival-territory boundary/control differs")
  LekmodScenarioRecord("crusader-peace-border-gate","PASS","Crusader can enter peaceful Roman land; ordinary Longswordsman cannot")
  phase="move";return "turn"
 elseif phase=="move"then
  if not sent then return "turn"end
  if not LekmodScenarioAwait("Crusader-rival-move",u:GetX()==target:GetX()and u:GetY()==target:GetY())then return false end
  assert(u:GetPlot():GetOwner()==3 and not Teams[p:GetTeam()]:IsAtWar(Players[3]:GetTeam()))
  assert(Players[2]:GetUnitByID(controlID):GetPlot():GetOwner()==-1)
  LekmodScenarioRecord("crusader-rival-territory-move","PASS","normal active-owner move enters peaceful rival land; ordinary control remains outside")
  return true
 end
 return false
end
