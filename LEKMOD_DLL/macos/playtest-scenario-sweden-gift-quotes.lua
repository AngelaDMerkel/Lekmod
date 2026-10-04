-- Native method surface: GameCore
-- Read-only API contract: quote requests must not pay the actual gift reward.
-- No treasury, influence, unit or relationship input is assigned by this probe.
LekmodScenario={name="sweden-gift-quotes",items={"gift-quote-data","gift-quote-values","gift-quote-repeat-values","gift-quote-readonly"}}
function LekmodScenario.snapshot(p)
 local owners={}
 for owner=0,2 do local v=Players[owner];local units={}
  for u in v:Units()do units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end
  local minors={};for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
   if m and m:IsAlive()and m:IsMinorCiv()then minors[id]={raw100=Game.ReadMinorInfluenceForTest(id,owner),met=Teams[v:GetTeam()]:IsHasMet(m:GetTeam())}end
  end
  owners[owner]={civilization=v:GetCivilizationType(),gold=v:GetGold(),units=units,minors=minors}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0)
 assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GOLDEN_HORDE and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SWEDEN and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 assert(GameInfo.Traits.TRAIT_DIPLOMACY_GREAT_PEOPLE.GreatPersonGiftInfluence==100 and GameDefines.FRIENDSHIP_PER_UNIT_GIFTED==5)
 local m=Players[GameDefines.MAX_MAJOR_CIVS];assert(m:IsAlive()and m:IsMinorCiv())
 local before=LekmodScenario.snapshot(p);local changes={}
 LekmodScenarioRecord("gift-quote-data","PASS","native Sweden trait100 and ordinary military gift5; two non-Swedish owner controls")
 for owner=0,2 do
  assert(not m:IsProxyWarActiveForMajor(owner)and not Players[owner]:HasPolicy(GameInfoTypes.POLICY_GUNBOAT_DIPLOMACY))
  for _,great in ipairs({false,true})do for _,distance in ipairs({false,true})do
   local old=Players[owner]:GetGold();local value=m:GetFriendshipFromUnitGift(owner,great,distance);local first=Players[owner]:GetGold()
   local repeated=m:GetFriendshipFromUnitGift(owner,great,distance);local second=Players[owner]:GetGold()
   local expected=great and(owner==1 and 100 or 0)or 5
   assert(value==expected and repeated==expected,"gift quote value differs from supplied data/owner")
   local observation={owner=owner,great_person=great,distance=distance,expected=expected,quote=value,repeated=repeated,gold_before=old,gold_after_first=first,gold_after_second=second}
   LekmodScenarioEvent("native-gift-quote",observation)
   if old~=first or old~=second then changes[#changes+1]=observation end
  end end
 end
 LekmodScenarioRecord("gift-quote-values","PASS","all12 owner/great-person/distance combinations match configured influence values")
 LekmodScenarioRecord("gift-quote-repeat-values","PASS","24 quote calls return the same values on repetition")
 local after=LekmodScenario.snapshot(p);local same=LekmodScenarioJSON(before)==LekmodScenarioJSON(after)
 LekmodScenarioEvent("native-gift-quote-state",{before=before,after=after,changed_calls=changes})
 LekmodScenarioRecord("gift-quote-readonly",same and"PASS"or"FAIL",same and"quotes preserve treasury, units and every minor relationship"or"read-only quote credited gold without a gift; changed combinations="..#changes)
 return true
end
