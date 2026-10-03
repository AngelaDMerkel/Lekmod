-- Native method surface: GameCore
-- Genuine failed saves. No policy, influence, research, turn or ownership input
-- is changed; corrected rate selection and ordinary turns must recover naturally.
LekmodScenario={name="minor-influence-recovery",items={"influence-load-protected-state","influence-load-corrected-rate","influence-load-natural-recovery","influence-load-stability"}}
local mode=assert(LekmodScenarioParameters.mode)
local phase,minorID,start,tick="init",nil,nil,0
local before={}
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
 assert(not Game.IsGameMultiPlayer())
 if phase=="init"then
  local state=LekmodScenario.snapshot(player)
  for id,majors in pairs(state.minors)do assert(not minorID);minorID=id;for _,v in pairs(majors)do v.rate100=nil end end
  assert(LekmodScenarioJSON({turn=state.turn,owners=state.minors})==LekmodScenarioParameters.expected_state,"saved fields changed beyond the recomputed rate query")
  local minor=assert(Players[minorID]);for owner=0,2 do before[owner]=read(minor,owner)end
  assert(before[0].raw100==(mode=="baseline"and -25 or 1975)and before[0].anchor==(mode=="baseline"and 0 or 20))
  assert(before[0].rate100==125 and before[1].rate100==-125 and before[2].rate100==125)
  LekmodScenarioRecord("influence-load-protected-state","PASS","genuine failed checkpoint preserves every recorded raw influence, whole view, anchor, policy, personality and turn; no repair assignment")
  LekmodScenarioRecord("influence-load-corrected-rate","PASS","negative fractional oldsave now quotes positive125 recovery instead of zero; all rates use exact storage")
  LekmodScenarioEvent("native-influence-recovery-loaded",{mode=mode,minor=minorID,states=before})
  start=Game.GetGameTurn();phase="turn";return "turn"
 end
 if Game.GetGameTurn()==start+tick then return "turn"end
 assert(Game.GetGameTurn()==start+tick+1);tick=tick+1;local states={};local minor=Players[minorID]
 for owner=0,2 do local old=before[owner];local now=read(minor,owner);local expected=old.raw100+old.rate100
  if old.raw100>=old.anchor*100 and expected<old.anchor*100 then expected=old.anchor*100 end
  assert(now.raw100==expected,"ordinary influence recovery differs from corrected quoted settlement")
  if tick>=2 then assert(now.raw100==now.anchor*100 and now.rate100==0)end
  states[owner]={before=old,after=now,expected100=expected};before[owner]=now
 end
 LekmodScenarioEvent("native-influence-recovery-tick",{mode=mode,minor=minorID,tick=tick,turn=Game.GetGameTurn(),states=states})
 if tick<3 then return "turn"end
 LekmodScenarioRecord("influence-load-natural-recovery","PASS","both retained defective states reach exact anchor through ordinary updates within2turns; far/negative controls settle correctly")
 LekmodScenarioRecord("influence-load-stability","PASS","third ordinary round remains at exact anchors with zero rate; exact replay follows")
 return true
end
