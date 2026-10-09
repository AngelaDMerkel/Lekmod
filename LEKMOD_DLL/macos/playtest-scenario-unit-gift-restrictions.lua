-- Native method surface: GameCore
-- Contact and one ordinary military unit are fixture inputs. Gift eligibility,
-- rejection/transfer, shipment countdown and influence are native outcomes.
LekmodScenario={name="unit-gift-restrictions",items={"unit-gift-receiver","unit-gift-eligibility","unit-gift-command","unit-gift-accounting","unit-gift-arrival","unit-gift-persistence"}}
local mode=assert(LekmodScenarioParameters.mode)
local receiver=assert(LekmodScenarioParameters.receiver)
local alliedCase=receiver=="allied-war"or receiver=="peace-after-war"
local blocked=receiver=="isolationist"or receiver=="allied-war"
local ally,duplicateID,duplicateBefore
local phase,target,unitID,before,delivered,deliveryBefore,deliveryAfter,turn="init",nil,nil,nil,nil,nil,nil,nil
local converted
local function alive(p,id)local u=p:GetUnitByID(id);return u and not u:IsDead()and not u:IsDelayedDeath()end
local function emptyLand(owner)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==owner and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then return q end
 end
 return nil
end
local function flag(v)return v==true or v==1 end
local function raw(m)return Game.ReadMinorInfluenceForTest(m:GetID(),0)end
local function militaryGift(m)
 local n=GameDefines.FRIENDSHIP_PER_UNIT_GIFTED
 if m:IsProxyWarActiveForMajor(0)then n=n+GameDefines.FRIENDSHIP_PER_UNIT_GIFTED end
 for row in GameInfo.Policies()do assert((row.MilitaryUnitGiftExtraInfluence or 0)==0)end
 return n*100
end
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,upgrade)if oldOwner==0 and oldID==unitID and not upgrade then converted={owner=newOwner,id=newID}end end)
GameEvents.UnitCreated.Add(function(owner,id,x,y)
 if phase=="travel"and owner==target then local m=Players[target]
  if m:GetIncomingUnitCountdown(0)==0 then delivered=id;deliveryBefore={gold=Players[0]:GetGold(),raw100=raw(m),gift100=militaryGift(m),x=x,y=y}end
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==target and phase=="travel"and delivered and not deliveryAfter then deliveryAfter={gold=Players[0]:GetGold(),raw100=raw(Players[target])}end
end)
function LekmodScenario.snapshot(p)
 local owners,minors={},{}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local q=Players[owner];if q and q:IsAlive()then local units={};for u in q:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end;owners[owner]={gold=q:GetGold(),units=units,war_with_donor=Teams[q:GetTeam()]:IsAtWar(p:GetTeam())}end end
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then local units={};for u in m:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()}end end;minors[id]={personality=m:GetMinorCivPersonalityType(),raw100=raw(m),ally=m:GetAlly(),blocked_by_allied_war=m:IsMajorBlockedByAlliedWar(0),incoming_type=m:GetIncomingUnitType(0),incoming_turns=m:GetIncomingUnitCountdown(0),units=units}end
 end
 return {turn=Game.GetGameTurn(),owners=owners,minors=minors}
