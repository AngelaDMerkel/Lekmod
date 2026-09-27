-- Native method surface: GameCore
-- Units, legal ownership, visibility spotters and Optics are supplied inputs.
-- Embark, rejected drop and exact-range drop use normal human network missions.
local kind=assert(LekmodScenarioParameters.unit)
LekmodScenario={name="paradrop",items={"drop-range-visibility-controls","drop-launch-controls","drop-embarked-rejection","drop-out-of-range-command","drop-native-boundary","drop-movement-attack-repeat"}}
local phase,unitID,cloneID,source,target,beyond,coastLand,coastWater,before,turn,waits,event="init",nil,nil,nil,nil,nil,nil,nil,nil,nil,0,nil
local range=kind=="UNIT_PARATROOPER"and 9 or 40
local function land(q)return q and not q:IsWater()and not q:IsMountain()and not q:IsImpassable()and not q:IsCity()and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==0)end
local function send(u,mission,q)
 UI.SelectUnit(u);assert(UI.GetHeadSelectedUnit():GetID()==u:GetID())
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,mission,q:GetX(),q:GetY(),0,false,false)
end
local function reveal(p,q)
 for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d)
  if land(n)then p:InitUnit(GameInfoTypes.UNIT_WARRIOR,n:GetX(),n:GetY());assert(q:IsVisible(p:GetTeam(),false));return end
 end
 error("no legal visibility spotter")
end
GameEvents.ParadropAt.Add(function(owner,id,fx,fy,tx,ty)
 if owner==0 and id==unitID then
  assert(not event);local u=assert(Players[owner]:GetUnitByID(id))
  event={from_x=fx,from_y=fy,to_x=tx,to_y=ty,moves=u:GetMoves(),out_of_attacks=u:IsOutOfAttacks()}
  LekmodScenarioEvent("native-paradrop",event)
 end
end)
function LekmodScenario.snapshot(p)
 local units={};for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={kind=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),range=u:GetDropRange(),embarked=u:IsEmbarked(),out_of_attacks=u:IsOutOfAttacks()}end end
 return {turn=Game.GetGameTurn(),units=units}
