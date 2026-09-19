-- Create probes on a real AI owner turn. Supplied units/positions are inputs;
-- AI mission processing must cause the native discovery/reward and repetition checks.
LekmodScenario={name="zabonah-ai-minor",items={"AI-Zabonah-Scout-control","AI-Zabonah-minor-capital","AI-Zabonah-no-repeat"}}
local phase="init"
local pending,done,aiError=false,false,nil
local function clear(p)return p and not p:IsWater()and not p:IsMountain()and not p:IsHills()and not p:IsCity()and not p:IsRiver()and p:GetFeatureType()<0 and p:GetOwner()==-1 and p:GetNumUnits()==0 end
local function safe(p,team,target,radius)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  local d=Map.PlotDistance(p:GetX(),p:GetY(),q:GetX(),q:GetY())
  if d<=radius then
   local c=q:GetPlotCity();if c and c:IsCapital()and c~=target and not c:IsRevealed(team)then return false end
   local f=q:GetFeatureType();if f>=0 then local info=GameInfo.Features[f];if info and(info.NaturalWonder==true or info.NaturalWonder==1)then return false end end
  end
 end
 return true
end
local function state(u)return {id=u:GetID(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),sight=u:VisibilityRange()}end
function LekmodScenario.snapshot(player)
 local ai=Players[1];local cities,units={},{}
 for owner=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[owner]
  if p and p:IsAlive()then for c in p:Cities()do cities[owner..":"..c:GetID()]={x=c:GetX(),y=c:GetY(),capital=c:IsCapital(),AI_revealed=c:IsRevealed(ai:GetTeam()),human_revealed=c:IsRevealed(player:GetTeam())}end end
 end
 for u in ai:Units()do if not u:IsDelayedDeath()and(u:GetUnitType()==GameInfoTypes.UNIT_MC_ZABONAH or u:GetUnitType()==GameInfoTypes.UNIT_SCOUT)then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),AI_civ=ai:GetCivilizationType(),AI_gold=ai:GetGold(),minor_cities=cities,AI_units=units}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or not pending then return end
 pending=false
 local ok,err=pcall(function()
  local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive(),"requires the real active AI owner turn")
  local team=p:GetTeam();local target,start,dest,again
  local radius=5
  for minor=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[minor];local city=m and m:IsAlive()and m:GetCapitalCity()
   if city and not city:IsRevealed(team)then
    for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
     if clear(q)and Map.PlotDistance(q:GetX(),q:GetY(),city:GetX(),city:GetY())==radius and safe(q,team,city,radius)then
      for d=0,5 do local r=Map.PlotDirection(q:GetX(),q:GetY(),d)
       if clear(r)and Map.PlotDistance(r:GetX(),r:GetY(),city:GetX(),city:GetY())==radius+1 and safe(r,team,city,radius)then
        for e=0,5 do local s=Map.PlotDirection(q:GetX(),q:GetY(),e)
         if s~=r and clear(s)and Map.PlotDistance(s:GetX(),s:GetY(),city:GetX(),city:GetY())==radius and safe(s,team,city,radius)then target=city;start=r;dest=q;again=s;break end
        end
       end
       if target then break end
      end
     end
     if target then break end
    end
   end
   if target then break end
  end
  assert(target,"no isolated unrevealed minor capital and two-step AI boundary")
  local scout=assert(p:InitUnit(GameInfoTypes.UNIT_SCOUT,start:GetX(),start:GetY()))
  assert(not target:IsRevealed(team)and scout:CanMoveOrAttackInto(dest))
  local gold=p:GetGold()
  LekmodScenarioEvent("fixture-setup",{operation="provided-real-AI-turn-Scout-and-boundary",owner=owner,minor=target:GetOwner(),city=target:GetID(),start=state(scout),destination={x=dest:GetX(),y=dest:GetY()}})
  scout:PushMission(MissionTypes.MISSION_MOVE_TO,dest:GetX(),dest:GetY(),0,0,1)
  assert(scout:GetX()==dest:GetX()and scout:GetY()==dest:GetY(),"AI Scout mission did not arrive synchronously")
  assert(not target:IsRevealed(team)and p:GetGold()==gold,"normal AI Scout received extended capital reveal/reward")
  LekmodScenarioRecord("AI-Zabonah-Scout-control","PASS","real AI owner-turn Scout mission; minor capital remains unrevealed; no gold")
  local spare
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if clear(q)and q~=start and q~=dest and q~=again then spare=q;break end end
  assert(spare);scout:SetXY(spare:GetX(),spare:GetY(),false,true,false,false)
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_MC_ZABONAH,start:GetX(),start:GetY()))
  LekmodScenarioEvent("fixture-setup",{operation="cleared-Scout-and-provided-real-AI-turn-Zabonah",scout=state(scout),zabonah=state(u)})
  assert(u:VisibilityRange()+3==radius and not target:IsRevealed(team)and u:CanMoveOrAttackInto(dest))
  gold=p:GetGold();u:PushMission(MissionTypes.MISSION_MOVE_TO,dest:GetX(),dest:GetY(),0,0,1)
  assert(u:GetX()==dest:GetX()and u:GetY()==dest:GetY(),"AI Zabonah mission did not arrive synchronously")
  LekmodScenarioEvent("AI-Zabonah-minor-discovery",{gold_before=gold,gold_after=p:GetGold(),target_owner=target:GetOwner(),capital=target:IsCapital(),revealed=target:IsRevealed(team),distance=Map.PlotDistance(u:GetX(),u:GetY(),target:GetX(),target:GetY()),unit=state(u)})
  assert(target:IsRevealed(team)and p:GetGold()==gold+10,"AI minor capital discovery/reward differs")
  LekmodScenarioRecord("AI-Zabonah-minor-capital","PASS","real AI owner-turn move reveals minor capital beyond sight; exact10gold")
  assert(u:GetMoves()>0 and u:CanMoveOrAttackInto(again),"AI repeat move unavailable")
  gold=p:GetGold();u:PushMission(MissionTypes.MISSION_MOVE_TO,again:GetX(),again:GetY(),0,0,1)
  assert(u:GetX()==again:GetX()and u:GetY()==again:GetY()and p:GetGold()==gold,"AI repeat discovery moved incorrectly or awarded twice")
  LekmodScenarioRecord("AI-Zabonah-no-repeat","PASS","second normal AI move grants no repeated discovery gold")
  done=true
 end)
 if not ok then aiError=tostring(err)end
end)
function LekmodScenario.step(player)
 assert(not aiError,aiError)
 assert(not Game.IsGameMultiPlayer()and player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  assert(Game.IsOption(GameInfoTypes.GAMEOPTION_NO_GOODY_HUTS)and Game.IsOption(GameInfoTypes.GAMEOPTION_NO_BARBARIANS),"no ruins/barbarians required")
  local minors=0;for i=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[i];if p and p:IsAlive()and p:GetCapitalCity()then minors=minors+1 end end
  if not player:GetCapitalCity()or minors==0 then return "turn"end
  pending=true;phase="AI";return "turn"
 elseif phase=="AI"then
  assert(not aiError,aiError)
  if not done then return "turn"end
  LekmodScenarioEvent("AI-Zabonah-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
