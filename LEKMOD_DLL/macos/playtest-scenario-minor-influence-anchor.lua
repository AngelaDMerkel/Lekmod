-- Native method surface: GameCore
-- Policy availability and initial whole-point influence are supplied inputs.
-- Ordinary minor turns must settle the quoted hundredths without crossing down
-- through the resting point. No per-turn influence value is assigned.
LekmodScenario={name="minor-influence-anchor",items={"influence-input-guards","influence-native-quotes","influence-far-decay","influence-below-recovery","influence-anchor-clamp","influence-repeated-boundary"}}
local mode=assert(LekmodScenarioParameters.mode)
local phase,minorID,start,tick="init",nil,nil,0
local before,under,farOK,recoveryOK,observations={},false,true,true,{}
local function read(minor,owner)
 return {raw100=Game.ReadMinorInfluenceForTest(minor:GetID(),owner),whole=minor:GetMinorCivBaseFriendshipWithMajor(owner),anchor=minor:GetMinorCivFriendshipAnchorWithMajor(owner),rate100=minor:GetFriendshipChangePerTurnTimes100(owner),policy=Players[owner]:HasPolicy(GameInfoTypes.POLICY_PATRONAGE),personality=minor:GetMinorCivPersonalityType()}
end
function LekmodScenario.snapshot(player)
 local minors={}
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then local majors={};for owner=0,2 do majors[owner]=read(m,owner)end;minors[id]=majors end
 end
 return {mode=mode,turn=Game.GetGameTurn(),minors=minors}
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer()and player:GetID()==0 and player:IsHuman())
 if phase=="init"then
  assert(type(Game.ReadMinorInfluenceForTest)=="function")
  for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id];if m and m:IsAlive()and m:IsMinorCiv()and m:GetCapitalCity()then assert(not minorID);minorID=id end end
  local minor=assert(Players[minorID]);assert(not pcall(Game.ReadMinorInfluenceForTest,0,0)and not pcall(Game.ReadMinorInfluenceForTest,minorID,-1)and not pcall(Game.ReadMinorInfluenceForTest,minorID,0.5))
  LekmodScenarioRecord("influence-input-guards","PASS","opted-in exact reader rejects invalid minor/major roles and fractional indices")
  for owner=0,2 do local p=Players[owner]
   assert(p:IsAlive()and p:GetCapitalCity()and not Teams[p:GetTeam()]:IsAtWar(minor:GetTeam()))
   assert(not p:HasPolicy(GameInfoTypes.POLICY_PATRONAGE))
   if mode=="policy"and owner~=1 then
    p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_PATRONAGE,true,false)
    if not p:HasPolicy(GameInfoTypes.POLICY_PATRONAGE)then p:SetHasPolicy(GameInfoTypes.POLICY_PATRONAGE,true)end
    LekmodScenarioEvent("fixture-setup",{operation="provided-Patronage-opener",owner=owner,anchor_expected=20})
   end
   local s=read(minor,owner);assert(s.anchor==((mode=="policy"and owner~=1)and 20 or 0))
   assert(s.raw100%100==0,"fixture already has fractional influence; review before setting integer input")
   local offset=owner==0 and 1 or owner==1 and 5 or -5;local target=s.anchor+offset
   minor:ChangeMinorCivFriendshipWithMajor(owner,target-s.whole);before[owner]=read(minor,owner)
   assert(before[owner].raw100==target*100)
   LekmodScenarioEvent("fixture-setup",{operation="provided-initial-whole-influence",mode=mode,owner=owner,minor=minorID,before=s,after=before[owner]})
  end
  assert(before[0].rate100< -100 and before[0].rate100> -200,"fixture must have fractional decay crossing a one-point gap")
  assert(before[1].rate100<0 and before[2].rate100>0)
  LekmodScenarioRecord("influence-native-quotes","PASS","negative fractional near-anchor rate, far-above decay and below-anchor recovery recorded before ordinary turns")
  start=Game.GetGameTurn();phase="observe";return "turn"
 end
 if Game.GetGameTurn()==start+tick then return "turn"end
 assert(Game.GetGameTurn()==start+tick+1);tick=tick+1;local minor=Players[minorID];local states={}
 for owner=0,2 do local old=before[owner];local now=read(minor,owner);local expected=old.raw100+old.rate100
  if old.raw100>=old.anchor*100 and expected<old.anchor*100 then expected=old.anchor*100 end
  states[owner]={before=old,after=now,expected100=expected}
  if owner==0 and now.raw100<now.anchor*100 then under=true end
  if owner==1 and now.raw100~=expected then farOK=false end
  if owner==2 and now.raw100~=expected then recoveryOK=false end
  before[owner]=now
 end
 observations[tick]=states;LekmodScenarioEvent("native-minor-influence-tick",{mode=mode,minor=minorID,tick=tick,turn=Game.GetGameTurn(),states=states})
 if tick<3 then return "turn"end
 LekmodScenarioRecord("influence-far-decay",farOK and"PASS"or"FAIL","ordinary far-above-anchor influence equals the pre-turn native rate")
 LekmodScenarioRecord("influence-below-recovery",recoveryOK and"PASS"or"FAIL","ordinary below-anchor influence equals the pre-turn native recovery rate")
 LekmodScenarioRecord("influence-anchor-clamp",not under and"PASS"or"FAIL","influence initially above resting point must never decay below its exact hundredths boundary")
 local final=before[0];local stable=not under and final.raw100==final.anchor*100 and final.rate100==0
 LekmodScenarioRecord("influence-repeated-boundary",stable and"PASS"or"FAIL","three ordinary minor turns reach and remain at exact anchor; no oscillation or negative fraction")
 return true
end
