-- Native method surface: GameCore
local policy=GameInfoTypes.POLICY_MERCHANT_CONFEDERACY
local opener=GameInfoTypes.POLICY_PATRONAGE
local function div(n,d)return n>=0 and math.floor(n/d)or math.ceil(n/d)end
local function routeCount(p,minor)
 local n=0;for _,r in ipairs(p:GetTradeRoutes())do if r.ToID==minor then n=n+1 end end;return n
end
local function relation(m,owner)
 local p=Players[owner];return {raw100=Game.ReadMinorInfluenceForTest(m:GetID(),owner),anchor=m:GetMinorCivFriendshipAnchorWithMajor(owner),rate100=m:GetFriendshipChangePerTurnTimes100(owner),met=Teams[p:GetTeam()]:IsHasMet(m:GetTeam()),protected=m:IsProtectedByMajor(owner),policy=p:HasPolicy(policy),patronage=p:HasPolicy(opener),routes=routeCount(p,m:GetID())}
end
local function minor()
 local chosen
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then assert(not chosen and m:GetCapitalCity());chosen=m end
 end
 assert(chosen and chosen:GetMinorCivPersonalityType()=="MINOR_CIV_PERSONALITY_ISOLATIONIST")
 return chosen
end
local function audit(label)
 local m=minor();local values={};local info=GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()]
 assert(info.BlocksQuests==true or info.BlocksQuests==1);assert(info.BlocksPledgeToProtect==true or info.BlocksPledgeToProtect==1)
 assert(info.FriendshipDropPerTurn==0 and info.FriendshipDecayModifierPercent==100 and info.FriendshipRecoveryModifierPercent==100)
 for owner=0,2 do local p=Players[owner];local v=relation(m,owner)
  assert(not v.protected and not Teams[p:GetTeam()]:IsAtWar(m:GetTeam())and not p:HasCreatedReligion())
  local anchor=v.patronage and 20 or 0;assert(v.anchor==anchor)
  local base=v.raw100==anchor*100 and 0 or(v.raw100>anchor*100 and GameDefines.MINOR_FRIENDSHIP_DROP_PER_TURN or GameDefines.MINOR_FRIENDSHIP_NEGATIVE_INCREASE_PER_TURN)
  local shift=v.policy and v.met and v.routes>0 and GameInfo.Policies[policy].ProtectedMinorPerTurnInfluence or 0
  assert(v.rate100==div((base+shift)*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldGiftMod,100),"route influence arithmetic differs")
  values[owner]=v
 end
 LekmodScenarioEvent("native-merchant-influence",{label=label,minor=m:GetID(),values=values});return values
end
local function snapshot(p)
 local routes,traders={},{}
 for _,r in ipairs(p:GetTradeRoutes())do routes[r.FromCity:GetID()..":"..r.ToID..":"..r.ToCity:GetID()]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),owner=r.ToID,domain=r.Domain,kind=r.ConnectionType,left=r.TurnsLeft}end
 for u in p:Units()do if u:IsTrade()then traders[u:GetID()]={x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),type=u:GetUnitType()}end end
 local values={};for owner=0,2 do values[owner]=relation(minor(),owner)end
 return {turn=Game.GetGameTurn(),routes=routes,traders=traders,used=p:GetNumInternationalTradeRoutesUsed(),influence=values,policy=p:HasPolicy(policy),free=p:GetNumFreePolicies(),next_cost=p:GetNextPolicyCost(),barbarian_units=Players[GameDefines.BARBARIAN_PLAYER]:GetNumUnits()}
end
local function settlement(before,after)
 for owner=0,2 do local old,new=before[owner],after[owner];local expected=old.raw100+old.rate100
  if old.raw100>=old.anchor*100 and expected<old.anchor*100 then expected=old.anchor*100 end
  assert(new.raw100==expected,"ordinary influence differs from quoted settlement")
 end
