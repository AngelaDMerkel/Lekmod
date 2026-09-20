-- Units, treasury and diplomatic standing are controlled inputs. Read-only
-- before/after observers bracket the actual installed owner-turn handler.
LekmodScenario={name="newzealand-battalion",items={"Battalion-human-friendly","Battalion-AI-friendly","Battalion-negative-controls","Battalion-foreign-owners"}}
local phase="init"
local friend,neutral,turn,AIpending,err
local ids,before,results={},{},{}
local unitType=GameInfoTypes.UNIT_MC_NEW_ZEALAND_MAORI_BATTALION
local marker=GameInfoTypes.PROMOTION_ATTACK_AWAY_CAPITAL
local function unitState(u)return {id=u:GetID(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),plot_owner=u:GetPlot():GetOwner(),promotion=u:IsHasPromotion(marker),dead=u:IsDead(),delayed=u:IsDelayedDeath()}end
local function influence(owner)
 return {friendly=Players[friend]:GetMinorCivFriendshipWithMajor(owner),neutral=Players[neutral]:GetMinorCivFriendshipWithMajor(owner)}
end
local function input(owner,landOwner,kind,typeID)
 local plot
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetOwner()==landOwner and not p:IsWater()and not p:IsMountain()and not p:IsCity()and p:GetNumUnits()==0 then plot=p;break end
 end
 assert(plot,"no empty land input for "..kind)
 local u=assert(Players[owner]:InitUnit(typeID,plot:GetX(),plot:GetY()))
 assert(not u:IsDead()and not u:IsDelayedDeath())
 assert(u:IsHasPromotion(marker)==(typeID==unitType),"provided unit's native marker differs")
 ids[owner]=ids[owner]or{};ids[owner][kind]=u:GetID()
 LekmodScenarioEvent("fixture-setup",{operation="provided-Battalion-control-unit",owner=owner,kind=kind,state=unitState(u)})
 return u
end
LuaEvents.LekmodNZBeforeOwnerTurn.Add(function(owner)
 if not friend or(owner~=0 and owner~=1)then return end
 local ok,e=pcall(function()
  if owner==1 and AIpending then
   assert(not Players[owner]:IsHuman()and Players[owner]:IsTurnActive())
   AIpending=false;input(owner,friend,"AI-friendly",unitType)
   -- Unit creation and preceding AI decisions can resolve city-state quests.
   -- Supply the required standing after that input, before measuring the handler.
   for _,minor in ipairs({friend,neutral})do
    local m=Players[minor];local old=m:GetMinorCivFriendshipWithMajor(owner);local value=minor==friend and 45 or 0
    LekmodScenarioEvent("fixture-setup",{operation="provided-AI-standing-after-unit-creation",owner=owner,minor=minor,before=old,level=m:GetMinorCivFriendshipLevelWithMajor(owner),value=value})
    m:ChangeMinorCivFriendshipWithMajor(owner,value-old)
   end
  end
  if not ids[owner]or results[owner]then return end
  local units={};for kind,id in pairs(ids[owner])do units[kind]=unitState(assert(Players[owner]:GetUnitByID(id)))end
  LekmodScenarioEvent("Battalion-standing-gates",{owner=owner,standing=influence(owner),friendly_level=Players[friend]:GetMinorCivFriendshipLevelWithMajor(owner),neutral_level=Players[neutral]:GetMinorCivFriendshipLevelWithMajor(owner)})
  assert(Players[friend]:GetMinorCivFriendshipLevelWithMajor(owner)>=1 and Players[neutral]:GetMinorCivFriendshipLevelWithMajor(owner)<1,"standing precondition changed before owner turn")
  before[owner]={influence=influence(owner),units=units,turn=Game.GetGameTurn()}
  LekmodScenarioEvent("Battalion-before-native-owner-handler",{owner=owner,state=before[owner]})
 end)
 if not ok then err=tostring(e)end
end)
LuaEvents.LekmodNZAfterOwnerTurn.Add(function(owner)
 if not before[owner]or results[owner]then return end
 local after=influence(owner);results[owner]={before=before[owner],after=after}
 LekmodScenarioEvent("Battalion-after-native-owner-handler",{owner=owner,result=results[owner]})
end)
function LekmodScenario.snapshot(player)
 local owners,minors={},{}
 for owner=0,1 do local p=Players[owner];local units={}
  for u in p:Units()do if not u:IsDelayedDeath()and(u:GetUnitType()==unitType or u:GetUnitType()==GameInfoTypes.UNIT_WARRIOR)then units[u:GetID()]=unitState(u)end end
  owners[owner]={civilization=p:GetCivilizationType(),units=units}
 end
 for owner=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[owner]
  if p and p:IsAlive()then minors[owner]={human=p:GetMinorCivFriendshipWithMajor(0),AI=p:GetMinorCivFriendshipWithMajor(1)}end
 end
 return {turn=Game.GetGameTurn(),owners=owners,minors=minors}
end
function LekmodScenario.step(player)
 assert(not err,err)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  local minors={}
  for owner=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[owner]
   if p and p:IsAlive()and p:GetCapitalCity()then minors[#minors+1]=owner end
  end
  assert(#minors==2,"requires the two-minor AI-Zabonah fixture");friend=minors[1];neutral=minors[2]
  for owner=0,1 do
   for u in Players[owner]:Units()do assert(not u:IsHasPromotion(marker),"fixture already contains influence units")end
   for _,minor in ipairs(minors)do if not Teams[Players[owner]:GetTeam()]:IsHasMet(Players[minor]:GetTeam())then Teams[Players[owner]:GetTeam()]:Meet(Players[minor]:GetTeam(),true)end end
   Players[owner]:SetGold(500)
  end
  input(0,friend,"human-friendly-one",unitType);input(0,friend,"human-friendly-two",unitType)
  input(0,friend,"normal-Warrior",GameInfoTypes.UNIT_WARRIOR)
  input(0,neutral,"unfriendly-Battalion",unitType);input(0,-1,"outside-Battalion",unitType)
  for owner=0,1 do for _,minor in ipairs(minors)do
   local p=Players[minor];local value=minor==friend and 45 or 0
   p:ChangeMinorCivFriendshipWithMajor(owner,value-p:GetMinorCivFriendshipWithMajor(owner))
   LekmodScenarioEvent("fixture-setup",{operation="provided-standing-and-upkeep",owner=owner,minor=minor,standing=value,gold=500})
  end end
  AIpending=true;turn=Game.GetGameTurn();phase="observed";return "turn"
 elseif phase=="observed"then
  assert(not err,err)
  if not results[0]or not results[1]then return "turn"end
  assert(Game.GetGameTurn()==turn+1,"owner observation exceeded one ordinary turn")
  for owner=0,1 do local r=results[owner];local expected=owner==0 and 2 or 1
   assert(r.after.friendly-r.before.influence.friendly==expected,"friendly influence increment differs")
   assert(r.after.neutral==r.before.influence.neutral,"unfriendly control received influence")
  end
  LekmodScenarioRecord("Battalion-human-friendly","PASS","two native Battalion units add exactly2 influence at actual human owner turn")
  LekmodScenarioRecord("Battalion-AI-friendly","PASS","fresh real-AI-owner-turn Battalion adds exactly1 influence")
  LekmodScenarioRecord("Battalion-negative-controls","PASS","normal Warrior, unowned plot and unfriendly minor do not add influence")
  LekmodScenarioRecord("Battalion-foreign-owners","PASS","human and AI Roman owners work with New Zealand absent")
  return true
 end
 return false
end
