-- Native method surface: GameCore
-- Natural resource plots, legal coastal cities, fishing improvements and naval
-- probes are fixture inputs. Actual pillage must destroy each enemy improvement
-- and emit the native event; no XP, movement, damage or ownership is assigned.
LekmodScenario={name="uae-improvement-pillage",items={"uae-pillage-peace-rejection","uae-pillage-own-rejection","uae-native-improvement-pillage","uae-pillage-xp","uae-pillage-movement","uae-pillage-ordinary-unit","uae-pillage-repeat-rejection","uae-pillage-save-state"}}
local phase,ordinal="init",1
local probes,plots,observed,before={}, {},{},nil
local prefix="LEKMOD_UAE_PILLAGE:"
local boat=GameInfoTypes.IMPROVEMENT_FISHING_BOATS
local allowed={};for row in GameInfo.Improvement_ResourceTypes{ImprovementType="IMPROVEMENT_FISHING_BOATS"}do allowed[GameInfoTypes[row.ResourceType]]=true end
local function suitable(q)
 return q:IsWater()and not q:IsLake()and q:GetTerrainType()==TerrainTypes.TERRAIN_COAST and q:GetFeatureType()==-1 and q:GetNumUnits()==0 and q:GetRouteType()==-1 and allowed[q:GetResourceType(-1)]and(q:GetImprovementType()==-1 or(q:GetImprovementType()==boat and not q:IsImprovementPillaged()))
end
local function site(owner,used)
 local p=Players[owner]
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if not used[i]and q:GetOwner()==owner and suitable(q)then return q end
 end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if not used[i]and q:GetOwner()==-1 and suitable(q)then
   for d=0,5 do local land=Map.PlotDirection(q:GetX(),q:GetY(),d)
    if land and land:GetOwner()==-1 and land:GetNumUnits()==0 and p:CanFound(land:GetX(),land:GetY())then
     p:Found(land:GetX(),land:GetY());assert(q:GetOwner()==owner)
     LekmodScenarioEvent("fixture-setup",{operation="provided-legal-coastal-city",owner=owner,city=land:GetPlotCity():GetID(),resource_plot=i});return q
    end
   end
  end
 end
 error("no natural legal fishing resource plot for owner"..owner)
end
local function create(p,role,kind,q)
 local u=assert(p:InitUnit(GameInfoTypes[kind],q:GetX(),q:GetY()));assert(u:GetX()==q:GetX()and u:GetY()==q:GetY());u:SetScriptData(prefix..role);probes[role]=u:GetID();plots[role]=q
 LekmodScenarioEvent("fixture-setup",{operation="provided-pillage-probe",role=role,type=kind,unit=u:GetID(),plot=q:GetPlotIndex(),owner=q:GetOwner()})
end
local function cost(u)
 for info in GameInfo.UnitPromotions()do if(info.FreePillageMoves==true or info.FreePillageMoves==1)and u:IsHasPromotion(info.ID)then return 0 end end
 return GameDefines.MOVE_DENOMINATOR
end
local function action(u)
 UI.SelectUnit(u)
 for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type=="MISSION_PILLAGE"then assert(Game.CanHandleAction(id),"normal pillage action unavailable");Game.HandleAction(id);return end end
 error("pillage action absent")
