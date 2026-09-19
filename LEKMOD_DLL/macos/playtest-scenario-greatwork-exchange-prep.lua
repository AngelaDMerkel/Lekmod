-- Prepare real AI-created works and a scripted foreign offer for physical UI.
include("LekmodTestGreatWorkExchange")
LekmodScenario={name="greatwork-exchange-prep",items={"foreign-works-created","foreign-work-offer","exchange-ready"}}
local phase,started,aiError,art,writing="init"
local units={}
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="pending"then return end
 phase="issued"
 local ok,err=pcall(function()
  local p=Players[1];assert(p:IsTurnActive(),"AI Great Work mission outside real owner turn")
  for _,id in ipairs(units)do
   local u=assert(p:GetUnitByID(id));local mission=GameInfoTypes.MISSION_CREATE_GREAT_WORK
   assert(u:CanStartMission(mission,-1,-1,u:GetPlot(),0),"supplied AI great person cannot create a work")
   LekmodScenarioEvent("AI-create-work-command",{owner=1,unit=id,mission=mission,owner_active=true})
   u:PushMission(mission,-1,-1,0,0,1)
  end
 end)
 if not ok then aiError=tostring(err)end
end)
function LekmodScenario.snapshot(player)return LekmodExchangeSnapshot()end
function LekmodScenario.step(player)
 assert(not aiError,aiError)
 local other=Players[1]
 if phase=="init"then
  assert(player:GetID()==0 and player:GetNumGreatWorks()==2 and other:IsAlive()and not other:IsHuman()and other:GetNumGreatWorks()==0,"requires original two-artwork fixture with empty AI holdings")
  assert(not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()),"foreign offer fixture requires peace")
  if not Teams[player:GetTeam()]:IsHasMet(other:GetTeam())then Teams[player:GetTeam()]:Meet(other:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="provided-contact",other=1})end
  local city=assert(other:GetCapitalCity())
  for _,name in ipairs({"BUILDING_MUSEUM","BUILDING_AMPHITHEATER"})do
   if city:GetNumBuilding(GameInfoTypes[name])==0 then city:SetNumRealBuilding(GameInfoTypes[name],1);LekmodScenarioEvent("fixture-setup",{operation="provided-AI-work-slot-building",owner=1,city=city:GetID(),type=name})end
  end
  for _,name in ipairs({"UNIT_ARTIST","UNIT_WRITER"})do
   local u=assert(other:InitUnit(GameInfoTypes[name],city:GetX(),city:GetY()));units[#units+1]=u:GetID();LekmodScenarioEvent("fixture-setup",{operation="provided-AI-great-person",owner=1,id=u:GetID(),type=name})
  end
  started=Game.GetGameTurn();phase="pending";return "turn"
 elseif phase=="pending"or phase=="issued"then
  if other:GetNumGreatWorks()<2 then assert(Game.GetGameTurn()-started<2,"AI Great Work missions did not complete within ordinary turn bound");return "turn"end
  assert(other:GetNumGreatWorks()==2 and player:GetNumGreatWorks()==2,"Great Work counts changed unexpectedly")
  for _,id in ipairs(units)do local u=other:GetUnitByID(id);assert(not u or u:IsDead()or u:IsDelayedDeath(),"Great Work mission did not consume its unit")end
  local s=LekmodExchangeSnapshot()
  for id,w in pairs(s.works)do
   if w.creator==1 then
    assert(w.controller==1,"AI-created work has unexpected controller")
    if w.class==GameInfoTypes.GREAT_WORK_ART then art=id elseif w.class==GameInfoTypes.GREAT_WORK_LITERATURE then writing=id end
   else assert(w.creator==0 and w.controller==0,"preexisting human work changed owner")end
  end
  assert(art and writing,"AI must have one real artwork and one real writing")
  LekmodScenarioRecord("foreign-works-created","PASS","two actual AI-owner-turn great-person missions; supplied units and slot buildings")
  Network.SendSetSwappableGreatWork(1,GameInfoTypes.GREAT_WORK_ART,art)
  Network.SendSetSwappableGreatWork(1,GameInfoTypes.GREAT_WORK_LITERATURE,writing)
  LekmodScenarioEvent("fixture-setup",{operation="scripted-foreign-work-offers",owner=1,art=art,writing=writing,path="normal-set-swappable-network-commands"})
  phase="offered";return false
 elseif phase=="offered"then
  if not LekmodScenarioAwait("foreign-work-offers",other:GetSwappableGreatArt()==art and other:GetSwappableGreatWriting()==writing)then return false end
  LekmodScenarioEvent("exchange-ready",LekmodExchangeSnapshot())
  LekmodScenarioRecord("foreign-work-offer","PASS","native offered art/writing indices match actual owned works; scripted offer, not autonomous AI negotiation")
  LekmodScenarioRecord("exchange-ready","PASS","human2art AI1art1writing; no exchange has been performed")
  return true
 end
end
