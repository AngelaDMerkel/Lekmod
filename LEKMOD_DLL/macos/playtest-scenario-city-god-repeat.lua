-- Native method surface: GameCore
-- Load an actual completed City of God/control checkpoint. No setup mutation;
-- send the ordinary repeat request and require unchanged saved state.
local mode=assert(LekmodScenarioParameters and LekmodScenarioParameters.mode)
assert(mode=="human"or mode=="tibet"or mode=="control")
LekmodScenario={name="city-god-repeat",items={"city-god-loaded-belief","city-god-loaded-repeat-rejection","city-god-loaded-state-preserved"}}
local phase,owner,belief,before,callbacks,updates="init",nil,nil,nil,0,0
local function ownerState(p)
 local units={}
 for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then
  units[u:GetID()]={kind=GameInfo.Units[u:GetUnitType()].Type,religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),moves=u:GetMoves(),x=u:GetX(),y=u:GetY()}
 end end
 return {civilization=p:GetCivilizationType(),faith=p:GetFaith(),next_prophet=p:GetMinimumFaithNextGreatProphet(),religion=p:GetReligionCreatedByPlayer(),beliefs=p:HasCreatedReligion()and Game.GetBeliefsInReligion(p:GetReligionCreatedByPlayer())or{},units=units}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive()then owners[id]=ownerState(p)end end
 return {turn=Game.GetGameTurn(),owners=owners}
end
GameEvents.ReformationAdded.Add(function(id)if id==owner then callbacks=callbacks+1 end end)
GameEvents.UnitCreated.Add(function(id)if id==owner then callbacks=callbacks+1 end end)
function LekmodScenario.step(player)
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN,"requires saved Spain/Tibet group")
  owner=player:GetID()
  if mode=="tibet"then
   owner=nil;for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TIBET then owner=id;break end end
   assert(owner and owner~=player:GetID())
  end
  local p=Players[owner];assert(p:HasCreatedReligion()and p:HasPolicy(GameInfoTypes.POLICY_REFORMATION),"loaded prerequisite state is absent")
  for _,id in ipairs(Game.GetBeliefsInReligion(p:GetReligionCreatedByPlayer()))do
   if GameInfo.Beliefs[id].Reformation then assert(not belief,"multiple saved reformation beliefs");belief=id end
  end
  assert(belief,"saved reformation missing")
  if mode=="control"then assert((GameInfo.Beliefs[belief].NumFreeSettlers or 0)==0)
  else assert(belief==GameInfoTypes.BELIEF_CITY_OF_GOD)end
  before=LekmodScenarioJSON(LekmodScenario.snapshot(player))
  assert(before==LekmodScenarioParameters.expected_state,"fresh-process load differs from the recorded checkpoint")
  LekmodScenarioRecord("city-god-loaded-belief","PASS","actual saved reformation/policy/owner identity verified")
  LekmodScenarioEvent("native-command",{operation="repeat-reformation-after-real-load",owner=owner,belief=belief,mode=mode})
  phase="wait";Network.SendFoundPantheon(owner,belief);return false
 end
 updates=updates+1;if updates<4 then return false end
 assert(callbacks==0,"repeat after load fired a grant/creation callback")
 assert(LekmodScenarioJSON(LekmodScenario.snapshot(player))==before,"repeat after load changed belief/unit/faith/price state")
 LekmodScenarioRecord("city-god-loaded-repeat-rejection","PASS","normal repeated message rejected after loading persisted state")
 LekmodScenarioRecord("city-god-loaded-state-preserved","PASS","all-owner snapshot unchanged after settled repeat request")
 return true
end
