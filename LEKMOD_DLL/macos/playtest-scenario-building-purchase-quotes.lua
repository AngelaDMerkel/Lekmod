-- Native method surface: GameCore
-- Read-only downstream price arithmetic. Production quotes and the player's
-- existing hurry modifier are observed inputs; no purchase, funds or rule is set.
LekmodScenario={name="building-purchase-quotes",items={"purchase-quote-configuration","purchase-gold-derived","purchase-gold-explicit","purchase-gold-disabled","purchase-faith-values","purchase-faith-zero","purchase-visible-rounding","purchase-query-no-debit"}}
local modes={
 ["standard-settler"]={speed="GAMESPEED_STANDARD",handicap="HANDICAP_SETTLER",era="ERA_ANCIENT"},
 ["epic-deity"]={speed="GAMESPEED_EPIC",handicap="HANDICAP_DEITY",era="ERA_MEDIEVAL"},
 ["marathon-prince"]={speed="GAMESPEED_MARATHON",handicap="HANDICAP_PRINCE",era="ERA_RENAISSANCE"},
 ["quick-immortal"]={speed="GAMESPEED_QUICK",handicap="HANDICAP_IMMORTAL",era="ERA_INDUSTRIAL"},
 ["online-prince"]={speed="GAMESPEED_ONLINE",handicap="HANDICAP_PRINCE",era="ERA_ANCIENT"}}
local mode=assert(LekmodScenarioParameters.mode);local wanted=assert(modes[mode])
local function div(n,d)return n>=0 and math.floor(n/d)or math.ceil(n/d)end
local function yes(v)return v==true or v==1 end
local function teammate(p)
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local q=Players[id];if q and q:IsAlive()and q:IsHuman()and q:GetTeam()==p:GetTeam()then return true end end
 return false
end
local function roles()
 local ids={0,1}
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[id];if p and p:IsAlive()and p:IsMinorCiv()and p:GetCapitalCity()then ids[#ids+1]=id;break end end
 return ids
end
local function modifiers(p)
 local gold,faith=0,0
 for row in GameInfo.Policies()do if p:HasPolicy(row.ID)and not p:IsPolicyBlocked(row.ID)then gold=gold+row.BuildingPurchaseCostModifier;faith=faith+row.FaithCostModifier end end
 return {gold=gold,faith=faith,hurry=p:GetHurryModifier(GameInfoTypes.HURRY_GOLD)}
end
local function quotes(p,c,b,mods)
 local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()];local gold
 if b.HurryCostModifier==-1 or b.GoldCost<0 then gold=-1
 else
  if b.GoldCost>0 then gold=div(b.GoldCost*(100+b.HurryCostModifier),100);gold=div(gold*speed.ConstructPercent,100)
  else
   gold=math.floor((c:GetBuildingProductionNeeded(b.ID)*GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION)^GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT)
   gold=div(gold*(100+mods.hurry),100);gold=div(gold*speed.HurryPercent,100);gold=div(gold*(100+b.HurryCostModifier),100)
  end
  gold=div(gold*(100+mods.gold),100);gold=div(gold,GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR)*GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR
 end
 local faith=div(b.FaithCost*GameInfo.Eras[Teams[p:GetTeam()]:GetCurrentEra()].FaithCostMultiplier,100)
 if faith>0 and b.FaithCost>0 and yes(b.UnlockedByBelief)and b.Cost==-1 then faith=div(faith*(100+mods.faith),100)end
 faith=div(faith*speed.ConstructPercent,100)
 if not p:IsHuman()and not teammate(p)and not p:IsBarbarian()then faith=div(faith*GameInfo.HandicapInfos[Game.GetHandicapType()].AIConstructPercent,100)end
 local divisor=GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR*2;faith=div(faith,divisor)*divisor
 return gold,faith
end
local function ownerState(p)
 local cities={}
 for c in p:Cities()do local values={};for b in GameInfo.Buildings()do values[b.ID]={production=c:GetBuildingProductionNeeded(b.ID),gold=c:GetBuildingPurchaseCost(b.ID),faith=c:GetBuildingFaithPurchaseCost(b.ID)}end
  cities[c:GetID()]={majority=c:GetReligiousMajority(),quotes=values}
 end
 return {gold=p:GetGold(),faith=p:GetFaith(),human=p:IsHuman(),minor=p:IsMinorCiv(),teammate=teammate(p),team_era=Teams[p:GetTeam()]:GetCurrentEra(),modifiers=modifiers(p),cities=cities}
