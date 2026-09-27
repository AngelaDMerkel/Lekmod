-- Native method surface: GameCore
-- Religion, prerequisite policy and a zero-faith budget are explicit inputs.
-- The checked native reformation message performs the grant; no prophet,
-- one-shot flag, religion-spread count or final reward is assigned by this test.
local mode=assert(LekmodScenarioParameters and LekmodScenarioParameters.mode, "reviewed batch parameters required")
assert(mode=="human" or mode=="tibet" or mode=="control", "unknown City of God role")
LekmodScenario={name="city-god",items={"city-god-eligibility-rejection","city-god-native-selection","city-god-grant-count","city-god-free-accounting","city-god-properties","city-god-repeat-rejection","city-god-owner-turn-no-repeat"}}
local phase,owner,religion,kind,belief,before,created,selected,waits,ownerTurn="init",nil,nil,nil,nil,nil,{},0,0,nil
local function units(p)
 local rows={}
 for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then
  rows[u:GetID()]={kind=GameInfo.Units[u:GetUnitType()].Type,religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),moves=u:GetMoves(),x=u:GetX(),y=u:GetY()}
 end end
 return rows
end
local function state(p)
 return {civilization=p:GetCivilizationType(),faith=p:GetFaith(),next_prophet=p:GetMinimumFaithNextGreatProphet(),
  religion=p:GetReligionCreatedByPlayer(),beliefs=p:HasCreatedReligion()and Game.GetBeliefsInReligion(p:GetReligionCreatedByPlayer())or{},units=units(p)}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive()then owners[id]=state(p)end end
 return {turn=Game.GetGameTurn(),owners=owners}
end
GameEvents.ReformationAdded.Add(function(id,religionID,beliefID)
 if id==owner then
  assert(phase=="selecting","unexpected/repeated reformation callback")
  assert(religionID==religion and beliefID==belief,"native selection identity differs")
  selected=selected+1
  LekmodScenarioEvent("city-god-reformation-event",{owner=id,religion=religionID,belief=beliefID})
 end
end)
GameEvents.UnitCreated.Add(function(id,unitID)
 if id==owner then
  local u=Players[id]:GetUnitByID(unitID)
  if u and u:GetUnitType()==GameInfoTypes[kind]then
   assert(phase=="selecting","prophet created outside the selected free-grant phase")
   created[unitID]=true
   LekmodScenarioEvent("city-god-created-event",{owner=id,unit=unitID,kind=kind})
  end
 end
end)
local function containsBelief(id)
 for _,b in ipairs(Game.GetBeliefsInReligion(religion))do if b==id then return true end end
 return false
end
local function countCreated()
 local n=0;for _ in pairs(created)do n=n+1 end;return n
