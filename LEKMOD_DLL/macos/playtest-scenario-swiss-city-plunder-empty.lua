-- Walls/Castle, attacker health/staging and defender budget are explicit inputs.
-- Normal melee must damage a surviving city; treasury outcomes are never assigned.
local enabled=true
local budget=0
LekmodScenario={name="swiss-city-plunder-empty",items={"swiss-city-damage","swiss-plunder-credit","swiss-plunder-debit"}}
local phase,id,targetX,targetY,before="init",nil,nil,nil,nil
function LekmodScenario.snapshot(player)
 local cities={}
 for owner=0,3 do for c in Players[owner]:Cities()do cities[owner..":"..c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),damage=c:GetDamage(),walls=c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALLS),castle=c:GetNumRealBuilding(GameInfoTypes.BUILDING_CASTLE)}end end
 local units={};for u in player:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves(),promotion=u:IsHasPromotion(GameInfoTypes.PROMOTION_DOUBLE_PLUNDER)}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),faith=player:GetFaith(),enemy_gold=Players[3]:GetGold(),cities=cities,units=units}
end
function LekmodScenario.step(player)
 if not id then for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_SWITZ then assert(not id);id=u:GetID()end end end
 local u=assert(player:GetUnitByID(id),"requires the actually purchased Guard fixture")
 local city=assert(Players[3]:GetCapitalCity())
 if phase=="init"then
  assert(Teams[player:GetTeam()]:IsAtWar(Players[3]:GetTeam())and u:GetMoves()>0 and u:IsHasPromotion(GameInfoTypes.PROMOTION_DOUBLE_PLUNDER))
  if not enabled then u:SetHasPromotion(GameInfoTypes.PROMOTION_DOUBLE_PLUNDER,false)end
  city:SetNumRealBuilding(GameInfoTypes.BUILDING_WALLS,1);city:SetNumRealBuilding(GameInfoTypes.BUILDING_CASTLE,1)
  assert(city:GetDamage()==0,"target must begin undamaged");u:SetDamage(0)
  Players[3]:ChangeGold(budget-Players[3]:GetGold())
  local plot
  for d=0,5 do local q=Map.PlotDirection(city:GetX(),city:GetY(),d)
   if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then plot=q;break end
  end
  assert(plot);u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
  targetX,targetY=city:GetX(),city:GetY()
  LekmodScenarioEvent("fixture-setup",{operation="provided-city-plunder-boundary",defender_gold=budget,walls=1,castle=1,attacker_damage=0,promotion_enabled=enabled,unit=id,x=plot:GetX(),y=plot:GetY()})
  phase="attack"
 elseif phase=="attack"then
  assert(city:GetStrengthValue()>=1500,"defended-city fixture is too weak for a noncapture probe")
  assert(u:CanMoveOrAttackInto(city:Plot()))
  before={gold=player:GetGold(),enemy_gold=Players[3]:GetGold(),faith=player:GetFaith(),damage=city:GetDamage(),owner=city:GetOwner()}
  UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,targetX,targetY,0,false,false);phase="result"
 elseif phase=="result"then
  local plot=Map.GetPlot(targetX,targetY);city=assert(plot:GetPlotCity())
  if plot:IsFighting()or u:IsBusy()then return false end
  if not LekmodScenarioAwait("Swiss-city-attack",city:GetDamage()>before.damage)then return false end
  assert(city:GetOwner()==before.owner and not u:IsDead()and not u:IsDelayedDeath(),"noncapture combat fixture changed owner or lost attacker")
  local damage=city:GetDamage()-before.damage;local expected=enabled and damage or 0
  local credit=player:GetGold()-before.gold;local debit=before.enemy_gold-Players[3]:GetGold()
  LekmodScenarioEvent("native-Swiss-city-plunder",{damage=damage,credit=credit,debit=debit,expected_credit=expected,expected_debit=math.min(expected,before.enemy_gold),promotion_enabled=enabled})
  assert(player:GetFaith()==before.faith,"nonlethal city attack granted unrelated faith")
  LekmodScenarioRecord("swiss-city-damage","PASS","normal melee damaged surviving enemy city by "..damage.."; attacker survived; no city damage assigned")
  assert(credit==expected,"attacker plunder differs from actual damage/promotion")
  LekmodScenarioRecord("swiss-plunder-credit","PASS","native attacker gold delta="..credit.." promotion="..tostring(enabled))
  assert(debit==math.min(expected,before.enemy_gold)and Players[3]:GetGold()>=0,"defender plunder debit/clamp differs")
  LekmodScenarioRecord("swiss-plunder-debit","PASS","native defender debit="..debit.." limited by provided treasury="..budget)
  return true
 end
 return false
end
