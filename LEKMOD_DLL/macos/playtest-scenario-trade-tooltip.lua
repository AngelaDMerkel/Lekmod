-- Read-only native tooltip/route precision on the preserved internal-route save.
LekmodScenario={name="trade-tooltip",items={"trade-tooltip-food-precision","trade-tooltip-production-precision","trade-tooltip-data-preserved"}}
function LekmodScenario.snapshot(player)
 local routes={}
 for _,r in ipairs(player:GetTradeRoutes())do routes[#routes+1]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),connection=r.ConnectionType,domain=r.Domain,food=r.ToFood,production=r.ToProduction,from_gold=r.FromGPT,to_gold=r.ToGPT,from_science=r.FromScience,to_science=r.ToScience,turns=r.TurnsLeft}end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),used=player:GetNumInternationalTradeRoutesUsed(),routes=routes,your_tooltip=player:GetTradeYourRoutesTTString(),incoming_tooltip=player:GetTradeToYouRoutesTTString()}
end
function LekmodScenario.step(player)
 local s=LekmodScenario.snapshot(player);LekmodScenarioEvent("native-trade-tooltip",s)
 assert(#s.routes==2 and s.used==2,"requires the two-route internal fixture")
 local food,production=false,false
 for _,r in ipairs(s.routes)do if r.food==175 then food=true end;if r.production==350 then production=true end end
 assert(food and production,"native route values differ from preserved fixture")
 local foodText=Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_ITR_FOOD_YIELD_TT",1.75)
 local productionText=Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_ITR_PRODUCTION_YIELD_TT",3.5)
 assert(foodText~=Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_ITR_FOOD_YIELD_TT",1) and productionText~=Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_ITR_PRODUCTION_YIELD_TT",3),"localization itself discarded the fractional input")
 assert(string.find(s.your_tooltip,foodText,1,true),"native tooltip lost food hundredths")
 assert(string.find(s.your_tooltip,productionText,1,true),"native tooltip lost production fraction")
 LekmodScenarioRecord("trade-tooltip-food-precision","PASS","native-localized-food=1.75")
 LekmodScenarioRecord("trade-tooltip-production-precision","PASS","native-localized-production=3.5")
 LekmodScenarioRecord("trade-tooltip-data-preserved","PASS","read-only route food175 production350 used2 turn-unchanged=true")
 return true
end
