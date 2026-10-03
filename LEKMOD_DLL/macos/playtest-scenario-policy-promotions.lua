-- Native method surface: GameCore
-- Provided units, upkeep, research, branch/prerequisite flags and choices are
-- fixtures. Target policy adoption and UnitCreated dispatch are native outcomes.
LekmodScenario={name="policy-promotions",items={"policy-promotion-human-existing","policy-promotion-human-new","policy-promotion-AI-existing","policy-promotion-AI-new","policy-promotion-foreign-control","policy-promotion-class-controls","policy-promotion-no-repeat","policy-promotion-choice-accounting"}}
local phase,target,aiPending,aiDone,err="init",1,false,false,nil
local policies={GameInfoTypes.POLICY_VOLUNTEER_ARMY,GameInfoTypes.POLICY_ARSENAL_DEMOCRACY}
local kinds={"UNIT_WARRIOR","UNIT_RIFLEMAN","UNIT_PARATROOPER","UNIT_FIGHTER","UNIT_ARCHER","UNIT_WORKER"}
local morale,dogfight=GameInfoTypes.PROMOTION_MORALE,GameInfoTypes.PROMOTION_DOGFIGHTING_1
local before,after,adopted,spending={},{},{},{}
local function create(p)
 local list={};local c=assert(p:GetCapitalCity())
 for _,kind in ipairs(kinds)do local u=assert(p:InitUnit(GameInfoTypes[kind],c:GetX(),c:GetY()));list[#list+1]=u:GetID()end
 LekmodScenarioEvent("fixture-setup",{operation="provided-promotion-probe-units",owner=p:GetID(),units=list})
 return list
end
local function state(p,list)
 local out={}
 for _,id in ipairs(list)do local u=assert(p:GetUnitByID(id));assert(not u:IsDead()and not u:IsDelayedDeath())
  out[id]={type=u:GetUnitType(),combat=u:GetUnitCombatType(),morale=u:IsHasPromotion(morale),dogfight=u:IsHasPromotion(dogfight),extra=u:GetExtraCombatPercent(),sweep=u:AirSweepCombatMod()}
 end
 return out
end
local function check(p,list,hasFirst,hasSecond)
 for _,r in pairs(state(p,list))do
  local isMorale=r.combat==GameInfoTypes.UNITCOMBAT_MELEE or r.combat==GameInfoTypes.UNITCOMBAT_GUN or r.combat==GameInfoTypes.UNITCOMBAT_PARADROPPER
  local isFighter=r.combat==GameInfoTypes.UNITCOMBAT_FIGHTER
  assert(r.morale==(hasFirst and isMorale)and r.dogfight==(hasSecond and isFighter),"promotion eligibility differs from the four configured rows")
  assert(r.extra==(hasFirst and isMorale and 15 or 0),"Morale combat modifier differs")
  assert(r.sweep==(hasSecond and isFighter and 33 or 0),"Dogfighting sweep modifier differs")
 end
end
local function prerequisites(p,id,seen)
 seen=seen or{};assert(not seen[id]);seen[id]=true
 local row=GameInfo.Policies[id]
 for req in GameInfo.Policy_PrereqPolicies{PolicyType=row.Type}do local q=GameInfoTypes[req.PrereqPolicy];prerequisites(p,q,seen);if not p:HasPolicy(q)then p:SetHasPolicy(q,true)end end
 seen[id]=nil
end
local function prepareChoice(p,id)
 local branch=GameInfoTypes.POLICY_BRANCH_FREEDOM
 assert(not p:HasPolicy(id));p:SetPolicyBranchUnlocked(branch,true,false)
 prerequisites(p,id)
 if GameInfo.Policies[id].Level==2 then
  local count=0
  for row in GameInfo.Policies{PolicyBranchType="POLICY_BRANCH_FREEDOM"}do
   if row.Level==1 and p:HasPolicy(row.ID)then count=count+1 end
  end
  for row in GameInfo.Policies{PolicyBranchType="POLICY_BRANCH_FREEDOM"}do
   if count>=2 then break end
   if row.Level==1 and row.ID~=policies[1] and not p:HasPolicy(row.ID)then p:SetHasPolicy(row.ID,true);count=count+1 end
  end
 end
 spending[p:GetID()]=LekmodScenarioPolicyChoice(p,id)
 LekmodScenarioEvent("fixture-setup",{operation="provided-policy-choice-and-prerequisites",owner=p:GetID(),policy=id,free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),culture=p:GetJONSCulture(),next_cost=p:GetNextPolicyCost()})
