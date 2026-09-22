-- Load the preserved pre-fix Defender save. Promotion repair must occur at the
-- next real owner turn. Positions and enemy ships are supplied; movement costs
-- must come from normal network movement commands, with no moves/flags assigned.
LekmodScenario={name="defender-zoc",items={"Defender-oldsave-owner-turn-recovery","Defender-active-ZOC-movement","Defender-inactive-ZOC-stop","Defender-normal-ZOC-stop"}}
local phase,turn,probes,index,pending="init",nil,{},1,nil
local active=GameInfoTypes.PROMOTION_JFD_DEFENDER_ACTIVE
local default=GameInfoTypes.PROMOTION_JFD_DEFENDER
local function distance(owner,p)
 local n=999;for c in Players[owner]:Cities()do n=math.min(n,Map.PlotDistance(c:GetX(),c:GetY(),p:GetX(),p:GetY()))end;return n
end
local function state(u)
 return {type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),active=u:IsHasPromotion(active),default=u:IsHasPromotion(default),damage=u:GetDamage()}
end
local function same(a,b)return a:GetX()==b:GetX()and a:GetY()==b:GetY()end
local function water(p)
 return p and p:IsWater()and not p:IsLake()and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and p:GetOwner()==-1 and p:GetNumUnits()==0
end
local function triangle()
 for i=0,Map.GetNumPlots()-1 do local a=Map.GetPlotByIndex(i)
  if water(a)and distance(0,a)>=5 and distance(1,a)>=5 then
   for d=0,5 do local b=Map.PlotDirection(a:GetX(),a:GetY(),d)
    if water(b)then
     for e=0,5 do local c=Map.PlotDirection(a:GetX(),a:GetY(),e)
      if water(c)and not same(b,c)and Map.PlotDistance(b:GetX(),b:GetY(),c:GetX(),c:GetY())==1 then return a,b,c end
     end
    end
   end
  end
 end
 error("no isolated three-water-tile staging triangle")
end
function LekmodScenario.snapshot(player)
 local units={}
 for _,owner in ipairs({player:GetID(),GameDefines.BARBARIAN_PLAYER})do
  units[owner]={};for u in Players[owner]:Units()do if u:GetDomainType()==DomainTypes.DOMAIN_SEA then units[owner][u:GetID()]=state(u)end end
 end
 return {turn=Game.GetGameTurn(),units=units,friendship=player:IsDoF(1)}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local own2,own3,normal,friend3
  for u in player:Units()do
   if u:GetUnitType()==GameInfoTypes.UNIT_JFD_DEFENDER then
    if distance(0,u:GetPlot())==2 then own2=u end
    if distance(0,u:GetPlot())==3 then own3=u end
    if distance(1,u:GetPlot())==3 then friend3=u end
   elseif u:GetUnitType()==GameInfoTypes.UNIT_IRONCLAD then normal=u end
  end
  assert(own2 and own3 and normal and friend3,"requires preserved six-ship boundary fixture")
  assert(own2:IsHasPromotion(active)and own3:IsHasPromotion(active)and friend3:IsHasPromotion(active),"requires the retained pre-fix wrong distance-three state")
  probes={{id=own2:GetID(),item="Defender-active-ZOC-movement",active=true},{id=own3:GetID(),item="Defender-inactive-ZOC-stop",active=false},{id=normal:GetID(),item="Defender-normal-ZOC-stop",active=false}}
  probes.friend3=friend3:GetID();turn=Game.GetGameTurn()
  player:SetGold(1000);LekmodScenarioEvent("fixture-setup",{operation="provided-ship-upkeep",gold=1000})
  LekmodScenarioEvent("Defender-oldsave-before",LekmodScenario.snapshot(player))
  phase="owner-turn";return "turn"
 elseif phase=="owner-turn"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1,"recovery must occur on next ordinary owner turn")
  local own2=assert(player:GetUnitByID(probes[1].id));local own3=assert(player:GetUnitByID(probes[2].id));local friend3=assert(player:GetUnitByID(probes.friend3))
  assert(own2:IsHasPromotion(active)and not own2:IsHasPromotion(default))
  assert(not own3:IsHasPromotion(active)and own3:IsHasPromotion(default))
  assert(not friend3:IsHasPromotion(active)and friend3:IsHasPromotion(default))
  LekmodScenarioRecord("Defender-oldsave-owner-turn-recovery","PASS","saved distance-three bonuses persisted until ordinary owner turn; owned/friendly distance-three removed and distance-two retained")
  phase="move-input"
 elseif phase=="move-input"then
  local probe=probes[index];local u=assert(player:GetUnitByID(probe.id));local a,b,c=triangle()
  assert(u:IsHasPromotion(active)==probe.active and u:GetMoves()>GameDefines.MOVE_DENOMINATOR)
  u:SetXY(a:GetX(),a:GetY(),false,true,false,false)
  assert(same(u,a),"staging ship relocated")
  local enemy=assert(Players[GameDefines.BARBARIAN_PLAYER]:InitUnit(GameInfoTypes.UNIT_TRIREME,c:GetX(),c:GetY()))
  assert(same(enemy,c)and enemy:GetBaseCombatStrength()>0)
  assert(Teams[player:GetTeam()]:IsAtWar(enemy:GetTeam()))
  assert(Map.PlotDistance(a:GetX(),a:GetY(),c:GetX(),c:GetY())==1 and Map.PlotDistance(b:GetX(),b:GetY(),c:GetX(),c:GetY())==1)
  assert(u:CanMoveOrAttackInto(b),"adjacent ZOC test destination is illegal")
  LekmodScenarioEvent("fixture-setup",{operation="provided-ZOC-staging-and-enemy",probe=probe.item,ship=state(u),enemy=state(enemy),target={x=b:GetX(),y=b:GetY()}})
  pending={to=b,before=u:GetMoves(),enemy=enemy:GetID()}
  UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,b:GetX(),b:GetY(),0,false,false)
  phase="moved"
 elseif phase=="moved"then
  local probe=probes[index];local u=assert(player:GetUnitByID(probe.id))
  if not LekmodScenarioAwait(probe.item,same(u,pending.to)and not u:IsBusy())then return false end
  assert(u:IsHasPromotion(active)==probe.active,"staging/movement changed start-of-turn effect")
  assert(Players[GameDefines.BARBARIAN_PLAYER]:GetUnitByID(pending.enemy),"enemy disappeared")
  local after=u:GetMoves()
  if probe.active then assert(after==pending.before-GameDefines.MOVE_DENOMINATOR and after>0,"active Defender failed to ignore enemy ZOC")
  else assert(after==0,"unprotected control retained movement through enemy ZOC")end
  LekmodScenarioRecord(probe.item,"PASS","normal-MOVE_TO before="..pending.before.." after="..after.." active="..tostring(probe.active).." enemy-adjacent-to-both-tiles=true")
  index=index+1;if index>#probes then return true end;phase="move-input"
 end
 return false
end
