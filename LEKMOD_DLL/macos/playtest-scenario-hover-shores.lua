-- Native method surface: GameCore
-- Research/resources/upkeep and units on legal natural shore pairs are supplied.
-- Normal moves and Skip/owner-turn processing determine position, domain, moves
-- and embark state; no target promotion, domain or movement value is assigned.
LekmodScenario={name="hover-shores",items={"hover-native-birth","hover-shore-entry","hover-land-return","hover-ordinary-turn","hover-embark-control","hover-movement-debit"}}
local kinds={"UNIT_HELICOPTER_GUNSHIP","UNIT_CARDOEN","UNIT_AIRSHIP","UNIT_WARRIOR"}
local phase,records,cursor,turn="init",{},1,nil
local prefix="LEKMOD_HOVER_SHORE:"
local hover=GameInfoTypes.PROMOTION_MOVE_ALL_TERRAIN
local embark=GameInfoTypes.PROMOTION_EMBARKATION
local function safe(q,p)
 if not q or q:GetNumUnits()~=0 or q:IsCity()or q:IsMountain()or(q:GetOwner()~=-1 and q:GetOwner()~=p:GetID())then return false end
 for i=0,Map.GetNumPlots()-1 do local t=Map.GetPlotByIndex(i)
  if Map.PlotDistance(q:GetX(),q:GetY(),t:GetX(),t:GetY())<=3 then
   if t:GetImprovementType()==GameInfoTypes.IMPROVEMENT_BARBARIAN_CAMP then return false end
   for n=0,t:GetNumUnits()-1 do local u=t:GetUnit(n);if u:GetOwner()~=p:GetID()and Teams[p:GetTeam()]:IsAtWar(Players[u:GetOwner()]:GetTeam())then return false end end
  end
 end
 return true
end
local function state(u)
 return {type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),domain=u:GetDomainType(),embarked=u:IsEmbarked(),hover=u:IsHasPromotion(hover),embark_promotion=u:IsHasPromotion(embark),tag=u:GetScriptData()}
