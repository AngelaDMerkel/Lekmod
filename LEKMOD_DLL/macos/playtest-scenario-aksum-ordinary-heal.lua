-- Native method surface: GameCore
-- Churches, plot ownership, units, wounds and funds are explicit fixture inputs.
-- Ordinary Heal/Move missions and owner turns are the only healing stimuli.
LekmodScenario={name="aksum-ordinary-heal",items={"church-ordinary-inputs","church-ordinary-on-adjacent","church-ordinary-foreign-owner","church-ordinary-distance-sea-healthy","church-ordinary-range-exit","church-ordinary-outside-heal"}}
local church=GameInfoTypes.IMPROVEMENT_AKSUM
local phase,site,adjacent,sea,far,exitStep,outside,foreignSite,foreignAdjacent="init"
local probes,records={},{}
local firstTurn,onID,healthyID,outsideEvents,outsideDamage,restTurn
local function clear(q,water)
 if not q or q:IsCity()or q:IsMountain()or q:GetFeatureType()~=-1 or q:GetImprovementType()~=-1 or q:GetResourceType(-1)~=-1 or q:GetNumUnits()~=0 or q:GetOwner()~=-1 or q:IsWater()~=water then return false end
 if not water and q:IsImpassable()then return false end
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
  if p and p:IsAlive()then
   for c in p:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<5 then return false end end
   for u in p:Units()do if Map.PlotDistance(q:GetX(),q:GetY(),u:GetX(),u:GetY())<3 then return false end end
  end
 end
 return true
end
local function same(a,b)return a and b and a:GetPlotIndex()==b:GetPlotIndex()end
local function action(u,kind)
 UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type==kind then assert(Game.CanHandleAction(i),"action unavailable "..kind);Game.HandleAction(i);return end end;error("missing action "..kind)
end
LuaEvents.LekmodAksumHealObserved.Add(function(owner,id,change,x,y,before,after)
 if owner~=0 or not probes[id]then return end
 local probe=probes[id];assert(change<0)
 local wanted=probe.award
 if id==onID and outside and x==outside:GetX()and y==outside:GetY()then wanted=0 end
 assert(after-before==wanted,"faith award differs for "..probe.name..": "..(after-before).." expected "..wanted)
 local r=records[id];r.count=r.count+1;r.delta=r.delta+change
 LekmodScenarioEvent("ordinary-heal-observed",{unit=id,name=probe.name,change=change,faith_before=before,faith_after=after,x=x,y=y})
end)
function LekmodScenario.snapshot(p)
 local units,plots={},{}
 for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves()}end end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:GetImprovementType()==church then plots[i]={owner=q:GetOwner(),pillaged=q:IsImprovementPillaged()}end end
 return {turn=Game.GetGameTurn(),faith=p:GetFaith(),units=units,churches=plots}
end
local function create(p,name,kind,q,award,damage)
 local u=assert(p:InitUnit(GameInfoTypes[kind],q:GetX(),q:GetY()));u:SetDamage(damage)
 local id=u:GetID();probes[id]={name=name,award=award,damage=damage};records[id]={count=0,delta=0}
 assert(u:GetX()==q:GetX()and u:GetY()==q:GetY())
 LekmodScenarioEvent("fixture-setup",{operation="provided-unit-and-wounds",unit=id,name=name,kind=kind,damage=damage,x=q:GetX(),y=q:GetY()})
 return u
