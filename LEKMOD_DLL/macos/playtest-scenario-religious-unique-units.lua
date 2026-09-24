-- Native acquisition/combat regression: human Vatican, AI Israel/Jerusalem/Rome.
-- Research/resources/hammers, war and battle staging/defenders are explicit inputs.
-- The three unique attackers must come from actual purchase/production.
LekmodScenario={name="religious-unique-units",items={"swiss-purchase-only","swiss-gold-purchase","maccabee-production","crusader-production","swiss-kill-yields","maccabee-kill-faith","crusader-kill-faith"}}
local phase,reply,price,goldBefore="init",false,nil,nil
local kinds={[0]="UNIT_SWITZ",[1]="UNIT_ISRAEL_MACCABEE",[2]="UNIT_CRUSADER"}
local units,queued,attacks,prekill={},{},{},{}
LuaEvents.LekmodScenarioTradeResponse.Add(function(action,id)if action=="purchase"and id==GameInfoTypes.UNIT_SWITZ then reply=true end end)
GameEvents.UnitCreated.Add(function(owner,id)
 if kinds[owner]then local u=Players[owner]:GetUnitByID(id)
  if u and u:GetUnitType()==GameInfoTypes[kinds[owner]]then
   assert(not units[owner],"unexpected duplicate target acquisition");units[owner]=id
   if owner~=0 then assert(queued[owner]and Players[owner]:GetCapitalCity():GetProductionUnit()==u:GetUnitType(),"AI target did not originate in the queued production")end
   LekmodScenarioEvent("native-religious-unit-created",{owner=owner,unit=id,type=kinds[owner]})
  end
 end
end)
GameEvents.UnitPrekill.Add(function(owner,id)if owner==3 then prekill[id]=true end end)
local function empty(q)
 if not q or q:GetOwner()~=-1 or q:IsCity()or q:IsWater()or q:IsMountain()or q:IsHills()or q:GetFeatureType()~=-1 or q:GetNumUnits()~=0 then return false end
 for owner=0,3 do for c in Players[owner]:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<5 then return false end end end
 return true
end
local function battle(owner)
 local p=Players[owner];local u=assert(p:GetUnitByID(units[owner]));assert(u:GetMoves()>0 and u:GetDamage()==0)
 local source,target
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if empty(q)then for d=0,5 do local a=Map.PlotDirection(q:GetX(),q:GetY(),d);if empty(a)then source,target=q,a;break end end end
  if source then break end
 end
 assert(source and target);u:SetXY(source:GetX(),source:GetY(),false,true,false,false)
 local enemy=assert(Players[3]:InitUnit(GameInfoTypes.UNIT_BARBARIAN_ARCHER,target:GetX(),target:GetY()))
 assert(enemy:GetDamage()==0 and enemy:GetBaseCombatStrength()==GameInfo.Units.UNIT_BARBARIAN_ARCHER.Combat)
 local strength=math.max(GameInfo.Units.UNIT_BARBARIAN_ARCHER.Combat,GameInfo.Units.UNIT_BARBARIAN_ARCHER.RangedCombat)
 attacks[owner]={defender=enemy:GetID(),x=target:GetX(),y=target:GetY(),faith=p:GetFaith(),gold=p:GetGold(),strength=strength}
 LekmodScenarioEvent("fixture-setup",{operation="provided-full-health-Roman-archer-and-unique-unit-staging",owner=owner,unit=u:GetID(),defender=enemy:GetID(),x=target:GetX(),y=target:GetY(),melee=enemy:GetBaseCombatStrength(),reward_strength=strength})
 assert(u:CanMoveOrAttackInto(target))
 if owner==0 then UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,false,false)
 else u:PushMission(MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,0,1)end