end
function LekmodScenario.snapshot(player)
 local owners={};for _,id in ipairs(roles())do owners[id]=ownerState(Players[id])end
 return {turn=Game.GetGameTurn(),speed=Game.GetGameSpeedType(),start_era=Game.GetStartEra(),handicap=Game.GetHandicapType(),owners=owners}
end
function LekmodScenario.step(player)
 assert(player:GetID()==0 and player:IsHuman())
 assert(Game.GetGameSpeedType()==GameInfo.GameSpeeds[wanted.speed].ID and Game.GetHandicapType()==GameInfo.HandicapInfos[wanted.handicap].ID and Game.GetStartEra()==GameInfo.Eras[wanted.era].ID)
 local totals={derived=0,explicit=0,disabled=0,faith=0,zero=0}
 for _,id in ipairs(roles())do local p=Players[id]
  assert(p:IsMinorCiv()or p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME or p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GREECE)
  local leader=assert(GameInfo.Leaders[p:GetLeaderType()])
  for t in GameInfo.Leader_Traits{LeaderType=leader.Type}do
   assert(GameInfo.Traits[t.TraitType].FaithCostModifier==0,"trait faith modifier requires separate scope")
   for row in GameInfo.Trait_BuildingCostOverride{TraitType=t.TraitType}do error("absolute cost override requires separate scope")end
  end
  local beforeGold,beforeFaith=p:GetGold(),p:GetFaith();local mods=modifiers(p)
  for c in p:Cities()do
   assert(c:GetReligiousMajority()<=0,"active belief-derived purchase prices require separate scope")
   for b in GameInfo.Buildings()do assert(b.FirstPurchaseDiscount==0 or c:GetNumActiveBuilding(b.ID)==0,"first-purchase discount requires separate scope")end
   local count=0
   for b in GameInfo.Buildings()do
    local gold,faith=quotes(p,c,b,mods);count=count+1
    assert(c:GetBuildingPurchaseCost(b.ID)==gold,"gold quote differs: "..b.Type.." owner"..id)
    assert(c:GetBuildingFaithPurchaseCost(b.ID)==faith,"faith quote differs: "..b.Type.." owner"..id)
    if gold<0 then totals.disabled=totals.disabled+1;assert(gold==-1)
    elseif b.GoldCost>0 then totals.explicit=totals.explicit+1
    else totals.derived=totals.derived+1 end
    if b.FaithCost>0 then totals.faith=totals.faith+1 else assert(faith==0);totals.zero=totals.zero+1 end
    assert(gold==-1 or gold%GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR==0);assert(faith%(2*GameDefines.FAITH_PURCHASE_VISIBLE_DIVISOR)==0)
   end
   assert(count==258)
  end
  assert(p:GetGold()==beforeGold and p:GetFaith()==beforeFaith)
  LekmodScenarioEvent("native-building-purchase-quotes",{mode=mode,owner=id,state=ownerState(p)})
 end
 assert(totals.derived>0 and totals.explicit>0 and totals.disabled>0 and totals.faith>0 and totals.zero>0)
 LekmodScenarioRecord("purchase-quote-configuration","PASS","variant="..mode.."; special belief/trait/first-purchase branches explicitly excluded")
 LekmodScenarioRecord("purchase-gold-derived","PASS","production-derived quotes match exponent, hurry, speed, building and policy factors")
 LekmodScenarioRecord("purchase-gold-explicit","PASS","explicit Israeli National College gold value uses construction-speed scaling")
 LekmodScenarioRecord("purchase-gold-disabled","PASS","disabled gold-price entries return-1")
 LekmodScenarioRecord("purchase-faith-values","PASS","positive faith quotes match era, applicable policy, speed and AI modifiers")
 LekmodScenarioRecord("purchase-faith-zero","PASS","zero faith-cost definitions remain0 without a granting belief")
 LekmodScenarioRecord("purchase-visible-rounding","PASS","gold and faith quotes obey their configured visible divisors")
 LekmodScenarioRecord("purchase-query-no-debit","PASS","read-only quotations do not debit gold or faith; exact replay follows")
 return true
end
