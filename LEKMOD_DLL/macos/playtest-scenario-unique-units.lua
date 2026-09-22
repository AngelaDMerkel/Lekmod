-- Broad native instantiation coverage for every unique unit referenced by a
-- playable civilization. Units are explicitly supplied to the current human;
-- this is foreign-owner/gift-style creation coverage, not each civilization's UA,
-- earned production, unit mission, animation or complete artwork certification.
LekmodScenario={name="unique-units",items={"unique-unit-catalogue","unique-unit-native-creation","unique-unit-created-events"}}
local phase,list,index,pending,created="init",{},1,nil,{}
local marker="LekmodMacUniqueUnitCatalogue"
GameEvents.UnitCreated.Add(function(owner,id)if owner==Game.GetActivePlayer()then created[id]=true end end)
local function state(u)
 local promotions={};for p in GameInfo.UnitPromotions()do if u:IsHasPromotion(p.ID)then promotions[p.ID]=true end end
 return {type=u:GetUnitType(),owner=u:GetOwner(),domain=u:GetDomainType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),base_combat=u:GetBaseCombatStrength(),promotions=promotions,script=u:GetScriptData()}
end
function LekmodScenario.snapshot(player)
 local units={};for u in player:Units()do if u:GetScriptData()==marker then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),civilization=player:GetCivilizationType(),units=units}
end
local function plotFor(player,info)
 if info.Domain=="DOMAIN_AIR"then return assert(player:GetCapitalCity()):Plot()end
 assert(info.Domain=="DOMAIN_LAND"or info.Domain=="DOMAIN_HOVER"or info.Domain=="DOMAIN_SEA","unreviewed unit domain: "..tostring(info.Domain))
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetNumUnits()==0 and not p:IsCity()and not p:IsMountain()and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and(p:GetOwner()==-1 or p:GetOwner()==player:GetID())then
   if(info.Domain=="DOMAIN_SEA"and p:IsWater()and not p:IsLake())or((info.Domain=="DOMAIN_LAND"or info.Domain=="DOMAIN_HOVER")and not p:IsWater())then return p end
  end
 end
 error("no domain-compatible empty staging plot for "..info.Type)
end
function LekmodScenario.step(player)
 if phase=="init"then
  local civilizations,types={},{}
  for civ in GameInfo.Civilizations()do if civ.Playable then civilizations[civ.Type]=true end end
  local civCount=0;for _ in pairs(civilizations)do civCount=civCount+1 end
  assert(civCount==114,"review playable civilization inventory change")
  for row in GameInfo.Civilization_UnitClassOverrides()do
   if civilizations[row.CivilizationType]and row.UnitType then
    local info=assert(GameInfo.Units[row.UnitType],"override references missing unit: "..row.UnitType)
    local class=assert(GameInfo.UnitClasses[row.UnitClassType]);assert(info.Class==class.Type,"unit override/class mismatch")
    if row.UnitType~=class.DefaultUnit then types[row.UnitType]=true end
   end
  end
  for kind in pairs(types)do list[#list+1]=kind end;table.sort(list);assert(#list==125,"review changed unique-unit catalogue before claiming complete creation coverage")
  -- Exercise the confirmed missing-flag regression first, then the rest.
  for i,kind in ipairs(list)do if kind=="UNIT_TUNISIA_PRIVATEER"then table.remove(list,i);table.insert(list,1,kind);break end end
  LekmodScenarioEvent("unique-unit-catalogue",{playable_civilizations=civCount,unique_unit_types=list,owner=player:GetID(),owner_civilization=player:GetCivilizationType()})
  LekmodScenarioRecord("unique-unit-catalogue","PASS","native database covers 114 playable civilizations; unique definitions="..#list)
  phase="create"
 elseif phase=="create"then
  local info=assert(GameInfo.Units[list[index]]);local p=plotFor(player,info)
  local u=assert(player:InitUnit(info.ID,p:GetX(),p:GetY()),"native creation returned nil: "..info.Type)
  assert(u:GetUnitType()==info.ID and u:GetOwner()==player:GetID(),"native unit identity/owner mismatch")
  -- CvUnit::getDomainType resolves HOVER to LAND/SEA at the current plot.
  local expectedDomain=GameInfoTypes[info.Domain]
  if info.Domain=="DOMAIN_HOVER"then expectedDomain=u:GetPlot():IsWater()and DomainTypes.DOMAIN_SEA or DomainTypes.DOMAIN_LAND end
  assert(u:GetDomainType()==expectedDomain,"native resolved domain mismatch: "..info.Type)
  assert(not u:IsDead()and not u:IsDelayedDeath()and u:GetDamage()==0,"new supplied unit is not alive/full health")
  u:SetScriptData(marker)
  LekmodScenarioEvent("fixture-setup",{operation="provided-unique-unit",kind=info.Type,id=u:GetID(),state=state(u)})
  pending=u:GetID();phase="observe"
 elseif phase=="observe"then
  local u=assert(player:GetUnitByID(pending),"created unit disappeared")
  assert(created[pending],"real UnitCreated event missing for "..list[index])
  assert(u:GetUnitType()==GameInfo.Units[list[index]].ID and u:GetScriptData()==marker,"unit changed identity after ordinary updates")
  LekmodScenarioRecord("unique-unit-created-"..list[index],"PASS","native creation, identity and UnitCreated event verified")
  index=index+1
  if index>#list then
   local n=0;for x in player:Units()do if x:GetScriptData()==marker then n=n+1 end end
   assert(n==#list,"created catalogue count differs")
   LekmodScenarioRecord("unique-unit-native-creation","PASS","all "..n.." supplied unique unit types remain alive with correct IDs/owners/domains")
   LekmodScenarioRecord("unique-unit-created-events","PASS","real UnitCreated observed for every supplied unique type")
   return true
  end
  phase="create"
 end
 return false
end
