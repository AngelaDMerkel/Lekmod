-- Original bilateral embassy/open-border trade callbacks for a scoped fixture.
do
 local request,waiting,elapsed,checks=nil,nil,0,0
 local counteroffer=false
 local context=ContextPtr:GetID()
 local function accepted(r)
  local us=Players[Game.GetActivePlayer()];local other=Players[r.player];local a,b=Teams[us:GetTeam()],Teams[other:GetTeam()]
  if r.kind=="embassies"then return a:HasEmbassyAtTeam(other:GetTeam())and b:HasEmbassyAtTeam(us:GetTeam())end
  return b:IsAllowsOpenBordersToTeam(us:GetTeam())
 end
 LuaEvents.LekmodAttritionDeal.Add(function(r)request=r;waiting=nil;elapsed=0;checks=0;counteroffer=false end)
 if context=="DiploTrade"then
  ContextPtr:SetUpdate(function(dt)
   if not request and not waiting and not ContextPtr:IsHidden()then
    elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=attrition-unsolicited-trade-closed");OnBack()end;return
   end
   if waiting and accepted(waiting)then local kind=waiting.kind;waiting=nil;LuaEvents.LekmodAttritionDealAccepted(kind);OnBack();LuaEvents.LekmodScenarioDiplomacyClose();return end
   if not request or ContextPtr:IsHidden()or g_iThem~=request.player then return end
   elapsed=elapsed+dt;if elapsed<1 then return end
   local r=request;request=nil;local ok,e=pcall(function()
    assert(not g_bPVPTrade and g_iUs==Game.GetActivePlayer())
    if counteroffer then
     local inbound=false;local terms={};g_Deal:ResetIterator()
     while true do
      local kind,duration,finish,data1,data2,data3,flag,from=g_Deal:GetNextItem();if kind==nil then break end
      assert(kind==TradeableItems.TRADE_ITEM_OPEN_BORDERS or kind==TradeableItems.TRADE_ITEM_RESOURCES or kind==TradeableItems.TRADE_ITEM_GOLD_PER_TURN or kind==TradeableItems.TRADE_ITEM_GOLD,"unreviewed counteroffer item")
      if kind==TradeableItems.TRADE_ITEM_OPEN_BORDERS and from==g_iThem then inbound=true end
      terms[#terms+1]={kind=kind,from=from,duration=duration,data1=data1,data2=data2}
     end
     assert(inbound,"counteroffer removed the required inbound border permission")
     print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=attrition-counteroffer-reviewed items="..#terms)
     counteroffer=false;waiting=r;OnPropose(PROPOSE_TYPE);LuaEvents.LekmodAttritionDealProposed(r.kind);return
    end
    g_Deal:ClearItems();g_Deal:SetFromPlayer(g_iUs);g_Deal:SetToPlayer(g_iThem)
    if r.kind=="embassies"then
     assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_ALLOW_EMBASSY)and g_Deal:IsPossibleToTradeItem(g_iThem,g_iUs,TradeableItems.TRADE_ITEM_ALLOW_EMBASSY))
     PocketAllowEmbassyHandler(1);PocketAllowEmbassyHandler(0)
    else
     assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_OPEN_BORDERS,g_iDealDuration)and g_Deal:IsPossibleToTradeItem(g_iThem,g_iUs,TradeableItems.TRADE_ITEM_OPEN_BORDERS,g_iDealDuration))
     PocketOpenBordersHandler(1);PocketOpenBordersHandler(0)
     assert(g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_GOLD_PER_TURN,1,g_iDealDuration))
     PocketGoldPerTurnHandler(1);ChangeGoldPerTurnAmount("1",Controls.UsGoldPerTurnAmount)
     assert(r.resource and g_Deal:IsPossibleToTradeItem(g_iUs,g_iThem,TradeableItems.TRADE_ITEM_RESOURCES,r.resource,1,g_iDealDuration))
     PocketResourceHandler(1,r.resource)
     OnWhatDoesAIWant();counteroffer=true;request=r;elapsed=0;return
    end
    waiting=r;OnPropose(PROPOSE_TYPE);LuaEvents.LekmodAttritionDealProposed(r.kind)
   end)
   if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=attrition-diplomacy status=FAIL error="..tostring(e));OnBack();LuaEvents.LekmodScenarioDiplomacyClose()end
  end)
 elseif context=="DiscussionDialog"then
  ContextPtr:SetUpdate(function(dt)
   if not request and not ContextPtr:IsHidden()and g_bCanGoBack then
    elapsed=elapsed+dt;if elapsed>=1 then elapsed=0;OnBack();LuaEvents.LekmodScenarioDiplomacyClose()end;return
   end
   if not request or ContextPtr:IsHidden()or g_iAIPlayer~=request.player or not g_bCanGoBack then return end
   elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0;checks=checks+1
   if accepted(request)then local kind=request.kind;request=nil;LuaEvents.LekmodAttritionDealAccepted(kind);OnBack();LuaEvents.LekmodScenarioDiplomacyClose()
   elseif checks>=8 then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=attrition-diplomacy status=FAIL AI did not accept reviewed proposal");request=nil;OnBack();LuaEvents.LekmodScenarioDiplomacyClose()end
  end)
 end
end
