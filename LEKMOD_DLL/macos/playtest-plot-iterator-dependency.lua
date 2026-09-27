-- Read-only proof in the actual prophetreplace Lua context. The earlier
-- PlotIterators include supplies the function; the later absent filename does
-- not abort the context. No dormant resource-placement function is invoked.
Events.SequenceGameInitComplete.Add(function()
 assert(type(PlotAreaSweepIterator)=="function"and type(PlaceExtraJuice)=="function","prophetreplace dependency or later context initialization missing")
 local city=assert(Players[Game.GetActivePlayer()]:GetCapitalCity())
 local center=city:Plot();local expected,actual={},{}
 for d=0,5 do local q=Map.PlotDirection(center:GetX(),center:GetY(),d);if q then expected[q:GetPlotIndex()]=true end end
 local count=0
 for q in PlotAreaSweepIterator(center,1,SECTOR_NORTH,DIRECTION_CLOCKWISE,DIRECTION_OUTWARDS,CENTRE_EXCLUDE)do
  local i=q:GetPlotIndex();assert(expected[i]and not actual[i],"native iterator neighbor mismatch");actual[i]=true;count=count+1
 end
 for i in pairs(expected)do assert(actual[i],"native iterator missed neighbor")end
 print("[LEKMOD_DEPENDENCY] run=__TEST_RUN__ context=prophetreplace status=PASS function=PlotAreaSweepIterator later_context=PlaceExtraJuice neighbors="..count)
end)