end
local function tickWait(label)
 -- A fixed number of driver updates lets the checked network message settle.
 -- Do not modify native synchronization or processing flags.
 waits=waits+1;LekmodScenarioEvent(label,{updates=waits,turn=Game.GetGameTurn()});return waits>=4
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN,"requires the pinned Spain/Tibet group")
  owner=player:GetID()
  if mode=="tibet"then
   owner=nil;for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TIBET then owner=id;break end end
   assert(owner and owner~=player:GetID(),"Tibetan AI owner missing")
  end
  local p=Players[owner];kind=mode=="tibet"and"UNIT_DALAILAMA"or"UNIT_PROPHET"
  assert(not p:HasCreatedReligion()and not p:HasPolicy(GameInfoTypes.POLICY_REFORMATION),"fixture already has religion/reformation eligibility")
  assert(Game.GetNumReligionsStillToFound()>0)
  p:ChangeFaith(-p:GetFaith());p:SetFaithPurchaseType(FaithPurchaseTypes.FAITH_PURCHASE_SAVE_PROPHET)
  local used={};for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local q=Players[id];if q and q:IsAlive()and q:HasCreatedReligion()then used[q:GetReligionCreatedByPlayer()]=true end end
  for row in GameInfo.Religions()do if row.ID>0 and not used[row.ID]then religion=row.ID;break end end
  assert(religion);local founder=assert(Game.GetAvailableFounderBeliefs()[1]);local follower=assert(Game.GetAvailableFollowerBeliefs()[1])
  Game.FoundReligion(owner,religion,nil,founder,follower,-1,-1,p:GetCapitalCity())
  assert(p:GetReligionCreatedByPlayer()==religion and p:GetCapitalCity():GetReligiousMajority()==religion)
  belief=GameInfoTypes.BELIEF_CITY_OF_GOD
  if mode=="control"then
   belief=nil;for _,id in ipairs(Game.GetAvailableReformationBeliefs())do if (GameInfo.Beliefs[id].NumFreeSettlers or 0)==0 then belief=id;break end end
   assert(belief,"no no-grant reformation control")
  end
  assert(not containsBelief(belief));before=state(p)
  LekmodScenarioEvent("fixture-setup",{operation="provided-founded-religion-zero-faith",owner=owner,religion=religion,founder=founder,follower=follower,kind=kind,mode=mode})
  phase="rejecting";Network.SendFoundPantheon(owner,belief);return false
 elseif phase=="rejecting"then
  if not tickWait("city-god-rejected-message-wait")then return false end
  local p=Players[owner];assert(selected==0 and countCreated()==0 and not containsBelief(belief))
  assert(p:GetFaith()==before.faith and p:GetMinimumFaithNextGreatProphet()==before.next_prophet)
  LekmodScenarioRecord("city-god-eligibility-rejection","PASS","no reformation policy: checked native message grants nothing")
  p:SetHasPolicy(GameInfoTypes.POLICY_REFORMATION,true)
  LekmodScenarioEvent("fixture-setup",{operation="provided-reformation-policy",owner=owner,policy="POLICY_REFORMATION"})
  before=state(p);phase="selecting";waits=0;Network.SendFoundPantheon(owner,belief);return false
 elseif phase=="selecting"then
  if not LekmodScenarioAwait("city-god-native-selection",selected==1 and containsBelief(belief))then return false end
  if not tickWait("city-god-grant-settlement")then return false end
  local p=Players[owner];local expected=mode=="control"and 0 or 1
  assert(countCreated()==expected,"free prophet count differs")
  assert(p:GetFaith()==before.faith and p:GetMinimumFaithNextGreatProphet()==before.next_prophet,"free grant charged faith or increased paid prophet price")
  for id in pairs(created)do local u=assert(p:GetUnitByID(id));assert(u:GetUnitType()==GameInfoTypes[kind]and u:GetOwner()==owner and not u:IsDelayedDeath())
   assert(u:GetReligion()==religion and u:GetSpreadsLeft()==GameInfo.Units[kind].ReligionSpreads,"settled free prophet properties differ")
  end
  LekmodScenarioRecord("city-god-native-selection","PASS","checked native message and reformation callback agree")
  LekmodScenarioRecord("city-god-grant-count","PASS","expected free "..kind.." count="..expected)
  LekmodScenarioRecord("city-god-free-accounting","PASS","zero faith charge and unchanged paid-prophet price")
  LekmodScenarioRecord("city-god-properties","PASS",expected==0 and"no prophet created by the control belief"or"correct owner/type/religion and data-defined spreads after native initialization")
  before=state(p);phase="repeating";waits=0;Network.SendFoundPantheon(owner,belief);return false
 elseif phase=="repeating"then
  if not tickWait("city-god-repeat-message-wait")then return false end
  assert(selected==1 and countCreated()==(mode=="control"and 0 or 1))
  assert(LekmodScenarioJSON(state(Players[owner]))==LekmodScenarioJSON(before),"repeat request changed free-grant state")
  LekmodScenarioRecord("city-god-repeat-rejection","PASS","repeat native selection rejected; no new unit, debit, price or belief change")
  assert(Players[owner]:GetFaith()<Players[owner]:GetMinimumFaithNextGreatProphet(),"isolate free grant from paid faith spawn")
  ownerTurn=Game.GetGameTurn();phase="owner-turn";return "turn"
 elseif phase=="owner-turn"then
  if Game.GetGameTurn()==ownerTurn then return "turn" end
  assert(Game.GetGameTurn()==ownerTurn+1,"expected exactly one normal round")
  assert(selected==1 and countCreated()==(mode=="control"and 0 or 1),"ordinary owner turn repeated the free grant")
  assert(Players[owner]:GetFaith()<Players[owner]:GetMinimumFaithNextGreatProphet(),"paid-spawn threshold reached during isolated check")
  LekmodScenarioRecord("city-god-owner-turn-no-repeat","PASS","actual turn "..ownerTurn.." to "..Game.GetGameTurn().." without another grant")
  return true
 end
 return false
end
