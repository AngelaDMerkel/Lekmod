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


if __name__=="__main__":
    unittest.main()