end
function LekmodScenario.step(p)
 if phase=="init"then
  assert(Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_AKSUM and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION))
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if clear(q,false)and q:IsHills()then
    local lands,water={},nil
    for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d)
     if clear(n,false)and not n:IsHills()then lands[#lands+1]=n elseif clear(n,true)and n:GetTerrainType()==GameInfoTypes.TERRAIN_COAST then water=n end
    end
    if #lands>=2 and water then
     local opts={};for j=0,Map.GetNumPlots()-1 do local n=Map.GetPlotByIndex(j)
      if clear(n,false)and not n:IsHills()and Map.PlotDistance(q:GetX(),q:GetY(),n:GetX(),n:GetY())==2 then opts[#opts+1]=n end
     end
     if #opts>=2 then
      for _,n in ipairs(opts)do if Map.PlotDistance(lands[2]:GetX(),lands[2]:GetY(),n:GetX(),n:GetY())==1 then
       site,adjacent,exitStep,sea,outside=q,lands[1],lands[2],water,n
       for _,f in ipairs(opts)do if not same(f,n)then far=f;break end end
       break
      end end
     end
    end
   end
   if site then break end
  end
  assert(site and far and outside,"no isolated Church layout")
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if clear(q,false)and q:IsHills()and Map.PlotDistance(q:GetX(),q:GetY(),site:GetX(),site:GetY())>=7 then
    for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d)
     if clear(n,false)then foreignSite,foreignAdjacent=q,n;break end
    end
   end
   if foreignSite then break end
  end
  assert(foreignSite)
  for _,q in ipairs({site,adjacent,sea,far,exitStep,outside,foreignAdjacent})do q:SetOwner(0,-1,true,true)end
  foreignSite:SetOwner(1,-1,true,true);site:SetImprovementType(church);foreignSite:SetImprovementType(church)
  p:ChangeGold(3000);LekmodScenarioEvent("fixture-setup",{operation="provided-two-Churches-ownership-and-upkeep",own=site:GetPlotIndex(),foreign=foreignSite:GetPlotIndex(),gold_added=3000})
  local on=create(p,"on-own-Church","UNIT_WARRIOR",site,2,60);onID=on:GetID()
  local a=create(p,"adjacent-own-Church","UNIT_WARRIOR",adjacent,2,60)
  local d=create(p,"distance-two","UNIT_WARRIOR",far,0,60)
  local f=create(p,"adjacent-foreign-Church","UNIT_WARRIOR",foreignAdjacent,2,60)
  local ship=create(p,"sea-near-Church","UNIT_TRIREME",sea,0,60)
  local healthy=create(p,"healthy-on-Church","UNIT_WORKER",site,0,0);healthyID=healthy:GetID()
  assert(not healthy:CanHeal(site)and not d:IsNearImprovementType(church,1,false))
  for _,u in ipairs({on,a,f,ship})do assert(u:IsNearImprovementType(church,1,false))end
  for _,u in ipairs({on,a,d,f,ship})do assert(u:CanHeal(u:GetPlot()));action(u,"MISSION_HEAL")end
  firstTurn=Game.GetGameTurn();phase="healed"
  LekmodScenarioRecord("church-ordinary-inputs","PASS","five damaged eligible healers and healthy control; distance2, sea and foreign-Church ownership explicitly isolated")
  return "turn"
 elseif phase=="healed"then
  if Game.GetGameTurn()==firstTurn then return "turn"end
  assert(Game.GetGameTurn()==firstTurn+1)
  for id,probe in pairs(probes)do local u=assert(p:GetUnitByID(id));local r=records[id]
   if id==healthyID then assert(r.count==0 and u:GetDamage()==0)
   else assert(r.count==1 and r.delta<0 and u:GetDamage()==math.max(0,probe.damage+r.delta))end
  end
  LekmodScenarioRecord("church-ordinary-on-adjacent","PASS","ordinary heal events restore actual HP and award exactly2 faith on/adjacent to own Church")
  LekmodScenarioRecord("church-ordinary-foreign-owner","PASS","ordinary land healing next to another owner's Church awards exactly2 faith")
  LekmodScenarioRecord("church-ordinary-distance-sea-healthy","PASS","actual sea/distance2 healing awards0; healthy unit emits no heal and gets no award")
  local u=assert(p:GetUnitByID(onID));assert(u:GetMoves()>0 and u:CanMoveOrAttackInto(outside));UI.SelectUnit(u)
  Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,outside:GetX(),outside:GetY(),0,false,false)
  phase="moved";return false
 elseif phase=="moved"then
  local u=assert(p:GetUnitByID(onID));if not LekmodScenarioAwait("Church-range-exit",u:GetX()==outside:GetX()and u:GetY()==outside:GetY())then return false end
  assert(not u:IsNearImprovementType(church,1,false));outsideEvents=records[onID].count;outsideDamage=u:GetDamage();restTurn=Game.GetGameTurn()
  LekmodScenarioRecord("church-ordinary-range-exit","PASS","normal movement left radius1; final distance2 and no nearby Church")
  phase="rest-ready";return "turn"
 elseif phase=="rest-ready"then
  if Game.GetGameTurn()==restTurn then return "turn"end
  local u=assert(p:GetUnitByID(onID));assert(u:GetDamage()==outsideDamage and records[onID].count==outsideEvents,"moving unit healed during its travel round")
  assert(u:CanHeal(u:GetPlot()));action(u,"MISSION_HEAL");restTurn=Game.GetGameTurn();phase="outside-heal";return "turn"
 elseif phase=="outside-heal"then
  if Game.GetGameTurn()==restTurn then return "turn"end
  local u=assert(p:GetUnitByID(onID));assert(records[onID].count==outsideEvents+1 and u:GetDamage()<outsideDamage and not u:IsNearImprovementType(church,1,false))
  LekmodScenarioRecord("church-ordinary-outside-heal","PASS","later ordinary healing restores HP outside range with zero faith award; observer never supplies a healing delta")
  return true
 end
 return false
end