end
LekmodScenario={name="minor-trade-influence",items={"merchant-inputs","merchant-before-condition","merchant-native-adoption","merchant-first-route","merchant-two-route-nonstack","merchant-owner-controls","merchant-native-settlement","merchant-positive-persistence"}}
local order=assert(LekmodScenarioParameters.order)
local phase,choice,response,adopted,unitID,originIndex,turn,before="init",nil,nil,false,nil,1,nil,nil
local origins={}
local idle,setupWait=0,0
LuaEvents.LekmodScenarioTradeResponse.Add(function(kind,id)response={kind=kind,id=id};LekmodScenarioEvent("native-trade-popup-response",response)end)
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)if owner==0 and id==policy then adopted=true end end)
function LekmodScenario.snapshot(p)return snapshot(p)end
local function normalize(p)
 local m=minor();local v=relation(m,0);assert(v.raw100%100==0);m:ChangeMinorCivFriendshipWithMajor(0,v.anchor-v.raw100/100)
 LekmodScenarioEvent("fixture-setup",{operation="provided-anchor-influence-before-observation",minor=m:GetID(),owner=0,raw100=v.anchor*100})
end
local function adopt(p)
 choice=LekmodScenarioPolicyChoice(p,policy);Network.SendUpdatePolicies(policy,true,true);phase="adopted"
