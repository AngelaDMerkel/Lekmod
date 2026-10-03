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
LekmodScenario={name="minor-trade-removal",items={"merchant-loaded-positive","merchant-first-removal","merchant-final-removal","merchant-native-plunder","merchant-disconnected-settlement","merchant-removal-persistence"}}
local phase,turn,before,pending,performed,err,plunderID="init",nil,nil,false,0,nil,nil
local removed,plundered={},{}
GameEvents.UnitPlundered.Add(function(owner,id,x,y)if owner==GameDefines.BARBARIAN_PLAYER then plundered[id]={x=x,y=y}end end)
GameEvents.TradeRouteRemoved.Add(function(owner,destination)if owner==0 then removed[#removed+1]={owner=owner,destination=destination,remaining=#Players[0]:GetTradeRoutes()}end end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=GameDefines.BARBARIAN_PLAYER or not pending then return end
 local ok,e=pcall(function()
  local p=Players[0];local barbarian=Players[owner];assert(barbarian:IsTurnActive()and barbarian:GetNumUnits()==0)
  local candidate
  for u in p:Units()do if u:IsTrade()then local q=u:GetPlot();if not q:IsCity()and not q:IsWater()and q:GetNumUnits()==0 then candidate=q;break end end end
  if not candidate then return end
  local old=#p:GetTradeRoutes();local count=#removed;local gold=barbarian:GetGold()
  local raider=assert(barbarian:InitUnit(GameInfoTypes.UNIT_WARRIOR,candidate:GetX(),candidate:GetY()));plunderID=raider:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-barbarian-raider-on-actual-owner-turn",owner=owner,unit=plunderID,x=candidate:GetX(),y=candidate:GetY()})
  assert(raider:CanStartMission(GameInfoTypes.MISSION_PLUNDER_TRADE_ROUTE,-1,-1,candidate,0))
  raider:PushMission(GameInfoTypes.MISSION_PLUNDER_TRADE_ROUTE,-1,-1,0,0,1)
  assert(plundered[plunderID]and #p:GetTradeRoutes()==old-1 and #removed==count+1 and removed[#removed].destination==minor():GetID()and removed[#removed].remaining==old-1)
  assert(barbarian:GetGold()==gold+100)
  local cleanup={};for u in barbarian:Units()do cleanup[#cleanup+1]=u:GetID()end
  for _,id in ipairs(cleanup)do barbarian:GetUnitByID(id):Kill(false,-1)end
  LekmodScenarioEvent("native-merchant-route-plunder",{before=old,after=#p:GetTradeRoutes(),gold_reward=100,event=removed[#removed],provided_actors_cleaned=cleanup})
  pending=false;performed=performed+1
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(p)return snapshot(p)end
function LekmodScenario.step(p)
 assert(not err,err);assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:HasPolicy(policy))
 if phase=="init"then
  assert(routeCount(p,minor():GetID())==2 and #p:GetTradeRoutes()==2 and Players[GameDefines.BARBARIAN_PLAYER]:GetNumUnits()==0)
  assert(Teams[p:GetTeam()]:IsAtWar(Players[GameDefines.BARBARIAN_PLAYER]:GetTeam()))
  audit("loaded-two-route-policy");LekmodScenarioRecord("merchant-loaded-positive","PASS","genuine saved positive state still has policy, two connections and exact native rate")
  phase="plunder";pending=true;before=audit("before-removal-turn");turn=Game.GetGameTurn();return "turn"
 elseif phase=="plunder"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  local after=audit("after-removal-turn");settlement(before,after)
  LekmodScenarioEvent("native-merchant-removal-settlement",{before=before,after=after,performed=performed,pending=pending})
  if pending then before=after;turn=Game.GetGameTurn();return "turn"end
  if performed==1 then
   assert(routeCount(p,minor():GetID())==1);LekmodScenarioRecord("merchant-first-removal","PASS","first native plunder leaves one connection and retains the single policy bonus")
   pending=true;before=after;turn=Game.GetGameTurn();return "turn"
  end
  assert(performed==2 and #p:GetTradeRoutes()==0 and p:GetNumInternationalTradeRoutesUsed()==0)
  LekmodScenarioRecord("merchant-final-removal","PASS","last native removal ends the connection bonus while policy remains active")
  LekmodScenarioRecord("merchant-native-plunder","PASS","two real enemy-owner-turn missions emitted plunder/removal events and100gold each; only supplied raiders/bonus spawns were cleaned afterward")
  before=after;turn=Game.GetGameTurn();phase="disconnected";return "turn"
 elseif phase=="disconnected"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  local after=audit("disconnected-settlement");settlement(before,after);assert(#p:GetTradeRoutes()==0)
  LekmodScenarioEvent("native-merchant-disconnected-settlement",{before=before,after=after})
  LekmodScenarioRecord("merchant-disconnected-settlement","PASS","subsequent ordinary minor update follows baseline decay/recovery with no connection income")
  LekmodScenarioRecord("merchant-removal-persistence","PASS","policy remains, routes/visual units are removed, exact influence and zero raiders retained for replay")
  return true
 end
 return false
end
