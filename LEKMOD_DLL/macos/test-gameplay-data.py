#!/usr/bin/env python3
"""Validate shipped gameplay XML and core victory/civilization references."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]


class GameplayDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=ET.parse(ROOT/"LEKMOD/Override/CIV5Units.xml").getroot()

    def rows(self, table):
        return self.data.findall(table+"/Row")

    def types(self, table):
        return {row.findtext("Type", "").strip() for row in self.rows(table)}

    def test_core_definitions_have_unique_types_and_ids(self):
        for table in ("Civilizations","Leaders","Traits","Units","Buildings","Technologies","Policies","Beliefs","Projects"):
            rows=self.rows(table)
            self.assertTrue(rows,table)
            for field in ("Type","ID"):
                values=[r.findtext(field).strip() for r in rows if r.findtext(field) is not None]
                self.assertEqual(len(values),len(set(values)),(table,field))

    def test_spaceship_references_and_thresholds(self):
        projects=self.types("Projects");techs=self.types("Technologies")
        parts=[r for r in self.rows("Units") if r.findtext("SpaceshipProject")]
        self.assertEqual(len(parts),4)
        for row in parts:
            for field,values in (("SpaceshipProject",projects),("ProjectPrereq",projects),("PrereqTech",techs)):
                self.assertIn(row.findtext(field),values,(row.findtext("Type"),field))
        thresholds={r.findtext("ProjectType"):int(r.findtext("Threshold")) for r in self.rows("Project_VictoryThresholds") if r.findtext("VictoryType")=="VICTORY_SPACE_RACE"}
        self.assertEqual(thresholds,{"PROJECT_SS_BOOSTER":3,"PROJECT_SS_COCKPIT":1,"PROJECT_SS_STASIS_CHAMBER":1,"PROJECT_SS_ENGINE":1})

    def test_civilization_leader_trait_references(self):
        civs=self.types("Civilizations");leaders=self.types("Leaders");traits=self.types("Traits")
        links=self.rows("Civilization_Leaders")
        for row in links:
            self.assertIn(row.findtext("CivilizationType"),civs)
            self.assertIn(row.findtext("LeaderheadType"),leaders)
        for row in self.rows("Leader_Traits"):
            self.assertIn(row.findtext("LeaderType"),leaders)
            self.assertIn(row.findtext("TraitType"),traits)

    def test_unit_flag_atlases_have_valid_slots_and_shipped_custom_textures(self):
        # These named stock/DLC atlases come from Aspyr's asset packs. Every
        # custom flag must instead resolve to a file in the mod payload.
        stock={"UNIT_FLAG_ATLAS", "GENGHIS_UNIT_FLAG_ATLAS", "KAMEHAMEHA_UNIT_FLAG_ATLAS",
               "HARALD_UNIT_FLAG_ATLAS", "SEJONG_UNIT_FLAG_ATLAS", "NEB_UNIT_FLAG_ATLAS",
               "CIVIL_WAR_UNIT_FLAG_ATLAS", "EXPANSION2_UNIT_FLAG_ATLAS", "RELIGION_ATLAS_WHITE",
               "EXPANSION_UNIT_FLAG_ATLAS", "EXPANSION_SCEN_CIV_SYMBOLS_COLOR_ATLAS",
               "EXPANSION_SCEN_UNIT_FLAG_ATLAS", "DLC02_UNIT_FLAG_ATLAS",
               "SCRAMBLE_UNIT_FLAG_ATLAS", "WONDER_UNIT_FLAG_ATLAS"}
        files={p.name.casefold() for p in (ROOT/"LEKMOD").rglob("*.dds")}
        atlases={r.findtext("Atlas"):r for r in self.rows("IconTextureAtlases") if r.findtext("IconSize")=="32"}
        for unit in self.rows("Units"):
            name=unit.findtext("Type");atlas=unit.findtext("UnitFlagAtlas") or "UNIT_FLAG_ATLAS"
            self.assertIn(atlas,atlases,name)
            row=atlases[atlas];offset=int(unit.findtext("UnitFlagIconOffset","0"))
            self.assertGreaterEqual(offset,0,name)
            self.assertLess(offset,int(row.findtext("IconsPerRow"))*int(row.findtext("IconsPerColumn")),name)
            if atlas not in stock:
                self.assertTrue(row.findtext("Filename").casefold() in files,(name,atlas,row.findtext("Filename"),"missing custom flag texture"))

    def test_playable_leaders_have_scene_definitions(self):
        playable={row.findtext("Type") for row in self.rows("Civilizations")
                  if row.findtext("Playable","true").strip().lower() in ("true","1")
                  and row.findtext("Type") not in ("CIVILIZATION_MINOR","CIVILIZATION_BARBARIAN")}
        leaders={row.findtext("Type"):row for row in self.rows("Leaders")}
        for link in self.rows("Civilization_Leaders"):
            if link.findtext("CivilizationType") in playable:
                leader=link.findtext("LeaderheadType")
                self.assertTrue(leaders[leader].findtext("ArtDefineTag"),leader)
        scene=ET.parse(ROOT/"LEKMOD/Art/Lekmod (v 1)/Art/LEKMOD_StaticLeaderScene.xml").getroot()
        image=scene.get("FallbackImage")
        self.assertEqual(image,"generic_DoM.dds")
        self.assertTrue((ROOT/"LEKMOD/Art/Lekmod (v 1)/Art"/image).is_file())


if __name__=="__main__":
    unittest.main()