end
local function verdict(item,ok,detail)LekmodScenarioRecord(item,ok and"PASS"or"FAIL",detail)end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0 )
 if phase=="init"then
  for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
   if m and m:IsAlive()and m:IsMinorCiv()then local info=GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()]
    if ((not alliedCase and flag(info.NoGifts)==blocked)or(alliedCase and not flag(info.NoGifts)and flag(info.NeverAlliedWarSupport)))and m:GetCapitalCity()and emptyLand(id)then target=id;break end
   end
  end
  assert(target);local m=Players[target];local team=Teams[p:GetTeam()];team:Meet(m:GetTeam(),true)
  if alliedCase then
   assert(not Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_PEACE)and not Game.IsOption(GameOptionTypes.GAMEOPTION_ALWAYS_WAR)and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_CHANGING_WAR_PEACE),"war fixture has incompatible game options")
   assert(not team:IsAtWar(m:GetTeam()),"minor must begin at peace with donor")
   for id=1,GameDefines.MAX_MAJOR_CIVS-1 do local q=Players[id]
    if q and q:IsAlive()and not q:IsHuman()and q:GetTeam()~=p:GetTeam()then
     team:Meet(q:GetTeam(),true)
     if team:IsAtWar(q:GetTeam())or team:CanDeclareWar(q:GetTeam())then ally=id;break end
    end
   end
   assert(ally,"no legal opposing major for allied-war input");Teams[Players[ally]:GetTeam()]:Meet(m:GetTeam(),true)
   local highest=0;for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local q=Players[id];if q and q:IsAlive()then highest=math.max(highest,m:GetMinorCivFriendshipWithMajor(id))end end
   m:ChangeMinorCivFriendshipWithMajor(ally,highest+100-m:GetMinorCivFriendshipWithMajor(ally));assert(m:GetAlly()==ally)
   if not team:IsAtWar(Players[ally]:GetTeam())then team:DeclareWar(Players[ally]:GetTeam())end
   assert(team:IsAtWar(Players[ally]:GetTeam())and not team:IsAtWar(m:GetTeam())and m:IsMajorBlockedByAlliedWar(0))
   if receiver=="peace-after-war"then team:MakePeace(Players[ally]:GetTeam());assert(not team:IsAtWar(Players[ally]:GetTeam())and not m:IsMajorBlockedByAlliedWar(0))end
   LekmodScenarioEvent("fixture-setup",{operation="provided-ally-influence-and-native-war-peace",minor=target,ally=ally,minor_at_peace=not team:IsAtWar(m:GetTeam()),blocked=m:IsMajorBlockedByAlliedWar(0),receiver=receiver})
  end
  assert(not team:IsAtWar(m:GetTeam())and m:IsMajorBlockedByAlliedWar(0)==(receiver=="allied-war"))
  assert(m:GetIncomingUnitCountdown(0)==-1 and m:GetIncomingUnitType(0)==-1)
  local plot=mode=="local"and emptyLand(target)or p:GetCapitalCity():Plot();local u=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,plot:GetX(),plot:GetY()));unitID=u:GetID()
  assert(u:GetX()==plot:GetX()and u:GetY()==plot:GetY())
  before={gold=p:GetGold(),raw100=raw(m),minor_units=m:GetNumUnits(),incoming_type=m:GetIncomingUnitType(0),incoming_turns=m:GetIncomingUnitCountdown(0),gift100=militaryGift(m)}
  local eligible=mode=="local"and u:CanGift()or(mode=="distance"and u:CanDistanceGift(target));local visible;if mode=="local"then visible=u:CanGift(1,0)end
  LekmodScenarioEvent("fixture-setup",{operation="provided-military-gift-probe",mode=mode,blocked=blocked,minor=target,personality=m:GetMinorCivPersonalityType(),unit=unitID,x=plot:GetX(),y=plot:GetY(),before=before,eligible=eligible,visible=visible})
  LekmodScenarioRecord("unit-gift-receiver","PASS","native receiver/personality/peace and empty incoming queue established")
  verdict("unit-gift-eligibility",eligible==not blocked and(mode~="local"or visible==not blocked),"native eligibility and visible-action gate must follow the receiver's current gift restrictions")
  if mode=="local"then u:DoCommand(CommandTypes.COMMAND_GIFT,-1,-1)else Network.SendGiftUnit(target,unitID)end
  phase="sent"
 elseif phase=="sent"then
  local m=Players[target];local live=alive(p,unitID);local count=m:GetNumUnits();local incoming=m:GetIncomingUnitType(0);local countdown=m:GetIncomingUnitCountdown(0)
  LekmodScenarioEvent("native-unit-gift-result",{mode=mode,blocked=blocked,minor=target,unit=unitID,donor_alive=not not live,before=before,after_gold=p:GetGold(),after_raw100=raw(m),after_minor_units=count,incoming_type=incoming,incoming_turns=countdown,converted=converted})
  if blocked then
   local untouched=live and count==before.minor_units and incoming==before.incoming_type and countdown==before.incoming_turns and not converted
   verdict("unit-gift-command",not not untouched,"disallowed ordinary command must preserve donor, receiver and shipment queue")
   verdict("unit-gift-accounting",p:GetGold()==before.gold and raw(m)==before.raw100,"rejected gift pays no gold or influence")
   verdict("unit-gift-arrival",incoming==-1 and countdown==-1,"rejected shipment creates no future delivery")
   verdict("unit-gift-persistence",not not untouched,"rejection state retained for exact replay")
   return true
  elseif mode=="local"then
   assert(converted and converted.owner==target and not live and count==before.minor_units+1)
   assert(alive(m,converted.id)and m:GetUnitByID(converted.id):GetUnitType()==GameInfoTypes.UNIT_WARRIOR)
   assert(p:GetGold()==before.gold and raw(m)==before.raw100+before.gift100 and incoming==-1 and countdown==-1)
   LekmodScenarioRecord("unit-gift-command","PASS","ordinary gift converts donor into one live recipient Warrior")
   LekmodScenarioRecord("unit-gift-accounting","PASS","native local military gift pays the configured influence/shared-war amount and no gold")
   LekmodScenarioRecord("unit-gift-arrival","PASS","local gift arrives immediately without shipment state")
   LekmodScenarioRecord("unit-gift-persistence","PASS","positive local gift retained for exact replay");return true
  else
   assert(not live and incoming==GameInfoTypes.UNIT_WARRIOR and countdown==GameDefines.MINOR_UNIT_GIFT_TRAVEL_TURNS and countdown==3)
   assert(p:GetGold()==before.gold and raw(m)==before.raw100 and count==before.minor_units)
   LekmodScenarioRecord("unit-gift-command","PASS","normal shipment message consumes donor and creates the native three-turn queue")
   local extra=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,p:GetCapitalCity():GetX(),p:GetCapitalCity():GetY()));duplicateID=extra:GetID()
   assert(not extra:CanDistanceGift(target));duplicateBefore={gold=p:GetGold(),raw100=raw(m),incoming=m:GetIncomingUnitType(0),countdown=m:GetIncomingUnitCountdown(0)}
   LekmodScenarioEvent("fixture-setup",{operation="provided-second-unit-for-occupied-shipment-rejection",unit=duplicateID,minor=target})
   Network.SendGiftUnit(target,duplicateID);phase="duplicate";return false
  end
 elseif phase=="duplicate"then
  local m=Players[target];assert(alive(p,duplicateID)and m:GetIncomingUnitType(0)==duplicateBefore.incoming and m:GetIncomingUnitCountdown(0)==duplicateBefore.countdown and p:GetGold()==duplicateBefore.gold and raw(m)==duplicateBefore.raw100,"occupied shipment consumed a second donor or changed the queue")
  LekmodScenarioEvent("native-unit-gift-repeat-rejected",{unit=duplicateID,minor=target,state=duplicateBefore});p:GetUnitByID(duplicateID):Kill(false,-1)
  turn=Game.GetGameTurn();phase="travel";return "turn"
 elseif phase=="travel"then
  local m=Players[target];local elapsed=Game.GetGameTurn()-turn
  if elapsed<3 then assert(m:GetIncomingUnitCountdown(0)==3-elapsed and m:GetIncomingUnitType(0)==GameInfoTypes.UNIT_WARRIOR);return "turn"end
  assert(elapsed==3 and delivered and deliveryBefore and deliveryAfter and alive(m,delivered))
  assert(m:GetUnitByID(delivered):GetUnitType()==GameInfoTypes.UNIT_WARRIOR and m:GetIncomingUnitType(0)==-1 and m:GetIncomingUnitCountdown(0)==-1)
  assert(deliveryAfter.raw100==deliveryBefore.raw100+deliveryBefore.gift100 and deliveryAfter.gold==deliveryBefore.gold)
  LekmodScenarioEvent("native-unit-gift-arrival",{minor=target,unit=delivered,before=deliveryBefore,after=deliveryAfter,elapsed=elapsed})
  LekmodScenarioRecord("unit-gift-accounting","PASS","arrival gives the configured influence/shared-war amount and no gift gold on the actual minor turn")
  LekmodScenarioRecord("unit-gift-arrival","PASS","three ordinary turns deliver one identified Warrior and clear the queue")
  LekmodScenarioRecord("unit-gift-persistence","PASS","delivered unit and cleared shipment state retained for exact replay");return true
 end
 return false
end
