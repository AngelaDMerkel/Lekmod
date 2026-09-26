-- Native method surface: GameCore
-- Continue the saved, naturally resolved Freedom-to-Order revolution fixture.
-- Only the opponent's next ideology is supplied. Existing concert influence,
-- ordinary rounds and original UI callbacks drive two further human switches.
LekmodScenario={name="yugoslav-revolution-cycle",items={"revolution-cancel","revolution-content-rejection","yugo-Autocracy-pressure","yugo-Autocracy-tenet","yugo-Autocracy-markers","yugo-Autocracy-expiry","yugo-Freedom-pressure","yugo-Freedom-tenet","yugo-Freedom-markers","yugo-Freedom-expiry"}}
local targets={{name="Autocracy",branch=GameInfoTypes.POLICY_BRANCH_AUTOCRACY},{name="Freedom",branch=GameInfoTypes.POLICY_BRANCH_FREEDOM}}
local phase,cursor,started,oldBranch,expected,culture,reply,switchTurn="init",1
LuaEvents.LekmodRevolutionFinished.Add(function()reply=true end)
local function markers(p)
 local result={}
 for c in p:Cities()do result[c:GetID()]={capital=c:IsCapital(),freedom=c:GetNumRealBuilding(GameInfoTypes.BUILDING_YUGO_FREEDOM),order=c:GetNumRealBuilding(GameInfoTypes.BUILDING_YUGO_ORDER),autocracy=c:GetNumRealBuilding(GameInfoTypes.BUILDING_YUGO_AUTOCRACY)}end
 return result
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner];local policies={}
  for row in GameInfo.Policies()do if p:HasPolicy(row.ID)then policies[row.ID]=true end end
  owners[owner]={civilization=p:GetCivilizationType(),ideology=p:GetLateGamePolicyTree(),policies=policies,free=p:GetNumFreeTenets(),free_policies=p:GetNumFreePolicies(),culture=p:GetJONSCulture(),lifetime_culture=p:GetJONSCultureEverGenerated(),anarchy=p:GetAnarchyNumTurns(),unhappiness=p:GetPublicOpinionUnhappiness(),preferred=p:GetPublicOpinionPreferredIdeology(),influence_other=p:GetInfluenceOn(1-owner),markers=markers(p)}
 end
 return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),owners=owners}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_YUGOSLAVIA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN and Game.GetWinner()==-1)
 local t=targets[cursor]
 if phase=="init"then
  assert(not player:IsAnarchy()and player:GetPublicOpinionUnhappiness()==0)
  if cursor==1 then assert(player:GetLateGamePolicyTree()==GameInfoTypes.POLICY_BRANCH_ORDER)end
  local foreign=Players[1];local previous=foreign:GetLateGamePolicyTree();assert(previous~=-1 and previous~=t.branch and player:GetLateGamePolicyTree()~=t.branch)
  local cleared={}
  for row in GameInfo.Policies()do if row.PolicyBranchType==GameInfo.PolicyBranchTypes[previous].Type and foreign:HasPolicy(row.ID)then foreign:SetHasPolicy(row.ID,false);cleared[#cleared+1]=row.ID end end
  foreign:SetPolicyBranchUnlocked(previous,false,false);foreign:SetPolicyBranchUnlocked(t.branch,true,false)
  assert(foreign:GetLateGamePolicyTree()==t.branch and foreign:GetInfluenceOn(0)<player:GetJONSCultureEverGenerated())
  LekmodScenarioEvent("fixture-setup",{operation="provided-next-opponent-ideology",owner=1,previous=previous,next=t.branch,cleared_tenets=cleared,influence=foreign:GetInfluenceOn(0),human_lifetime=player:GetJONSCultureEverGenerated()})
  started=Game.GetGameTurn();phase="pressure";return "turn"
 elseif phase=="pressure"then
  if player:GetPublicOpinionUnhappiness()==0 then assert(Game.GetGameTurn()-started<4,"existing concert influence did not create new pressure");return "turn"end
  assert(player:GetPublicOpinionPreferredIdeology()==t.branch and not player:IsAnarchy())
  LekmodScenarioRecord("yugo-"..t.name.."-pressure","PASS","ordinary rounds apply existing foreign influence to the supplied opposing ideology")
  oldBranch=player:GetLateGamePolicyTree();culture=player:GetJONSCulture()
  expected=player:GetNumFreeTenets()+Game.GetNumFreePolicies(t.branch)+math.max(0,player:GetNumPoliciesInBranch(oldBranch)-GameDefines.SWITCH_POLICY_BRANCHES_TENETS_LOST)+1
  LekmodScenarioEvent("cycle-before-revolution",{target=t.name,expected_free=expected,state=LekmodScenario.snapshot(player)})
  reply=false;LuaEvents.LekmodTestRevolution();phase="switched"
 elseif phase=="switched"then
  if not reply then return false end
  assert(player:GetLateGamePolicyTree()==t.branch and not player:IsPolicyBranchUnlocked(oldBranch)and player:GetNumFreeTenets()==expected and player:GetJONSCulture()==culture)
  assert(player:GetAnarchyNumTurns()==GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS)
  LekmodScenarioRecord("yugo-"..t.name.."-tenet","PASS","normal revolution grants standard accounting plus exactly one Yugoslav tenet while retaining anarchy and culture")
  local actual=markers(player)
  for _,m in pairs(actual)do
   if t.name=="Autocracy"then assert(m.autocracy==0 and m.order==1 and m.freedom==(m.capital and 1 or 0))
   else assert(m.freedom==0 and m.order==1 and m.autocracy==1)end
  end
  LekmodScenarioRecord("yugo-"..t.name.."-markers","PASS","native branch transition replaces the rival-ideology effect buildings")
  LekmodScenarioEvent("cycle-after-revolution",{target=t.name,state=LekmodScenario.snapshot(player)})
  switchTurn=Game.GetGameTurn();phase="expiry";return "turn"
 elseif phase=="expiry"then
  if player:IsAnarchy()then assert(Game.GetGameTurn()-switchTurn<=GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS+1);return "turn"end
  assert(Game.GetGameTurn()>switchTurn and player:GetLateGamePolicyTree()==t.branch and player:GetPublicOpinionUnhappiness()==0)
  LekmodScenarioRecord("yugo-"..t.name.."-expiry","PASS","ordinary turns end the required anarchy and preserve the selected ideology")
  if cursor==#targets then return true end
  cursor=cursor+1;phase="init"
 end
 return false
end
