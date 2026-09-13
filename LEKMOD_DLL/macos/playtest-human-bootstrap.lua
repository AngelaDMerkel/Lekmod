-- Temporary entry point; the separate driver can be refreshed without restarting Civ V.
if __TEST_PRODUCTION_COMPLETION__ then include("LekmodTestCompletion.lua") end
include("LekmodTestDriver.lua")
