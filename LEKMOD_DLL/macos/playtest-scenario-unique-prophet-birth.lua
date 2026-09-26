-- Native method surface: GameCore
-- Existing religions, save-prophet choice and faith budgets are fixture inputs.
-- No prophet, spawn roll, elapsed-turn state or completed outcome is supplied.
LekmodScenario={name="unique-prophet-birth",items={"prophet-below-cost-gate","prophet-Tibetan-birth","prophet-default-control","prophet-faith-threshold-accounting"}}
local phase,targets,started="init",{},nil
local function religion(p)
 assert(not p:HasCreatedReligion());local used={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local other=Players[owner];if other and other:IsAlive()and other:HasCreatedReligion()then used[other:GetReligionCreatedByPlayer()]=true end end
 local id;for info in GameInfo.Religions()do if info.ID>0 and not used[info.ID]then id=info.ID;break end end
 local founder=assert(Game.GetAvailableFounderBeliefs()[1]);local follower=assert(Game.GetAvailableFollowerBeliefs()[1])
 assert(id and Game.GetNumReligionsStillToFound()>0)
 Game.FoundReligion(p:GetID(),id,nil,founder,follower,-1,-1,p:GetCapitalCity());assert(p:GetReligionCreatedByPlayer()==id)
 LekmodScenarioEvent("fixture-setup",{operation="provided-founded-religion",owner=p:GetID(),religion=id,founder=founder,follower=follower});return id
end
-- Native enhancement and reformation may award free prophets. City of God
-- is a reformation belief using the legacy NumFreeSettlers field. Observe both
-- event paths before DoReligionOneShots, keeping paid births distinct.
local function beliefGrant(owner,id,beliefs,event)
 local t=targets[owner];if not t then return end
 local count=0;for _,belief in ipairs(beliefs)do count=count+(GameInfo.Beliefs[belief].NumFreeSettlers or 0)end
 if count>0 then assert(not t.freeExpected,"unreviewed repeated one-shot grant");t.freeExpected=count;t.freeSeen=0 end
 LekmodScenarioEvent(event,{owner=owner,religion=id,beliefs=beliefs,free_prophets=count})
end
GameEvents.ReligionEnhanced.Add(function(owner,id,first,second)beliefGrant(owner,id,{first,second},"native-prophet-religion-enhanced")end)
GameEvents.ReformationAdded.Add(function(owner,id,belief)beliefGrant(owner,id,{belief},"native-prophet-reformation")end)
GameEvents.UnitCreated.Add(function(owner,id)
 local t=targets[owner];if not t then return end
 local p=Players[owner];local u=p:GetUnitByID(id);if not u or u:GetUnitType()~=GameInfoTypes[t.kind]then return end
 if (t.freeExpected or 0)>(t.freeSeen or 0)then
  assert(p:GetMinimumFaithNextGreatProphet()>p:GetFaith(),"additional prophet is not isolated from a possible faith spawn")
  t.freeSeen=(t.freeSeen or 0)+1
  LekmodScenarioEvent("native-belief-prophet-birth",{owner=owner,kind=t.kind,id=id,faith=p:GetFaith(),next_faith_cost=p:GetMinimumFaithNextGreatProphet(),grant=t.freeSeen,expected=t.freeExpected})
  return
 end
 assert(phase=="funded"and not t.born,"unexplained paid prophet outside funded phase")
 assert(u:GetOwner()==owner and not u:IsDead()and not u:IsDelayedDeath())
 t.born=id;t.faithAtBirth=p:GetFaith();assert(t.faithAtBirth>=t.cost+100)
 LekmodScenarioEvent("native-faith-prophet-birth",{owner=owner,kind=t.kind,id=id,turn=Game.GetGameTurn(),faith_before_spawn_debit=t.faithAtBirth,cost=t.cost,control=t.control,owner_active=p:IsTurnActive()})
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 local t=targets[owner];if phase~="funded"or not t or not t.born or t.observed then return end
 local p=Players[owner];local u=p:GetUnitByID(t.born)
 assert(p:GetMinimumFaithNextGreatProphet()>t.cost,"next prophet threshold did not rise")
 -- Observe before the next human checkpoint; later AI faith spending is
 -- distinct from the spawn's debit. The human control must retain it exactly.
 assert(p:GetFaith()<=t.faithAtBirth-t.cost,"quoted prophet cost was not removed")
 if p:IsHuman()then assert(p:GetFaith()==t.faithAtBirth-t.cost,"human prophet faith debit differs")end
 if u then assert(u:GetReligion()==t.religion and u:GetSpreadsLeft()==GameInfo.Units[t.kind].ReligionSpreads,"fresh prophet religion/spreads differ")end
 t.observed=true
 LekmodScenarioEvent("prophet-owner-turn-accounting",{owner=owner,kind=t.kind,cost=t.cost,next_cost=p:GetMinimumFaithNextGreatProphet(),faith=p:GetFaith(),expected_after_spawn=t.faithAtBirth-t.cost,present=u~=nil,religion=u and u:GetReligion(),spreads=u and u:GetSpreadsLeft()})
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
  if p and p:IsAlive()then local cities,units={},{}
   for c in p:Cities()do cities[c:GetID()]={religion=c:GetReligiousMajority(),faith_rate=c:GetYieldRateTimes100(YieldTypes.YIELD_FAITH),population=c:GetPopulation()}end
   for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={kind=GameInfo.Units[u:GetUnitType()].Type,x=u:GetX(),y=u:GetY(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),moves=u:GetMoves()}end end
   local id=p:GetReligionCreatedByPlayer();owners[owner]={civilization=p:GetCivilizationType(),faith=p:GetFaith(),next_prophet=p:GetMinimumFaithNextGreatProphet(),religion=id,beliefs=id>0 and Game.GetBeliefsInReligion(id)or{},faith_choice=p:GetFaithPurchaseType(),cities=cities,units=units}
  end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  local owner;for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id];if p and p:IsAlive()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TIBET then owner=id end end
  assert(owner and owner~=player:GetID()and player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN,"requires reviewed Tibet-AI/Spain-human baseline")
  for _,id in ipairs({owner,player:GetID()})do local p=Players[id];local kind=id==owner and"UNIT_DALAILAMA"or"UNIT_PROPHET"
   assert(not p:GetCapitalCity():CanTrain(GameInfoTypes[kind]))
   assert(not p:HasCreatedReligion()and Game.GetNumReligionsStillToFound()>0)
   p:SetFaithPurchaseType(FaithPurchaseTypes.FAITH_PURCHASE_SAVE_PROPHET)
   local before=p:GetFaith();p:ChangeFaith(-before);targets[id]={owner=id,kind=kind,control=id~=owner}
   LekmodScenarioEvent("fixture-setup",{operation="provided-zero-faith-and-save-prophet-choice",owner=id,faith_before=before})
  end
  started=Game.GetGameTurn();phase="below-cost";return "turn"
 elseif phase=="below-cost"then
  if Game.GetGameTurn()==started then return "turn"end
  assert(Game.GetGameTurn()==started+1,"below-cost observation skipped a full round")
  for _,t in pairs(targets)do local p=Players[t.owner];assert(not t.born and p:GetFaith()<p:GetMinimumFaithNextGreatProphet(),"unexpected prophet/faith in below-cost control")end
  LekmodScenarioEvent("prophet-below-cost-round",{before_turn=started,after_turn=Game.GetGameTurn()})
  LekmodScenarioRecord("prophet-below-cost-gate","PASS","one complete ordinary round below quoted faith cost did not spawn either replacement")
  for _,t in pairs(targets)do local p=Players[t.owner];t.religion=religion(p);t.cost=p:GetMinimumFaithNextGreatProphet();local amount=t.cost+100;local before=p:GetFaith();p:ChangeFaith(amount-before)
   assert(not t.born);LekmodScenarioEvent("fixture-setup",{operation="provided-faith-above-guaranteed-spawn-chance",owner=t.owner,faith_before=before,faith_after=amount,cost=t.cost,excess=100})
  end
  phase="funded";started=Game.GetGameTurn();return "turn"
 elseif phase=="funded"then
  for _,t in pairs(targets)do if not t.born or not t.observed then assert(Game.GetGameTurn()-started<3,"faith-born prophet exceeded ordinary turn bound");return "turn"end end
  for _,t in pairs(targets)do if t.freeExpected then assert(t.freeSeen==t.freeExpected,"enhancement prophet grant count differs")end;LekmodScenarioRecord(t.control and"prophet-default-control"or"prophet-Tibetan-birth","PASS","normal faith processing created "..t.kind.." owner="..t.owner)end
  LekmodScenarioRecord("prophet-faith-threshold-accounting","PASS","both next thresholds increased and quoted costs removed; human debit exact; later AI spending distinguished")
  return true
 end
 return false
end
