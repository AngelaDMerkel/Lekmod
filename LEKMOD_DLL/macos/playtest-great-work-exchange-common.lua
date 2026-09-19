-- Read both sides of a Great Work exchange; never assign works or controllers.
function LekmodExchangeSnapshot()
 local owners,works={},{}
 for owner=0,1 do
  local p=Players[owner];local cities,holdings={},{}
  for c in p:Cities()do
   cities[c:GetID()]={name=c:GetName(),works=c:GetNumGreatWorks(),tourism=c:GetBaseTourism(),theme=c:GetThemingBonus(GameInfoTypes.BUILDINGCLASS_MUSEUM)}
   for b in GameInfo.Buildings()do
    if b.GreatWorkCount>0 and c:GetNumBuilding(b.ID)>0 then
     local class=GameInfo.BuildingClasses[b.BuildingClass].ID
     for slot=0,b.GreatWorkCount-1 do
      local id=c:GetBuildingGreatWork(class,slot);holdings[c:GetID()..":"..class..":"..slot]=id
      if id>=0 then works[id]={class=Game.GetGreatWorkClass(id),creator=Game.GetGreatWorkCreator(id),controller=Game.GetGreatWorkController(id),name=Game.GetGreatWorkName(id),era=Game.GetGreatWorkEra(id)}end
     end
    end
   end
  end
  owners[owner]={total=p:GetNumGreatWorks(),cities=cities,holdings=holdings,offered_art=p:GetSwappableGreatArt(),offered_writing=p:GetSwappableGreatWriting(),offered_artifact=p:GetSwappableGreatArtifact()}
 end
 return {turn=Game.GetGameTurn(),owners=owners,works=works,classes={art=GameInfoTypes.GREAT_WORK_ART,artifact=GameInfoTypes.GREAT_WORK_ARTIFACT,writing=GameInfoTypes.GREAT_WORK_LITERATURE,music=GameInfoTypes.GREAT_WORK_MUSIC}}
end
