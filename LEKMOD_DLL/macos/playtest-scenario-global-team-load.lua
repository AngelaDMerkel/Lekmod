-- Native method surface: GameCore
-- Genuine failed checkpoints. Product load repair precedes every test assertion;
-- no building, policy, research, team or reward state is assigned here.
LekmodScenario={name="global-team-load",items={"global-load-repair","global-load-protected-state","global-load-next-turn"}}
local mode=assert(LekmodScenarioParameters.mode)
local phase,turn="init",nil
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];local cities={}
  for c in p:Cities()do
   local row={ulug=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ULUG),wales=c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT),mongol=c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT),union=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ECONOMIC_UNION_GOLD)}
   if mode=="initial"then row.x=c:GetX();row.y=c:GetY()end;cities[c:GetID()]=row
  end
  local row={team=p:GetTeam(),civilization=p:GetCivilizationType(),cities=cities}
  if mode=="policy"then row.era=p:GetCurrentEra();row.free=p:GetNumFreePolicies();row.tenets=p:GetNumFreeTenets();row.culture=p:GetJONSCulture();row.next_cost=p:GetNextPolicyCost();row.union=p:HasPolicy(GameInfoTypes.POLICY_ECONOMIC_UNION)end
  owners[owner]=row
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function check()
 for owner=0,2 do local p=Players[owner]
  for c in p:Cities()do
   assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_ULUG)==(owner==2 and c:IsCapital()and 1 or 0))
   assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT)==(owner==0 and c:IsCapital()and Teams[7]:IsHasTech(GameInfoTypes.TECH_ANIMAL_HUSBANDRY)and 1 or 0))
   assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT)==(owner==1 and c:IsCapital()and Teams[7]:IsHasTech(GameInfoTypes.TECH_CHIVALRY)and 1 or 0))
   assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_ECONOMIC_UNION_GOLD)==(p:HasPolicy(GameInfoTypes.POLICY_ECONOMIC_UNION)and 1 or 0))
  end
 end
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer()and player:GetID()==0 and player:GetTeam()==7 and Players[1]:GetTeam()==7 and Players[2]:GetTeam()==0)
 if phase=="init"then
  assert(player:GetNextPolicyCost()>0,"invalid policy-history fixture: nonpositive next cost")
  assert(LekmodScenarioJSON(LekmodScenario.snapshot(player))==LekmodScenarioParameters.expected_state,"native load repair differs from declared marker-only correction")
  check();LekmodScenarioRecord("global-load-repair","PASS","authentic failed "..mode.." checkpoint now has required markers before any test mutation")
  LekmodScenarioRecord("global-load-protected-state","PASS","all recorded owner/team/civilization/city fields and applicable era/policy/choice/coordinates match except the specified corrected markers")
  turn=Game.GetGameTurn();phase="turn";return "turn"
 end
 if Game.GetGameTurn()==turn then return "turn"end
 assert(Game.GetGameTurn()==turn+1);check()
 LekmodScenarioRecord("global-load-next-turn","PASS","one ordinary owner round preserves the data-required marker counts without stacking")
 return true
end
