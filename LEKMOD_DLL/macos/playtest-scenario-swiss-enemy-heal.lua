-- Hostile plot ownership, placement and damage are explicit isolated inputs.
-- Both units must heal through normal missions and one ordinary turn.
LekmodScenario={name="swiss-enemy-heal",items={"swiss-enemy-heal-gate","swiss-enemy-self-heal"}}
local phase,id,controlID,turn,plots="init",nil,nil,nil,{}
local function action(u)
 UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_HEAL"then assert(Game.CanHandleAction(i));Game.HandleAction(i);return end end;error("Heal action missing")
end
local function clear(q)
 if q:GetOwner()~=-1 or q:IsCity()or q:IsWater()or q:IsMountain()or q:IsHills()or q:GetFeatureType()~=-1 or q:GetResourceType(-1)~=-1 or q:GetImprovementType()~=-1 or q:GetNumUnits()~=0 then return false end
 for owner=0,3 do
  for c in Players[owner]:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<7 then return false end end
  for u in Players[owner]:Units()do if not u:IsDead()and not u:IsDelayedDeath()and Map.PlotDistance(q:GetX(),q:GetY(),u:GetX(),u:GetY())<7 then return false end end
 end
 return true
end
function LekmodScenario.snapshot(player)
 local units,owned={},{ }
 for u in player:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),plot_owner=u:GetPlot():GetOwner(),enemy_heal=u:GetExtraEnemyHeal()}end end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:GetOwner()==3 then owned[i]=3 end end
 return {turn=Game.GetGameTurn(),war=Teams[player:GetTeam()]:IsAtWar(Players[3]:GetTeam()),units=units,enemy_plots=owned}
end
function LekmodScenario.step(player)
 if not id then for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_SWITZ then assert(not id);id=u:GetID()end end end
 local swiss=assert(player:GetUnitByID(id))
 if phase=="init"then
  assert(Teams[player:GetTeam()]:IsAtWar(Players[3]:GetTeam())and swiss:GetExtraEnemyHeal()==5)
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if clear(q)and(#plots==0 or Map.PlotDistance(q:GetX(),q:GetY(),plots[1]:GetX(),plots[1]:GetY())>=4)then plots[#plots+1]=q;if #plots==2 then break end end
  end
  assert(#plots==2,"no isolated hostile-healing layout")
  for _,q in ipairs(plots)do q:SetOwner(3,-1,true,true);assert(q:GetOwner()==3)end
  swiss:SetXY(plots[1]:GetX(),plots[1]:GetY(),false,true,false,false)
  local control=assert(player:InitUnit(GameInfoTypes.UNIT_WARRIOR,plots[2]:GetX(),plots[2]:GetY()));controlID=control:GetID()
  assert(control:GetExtraEnemyHeal()==0)
  for _,u in ipairs({swiss,control})do u:SetDamage(80);assert(u:CanHeal(u:GetPlot()))end
  LekmodScenarioEvent("fixture-setup",{operation="provided-isolated-hostile-territory-and-wounds",plots={plots[1]:GetPlotIndex(),plots[2]:GetPlotIndex()},owner=3,damage=80,Swiss=id,control=controlID})
  LekmodScenarioRecord("swiss-enemy-heal-gate","PASS","both wounded land units can heal on hostile plots; Swiss enemy bonus5/control0; no nearby medic/city/enemy units")
  action(swiss);action(control);turn=Game.GetGameTurn();phase="healed";return "turn"
 elseif phase=="healed"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1);local control=assert(player:GetUnitByID(controlID));local a,b=80-swiss:GetDamage(),80-control:GetDamage()
  LekmodScenarioEvent("native-Swiss-hostile-healing",{Swiss=a,control=b})
  assert(swiss:GetPlot():GetOwner()==3 and control:GetPlot():GetOwner()==3 and Teams[player:GetTeam()]:IsAtWar(Players[3]:GetTeam()))
  assert(b>0 and a==b+5)
  LekmodScenarioRecord("swiss-enemy-self-heal","PASS","one ordinary healing turn: Swiss restored"..a.."HP/control"..b.."HP; extra5HP")
  return true
 end
 return false
end