end
function LekmodScenario.step(p)
 if phase=="init"then
  p:ChangeGold(3000);LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-gold",amount=3000})
  assert(kind=="UNIT_PARATROOPER"or kind=="UNIT_XCOM_SQUAD")
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if land(q)and q:GetOwner()==0 then source=q;break end end
  assert(source);local u=assert(p:InitUnit(GameInfoTypes[kind],source:GetX(),source:GetY()));unitID=u:GetID();assert(u:GetDropRange()==range and not u:IsOutOfAttacks())
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if land(q)then
    local d=Map.PlotDistance(source:GetX(),source:GetY(),q:GetX(),q:GetY())
    if d==range and not q:IsVisible(p:GetTeam(),false)and not target then target=q end
    if d==range+1 and not beyond then beyond=q end
   end
  end
  assert(target and beyond,"fixture lacks range boundary pair")
  assert(not u:CanParadropAt(source,source:GetX(),source:GetY())and not u:CanParadropAt(source,target:GetX(),target:GetY()))
  reveal(p,target);reveal(p,beyond)
  assert(u:CanParadropAt(source,target:GetX(),target:GetY())and not u:CanParadropAt(source,beyond:GetX(),beyond:GetY()))
  local blocked=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,target:GetX(),target:GetY()));assert(not u:CanParadropAt(source,target:GetX(),target:GetY()));blocked:Kill(false,-1)
  LekmodScenarioRecord("drop-range-visibility-controls","PASS","configured range="..range.."; same/unseen/occupied/range+1 reject; visible exact boundary permits")
  local neutral;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if land(q)and q:GetOwner()==-1 then neutral=q;break end end
  assert(neutral);local other=assert(p:InitUnit(GameInfoTypes[kind],neutral:GetX(),neutral:GetY()));assert(not other:CanParadrop(neutral,false))
  local noDrop;for d=0,5 do local q=Map.PlotDirection(source:GetX(),source:GetY(),d);if land(q)then noDrop=q;break end end
  assert(noDrop);local normal=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,noDrop:GetX(),noDrop:GetY()));assert(normal:GetDropRange()==0 and not normal:CanParadrop(noDrop,false))
  LekmodScenarioRecord("drop-launch-controls","PASS","neutral launch without permission and no-promotion unit reject")
  LekmodScenarioGrantTech(p,"TECH_OPTICS")
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if land(q)then for d=0,5 do local w=Map.PlotDirection(q:GetX(),q:GetY(),d)
    if w and w:IsWater()and w:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and w:GetFeatureType()==-1 and w:GetNumUnits()==0 and(w:GetOwner()==-1 or w:GetOwner()==0)then coastLand,coastWater=q,w;break end
   end end
   if coastLand then break end
  end
  assert(coastLand);coastLand:SetOwner(0,-1,true,true);coastWater:SetOwner(0,-1,true,true)
  local clone=assert(p:InitUnit(GameInfoTypes[kind],coastLand:GetX(),coastLand:GetY()));cloneID=clone:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-drop-units-ownership-and-visibility",kind=kind,range=range,source=source:GetPlotIndex(),target=target:GetPlotIndex(),beyond=beyond:GetPlotIndex(),embark_control=cloneID})
  phase="embark";return false
 elseif phase=="embark"then
  local u=assert(p:GetUnitByID(cloneID));assert(u:CanEmbarkOnto(coastLand,coastWater));send(u,MissionTypes.MISSION_EMBARK,coastWater);phase="embarked";return false
 elseif phase=="embarked"then
  local u=assert(p:GetUnitByID(cloneID));if not LekmodScenarioAwait("drop-control-embark",u:IsEmbarked()and u:GetX()==coastWater:GetX()and u:GetY()==coastWater:GetY())then return false end
  turn=Game.GetGameTurn();phase="refreshed";return "turn"
 elseif phase=="refreshed"then
  if Game.GetGameTurn()==turn then return "turn"end
  local clone=assert(p:GetUnitByID(cloneID));assert(clone:IsEmbarked()and clone:GetMoves()==clone:MaxMovesWithStack()and not clone:CanParadrop(coastWater,false))
  LekmodScenarioRecord("drop-embarked-rejection","PASS","normally embarked unit with refreshed full moves still cannot drop")
  local u=assert(p:GetUnitByID(unitID));assert(u:CanParadropAt(source,target:GetX(),target:GetY()));before=u:GetMoves();send(u,MissionTypes.MISSION_PARADROP,beyond);phase="rejected";return false
 elseif phase=="rejected"then
  waits=waits+1;if waits<3 then return false end
  local u=assert(p:GetUnitByID(unitID));assert(not event and u:GetX()==source:GetX()and u:GetY()==source:GetY()and u:GetMoves()==before and not u:IsOutOfAttacks())
  LekmodScenarioRecord("drop-out-of-range-command","PASS","normal out-of-range request leaves coordinates, movement and attack budget unchanged")
  send(u,MissionTypes.MISSION_PARADROP,target);phase="landed";return false
 elseif phase=="landed"then
  if not event then return false end
  local u=assert(p:GetUnitByID(unitID));assert(event.from_x==source:GetX()and event.from_y==source:GetY()and event.to_x==target:GetX()and event.to_y==target:GetY())
  assert(u:GetX()==target:GetX()and u:GetY()==target:GetY())
  LekmodScenarioRecord("drop-native-boundary","PASS","normal mission/native ParadropAt reaches exact range="..range)
  assert(event.moves==before-GameDefines.MOVE_DENOMINATOR/2 and event.out_of_attacks and u:IsOutOfAttacks()and not u:CanParadrop(u:GetPlot(),false))
  LekmodScenarioRecord("drop-movement-attack-repeat","PASS","native drop spends exactly30 movement and one attack; repeat rejected")
  return true
 end
 return false
end
