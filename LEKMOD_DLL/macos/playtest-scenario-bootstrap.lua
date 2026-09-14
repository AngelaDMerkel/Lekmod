if __TEST_SCENARIO_TURN_LIMIT__ > 0 then
    LEKMOD_TEST_EXTERNAL_DRIVER=true
    include("LekmodTestDriver.lua")
end
include("LekmodTestScenarioCore.lua")
include("LekmodTestScenario.lua")
LekmodScenarioStart()
