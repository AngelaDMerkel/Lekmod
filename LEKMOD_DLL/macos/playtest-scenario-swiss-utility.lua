-- Reuse the actually purchased Swiss Guard. Farm, unit placement and damaged
-- healing probes are explicit inputs; pillage, movement and healing are outcomes.
LekmodScenario={name="swiss-utility",items={"swiss-free-pillage","swiss-medic-adjacent","swiss-medic-neutral-self","swiss-medic-range-removal"}}
local phase,id,farm,before,center,nearID,controlID,moveTo,turn,healing="init",nil,nil,nil,nil,nil,nil,nil,nil,nil
local function action(u,kind)
 UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type==kind then assert(Game.CanHandleAction(i),"normal action unavailable: "..kind);Game.HandleAction(i);return end end
 error("action missing: "..kind)
end
local function safe(q)
 if not q or q:GetOwner()~=-1 or q:IsWater()or q:IsMountain()or q:IsHills()or q:IsCity()or q:GetFeatureType()~=-1 or q:GetNumUnits()~=0 then return false end
 for owner=0,3 do for c in Players[owner]:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<5 then return false end end end
 for enemy in Players[3]:Units()do if Map.PlotDistance(q:GetX(),q:GetY(),enemy:GetX(),enemy:GetY())<5 then return false end end
 return true
end
function LekmodScenario.snapshot(player)
 local units,plots={},{}
 for u in player:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves(),adjacent_heal=u:GetAdjacentTileHeal(),neutral_heal=u:GetExtraNeutralHeal()}end end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:IsImprovementPillaged()then plots[i]={improvement=q:GetImprovementType(),pillaged=true,owner=q:GetOwner()}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),units=units,plots=plots}
