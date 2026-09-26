print("[LEKMOD_DIAGNOSTIC] Romania trade context="..tostring(ContextPtr:GetID()))
if ContextPtr:GetID()=="DiploTrade"then
 local request,waiting,closing,elapsed,observed
 LuaEvents.LekmodRomaniaCityGift.Add(function(r)request=r;waiting=nil;closing=false;elapsed=0;print("[LEKMOD_DIAGNOSTIC] Romania gift request received player="..r.player)end)
 LuaEvents.LekmodScenarioDiplomacyClose.Add(function()closing=true end)
 ContextPtr:SetUpdate(function(dt)
  if waiting then
   local c=Map.GetPlot(waiting.x,waiting.y):GetPlotCity()
   if c and c:GetOwner()==waiting.player then LuaEvents.LekmodRomaniaCityGiftAccepted();waiting=nil;LuaEvents.LekmodScenarioDiplomacyClose()end
  end
  if closing and not ContextPtr:IsHidden()then closing=false;OnBack();return end
  if request and not ContextPtr:IsHidden()and not observed then
   observed=true;print("[LEKMOD_DIAGNOSTIC] Romania visible trade us="..tostring(g_iUs).." them="..tostring(g_iThem).." processing="..tostring(Game.IsProcessingMessages()))
  end
  if not request or ContextPtr:IsHidden()or g_iThem~=request.player or Game.IsProcessingMessages()then return end
  elapsed=elapsed+dt;if elapsed<1 then return end
  local r=request;request=nil
  local ok,err=pcall(function()
   assert(not g_bPVPTrade and g_iUs==Game.GetActivePlayer())
   g_Deal:ClearItems();g_Deal:SetFromPlayer(g_iUs);g_Deal:SetToPlayer(g_iThem)
   assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_CITIES,r.x,r.y),"normal city gift is not legal")
   -- Diplomacy's native dialog must answer while the game waits for that
   -- conversation. Use the original controls and native deal legality checks.
   -- The scenario driver and all GameCore synchronization checks stay intact.
   print("[LEKMOD_DIAGNOSTIC] Romania original gift controls processing="..tostring(Game.IsProcessingMessages()))
   OnChooseCity(g_iUs,r.city);assert(not Controls.ProposeButton:IsDisabled(),"native Propose button disabled");OnPropose(PROPOSE_TYPE);waiting=r
   LuaEvents.LekmodRomaniaCityGiftProposed()
  end)
  if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=romania-city-gift status=FAIL error="..tostring(err));OnBack();LuaEvents.LekmodScenarioDiplomacyClose()end
 end)
end
