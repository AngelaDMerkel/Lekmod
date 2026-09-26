do
 local request,elapsed,checks
 LuaEvents.LekmodRomaniaCityGift.Add(function(r)request=r;elapsed=0;checks=0 end)
 ContextPtr:SetUpdate(function(dt)
  if not request or ContextPtr:IsHidden()or g_iAIPlayer~=request.player or not g_bCanGoBack then return end
  elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
  local c=Map.GetPlot(request.x,request.y):GetPlotCity();checks=checks+1
  if not c or c:GetOwner()~=request.player then
   if checks>=8 then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=romania-city-gift status=FAIL error=AI-reply-did-not-transfer-city");request=nil;OnBack();LuaEvents.LekmodScenarioDiplomacyClose()end
   return
  end
  request=nil;LuaEvents.LekmodRomaniaCityGiftAccepted();OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
 end)
end
