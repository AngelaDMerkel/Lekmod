-- Read-only observation of normally generated starts and native initial vision.
-- No terrain, area, civilization, starting position or visibility is supplied.
LekmodScenario={name="tonga-vision",items={"tonga-singleton-islands","tonga-near-islands","tonga-native-area-identity","tonga-other-owner-vision"}}
local function visibility(player)
 local start=assert(player:GetStartingPlot());local team=player:GetTeam()
 local s={civilization=player:GetCivilizationType(),team=team,start_x=start:GetX(),start_y=start:GetY(),start_area=start:GetArea(),islands={},visible={},area_identity_mismatches=0}
 for i=0,Map.GetNumPlots()-1 do
  local p=Map.GetPlotByIndex(i)
  if p:IsRevealed(team)then s.visible[#s.visible+1]=i end
  local distance=Map.PlotDistance(start:GetX(),start:GetY(),p:GetX(),p:GetY())
  if distance>0 and distance<=12 and not p:IsWater()then
   if (p:Area()==start:Area())~=(p:GetArea()==start:GetArea())then s.area_identity_mismatches=s.area_identity_mismatches+1 end
   if p:GetArea()~=start:GetArea() and p:IsCoastalLand() and not p:IsLake()then
    local coast={}
    for direction=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),direction)
     if q and q:IsWater() and not q:IsLake()then coast[#coast+1]={x=q:GetX(),y=q:GetY(),revealed=q:IsRevealed(team)}end
    end
    s.islands[#s.islands+1]={x=p:GetX(),y=p:GetY(),distance=distance,area=p:GetArea(),tiles=p:Area():GetNumTiles(),revealed=p:IsRevealed(team),coast=coast}
   end
  end
 end
 return s
end
function LekmodScenario.snapshot(player)
 return {turn=Game.GetGameTurn(),owners={[0]=visibility(Players[0]),[1]=visibility(Players[1]),[2]=visibility(Players[2])}}
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer())
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TONGA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_TONGA and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires normal human/AI Tonga and Roman AI control")
 local s=LekmodScenario.snapshot(player);LekmodScenarioEvent("tonga-generated-start-visibility",s)
 local singletons,singleMissing,islands,missing,identity=0,0,0,0,0
 for id=0,1 do
  local owner=s.owners[id];assert(#owner.islands>0,"no nearby foreign-area coast for owner "..id)
  identity=identity+owner.area_identity_mismatches
  for _,p in ipairs(owner.islands)do
   islands=islands+1;if not p.revealed then missing=missing+1 end
   if p.tiles==1 and p.distance>=7 then
    singletons=singletons+1;if not p.revealed then singleMissing=singleMissing+1 end
    for _,q in ipairs(p.coast)do if not q.revealed then singleMissing=singleMissing+1 end end
   end
  end
 end
 assert(singletons>0,"generated fixture has no one-tile island at distance 7..12; retain as an insufficient fixture")
 local controls,controlSeen=0,0
 for _,p in ipairs(s.owners[2].islands)do if p.distance>=7 then controls=controls+1;if p.revealed then controlSeen=controlSeen+1 end end end
 assert(controls>0,"Roman setup has no distant island control")
 LekmodScenarioRecord("tonga-singleton-islands",singleMissing==0 and "PASS" or "FAIL","natural-singletons="..singletons.." hidden-island-or-coast-plots="..singleMissing)
 LekmodScenarioRecord("tonga-near-islands",missing==0 and "PASS" or "FAIL","natural-nearby-island-coast="..islands.." hidden="..missing)
 LekmodScenarioRecord("tonga-native-area-identity",identity==0 and "PASS" or "FAIL","native-area-identity-mismatches="..identity)
 LekmodScenarioRecord("tonga-other-owner-vision",controlSeen==0 and "PASS" or "FAIL","Roman-distant-island-controls="..controls.." revealed="..controlSeen)
 return true
end
