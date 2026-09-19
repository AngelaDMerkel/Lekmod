-- Read-only verification of the physical Self portrait / Dutch men-o'-war swap.
include("LekmodTestGreatWorkExchange")
LekmodScenario={name="greatwork-exchange-verify",items={"exchange-controllers","exchange-slot-counts","exchange-theme-yields","exchange-offers-cleared"}}
function LekmodScenario.snapshot(player)return LekmodExchangeSnapshot()end
function LekmodScenario.step(player)
 local s=LekmodExchangeSnapshot();local w=s.works;local own=s.owners[0];local other=s.owners[1]
 assert(s.turn==180,"physical fixture unexpectedly advanced a turn")
 assert(w[0]and w[1]and w[2]and w[3],"prepared fixture works missing")
 assert(w[1].name=="TXT_KEY_GREAT_WORK_SELF_PORTRAIT"and w[1].creator==0 and w[1].controller==1,"Self portrait did not transfer to Belgium with its creator preserved")
 assert(w[2].name=="TXT_KEY_GREAT_WORK_DUTCH_MEN_O_WAR"and w[2].creator==1 and w[2].controller==0,"Dutch artwork did not transfer to Rome with its creator preserved")
 assert(w[0].creator==0 and w[0].controller==0 and w[3].creator==1 and w[3].controller==1,"unexchanged artwork/writing changed controller")
 assert(w[0].class==s.classes.art and w[1].class==s.classes.art and w[2].class==s.classes.art and w[3].class==s.classes.writing,"work classes changed")
 LekmodScenarioRecord("exchange-controllers","PASS","work1 Rome->Belgium, work2 Belgium->Rome; creators/classes and untouched works preserved")
 local museum=GameInfoTypes.BUILDINGCLASS_MUSEUM;local human=player:GetCapitalCity();local ai=Players[1]:GetCapitalCity()
 assert(own.total==2 and other.total==2,"exchange lost or duplicated works")
 assert(human:GetBuildingGreatWork(museum,0)==2 and human:GetBuildingGreatWork(museum,1)==0 and ai:GetBuildingGreatWork(museum,0)==1,"exchanged works did not occupy their counterpart slots")
 LekmodScenarioRecord("exchange-slot-counts","PASS","both owners retain2works; intendedMuseum slots exchanged")
 assert(human:GetThemingBonus(museum)==1 and human:GetBaseTourism()==5 and ai:GetBaseTourism()==4,"post-swap theme/tourism differs from mixed-creator fixture")
 LekmodScenarioRecord("exchange-theme-yields","PASS","RomeMuseum theme1 tourism5; Belgianbase tourism4")
 assert(own.offered_art==-1 and other.offered_art==-1 and other.offered_writing==3,"consumed art offers or untouched writing offer incorrect")
 LekmodScenarioRecord("exchange-offers-cleared","PASS","both art offers cleared; foreign writing offer3 retained")
 LekmodScenarioEvent("physical-exchange-reloaded",s)
 return true
end
