-- Native method surface: GameCore
-- @native-receiver u Unit
-- @native-receiver player Player
-- Units, contact, one policy and later-era prerequisites are supplied inputs.
-- Rewards use independent arithmetic from resolved data, never native quotes.
LekmodScenario={name="merchant-rewards",items={"merchant-input-parameters","merchant-location-controls","merchant-base-era-rewards","merchant-later-era-rewards","merchant-additive-modifiers","merchant-consumption"}}
local phase,index,round="init",1,1
local minor,site,neutral,id,before,expected,startEra
local observations={}
local combos={{unit="UNIT_MERCHANT",policy=false},{unit="UNIT_VENETIAN_MERCHANT",policy=false},{unit="UNIT_MERCHANT",policy=true},{unit="UNIT_VENETIAN_MERCHANT",policy=true}}
local policy=GameInfoTypes.POLICY_COMMERCE_FINISHER
local bonus=GameInfoTypes.PROMOTION_TRADE_MISSION_BONUS
local function gone(player)
 local u=player:GetUnitByID(id);return not u or u:IsDead()or u:IsDelayedDeath()
end
local function balances(player)
 return {gold=player:GetGold(),influence=Players[minor]:GetMinorCivFriendshipWithMajor(player:GetID())}
end
function LekmodScenario.snapshot(player)
 local units,minors={},{ }
 for u in player:Units()do if not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()}end end
 for owner=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[owner]
  if p and p:IsAlive()then minors[owner]=p:GetMinorCivFriendshipWithMajor(player:GetID())end
 end
 return {turn=Game.GetGameTurn(),era=player:GetCurrentEra(),speed=Game.GetGameSpeedType(),gold=player:GetGold(),policy=player:HasPolicy(policy),units=units,minors=minors}
end
local function supply(player)
 local c=combos[index]
 player:SetHasPolicy(policy,c.policy)
 assert(player:HasPolicy(policy)==c.policy)
 local u=assert(player:InitUnit(GameInfoTypes[c.unit],site:GetX(),site:GetY()));id=u:GetID()
 assert(u:GetX()==site:GetX()and u:GetY()==site:GetY()and not gone(player),"merchant relocated or died")
 local promoted=c.unit=="UNIT_VENETIAN_MERCHANT"
 assert(u:IsHasPromotion(bonus)==promoted,"native starting trade promotion differs")
 local info=GameInfo.Units[c.unit];local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
 assert(info.BaseGold==300 and info.NumGoldPerEra==100)
 assert(GameInfo.Policies[policy].TradeMissionGoldModifier==100)
 assert(GameInfo.UnitPromotions[bonus].TradeMissionGoldModifier==100 and GameInfo.UnitPromotions[bonus].TradeMissionInfluenceModifier==100)
 local pg,pi=0,0
 for p in GameInfo.UnitPromotions()do if u:IsHasPromotion(p.ID)then pg=pg+(p.TradeMissionGoldModifier or 0);pi=pi+(p.TradeMissionInfluenceModifier or 0)end end
 assert(pg==(promoted and 100 or 0)and pi==(promoted and 100 or 0),"unexpected merchant reward promotion")
 local polGold,polInf=0,0
 for p in GameInfo.Policies()do if player:HasPolicy(p.ID)then polGold=polGold+(p.TradeMissionGoldModifier or 0);polInf=polInf+(p.TradeMissionInfluenceModifier or 0)end end
 assert(polGold==(c.policy and 100 or 0)and polInf==0,"fixture has unreviewed reward policy")
 local base=math.floor((300+100*player:GetCurrentEra())*speed.UnitTradePercent/100)
 expected={gold=math.floor(base*(100+pg+polGold)/100),influence=math.floor(GameDefines.MINOR_FRIENDSHIP_FROM_TRADE_MISSION*(100+pi)/100)}
 assert(not u:CanTrade(player:GetCapitalCity():Plot())and not u:CanTrade(neutral),"own-major/unowned location wrongly eligible")
 assert(u:CanTrade(site),"peaceful minor mission unavailable")
 assert(u:GetTradeGold(site)==expected.gold and u:GetTradeInfluence(site)==expected.influence,"native quote differs from independent arithmetic")
 LekmodScenarioEvent("fixture-setup",{operation="provided-merchant-policy-and-position",unit=c.unit,id=id,policy=c.policy,era=player:GetCurrentEra(),speed=speed.Type,trade_percent=speed.UnitTradePercent,minor=minor,x=site:GetX(),y=site:GetY(),expected=expected})
 before=balances(player)
 UI.SelectUnit(u)
 for a=0,#GameInfoActions do if GameInfoActions[a]and GameInfoActions[a].Type=="MISSION_TRADE"then assert(Game.CanHandleAction(a));Game.HandleAction(a);phase="outcome";return end end
 error("missing normal merchant action")
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires Roman control fixture")
 if phase=="init"then
  startEra=player:GetCurrentEra();assert(startEra<GameInfoTypes.ERA_POSTMODERN,"fixture must precede Atomic")
  assert(not player:HasPolicy(policy),"fixture already has Commerce finisher")
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if not p:IsWater()and not p:IsMountain()and not p:IsCity()and p:GetNumUnits()==0 then
    if p:GetOwner()==-1 then neutral=neutral or p
    elseif Players[p:GetOwner()]:IsMinorCiv()and Players[p:GetOwner()]:IsAlive()and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam())then site=site or p end
   end
  end
  assert(site and neutral,"missing peaceful minor or neutral land")
  minor=site:GetOwner();local team=Players[minor]:GetTeam()
  if not Teams[player:GetTeam()]:IsHasMet(team)then Teams[player:GetTeam()]:Meet(team,true)end
  LekmodScenarioRecord("merchant-input-parameters","PASS","reviewed two300-base/100-per-era units,100% promotion/policy modifiers; actual native unit promotion checked per action")
  phase="supply"
 elseif phase=="supply"then supply(player)
 elseif phase=="outcome"then
  if not LekmodScenarioAwait("merchant-consumed",gone(player))then return false end
  local after=balances(player)
  assert(after.gold-before.gold==expected.gold,"actual treasury reward differs from independent arithmetic")
  assert(after.influence-before.influence==expected.influence,"actual minor influence differs from independent arithmetic")
  observations[#observations+1]={era=player:GetCurrentEra(),unit=combos[index].unit,policy=combos[index].policy,before=before,after=after,expected=expected}
  LekmodScenarioEvent("merchant-independent-outcome",observations[#observations])
  index=index+1
  if index<=#combos then phase="supply"
  elseif round==1 then
   LekmodScenarioRecord("merchant-base-era-rewards","PASS","four normal actions: both merchant types with/without policy; exact gold and influence")
   round=2;index=1;LekmodScenarioGrantTech(player,"TECH_ATOMIC_THEORY");phase="era"
  else
   LekmodScenarioRecord("merchant-later-era-rewards","PASS","four normal actions after actual research-induced era change; exact gold and influence")
   LekmodScenarioRecord("merchant-location-controls","PASS","all eight own-major/unowned queries rejected; peaceful minor actions accepted")
   LekmodScenarioRecord("merchant-additive-modifiers","PASS","ordinary policy doubles gold; promoted merchant plus policy triples base gold, does not multiply to4x; influence changes only with promotion")
   LekmodScenarioRecord("merchant-consumption","PASS","all eight actual missions consume their units; no assigned treasury/influence results")
   return true
  end
 elseif phase=="era"then
  assert(player:GetCurrentEra()==GameInfoTypes.ERA_POSTMODERN and player:GetCurrentEra()>startEra)
  phase="supply"
 end
 return false
end