end
local function checkBattle(owner)
 local r=attacks[owner];if not r then return false end
 local p=Players[owner];local u=p:GetUnitByID(units[owner]);local dead=Players[3]:GetUnitByID(r.defender)
 if Map.GetPlot(r.x,r.y):IsFighting()or(u and u:IsBusy())then return false end
 if not LekmodScenarioAwait(owner.."-unique-kill",prekill[r.defender]and(not dead or dead:IsDead()or dead:IsDelayedDeath()))then return false end
 assert(u and not u:IsDead()and not u:IsDelayedDeath()and u:GetExperience()>0,"acquired attacker failed the bounded battle")
 local expectedFaith=r.strength*(owner==1 and 1 or 2);local faith=p:GetFaith()-r.faith;local gold=p:GetGold()-r.gold
 LekmodScenarioEvent("unique-unit-kill-yields",{owner=owner,type=kinds[owner],faith=faith,expected_faith=expectedFaith,gold=gold,strength=r.strength})
 assert(faith==expectedFaith,"unique kill faith differs")
 if owner==0 then assert(gold==r.strength,"Swiss Guard unit gold reward differs")end
 return true
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 and owner~=2 then return end
 local p=Players[owner]
 if phase=="production"and not queued[owner]then
  assert(p:IsTurnActive()and not p:IsHuman());local c=p:GetCapitalCity();local id=GameInfoTypes[kinds[owner]];assert(c:CanTrain(id))
  c:PushOrder(OrderTypes.ORDER_TRAIN,id,-1,0,true,false,0);assert(c:GetProductionUnit()==id)
  local cost=c:GetUnitProductionNeeded(id);assert(cost>1);queued[owner]=true;c:SetUnitProduction(id,cost-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-unique-unit",owner=owner,type=kinds[owner],hammers=cost-1,cost=cost})
 elseif phase=="AI-combat"and not attacks[owner]then assert(p:IsTurnActive());battle(owner)end
end)
function LekmodScenario.snapshot(player)
 local result={turn=Game.GetGameTurn(),owners={}}
 for owner=0,3 do local p=Players[owner];local list={}
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then list[u:GetID()]={type=u:GetUnitType(),owner=u:GetOwner(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves(),experience=u:GetExperience(),base_combat=u:GetBaseCombatStrength()}end end
  result.owners[owner]={civilization=p:GetCivilizationType(),gold=p:GetGold(),faith=p:GetFaith(),units=list}
 end
 return result
end
function LekmodScenario.step(player)
 local expected={[0]="CIVILIZATION_VATICAN",[1]="CIVILIZATION_ISRAEL",[2]="CIVILIZATION_JERUSALEM",[3]="CIVILIZATION_ROME"}
 for owner,kind in pairs(expected)do assert(Players[owner]:GetCivilizationType()==GameInfoTypes[kind],"requires reviewed Vatican-human roster")end
 local city=player:GetCapitalCity();local swiss=GameInfoTypes.UNIT_SWITZ
 if phase=="init"then
  assert(not player:HasCreatedReligion());local religion
  for info in GameInfo.Religions()do if info.ID>0 then religion=info.ID;break end end
  Game.FoundReligion(0,religion,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_FEED_WORLD,-1,-1,city)
  assert(player:GetReligionCreatedByPlayer()==religion)
  LekmodScenarioEvent("fixture-setup",{operation="provided-noncombat-human-religion",religion=religion})
  for owner=0,2 do local p=Players[owner];local info=GameInfo.Units[kinds[owner]];LekmodScenarioGrantTech(p,info.PrereqTech)
   for row in GameInfo.Unit_ResourceQuantityRequirements{UnitType=kinds[owner]}do local resource=GameInfoTypes[row.ResourceType];local amount=math.max(0,row.Cost-p:GetNumResourceAvailable(resource,true));if amount>0 then p:ChangeNumResourceTotal(resource,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-unit-resource",owner=owner,resource=row.ResourceType,amount=amount})end end
  end
  assert(not city:CanTrain(swiss)and city:IsCanPurchase(false,true,swiss,-1,-1,YieldTypes.YIELD_GOLD))
  LekmodScenarioRecord("swiss-purchase-only","PASS","normal production rejected and legal gold purchase available")
  price=city:GetUnitPurchaseCost(swiss);assert(price>0);player:ChangeGold(price);goldBefore=player:GetGold();LekmodScenarioEvent("fixture-setup",{operation="provided-Swiss-purchase-budget",gold_added=price})
  LuaEvents.LekmodScenarioGoldPurchase(city:GetID(),swiss);phase="purchased"
 elseif phase=="purchased"then
  if not reply then return false end
  if not LekmodScenarioAwait("Swiss-purchased",units[0]~=nil)then return false end
  assert(player:GetGold()==goldBefore-price and player:GetUnitByID(units[0]):GetUnitType()==swiss)
  LekmodScenarioRecord("swiss-gold-purchase","PASS","real ProductionPopup callback and UnitCreated; exact gold debit="..price)
  phase="production";return "turn"
 elseif phase=="production"then
  if not units[1]or not units[2]then return "turn"end
  for owner=0,2 do local u=assert(Players[owner]:GetUnitByID(units[owner]));assert(u:GetBaseCombatStrength()==GameInfo.Units[kinds[owner]].Combat and u:GetOwner()==owner)end
  LekmodScenarioRecord("maccabee-production","PASS","unforced real owner-turn production/UnitCreated with correct owner/base strength")
  LekmodScenarioRecord("crusader-production","PASS","unforced real owner-turn production/UnitCreated with correct owner/base strength")
  for owner=0,2 do local team=Teams[Players[owner]:GetTeam()];team:Meet(Players[3]:GetTeam(),true);team:DeclareWar(Players[3]:GetTeam(),false)end
  LekmodScenarioEvent("fixture-setup",{operation="provided-wars-against-Roman-defenders"});phase="human-ready"
 elseif phase=="human-ready"then
  if player:GetUnitByID(units[0]):GetMoves()<=0 then return "turn"end
  battle(0);phase="human-combat"
 elseif phase=="human-combat"then
  if not checkBattle(0)then return false end
  LekmodScenarioRecord("swiss-kill-yields","PASS","unit gold and faith plus Vatican trait faith from real military kill; no ordinary turn in spending comparison")
  phase="AI-combat";return "turn"
 elseif phase=="AI-combat"then
  if not attacks[1]or not attacks[2]then return "turn"end
  if not checkBattle(1)or not checkBattle(2)then return false end
  LekmodScenarioRecord("maccabee-kill-faith","PASS","actual produced Maccabee earns unit-defined 100% faith reward")
  LekmodScenarioRecord("crusader-kill-faith","PASS","actual produced Crusader earns unit-defined 200% faith reward")
  return true
 end
 return false
end