end
function LekmodScenario.step(player)
 if not id then for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_SWITZ then assert(not id,"fixture has duplicate Swiss Guards");id=u:GetID()end end end
 local u=assert(player:GetUnitByID(id),"requires the purchased Swiss Guard fixture")
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VATICAN and u:GetAdjacentTileHeal()==10 and u:GetExtraNeutralHeal()==5)
  for _,name in ipairs({"PROMOTION_FREE_PILLAGE_MOVES","PROMOTION_MEDIC","PROMOTION_MEDIC_II"})do assert(u:IsHasPromotion(GameInfoTypes[name]))end
  if u:GetMoves()<=0 then return "turn"end
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if safe(q)and q:GetImprovementType()==-1 and q:GetResourceType(-1)==-1 and(q:GetTerrainType()==GameInfoTypes.TERRAIN_GRASS or q:GetTerrainType()==GameInfoTypes.TERRAIN_PLAINS)then farm=q;break end
  end
  assert(farm);farm:SetImprovementType(GameInfoTypes.IMPROVEMENT_FARM);u:SetXY(farm:GetX(),farm:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="provided-unowned-farm-and-Swiss-position",unit=id,x=farm:GetX(),y=farm:GetY()})
  before={moves=u:GetMoves(),damage=u:GetDamage(),gold=player:GetGold()};assert(u:CanPillage(farm));action(u,"MISSION_PILLAGE");phase="pillaged"
 elseif phase=="pillaged"then
  if not LekmodScenarioAwait("Swiss-farm-pillaged",farm:IsImprovementPillaged())then return false end
  assert(u:GetMoves()==before.moves and u:GetDamage()==math.max(0,before.damage-GameDefines.PILLAGE_HEAL_AMOUNT))
  local gold=player:GetGold()-before.gold;assert(gold>=0 and gold<=2*math.max(0,GameInfo.Improvements.IMPROVEMENT_FARM.PillageGold-1))
  LekmodScenarioRecord("swiss-free-pillage","PASS","normal Pillage action; farm pillaged; moves unchanged; normal heal/loot bounds")
  local near,control;local candidates={};local lookup={};local areas={}
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if safe(q)then candidates[#candidates+1]=q;lookup[i]=true;areas[q:GetArea()]=(areas[q:GetArea()]or 0)+1 end
  end
  for _,q in ipairs(candidates)do
   if areas[q:GetArea()]>=4 then
    for d=0,5 do local adjacent=Map.PlotDirection(q:GetX(),q:GetY(),d)
     if adjacent and lookup[adjacent:GetPlotIndex()]and adjacent:GetArea()==q:GetArea()then
      for e=0,5 do local exit=Map.PlotDirection(q:GetX(),q:GetY(),e)
       if exit and lookup[exit:GetPlotIndex()]and exit:GetArea()==q:GetArea()and Map.PlotDistance(exit:GetX(),exit:GetY(),adjacent:GetX(),adjacent:GetY())>1 then
        for _,other in ipairs(candidates)do
         if other:GetArea()==q:GetArea()and Map.PlotDistance(other:GetX(),other:GetY(),q:GetX(),q:GetY())>=4 and Map.PlotDistance(other:GetX(),other:GetY(),exit:GetX(),exit:GetY())>1 then
          center,near,control,moveTo=q,adjacent,other,exit;break
         end
        end
       end
       if control then break end
      end
     end
     if control then break end
    end
   end
   if control then break end
  end
  assert(center and near and control and moveTo,"no complete neutral healing/control/exit group")
  LekmodScenarioEvent("healing-site-layout",{center=center:GetPlotIndex(),adjacent=near:GetPlotIndex(),control=control:GetPlotIndex(),exit=moveTo:GetPlotIndex()})
  u:SetXY(center:GetX(),center:GetY(),false,true,false,false)
  local a=assert(player:InitUnit(GameInfoTypes.UNIT_WARRIOR,near:GetX(),near:GetY()));nearID=a:GetID()
  local b=assert(player:InitUnit(GameInfoTypes.UNIT_WARRIOR,control:GetX(),control:GetY()));controlID=b:GetID()
  for _,unit in ipairs({u,a,b})do unit:SetDamage(80);assert(unit:CanHeal(unit:GetPlot()))end
  LekmodScenarioEvent("fixture-setup",{operation="provided-neutral-healing-probes",swiss=id,adjacent=nearID,control=controlID,damage=80})
  action(u,"MISSION_HEAL");action(a,"MISSION_HEAL");action(b,"MISSION_HEAL");turn=Game.GetGameTurn();phase="healed";return "turn"
 elseif phase=="healed"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1);local a=assert(player:GetUnitByID(nearID));local b=assert(player:GetUnitByID(controlID))
  local da,db,ds=80-a:GetDamage(),80-b:GetDamage(),80-u:GetDamage();LekmodScenarioEvent("Swiss-healing-result",{adjacent=da,control=db,Swiss=ds,aura=u:GetAdjacentTileHeal(),self_bonus=u:GetExtraNeutralHeal()})
  assert(db>0 and da==db+10 and ds==db+5 and a:GetDamage()>0 and b:GetDamage()>0)
  LekmodScenarioRecord("swiss-medic-adjacent","PASS","ordinary healing adjacent to Swiss Guard adds exactly 10 HP over matched neutral control")
  LekmodScenarioRecord("swiss-medic-neutral-self","PASS","Swiss Guard itself heals exactly 5 HP more than matched neutral control")
  action(u,"COMMAND_WAKE");phase="wake-move";return false
 elseif phase=="wake-move"then
  if u:GetMoves()<=0 then return "turn"end
  local a=assert(player:GetUnitByID(nearID));local b=assert(player:GetUnitByID(controlID))
  assert(safe(moveTo)and Map.PlotDistance(moveTo:GetX(),moveTo:GetY(),a:GetX(),a:GetY())>1 and Map.PlotDistance(moveTo:GetX(),moveTo:GetY(),b:GetX(),b:GetY())>1 and u:CanMoveOrAttackInto(moveTo),"reserved medic exit became unavailable");UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,moveTo:GetX(),moveTo:GetY(),0,false,false);phase="moved"
 elseif phase=="moved"then
  if not LekmodScenarioAwait("Swiss-left-medic-range",u:GetX()==moveTo:GetX()and u:GetY()==moveTo:GetY())then return false end
  local a=player:GetUnitByID(nearID);local b=player:GetUnitByID(controlID);healing={a=a:GetDamage(),b=b:GetDamage()};turn=Game.GetGameTurn();phase="no-aura";return "turn"
 elseif phase=="no-aura"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1);local a=player:GetUnitByID(nearID);local b=player:GetUnitByID(controlID)
  local da,db=healing.a-a:GetDamage(),healing.b-b:GetDamage();LekmodScenarioEvent("Swiss-healing-out-of-range",{adjacent_former=da,control=db})
  assert(da>0 and da==db)
  LekmodScenarioRecord("swiss-medic-range-removal","PASS","normal Swiss move beyond adjacency removes extra healing; both probes heal equally next turn")
  return true
 end
 return false
end
