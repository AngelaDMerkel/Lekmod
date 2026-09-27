-- Native method surface: GameCore
-- Re-enter native religion one-shots after a real load using a supplied legal
-- enhancement. This is a native API/one-shot-persistence test, not a prophet
-- mission or religion popup interaction claim. No grant counter/unit is set.
local mode=assert(LekmodScenarioParameters.mode)
assert(mode=="human"or mode=="control")
LekmodScenario={name="city-god-reentry",items={"city-god-reentry-load","city-god-reentry-enhanced","city-god-reentry-no-second-grant"}}
local phase,owner,before,created,enhanced,updates="init",nil,nil,0,0,0
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

GameEvents.UnitCreated.Add(function(id)if id==owner then created=created+1 end end)
GameEvents.ReligionEnhanced.Add(function(id)if id==owner then enhanced=enhanced+1 end end)
function LekmodScenario.step(player)
 if phase=="init"then
  owner=player:GetID();assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN)
  assert(LekmodScenarioJSON(LekmodScenario.snapshot(player))==LekmodScenarioParameters.expected_state,"fresh-process load differs from checkpoint")
  local religion=player:GetReligionCreatedByPlayer();local beliefs=Game.GetBeliefsInReligion(religion)
  assert(religion>0 and #beliefs==3,"requires founded/reformed but not enhanced saved religion")
  local found=false;for _,id in ipairs(beliefs)do if id==GameInfoTypes.BELIEF_CITY_OF_GOD then found=true end end
  assert(found==(mode=="human"),"saved reformation variant differs")
  local follower=assert(Game.GetAvailableFollowerBeliefs()[1]);local enhancer
  for _,id in ipairs(Game.GetAvailableEnhancerBeliefs())do local b=GameInfo.Beliefs[id]
   if (b.NumFreeSettlers or 0)==0 and (b.ProphetCostModifier or 0)==0 and (b.GoldenAgeTurns or 0)==0 then enhancer=id;break end
  end
  assert(enhancer);before=ownerState(player)
  LekmodScenarioRecord("city-god-reentry-load","PASS","cold loaded snapshot exactly matches the native saved checkpoint")
  LekmodScenarioEvent("fixture-setup",{operation="provided-legal-enhancement-after-load",owner=owner,religion=religion,follower=follower,enhancer=enhancer,mode=mode})
  phase="enhancing";Game.EnhanceReligion(owner,religion,follower,enhancer);return false
 end
 updates=updates+1;if updates<4 then return false end
 local after=ownerState(player)
 assert(enhanced==1 and #after.beliefs==5,"native enhancement did not complete once")
 assert(created==0,"religion one-shots repeated the saved free-prophet grant")
 assert(after.faith==before.faith and after.next_prophet==before.next_prophet,"enhancement changed faith/paid prophet price")
 assert(LekmodScenarioJSON(after.units)==LekmodScenarioJSON(before.units),"enhancement API unexpectedly changed units")
 LekmodScenarioRecord("city-god-reentry-enhanced","PASS","native enhancement and ReligionEnhanced event completed with two legal added beliefs")
 LekmodScenarioRecord("city-god-reentry-no-second-grant","PASS","native DoReligionOneShots reentry after cold load creates no second prophet; units/faith/price unchanged")
 return true
end
