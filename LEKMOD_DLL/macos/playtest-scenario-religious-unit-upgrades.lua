-- Use actual purchased/produced uniques. Research, resources, upgrade budget,
-- friendly placement and later full-health defenders are explicit inputs.
LekmodScenario={name="religious-unit-upgrades",items={"unique-upgrade-budgets","Swiss-upgrade","Maccabee-upgrade","Crusader-upgrade","Swiss-upgraded-kills","Maccabee-upgraded-kills","Crusader-upgraded-kills"}}
local phase,records,battles,prekill="init",{}, {},{}
local kinds={[0]="UNIT_SWITZ",[1]="UNIT_ISRAEL_MACCABEE",[2]="UNIT_CRUSADER"}
local names={[0]="Swiss",[1]="Maccabee",[2]="Crusader"}
local targets={[0]="UNIT_RIFLEMAN",[1]="UNIT_LONGSWORDSMAN",[2]="UNIT_MUSKETMAN"}
local function state(u)
 local promotions={};for info in GameInfo.UnitPromotions()do if u:IsHasPromotion(info.ID)then promotions[info.Type]=true end end
 return {type=u:GetUnitType(),damage=u:GetDamage(),xp=u:GetExperience(),level=u:GetLevel(),promotions=promotions,x=u:GetX(),y=u:GetY()}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,3 do local p=Players[owner];local units={}
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
  owners[owner]={gold=p:GetGold(),faith=p:GetFaith(),units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
GameEvents.UnitUpgraded.Add(function(owner,old,id,ruin)
 local r=records[owner];if r and r.old==old then assert(not ruin);r.new=id;LekmodScenarioEvent("native-unique-upgrade",{owner=owner,old=old,new=id})end
end)
GameEvents.UnitPrekill.Add(function(owner,id)if owner==3 then prekill[id]=true end end)
local function prepare(owner)
 local p=Players[owner];local r=records[owner];local u=assert(p:GetUnitByID(r.old));local target=GameInfo.Units[targets[owner]]
 LekmodScenarioGrantTech(p,target.PrereqTech)
 for row in GameInfo.Unit_ResourceQuantityRequirements{UnitType=target.Type}do local res=GameInfoTypes[row.ResourceType];local n=math.max(0,row.Cost-p:GetNumResourceAvailable(res,true));if n>0 then p:ChangeNumResourceTotal(res,n);LekmodScenarioEvent("fixture-setup",{operation="provided-upgrade-resource",owner=owner,resource=row.ResourceType,amount=n})end end
 local plot;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==owner and not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 then plot=q;break end
 end
 assert(plot);u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
 assert(u:GetUpgradeUnitType()==target.ID,"next upgrade differs from reviewed class")
 r.cost=u:UpgradePrice(target.ID);assert(r.cost>1)
 local previous=p:GetGold();p:ChangeGold(r.cost-1-previous);assert(not u:CanUpgradeRightNow(),"cost-minus-one allowed upgrade")
 p:ChangeGold(1);assert(u:CanUpgradeRightNow(),"exact-budget friendly upgrade unavailable")
 r.before=state(u);r.gold=p:GetGold();r.ready=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-friendly-upgrade-and-exact-budget",owner=owner,unit=r.old,x=plot:GetX(),y=plot:GetY(),previous_gold=previous,cost=r.cost,target=target.Type})
 return u
end
local function verified(owner)
 local r=records[owner];if r.checked then return true end
 if not r.new then return false end
 local p=Players[owner];local u=assert(p:GetUnitByID(r.new));local old=p:GetUnitByID(r.old);local after=state(u)
 assert(not old or old:IsDead()or old:IsDelayedDeath())
 assert(after.type==GameInfoTypes[targets[owner]]and p:GetGold()==r.gold-r.cost,"upgrade type/debit differs")
 assert(after.xp==r.before.xp and after.level==r.before.level and after.damage==r.before.damage,"upgrade changed XP/level/damage")
 for kind in pairs(r.before.promotions)do if not GameInfo.UnitPromotions[kind].LostWithUpgrade then assert(after.promotions[kind],"retained promotion missing: "..kind)end end
 if owner==0 then assert(not after.promotions.PROMOTION_ANTI_MOUNTED_I,"lost-on-upgrade anti-mounted promotion retained")end
 r.checked=true;LekmodScenarioEvent("upgrade-state-comparison",{owner=owner,before=r.before,after=after,cost=r.cost})
 LekmodScenarioRecord(names[owner].."-upgrade","PASS","normal command/native UnitUpgraded; exact gold; XP/level/damage and retained promotions; data-defined loss checked")
 return true
end
local function clear(q)
 if not q or q:GetOwner()~=-1 or q:IsCity()or q:IsWater()or q:IsMountain()or q:IsHills()or q:GetFeatureType()~=-1 or q:GetNumUnits()~=0 then return false end
 for owner=0,3 do for c in Players[owner]:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<5 then return false end end end
 return true
end
local function battle(owner)
 local p=Players[owner];local u=assert(p:GetUnitByID(records[owner].new));assert(u:GetMoves()>0)
 local source,target
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if clear(q)then for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d);if clear(a)then source,target=q,a;break end end end
  if source then break end
 end
 assert(source);u:SetXY(source:GetX(),source:GetY(),false,true,false,false)
 local enemy=assert(Players[3]:InitUnit(GameInfoTypes.UNIT_BARBARIAN_ARCHER,target:GetX(),target:GetY()));assert(enemy:GetDamage()==0)
 battles[owner]={defender=enemy:GetID(),x=target:GetX(),y=target:GetY(),faith=p:GetFaith(),gold=p:GetGold()}
 LekmodScenarioEvent("fixture-setup",{operation="provided-upgraded-unit-battle-staging",owner=owner,unit=u:GetID(),defender=enemy:GetID(),x=target:GetX(),y=target:GetY()})
 assert(u:CanMoveOrAttackInto(target))
 if owner==0 then UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,false,false)
 else u:PushMission(MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,0,1)end