end
function LekmodScenario.snapshot(p)
 local units={};for u in p:Units()do if string.sub(u:GetScriptData(),1,#prefix)==prefix then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),units=units}
end
local function order(p,r,plot)
 local u=assert(p:GetUnitByID(r.id));assert(not u:IsBusy()and u:GetMoves()>0,r.kind..": no available movement")
 local mission=MissionTypes.MISSION_MOVE_TO
 if r.kind=="UNIT_WARRIOR"then
  -- Ordinary land movement eligibility does not include a future embark state.
  -- Use the same native transition query and mission as the embark controls.
  if plot:IsWater()then
   assert(u:CanEmbarkOnto(u:GetPlot(),plot),"Warrior: native embark rejected shore")
   mission=MissionTypes.MISSION_EMBARK
  else
   assert(u:CanDisembarkOnto(plot),"Warrior: native disembark rejected shore")
   mission=MissionTypes.MISSION_DISEMBARK
  end
 else
  assert(u:CanMoveOrAttackInto(plot),r.kind..": native hover move rejected shore")
  if plot:IsWater()then assert(not u:CanEmbarkOnto(u:GetPlot(),plot),r.kind..": hover unexpectedly permits embark")end
 end
 r.before=u:GetMoves();UI.SelectUnit(u)
 LekmodScenarioEvent("native-shore-order",{kind=r.kind,mission=mission,origin=u:GetPlot():GetPlotIndex(),destination=plot:GetPlotIndex(),moves=r.before})
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,mission,plot:GetX(),plot:GetY(),0,false,false)
end
local function arrived(p,r,plot,water)
 local u=assert(p:GetUnitByID(r.id));if not LekmodScenarioAwait(r.kind..(water and"-water"or"-land"),u:GetX()==plot:GetX()and u:GetY()==plot:GetY()and not u:IsBusy())then return false end
 assert(u:GetMoves()>=0 and u:GetMoves()<r.before,"normal movement did not spend movement")
 if r.kind~="UNIT_WARRIOR"then
  assert(u:IsHasPromotion(hover)and not u:IsHasPromotion(embark)and not u:IsEmbarked())
  assert(u:GetDomainType()==(water and DomainTypes.DOMAIN_SEA or DomainTypes.DOMAIN_LAND))
 else assert(u:IsHasPromotion(embark)and u:IsEmbarked()==water)end
 LekmodScenarioEvent("native-shore-move",{kind=r.kind,water=water,state=state(u)})
 return true
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman())
 if phase=="init"then
  LekmodScenarioGrantTech(p,"TECH_OPTICS");p:ChangeGold(10000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_ALUMINUM,2)
  local used={}
  for _,kind in ipairs(kinds)do local chosen
   for i=0,Map.GetNumPlots()-1 do local land=Map.GetPlotByIndex(i)
    if not used[i]and not land:IsWater()and safe(land,p)then
     for d=0,5 do local sea=Map.PlotDirection(land:GetX(),land:GetY(),d)
      if sea and not used[sea:GetPlotIndex()]and sea:IsWater()and not sea:IsLake()and sea:GetTerrainType()==TerrainTypes.TERRAIN_COAST and sea:GetFeatureType()==-1 and safe(sea,p)then chosen={kind=kind,land=land,sea=sea};break end
     end
    end
    if chosen then break end
   end
   assert(chosen,"fixture lacks independent natural shore pair for "..kind)
   used[chosen.land:GetPlotIndex()]=true;used[chosen.sea:GetPlotIndex()]=true;records[#records+1]=chosen
  end
  for _,r in ipairs(records)do
   local u=assert(p:InitUnit(GameInfoTypes[r.kind],r.land:GetX(),r.land:GetY()));r.id=u:GetID();u:SetScriptData(prefix..r.kind)
   assert(not u:IsEmbarked()and u:GetDomainType()==DomainTypes.DOMAIN_LAND)
   if r.kind=="UNIT_WARRIOR"then assert(u:IsHasPromotion(embark))else assert(u:IsHasPromotion(hover)and not u:IsHasPromotion(embark))end
   LekmodScenarioEvent("fixture-setup",{operation="provided-unit-shore-pair",kind=r.kind,unit=r.id,land=r.land:GetPlotIndex(),sea=r.sea:GetPlotIndex()})
  end
  LekmodScenarioRecord("hover-native-birth","PASS","all3configured hover types lack ordinary embark promotion after native creation; Warrior has valid embark")
  phase="water-order"
 elseif phase=="water-order"then order(p,records[cursor],records[cursor].sea);phase="water-arrive"
 elseif phase=="water-arrive"then
  if not arrived(p,records[cursor],records[cursor].sea,true)then return false end
  cursor=cursor+1;if cursor<=#records then phase="water-order"else
   LekmodScenarioRecord("hover-shore-entry","PASS","three normal coast moves report sea domain without embark; Warrior actually embarks")
   -- The shared human driver issues Skip only while IsReadyToMove is true.
   -- Skip keeps unused movement points; it must not be polled by GetMoves.
   turn=Game.GetGameTurn();phase="round";return "turn"
  end
 elseif phase=="round"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  for _,r in ipairs(records)do local u=assert(p:GetUnitByID(r.id));assert(u:GetX()==r.sea:GetX()and u:GetY()==r.sea:GetY())
   if r.kind~="UNIT_WARRIOR"then assert(not u:IsEmbarked()and not u:IsHasPromotion(embark))else assert(u:IsEmbarked()and u:IsHasPromotion(embark))end
  end
  LekmodScenarioRecord("hover-ordinary-turn","PASS","genuine owner round refreshes movement and preserves hover versus embarked control states")
  cursor=1;phase="land-order"
 elseif phase=="land-order"then order(p,records[cursor],records[cursor].land);phase="land-arrive"
 elseif phase=="land-arrive"then
  if not arrived(p,records[cursor],records[cursor].land,false)then return false end
  cursor=cursor+1;if cursor<=#records then phase="land-order"else
   LekmodScenarioRecord("hover-land-return","PASS","all3hover types return to land domain without an embark transition")
   LekmodScenarioRecord("hover-embark-control","PASS","ordinary Warrior retains promotion, embarks and disembarks through actual moves")
   LekmodScenarioRecord("hover-movement-debit","PASS","every outward and return mission spends real movement")
   return true
  end
 end
 return false
end
