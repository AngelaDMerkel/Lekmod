-- Supplied units and upkeep gold. Ordinary owner turns must expire bonuses;
-- no promotion, move budget, readiness, turn, position or wait flag is assigned.
LekmodScenario={name="maori-movement",items={"maori-initial-moves-sight","maori-recon-air-controls","maori-first-five-expiry","maori-late-created-bonus","maori-late-next-turn-expiry","maori-AI-owner-expiry"}}
local phase="init"
local probes,late={},{}
local function state(u)
 return {id=u:GetID(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),sight=u:VisibilityRange(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN),embarked=u:IsEmbarked()}
end
function LekmodScenario.snapshot(player)
 local s={turn=Game.GetGameTurn(),owners={}}
 for id=0,2 do local units={};for u in Players[id]:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
  s.owners[id]={civilization=Players[id]:GetCivilizationType(),units=units}
 end
 return s
end
local function create(owner,kind)
 local p=Players[owner];local c=assert(p:GetCapitalCity());local info=assert(GameInfo.Units[kind]);local plot
 if info.Domain=="DOMAIN_AIR" then plot=c:Plot()
 else for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==owner and not q:IsCity() and q:GetNumUnits()==0 and not q:IsWater() and not q:IsMountain() and q:GetArea()==c:Plot():GetArea()then plot=q;break end
 end end
 assert(plot,"no legal unused unit fixture plot")
 local u=assert(p:InitUnit(info.ID,plot:GetX(),plot:GetY()))
 local probe={owner=owner,id=u:GetID(),kind=kind,moves=info.Moves*GameDefines.MOVE_DENOMINATOR,sight=info.BaseSightRange,eligible=(owner<2 and (kind=="UNIT_WARRIOR" or kind=="UNIT_WORKER"))}
 assert(probe.sight and probe.moves>0)
 LekmodScenarioEvent("fixture-setup",{operation="provided-unit",owner=owner,kind=kind,state=state(u)})
 return probe
end
local function check(probe,bonus)
 local u=assert(Players[probe.owner]:GetUnitByID(probe.id),"tracked unit disappeared")
 local s=state(u);assert(not s.embarked,"fixture unit embarked; land movement assertion is no longer isolated")
 local expected=bonus and probe.eligible
 assert(s.maximum==probe.moves+(expected and 2*GameDefines.MOVE_DENOMINATOR or 0),"move limit mismatch for "..probe.owner.."/"..probe.kind)
 assert(s.sight==probe.sight+(expected and 1 or 0),"sight mismatch for "..probe.owner.."/"..probe.kind)
 assert((s.maori or s.civilian)==expected,"promotion state mismatch for "..probe.owner.."/"..probe.kind)
 return s
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 local turn=Game.GetGameTurn();assert(turn<=6,"bounded test exceeded turn six")
 if phase=="init" then
  if not player:GetCapitalCity() or not Players[1]:GetCapitalCity() or not Players[2]:GetCapitalCity()then return "turn" end
  assert(turn<=1,"opening fixture started too late")
  for owner=0,2 do
   Players[owner]:ChangeGold(1000);LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-gold",owner=owner,amount=1000})
   for _,kind in ipairs({"UNIT_WARRIOR","UNIT_WORKER","UNIT_SCOUT"})do probes[#probes+1]=create(owner,kind)end
  end
  probes[#probes+1]=create(0,"UNIT_TRIPLANE")
  for _,p in ipairs(probes)do check(p,true)end
  LekmodScenarioRecord("maori-initial-moves-sight","PASS","supplied-human-and-AI Warrior/Worker native-limit=base+2 sight=base+1 turn="..turn)
  LekmodScenarioRecord("maori-recon-air-controls","PASS","Scout-and-human-air plus-Roman-units no-Maori-bonus=true")
  phase="early";return "turn"
 elseif phase=="early" then
  if turn<5 then for _,p in ipairs(probes)do check(p,true)end;return "turn" end
  assert(turn==5)
  for _,p in ipairs(probes)do if p.owner~=1 then local s=check(p,false);LekmodScenarioEvent("maori-expired-original-unit",{owner=p.owner,state=s});if p.owner==0 and p.eligible then assert(s.moves==p.moves,"eligible unit movement budget after expiry differs")end end end
  LekmodScenarioRecord("maori-first-five-expiry","PASS","human-existing-units bonus-cleared-on-normal-turn-five=true")
  for _,kind in ipairs({"UNIT_WARRIOR","UNIT_WORKER"})do local p=create(0,kind);late[#late+1]=p;check(p,true)end
  LekmodScenarioRecord("maori-late-created-bonus","PASS","created-after-owner-turn-five units-have-two-moves-and-one-sight=true")
  phase="late";return "turn"
 elseif phase=="late" then
  if turn==5 then return "turn" end;assert(turn==6)
  for _,p in ipairs(probes)do check(p,false)end
  for _,p in ipairs(late)do local s=check(p,false);assert(s.moves==p.moves,"ordinary next turn did not refresh the unbonused movement budget")end
  LekmodScenarioEvent("maori-final-state",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("maori-late-next-turn-expiry","PASS","normal-turn-six late bonuses-cleared-and-base-moves-refreshed=true")
  LekmodScenarioRecord("maori-AI-owner-expiry","PASS","original-AI-probes bonus-absent-after-AI-owner-turn-five=true")
  return true
 end
 return false
end
