-- Buildings and pressure transfers are explicit inputs. Observe native cached
-- religion yields; this does not claim normal construction or faith purchase.
LekmodScenario={name="diversity-yields",items={"candi-minority-faith","candi-minority-removal","gurdwara-minority-yields","diversity-building-other-owner"}}
local phase,own,foreign,baseline,control,majorityFollowers="init"
local candi,gurdwara=GameInfoTypes.BUILDING_CANDI,GameInfoTypes.BUILDING_GURDWARA
local function state(player)
 local c=assert(player:GetCapitalCity());local followers={}
 for r in GameInfo.Religions()do followers[r.ID]=c:GetNumFollowers(r.ID)end
 followers[-1]=c:GetNumFollowers(-1)
 return {followers=followers,majority=c:GetReligiousMajority(),population=c:GetPopulation(),candi=c:GetNumRealBuilding(candi),gurdwara=c:GetNumRealBuilding(gurdwara),faith_total=c:GetFaithPerTurn(),faith_religion=c:GetBaseYieldRateFromReligion(YieldTypes.YIELD_FAITH),science_religion=c:GetBaseYieldRateFromReligion(YieldTypes.YIELD_SCIENCE),faith_bank=player:GetFaith()}
end
function LekmodScenario.snapshot(player)
 return {turn=Game.GetGameTurn(),human=state(player),other=state(Players[2])}
end
local function transfer(city,to,from,percent)
 city:ConvertPercentFollowers(to,from,percent)
 LekmodScenarioEvent("fixture-setup",{operation="provided-pressure-transfer",to=to,from=from,percent=percent})
end
local function building(city,id,n)
 city:SetNumRealBuilding(id,n)
 LekmodScenarioEvent("fixture-setup",{operation="provided-building-count",building=id,count=n})
end
local function sameFollowers(s)
 assert(s.majority==own and s.followers[own]==majorityFollowers,"fixture changed majority religion/followers")
end
function LekmodScenario.step(player)
 local c=assert(player:GetCapitalCity())
 if phase=="init" then
  own=player:GetReligionCreatedByPlayer();foreign=Players[1]:GetReligionCreatedByPlayer()
  assert(own>0 and foreign>0 and own~=foreign and c:GetPopulation()==20 and c:GetNumFollowers(own)==20)
  assert(c:GetNumRealBuilding(candi)==0 and c:GetNumRealBuilding(gurdwara)==0)
  local rows=0
  for row in GameInfo.Building_YieldChangesPerReligion()do
   if row.BuildingType=="BUILDING_CANDI" or row.BuildingType=="BUILDING_GURDWARA" then
    assert(row.Yield==200)
    assert(row.YieldType=="YIELD_FAITH" or (row.BuildingType=="BUILDING_GURDWARA" and row.YieldType=="YIELD_SCIENCE"));rows=rows+1
   end
  end
  assert(rows==3,"unexpected per-religion building definitions")
  control=state(Players[2]);transfer(c,-1,own,40);building(c,candi,1);phase="candi-ready"
 elseif phase=="candi-ready" then
  baseline=state(player);majorityFollowers=baseline.followers[own]
  assert(majorityFollowers==12 and baseline.followers[-1]==8)
  LekmodScenarioEvent("candi-before-minority",baseline)
  transfer(c,foreign,-1,50);phase="candi-added"
 elseif phase=="candi-added" then
  local s=state(player);sameFollowers(s);LekmodScenarioEvent("candi-after-minority",s)
  assert(s.followers[foreign]==4 and s.faith_religion==baseline.faith_religion+2 and s.faith_total==baseline.faith_total+2 and s.science_religion==baseline.science_religion,"Candi minority-only faith cache did not refresh")
  LekmodScenarioRecord("candi-minority-faith","PASS","native-minority-only change faith-religion=+2 faith-total=+2 science-unchanged=true")
  transfer(c,-1,foreign,100);phase="candi-removed"
 elseif phase=="candi-removed" then
  local s=state(player);sameFollowers(s);LekmodScenarioEvent("candi-after-removal",s)
  assert(s.followers[foreign]==0 and s.faith_religion==baseline.faith_religion and s.faith_total==baseline.faith_total,"Candi lost minority retained stale faith")
  LekmodScenarioRecord("candi-minority-removal","PASS","native-minority-only removal clears-two-faith=true")
  building(c,candi,0);building(c,gurdwara,1);phase="gurdwara-ready"
 elseif phase=="gurdwara-ready" then
  baseline=state(player);sameFollowers(baseline);LekmodScenarioEvent("gurdwara-before-minority",baseline)
  transfer(c,foreign,-1,50);phase="gurdwara-added"
 elseif phase=="gurdwara-added" then
  local s=state(player);sameFollowers(s);LekmodScenarioEvent("gurdwara-after-minority",s)
  assert(s.followers[foreign]==4 and s.faith_religion==baseline.faith_religion+2 and s.faith_total==baseline.faith_total+2 and s.science_religion==baseline.science_religion+2,"Gurdwara minority-only yields did not refresh")
  assert(s.faith_bank==baseline.faith_bank,"query-only test unexpectedly settled banked faith")
  LekmodScenarioRecord("gurdwara-minority-yields","PASS","native-minority-only change faith-religion=+2 faith-total=+2 science-religion=+2")
  local other=state(Players[2])
  assert(other.faith_total==control.faith_total and other.faith_religion==control.faith_religion and other.science_religion==control.science_religion and other.faith_bank==control.faith_bank and other.candi==0 and other.gurdwara==0,"other-owner yields changed")
  LekmodScenarioRecord("diversity-building-other-owner","PASS","Roman-three-religion control without-buildings unchanged=true")
  return true
 end
 return false
end
