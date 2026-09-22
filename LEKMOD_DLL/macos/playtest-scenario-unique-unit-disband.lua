-- Consume the preserved native creation catalogue through actual Delete/Yes
-- commands. Alternating units are staged in the owner's capital so both owned
-- refund and neutral no-refund cases occur. No Kill/gold/outcome field is assigned.
LekmodScenario={name="unique-unit-disband",items={"unique-unit-disband-commands","unique-unit-disband-refunds","unique-unit-prekill-events"}}
local marker="LekmodMacUniqueUnitCatalogue"
local phase,ids,index,confirmation,prekill,before,refund,total="init",{},1,nil,{},nil,nil,0
LuaEvents.LekmodUnitCommandConfirmed.Add(function(kind,id,choice)confirmation={kind=kind,id=id,choice=choice}end)
GameEvents.UnitPrekill.Add(function(owner,id)if owner==Game.GetActivePlayer()then prekill[id]=true end end)
function LekmodScenario.snapshot(player)
 local units={};for u in player:Units()do if not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),script=u:GetScriptData(),moves=u:GetMoves()}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),units=units}
end
function LekmodScenario.step(player)
 if phase=="init"then
  for u in player:Units()do if u:GetScriptData()==marker then ids[#ids+1]=u:GetID()end end
  table.sort(ids);assert(#ids==125,"requires the complete saved125-unit catalogue")
  phase="delete"
 elseif phase=="delete"then
  local u=assert(player:GetUnitByID(ids[index]));assert(u:GetScriptData()==marker)
  if index%2==0 then
   local c=assert(player:GetCapitalCity());u:SetXY(c:GetX(),c:GetY(),false,true,false,false)
   assert(u:GetX()==c:GetX()and u:GetY()==c:GetY())
   LekmodScenarioEvent("fixture-setup",{operation="provided-owned-disband-position",id=u:GetID(),x=u:GetX(),y=u:GetY()})
  end
  assert(u:CanScrap(),"catalogue unit cannot be legally disbanded: "..GameInfo.Units[u:GetUnitType()].Type)
  local quote=u:GetScrapGold();before=player:GetGold();refund=u:GetPlot():GetOwner()==player:GetID()and quote or 0
  LekmodScenarioEvent("unique-disband-before",{id=u:GetID(),type=u:GetUnitType(),plot_owner=u:GetPlot():GetOwner(),quoted_refund=quote,expected_refund=refund,gold=before})
  UI.SelectUnit(u);confirmation=nil;LuaEvents.LekmodConfirmUnitAction("COMMAND_DELETE",u:GetID(),"yes")
  local found=false
  for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="COMMAND_DELETE"then assert(Game.CanHandleAction(i),"Delete action disabled");Game.HandleAction(i);found=true;break end end
  assert(found,"Delete action missing");phase="deleted"
 elseif phase=="deleted"then
  if not confirmation then return false end
  local id=ids[index];local u=player:GetUnitByID(id)
  if not LekmodScenarioAwait("unique-disband-"..id,not u or u:IsDead()or u:IsDelayedDeath())then return false end
  assert(confirmation.kind=="COMMAND_DELETE"and confirmation.id==id and confirmation.choice=="yes","wrong actual confirmation")
  assert(prekill[id],"native UnitPrekill event missing")
  assert(player:GetGold()==before+refund,"native disband refund differs")
  total=total+refund
  LekmodScenarioEvent("unique-disband-result",{id=id,gold=player:GetGold(),refund=refund,processed=index})
  LekmodScenarioRecord("unique-unit-disband-"..id,"PASS","normal Delete/Yes, native UnitPrekill and treasury delta verified")
  index=index+1
  if index>#ids then
   for x in player:Units()do assert(x:GetScriptData()~=marker or x:IsDelayedDeath(),"catalogue unit survived disband")end
   LekmodScenarioRecord("unique-unit-disband-commands","PASS","125 normal Delete/Yes commands consumed all catalogue units")
   LekmodScenarioRecord("unique-unit-disband-refunds","PASS","owned quote versus neutral no-refund checked for each command; total="..total)
   LekmodScenarioRecord("unique-unit-prekill-events","PASS","native UnitPrekill observed for every catalogue unit")
   return true
  end
  phase="delete"
 end
 return false
end
