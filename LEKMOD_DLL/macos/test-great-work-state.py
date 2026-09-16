#!/usr/bin/env python3
"""Exercise the product's optional-class SQL and great-work holding state."""
from pathlib import Path
import ast
import re
import sqlite3
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
SOURCE=(ROOT/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvBuildingClasses.cpp').read_text()
CULTURE=(ROOT/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvCultureClasses.cpp').read_text()

class GreatWorkDataTests(unittest.TestCase):
    def setUp(self):
        start=SOURCE.index('const char* szSQL',SOURCE.index('std::string strKey("Building_GreatWorkYieldChanges")'))
        fragment=SOURCE[start:SOURCE.index(';',start)]
        self.query=''.join(ast.literal_eval(s) for s in re.findall(r'"(?:[^"\\]|\\.)*"',fragment))
        self.db=sqlite3.connect(':memory:')
        self.addCleanup(self.db.close)
        self.db.executescript('CREATE TABLE Yields(ID INTEGER,Type TEXT); CREATE TABLE GreatWorkClasses(ID INTEGER,Type TEXT); CREATE TABLE Building_GreatWorkYieldChanges(BuildingType TEXT,GreatWorkClassType TEXT,YieldType TEXT,YieldChange INTEGER,HoldingYield INTEGER);')
        data=ET.parse(ROOT/'LEKMOD/Override/CIV5Units.xml').getroot()
        for table in ('Yields','GreatWorkClasses'):
            for row in data.findall(table+'/Row'):
                self.db.execute('INSERT INTO '+table+' VALUES (?,?)',(int(row.findtext('ID')),row.findtext('Type')))
        for row in data.findall('Building_GreatWorkYieldChanges/Row'):
            self.db.execute('INSERT INTO Building_GreatWorkYieldChanges VALUES (?,?,?,?,?)',(row.findtext('BuildingType'),row.findtext('GreatWorkClassType'),row.findtext('YieldType'),int(row.findtext('YieldChange','0')),int(row.findtext('HoldingYield','0'))))
    def test_shipped_dance_hall_row_without_class_is_loaded(self):
        culture=self.db.execute("SELECT ID FROM Yields WHERE Type='YIELD_CULTURE'").fetchone()[0]
        self.assertEqual(self.db.execute(self.query,('BUILDING_DANCE_HALL',)).fetchall(),[(culture,-1,0,4)])
    def test_specific_class_row_retains_its_class(self):
        music=self.db.execute("SELECT ID FROM GreatWorkClasses WHERE Type='GREAT_WORK_MUSIC'").fetchone()[0]
        science=self.db.execute("SELECT ID FROM Yields WHERE Type='YIELD_SCIENCE'").fetchone()[0]
        self.db.execute('INSERT INTO Building_GreatWorkYieldChanges VALUES (?,?,?,?,?)',('BUILDING_TEST','GREAT_WORK_MUSIC','YIELD_SCIENCE',3,0))
        self.assertEqual(self.db.execute(self.query,('BUILDING_TEST',)).fetchall(),[(science,music,3,0)])
    def test_unrelated_building_gets_no_bonus(self):
        self.assertEqual(self.db.execute(self.query,('BUILDING_MONUMENT',)).fetchall(),[])

class GreatWorkStateTests(unittest.TestCase):
    def test_holding_mutations_and_derived_happiness(self):
        a=SOURCE.index('void CvCityBuildings::SetBuildingGreatWork(')
        b=SOURCE.index('/// Accessor: Is there a Great Work',a)
        setter=SOURCE[a:b]
        a=SOURCE.index('const std::map<GreatWorkClass, int>& CvCityBuildings::GetGreatWorkClassCounts() const')
        b=SOURCE.index('void CvCityBuildings::rebuildGreatWorkYields',a)
        counts=SOURCE[a:b]
        a=SOURCE.index('int CvCityBuildings::GetHappinessFromGreatWorks() const')
        b=SOURCE.index('int CvCityBuildings::countNumThemesActive()',a)
        happiness=SOURCE[a:b]
        a=SOURCE.index('void CvCityBuildings::rebuildGreatWorkYields(')
        b=SOURCE.index('int CvCityBuildings::GetHappinessFromGreatWorks()',a)
        yields=SOURCE[a:b]
        a=CULTURE.index('void CvGameCulture::MoveGreatWorks(')
        b=CULTURE.index('/// How many civs do we need',a)
        move=CULTURE[a:b]
        a=SOURCE.index('int CvCityBuildings::GetYieldFromGreatWorks(',SOURCE.index('/// Accessor: Total theming bonus'))
        b=SOURCE.index('int CvCityBuildings::GetNumGreatWorks(GreatWorkClass',a)
        getter=SOURCE[a:b]
        a=SOURCE.index('static CvBuildingEntry* GreatWorkHoldingBuilding(')
        b=SOURCE.index('int CvCityBuildings::GetYieldFromGreatWorks(',a)
        helpers=SOURCE[a:b]
        prefix=r'''
#include <vector>
#include <map>
#include <iostream>
#define LEKMOD_GREAT_WORK_YIELD_EFFECTS
using BuildingClassTypes=int;using BuildingTypes=int;using GreatWorkClass=int;using YieldTypes=int;using PlayerTypes=int;
const int NO_GREAT_WORK_CLASS=-1,NO_GREAT_WORK=-1,NO_PLAYER=-1,NO_BUILDING=-1,NUM_YIELD_TYPES=1,CityInfo_DIRTY_BIT=1,GreatWorksScreen_DIRTY_BIT=2;
struct BuildingGreatWork { int eBuildingClass,iSlot,iGreatWorkIndex; };
struct CvGreatWork { int m_eClassType;std::vector<int> m_viYield=std::vector<int>(1,0); };
struct CvGameCulture {
 std::vector<CvGreatWork> m_CurrentGreatWorks={{0},{1},{0}};
 int GetGreatWorkClass(int id){return m_CurrentGreatWorks.at(id).m_eClassType;}
 void MoveGreatWorks(PlayerTypes,int,int,int,int,int,int);
};
struct CvBuildingEntry { int happy;int GetGreatWorkHappiness(){return happy;} int GetGreatWorkCount(){return 1;} int GetBuildingGreatWorkYieldChange(int){return happy?4:0;} };
struct CvCity;
struct CvCityBuildings {
 CvCity* m_pCity;std::vector<BuildingGreatWork> m_aBuildingGreatWork;
 mutable bool m_bGreatWorkClassMapDirty=true;
 mutable std::map<GreatWorkClass,int> m_cachedGreatWorkClassCounts;
 int m_iHappinessFromGreatWorks=0;
 void SetBuildingGreatWork(BuildingClassTypes,int,int);
 const std::map<GreatWorkClass,int>& GetGreatWorkClassCounts() const;
 void rebuildGreatWorkYields(GreatWorkClass);
 int GetCityGreatWorkClassYieldChanges(GreatWorkClass,YieldTypes) const{return 0;}
 int GetNumBuilding(BuildingTypes id)const{return id==10||id==20?1:0;}
 int GetHeldGreatWorkYield(GreatWorkClass,BuildingClassTypes,int,YieldTypes) const;
 int GetYieldFromGreatWorks(YieldTypes) const;
 int GetBuildingGreatWork(int building,int slot){for(auto w:m_aBuildingGreatWork)if(w.eBuildingClass==building&&w.iSlot==slot)return w.iGreatWorkIndex;return -1;}
 int GetHappinessFromGreatWorks() const;
 void calculateHappinessFromGreatWorks();
};
struct CvCity {int id;CvCityBuildings buildings;CvCity(int n):id(n){buildings.m_pCity=this;} int getOwner()const{return 0;} CvCityBuildings* GetCityBuildings(){return &buildings;}const CvCityBuildings* GetCityBuildings() const{return &buildings;}};
std::vector<CvCity*> cities;
struct CvPlayerCulture {
 bool GetGreatWorkLocation(int id,int& city,int& building,int& slot){
  for(auto c:cities)for(auto w:c->buildings.m_aBuildingGreatWork)if(w.iGreatWorkIndex==id){city=c->id;building=w.eBuildingClass;slot=w.iSlot;return true;}return false;
 }
};
struct CvCivilizationInfo {int getCivilizationBuildings(int c){return c;}};
struct Player {CvCivilizationInfo civilization;CvCivilizationInfo& getCivilizationInfo(){return civilization;} CvPlayerCulture culture;int happy=0;bool isAlive(){return true;} CvCity* getCity(int id){for(auto c:cities)if(c->id==id)return c;return nullptr;} int GetGreatWorkClassYieldChange(GreatWorkClass,YieldTypes){return 0;}CvPlayerCulture* GetCulture(){return &culture;} void DoUpdateHappiness(){happy=0;for(auto c:cities)happy+=c->buildings.GetHappinessFromGreatWorks();}} player;
using CvPlayer=Player;
#define GET_PLAYER(id) player
struct Interface {void setDirty(int,bool){}};
struct Game {CvGameCulture culture;CvGameCulture* GetGameCulture(){return &culture;}};
struct WorkClassInfo {int getGreatWorkClassBaseYield(int){return 2;}};
struct Globals {WorkClassInfo classInfo;WorkClassInfo* getGreatWorkClassInfo(int){return &classInfo;} Game game;Interface ui;CvBuildingEntry hall{1},tower{0};Game& getGame(){return game;} Interface* GetEngineUserInterface(){return &ui;} CvBuildingEntry* getBuildingInfo(int id){return id==10?&hall:&tower;}} GC;
'''
        suffix=r'''
int main(){
 int failed=0,count=0;auto check=[&](const char* name,bool ok){++count;std::cout<<(ok?"PASS ":"FAIL ")<<name<<"\n";failed+=!ok;};
 CvCity a(1),b(2);cities={&a,&b};
 a.buildings.SetBuildingGreatWork(10,0,0);
 check("new-held-work-happiness",a.buildings.GetHappinessFromGreatWorks()==1&&player.happy==1);
 check("initial-class-cache",a.buildings.GetGreatWorkClassCounts().at(0)==1);
 a.buildings.SetBuildingGreatWork(10,0,-1);
 check("removed-work-happiness",a.buildings.GetHappinessFromGreatWorks()==0&&player.happy==0);
 check("removed-work-class-cache",a.buildings.GetGreatWorkClassCounts().empty());
 a.buildings.SetBuildingGreatWork(10,0,0);a.buildings.GetGreatWorkClassCounts();
 a.buildings.SetBuildingGreatWork(10,0,1);
 auto classes=a.buildings.GetGreatWorkClassCounts();
 check("replacement-class-cache",classes.size()==1&&classes.count(1)&&classes.at(1)==1);
 a.buildings.SetBuildingGreatWork(10,0,-1);b.buildings.SetBuildingGreatWork(20,0,1);
 check("cross-city-to-nonbonus-building",player.happy==0&&a.buildings.GetHappinessFromGreatWorks()==0&&b.buildings.GetHappinessFromGreatWorks()==0);
 b.buildings.SetBuildingGreatWork(20,0,-1);a.buildings.SetBuildingGreatWork(10,0,1);
 check("returned-held-work-happiness",player.happy==1);
 a.buildings.SetBuildingGreatWork(10,0,1);
 check("same-work-no-double-bonus",a.buildings.GetHappinessFromGreatWorks()==1);
 a.buildings.m_iHappinessFromGreatWorks=0;
 check("derived-cache-reset-retains-real-holdings",a.buildings.GetHappinessFromGreatWorks()==1);
 a.buildings.SetBuildingGreatWork(10,0,-1);a.buildings.SetBuildingGreatWork(10,0,0);b.buildings.SetBuildingGreatWork(20,0,2);
 check("occupied-swap-distinct-input-yields",GC.game.culture.m_CurrentGreatWorks[0].m_viYield[0]==6&&GC.game.culture.m_CurrentGreatWorks[2].m_viYield[0]==2);
 GC.game.culture.MoveGreatWorks(0,2,20,0,1,10,0);
 check("occupied-swap-higher-city-to-lower",a.buildings.GetBuildingGreatWork(10,0)==2&&b.buildings.GetBuildingGreatWork(20,0)==0&&GC.game.culture.m_CurrentGreatWorks[2].m_viYield[0]==6&&GC.game.culture.m_CurrentGreatWorks[0].m_viYield[0]==2&&player.happy==1);
 GC.game.culture.MoveGreatWorks(0,1,10,0,2,20,0);
 check("occupied-swap-lower-city-to-higher",a.buildings.GetBuildingGreatWork(10,0)==0&&b.buildings.GetBuildingGreatWork(20,0)==2&&GC.game.culture.m_CurrentGreatWorks[0].m_viYield[0]==6&&GC.game.culture.m_CurrentGreatWorks[2].m_viYield[0]==2&&player.happy==1);
 GC.game.culture.m_CurrentGreatWorks[0].m_viYield[0]=99;
 check("yield-read-ignores-stale-cache-without-mutating-it",a.buildings.GetYieldFromGreatWorks(0)==6&&b.buildings.GetYieldFromGreatWorks(0)==2&&GC.game.culture.m_CurrentGreatWorks[0].m_viYield[0]==99);
 std::cout<<count<<" state cases, "<<failed<<" failures\n";return failed?1:0;
}
'''
        with tempfile.TemporaryDirectory(prefix='lekmod-great-work-state-') as d:
            p=Path(d);(p/'test.cpp').write_text(prefix+helpers+getter+setter+counts+yields+happiness+move+suffix)
            subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
            result=subprocess.run([str(p/'test')],text=True,capture_output=True)
            print(result.stdout,end='')
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)

if __name__=='__main__': unittest.main()