end
local function checkBattle(owner)
 local r=battles[owner];if not r then return false end
 local p=Players[owner];local u=assert(p:GetUnitByID(records[owner].new));local enemy=Players[3]:GetUnitByID(r.defender)
 if u:IsBusy()or Map.GetPlot(r.x,r.y):IsFighting()then return false end
 if not LekmodScenarioAwait(owner.."-upgraded-kill",prekill[r.defender]and(not enemy or enemy:IsDead()or enemy:IsDelayedDeath()))then return false end
 local expected=owner==0 and math.max(GameInfo.Units.UNIT_BARBARIAN_ARCHER.Combat,GameInfo.Units.UNIT_BARBARIAN_ARCHER.RangedCombat)or 0
 LekmodScenarioEvent("native-upgraded-kill-yields",{owner=owner,faith=p:GetFaith()-r.faith,gold=p:GetGold()-r.gold,expected_faith=expected})
 assert(p:GetFaith()-r.faith==expected and p:GetGold()==r.gold,"old intrinsic unit rewards survived upgrade or trait reward was lost")
 LekmodScenarioRecord(names[owner].."-upgraded-kills","PASS","actual military kill: old intrinsic unique-unit yields gone; Vatican trait faith remains only for owner0")
 return true
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 and owner~=2 then return end
 local p=Players[owner];local r=records[owner]
 if phase=="AI-upgrades"and not r.ready then
  assert(p:IsTurnActive()and not p:IsHuman());local u=prepare(owner);u:DoCommand(CommandTypes.COMMAND_UPGRADE,-1,-1);assert(verified(owner))
 elseif phase=="AI-battles"and not battles[owner]then assert(p:IsTurnActive());battle(owner)end
end)
function LekmodScenario.step(player)
 if phase=="init"then
  for owner=0,2 do for u in Players[owner]:Units()do if u:GetUnitType()==GameInfoTypes[kinds[owner]]then assert(not records[owner]);records[owner]={old=u:GetID()}end end;assert(records[owner],"original acquired unit missing")end
  prepare(0);phase="human-command"
 elseif phase=="human-command"then
  local u=player:GetUnitByID(records[0].old);UI.SelectUnit(u);local action
  for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="COMMAND_UPGRADE"then action=i;break end end
  assert(action);if not Game.CanHandleAction(action)then records[0].wait=(records[0].wait or 0)+1;assert(records[0].wait<60,"normal upgrade action remained blocked");return false end
  Game.HandleAction(action);phase="human-upgraded"
 elseif phase=="human-upgraded"then
  if not LekmodScenarioAwait("human-unique-upgrade",records[0].new~=nil)then return false end
  assert(verified(0));phase="AI-upgrades";return "turn"
 elseif phase=="AI-upgrades"then
  if not records[1].checked or not records[2].checked then return "turn"end
  LekmodScenarioRecord("unique-upgrade-budgets","PASS","all three owner-specific upgrades reject cost-minus-one and accept exact budget")
  phase="human-ready"
 elseif phase=="human-ready"then
  if player:GetUnitByID(records[0].new):GetMoves()<=0 then return "turn"end
  battle(0);phase="human-battle"
 elseif phase=="human-battle"then
  if not checkBattle(0)then return false end
  phase="AI-battles";return "turn"
 elseif phase=="AI-battles"then
  if not battles[1]or not battles[2]then return "turn"end
  if not checkBattle(1)or not checkBattle(2)then return false end
  return true
 end
 return false
end