end
local function adoptedResult(p,id)
 local r=spending[p:GetID()]
 assert(adopted[p:GetID()..":"..id],"native adoption event missing");LekmodScenarioVerifyPolicyChoice(p,id,r)
 assert(not p:CanAdoptPolicy(id),"already owned policy still adoptable")
end
GameEvents.PlayerAdoptPolicy.Add(function(owner,id)adopted[owner..":"..id]=true end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or not aiPending then return end;aiPending=false
 local ok,e=pcall(function()
  local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman());check(p,before[1],false,false)
  for _,id in ipairs(policies)do prepareChoice(p,id);p:DoAdoptPolicy(id);adoptedResult(p,id)end
  check(p,before[1],true,true);after[1]=create(p);check(p,after[1],true,true);aiDone=true
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner];local units={}
  for u in p:Units()do units[u:GetID()]={type=u:GetUnitType(),morale=u:IsHasPromotion(morale),dogfight=u:IsHasPromotion(dogfight),extra=u:GetExtraCombatPercent(),sweep=u:AirSweepCombatMod()}end
  owners[owner]={units=units,first=p:HasPolicy(policies[1]),second=p:HasPolicy(policies[2]),free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),culture=p:GetJONSCulture(),next_cost=p:GetNextPolicyCost()}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not err,err);assert(p:GetID()==0 and p:IsHuman()and not Players[1]:IsHuman())
 if phase=="init"then
  if not p:GetCapitalCity()or not Players[1]:GetCapitalCity()then return "turn"end
  local count=0;for row in GameInfo.Policy_FreePromotionUnitCombats()do count=count+1 end;assert(count==4)
  assert(GameInfo.UnitPromotions[morale].CombatPercent==15 and GameInfo.UnitPromotions[dogfight].AirSweepCombatModifier==33)
  for owner=0,1 do local q=Players[owner]
   assert(not q:HasPolicy(policies[1])and not q:HasPolicy(policies[2]));q:ChangeGold(10000);LekmodScenarioGrantTech(q,"TECH_RADIO")
   before[owner]=create(q);check(q,before[owner],false,false)
  end
  prepareChoice(p,policies[target]);Network.SendUpdatePolicies(policies[target],true,true);phase="human"
 elseif phase=="human"then
  if not LekmodScenarioAwait("promotion-policy-"..target,p:HasPolicy(policies[target]))then return false end
  adoptedResult(p,policies[target]);check(p,before[0],true,target==2);check(Players[1],before[1],false,false)
  if target==1 then target=2;prepareChoice(p,policies[2]);Network.SendUpdatePolicies(policies[2],true,true);return false end
  LekmodScenarioRecord("policy-promotion-human-existing","PASS","both legal adoptions update all four eligible combat classes; native modifiers15/33")
  LekmodScenarioRecord("policy-promotion-foreign-control","PASS","other owner probes stay unpromoted through both human adoptions")
  after[0]=create(p);check(p,after[0],true,true)
  LekmodScenarioRecord("policy-promotion-human-new","PASS","actual UnitCreated gives the four configured class promotions")
  aiPending=true;phase="AI";return "turn"
 elseif phase=="AI"then
  if not aiDone then return "turn"end
  check(p,before[0],true,true);check(p,after[0],true,true)
  LekmodScenarioRecord("policy-promotion-AI-existing","PASS","actual AI owner-turn adoptions grant the four existing-unit awards")
  LekmodScenarioRecord("policy-promotion-AI-new","PASS","new AI units receive expected flags and native modifiers")
  LekmodScenarioRecord("policy-promotion-class-controls","PASS","Archer and Worker excluded for both owners before/after adoption and creation")
  LekmodScenarioRecord("policy-promotion-no-repeat","PASS","later adoption/creation refresh leaves each existing modifier at15 or33; duplicate policy ineligible")
  LekmodScenarioRecord("policy-promotion-choice-accounting","PASS","each target adoption emitted native event and consumed one available choice with native lifetime accounting preserved")
  return true
 end
 return false
end