end
LuaEvents.LekmodUaePillageObserved.Add(function(owner,id,x,y,xpBefore,xpAfter,movesBefore,movesAfter,goldBefore,goldAfter)
 if owner==0 then assert(not observed[id],"unexpected repeated pillage callback");observed[id]={x=x,y=y,xp_before=xpBefore,xp_after=xpAfter,moves_before=movesBefore,moves_after=movesAfter,gold_before=goldBefore,gold_after=goldAfter};LekmodScenarioEvent("native-UAE-pillage-reward",observed[id])end
end)
function LekmodScenario.snapshot(p)
 local units={}
 for u in p:Units()do if string.sub(u:GetScriptData(),1,#prefix)==prefix then local q=u:GetPlot()
  units[u:GetID()]={tag=u:GetScriptData(),type=u:GetUnitType(),xp=u:GetExperience(),moves=u:GetMoves(),x=u:GetX(),y=u:GetY(),owner=q:GetOwner(),resource=q:GetResourceType(-1),improvement=q:GetImprovementType(),pillaged=q:IsImprovementPillaged(),can_pillage=u:CanPillage(q)}
 end end
 return {turn=Game.GetGameTurn(),gold=p:GetGold(),war=Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()),units=units}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_UAE)
 if phase=="init"then
  assert(not Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()));p:ChangeGold(10000)
  local info=GameInfo.Improvements[boat];assert(info.DestroyedWhenPillaged==true or info.DestroyedWhenPillaged==1)
  local used={}
  for _,r in ipairs({{"raider",1,"UNIT_QASIMI_RAIDER"},{"ordinary",1,"UNIT_TRIREME"},{"own",0,"UNIT_QASIMI_RAIDER"}})do
   local q=site(r[2],used);used[q:GetPlotIndex()]=true;q:SetImprovementType(boat);assert(q:GetImprovementType()==boat and not q:IsImprovementPillaged());create(p,r[1],r[3],q)
   LekmodScenarioEvent("fixture-setup",{operation="provided-unpillaged-fishing-improvement",plot=q:GetPlotIndex(),resource=q:GetResourceType(-1)})
  end
  for _,role in ipairs({"raider","ordinary"})do local u=assert(p:GetUnitByID(probes[role]));assert(u:GetMoves()>0 and not u:CanPillage(plots[role]))end
  LekmodScenarioRecord("uae-pillage-peace-rejection","PASS","both naval probes reject pillaging foreign improvements while at peace")
  assert(not p:GetUnitByID(probes.own):CanPillage(plots.own));LekmodScenarioRecord("uae-pillage-own-rejection","PASS","matching Qasimi probe rejects its own intact fishing improvement")
  local other=Players[1]:GetTeam();Teams[p:GetTeam()]:Meet(other,true);assert(Teams[p:GetTeam()]:CanDeclareWar(other));Network.SendChangeWar(other,true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("UAE-pillage-war",Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()))then return false end
  -- Declaring war expels units staged in foreign territory during peace.
  -- Retain those negative controls and supply fresh probes after the declaration.
  for _,r in ipairs({{"raider","UNIT_QASIMI_RAIDER"},{"ordinary","UNIT_TRIREME"}})do
   local u=assert(p:GetUnitByID(probes[r[1]]));local q=plots[r[1]]
   if u:GetX()~=q:GetX()or u:GetY()~=q:GetY()then
    LekmodScenarioEvent("native-war-displacement",{role=r[1],unit=u:GetID(),x=u:GetX(),y=u:GetY(),target_x=q:GetX(),target_y=q:GetY()})
    u:SetScriptData(prefix.."peace-"..r[1]);assert(q:GetNumUnits()==0);create(p,r[1],r[2],q)
   end
  end
  phase="order"
 elseif phase=="order"then
  local role=ordinal==1 and"raider"or"ordinary";local u=assert(p:GetUnitByID(probes[role]));assert(u:GetX()==plots[role]:GetX()and u:GetY()==plots[role]:GetY(),"pillage probe displaced from fixture target");assert(u:CanPillage(plots[role])and u:GetMoves()>=cost(u))
  before={role=role,id=u:GetID(),moves=u:GetMoves(),xp=u:GetExperience(),cost=cost(u)};action(u);phase="result"
 elseif phase=="result"then
  local u=assert(p:GetUnitByID(before.id));local q=plots[before.role];local e=observed[before.id]
  if not LekmodScenarioAwait("UAE-fishing-pillage-"..before.role,e and q:GetImprovementType()==-1)then return false end
  assert(e.x==q:GetX()and e.y==q:GetY()and not u:CanPillage(q))
  local xp=ordinal==1 and 15 or 0;local moves=ordinal==1 and 2*GameDefines.MOVE_DENOMINATOR or 0
  assert(e.xp_after-e.xp_before==xp and e.moves_after-e.moves_before==moves and e.gold_after==e.gold_before,"isolated Lua pillage reward differs")
  assert(e.moves_before==before.moves-before.cost and u:GetMoves()==before.moves-before.cost+moves,"native cost and Lua movement reward do not compose")
  assert(u:GetExperience()==e.xp_after)
  if ordinal==1 then
   LekmodScenarioRecord("uae-pillage-xp","PASS","actual UnitPillaged callback adds exactly15 XP to Qasimi")
   LekmodScenarioRecord("uae-pillage-movement","PASS","normal mission cost plus exactly120 movement-point reward, including allowed overfill")
   ordinal=2;phase="order"
  else
   LekmodScenarioRecord("uae-pillage-ordinary-unit","PASS","same normal mission destroys the other enemy improvement but ordinary Trireme gets zero UAE XP/movement reward")
   assert(plots.raider:GetImprovementType()==-1 and plots.ordinary:GetImprovementType()==-1 and plots.own:GetImprovementType()==boat)
   assert(not p:GetUnitByID(probes.raider):CanPillage(plots.raider)and not p:GetUnitByID(probes.own):CanPillage(plots.own))
   LekmodScenarioRecord("uae-native-improvement-pillage","PASS","two actual pillage missions destroyed the enemy fishing improvements; own improvement remains intact")
   LekmodScenarioRecord("uae-pillage-repeat-rejection","PASS","destroyed targets and own improvement reject another pillage")
   LekmodScenarioRecord("uae-pillage-save-state","PASS","real improvement/unit/reward/war state retained for exact replay");return true
  end
 end
 return false
end