end
local function route(p)
 local c=assert(p:GetCityByID(origins[originIndex]));local target=minor():GetCapitalCity()
 local u=assert(p:InitUnit(p:GetTradeUnitType(DomainTypes.DOMAIN_LAND),c:GetX(),c:GetY()));unitID=u:GetID();local kind
 for _,r in ipairs(p:GetPotentialInternationalTradeRouteDestinations(u))do if r.X==target:GetX()and r.Y==target:GetY()then kind=r.TradeConnectionType;break end end
 assert(kind and u:CanMakeTradeRouteAt(c:Plot(),target:GetX(),target:GetY(),kind),"provided caravan lacks legal minor route")
 LekmodScenarioEvent("fixture-setup",{operation="provided-caravan",owner=0,unit=unitID,origin=c:GetID(),destination=minor():GetID(),kind=kind})
 response=nil;UI.SelectUnit(u);phase="route-ready"
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAURYA)
 if phase=="init"then
  local m=minor();assert(#p:GetTradeRoutes()==0 and not p:HasPolicy(policy)and not p:HasPolicy(opener))
  assert(GameInfo.Policies[policy].ProtectedMinorPerTurnInfluence==100 and Players[GameDefines.BARBARIAN_PLAYER]:GetNumUnits()==0)
  assert(Teams[p:GetTeam()]:IsAtWar(Players[GameDefines.BARBARIAN_PLAYER]:GetTeam()))
  LekmodScenarioGrantTech(p,"TECH_COMPASS");LekmodScenarioGrantTech(p,"TECH_CURRENCY")
  p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_PATRONAGE,true,false);if not p:HasPolicy(opener)then p:SetHasPolicy(opener,true)end
  Teams[p:GetTeam()]:Meet(m:GetTeam(),true);p:ChangeGold(5000)
  local target=m:GetCapitalCity()
  for n=1,2 do local found
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(q:GetX(),q:GetY(),target:GetX(),target:GetY())
    if d>=4 and d<=7 and q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then p:Found(q:GetX(),q:GetY());found=q:GetPlotCity();break end
   end
   assert(found,"no legal caravan origin near city-state");origins[n]=found:GetID();found:SetNumRealBuilding(GameInfoTypes.BUILDING_CARAVANSARY,1)
   local range=p:GetTradeRouteRange(DomainTypes.DOMAIN_LAND,found)
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if Map.PlotDistance(found:GetX(),found:GetY(),q:GetX(),q:GetY())<=range then q:SetRevealed(p:GetTeam(),true)end end
   LekmodScenarioEvent("fixture-setup",{operation="provided-legal-origin-city-range-building-and-reveal",city=found:GetID(),x=found:GetX(),y=found:GetY(),range=range})
  end
  for c in p:Cities()do Game.CityPushOrder(c,OrderTypes.ORDER_MAINTAIN,GameInfoTypes.PROCESS_WEALTH,false,true,true)end
  assert(p:GetNumInternationalTradeRoutesAvailable()-p:GetNumInternationalTradeRoutesUsed()>=2)
  normalize(p);audit("before-policy-and-routes")
  LekmodScenarioRecord("merchant-inputs","PASS","normal one-human fixture, Isolationist minor, legal origins/research/contact/upkeep inputs; no quests or pledges")
  phase="inputs-ready"
 elseif phase=="inputs-ready"then
  setupWait=setupWait+1;assert(setupWait<=60,"supplied research popup queue did not drain")
  if UI.IsPopupUp()then idle=0;return false end
  idle=idle+1;if idle<2 then return false end
  LekmodScenarioEvent("fixture-ui-ready",{updates=setupWait,popup_up=UI.IsPopupUp()})
  if order=="policy-first"then adopt(p)else route(p)end
 elseif phase=="route-ready"then
  local u=p:GetUnitByID(unitID);local selected=UI.GetHeadSelectedUnit()
  if not LekmodScenarioAwait("merchant-selection",selected and selected:GetID()==unitID and selected:GetOwner()==p:GetID())then return false end
  local target=minor():GetCapitalCity();local kind
  for _,r in ipairs(p:GetPotentialInternationalTradeRouteDestinations(u))do if r.X==target:GetX()and r.Y==target:GetY()then kind=r.TradeConnectionType;break end end
  assert(kind);LuaEvents.LekmodScenarioTradeRoute(unitID,target:GetX(),target:GetY(),kind);phase="routed"
 elseif phase=="adopted"then
  if not LekmodScenarioAwait("merchant-adopted",adopted and p:HasPolicy(policy))then return false end
  LekmodScenarioVerifyPolicyChoice(p,policy,choice);assert(not p:IsPolicyBlocked(policy));normalize(p);local v=audit("policy-adopted")
  assert(v[0].rate100==(routeCount(p,minor():GetID())>0 and 125 or 0))
  LekmodScenarioRecord("merchant-native-adoption","PASS","legal normal policy message consumes exactly one choice and emits native adoption event")
  if order=="policy-first"then
   LekmodScenarioRecord("merchant-before-condition","PASS","policy without active connection adds no influence");route(p)
  else originIndex=2;route(p)end
 elseif phase=="routed"then
  if not LekmodScenarioAwait("merchant-route",response and response.kind=="route"and response.id==unitID and routeCount(p,minor():GetID())==originIndex)then return false end
  normalize(p);local v=audit("routes-"..originIndex)
  if originIndex==1 then
   assert(v[0].rate100==(p:HasPolicy(policy)and 125 or 0))
   LekmodScenarioRecord("merchant-first-route","PASS","real destination/confirm callbacks create one legal native city-state connection")
   if order=="route-first"and not p:HasPolicy(policy)then LekmodScenarioRecord("merchant-before-condition","PASS","active connection without policy adds no influence");adopt(p)
   else originIndex=2;route(p)end
  else
   assert(v[0].rate100==125 and v[1].rate100==0 and v[2].rate100==0)
   LekmodScenarioRecord("merchant-two-route-nonstack","PASS","two active connections to one minor still add only100 before the fixture Online125 speed scaling")
   LekmodScenarioRecord("merchant-owner-controls","PASS","separate AI and same-team different-player controls retain zero policy/connection influence")
   before=v;turn=Game.GetGameTurn();phase="settle";return "turn"
  end
 elseif phase=="settle"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  local after=audit("ordinary-settlement");settlement(before,after);assert(routeCount(p,minor():GetID())==2)
  LekmodScenarioEvent("native-merchant-settlement",{before=before,after=after,routes=2})
  LekmodScenarioRecord("merchant-native-settlement","PASS","normal minor update adds the exact quoted influence without assigning its result")
  LekmodScenarioRecord("merchant-positive-persistence","PASS","active policy, two routes and exact influence state retained for replay")
  return true
 end
 return false
end
