#!/usr/bin/env python3
"""Regression tests for the macOS UI configurator."""

from __future__ import annotations

import importlib.util
import shutil
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


PORT_DIR = Path(__file__).resolve().parent
REPO_DIR = PORT_DIR.parent.parent
SPEC = importlib.util.spec_from_file_location(
    "lekmod_configure_ui", PORT_DIR / "configure-ui.py"
)
assert SPEC and SPEC.loader
CONFIGURE_UI = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONFIGURE_UI)


class ConfigureUiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="lekmod-ui-tests-")
        self.root = Path(self.temporary.name)
        self.lekmod = self.root / "LEKMOD"
        (self.lekmod / "Lua").mkdir(parents=True)
        shutil.copytree(REPO_DIR / "LEKMOD" / "Lua" / "tmp", self.lekmod / "Lua" / "tmp")

    def tearDown(self) -> None:
        self.temporary.cleanup()

    @property
    def output(self) -> Path:
        return self.lekmod / "Lua" / "UI"

    def test_standard_ui_includes_case_insensitive_templates(self) -> None:
        count, mode = CONFIGURE_UI.configure(self.lekmod, "standard", None)

        self.assertEqual(mode, "standard")
        self.assertEqual(count, 87)
        self.assertTrue((self.output / "CityView.xml").is_file())
        self.assertTrue((self.output / "CityView_small.xml").is_file())
        self.assertTrue((self.output / "ProductionPopup.xml").is_file())
        self.assertTrue((self.output / "PlotMouseoverInclude.lua").is_file())
        self.assertTrue((self.output / "TopPanel.lua").is_file())
        self.assertFalse((self.output / "MainMenu.xml").exists())
        self.assertTrue((self.output / "CivilopediaScreen.xml").is_file())
        self.assertIn(
            'ID="GoldenAgePointsFocusButton"',
            (self.output / "CityView.xml").read_text(encoding="utf-8"),
        )

    def test_all_ui_xml_templates_are_well_formed(self) -> None:
        for template_root in (
            self.lekmod / "Lua" / "tmp" / "ui",
            self.lekmod / "Lua" / "tmp" / "eui",
        ):
            for template in template_root.rglob("*"):
                if template.is_file() and template.name.lower().endswith(".xml.ignore"):
                    with self.subTest(template=template.relative_to(self.lekmod)):
                        ET.parse(template)

    def test_tech_tree_uses_aspyr_safe_vertical_geometry(self) -> None:
        for mode in ("ui", "eui"):
            template = (
                self.lekmod
                / "Lua"
                / "tmp"
                / mode
                / "TechTree"
                / "TechTree.xml.ignore"
            )
            root = ET.parse(template).getroot()
            controls = {
                element.get("ID"): element
                for element in root.iter()
                if element.get("ID")
            }
            with self.subTest(mode=mode):
                self.assertEqual(controls["TechTreePanel"].get("Size"), "Full,740")
                self.assertEqual(
                    controls["TechTreeScrollPanel"].get("Size"), "Full,705"
                )
                self.assertEqual(controls["EraBlock"].get("Size"), "1650,740")
                self.assertEqual(controls["OldBar"].get("Size"), "1650,722")
                self.assertEqual(controls["CurrentBlock2"].get("Size"), "1650,722")

    def test_civilopedia_close_is_in_the_header_and_has_a_visible_label(self) -> None:
        CONFIGURE_UI.configure(self.lekmod, "standard", None)
        root=ET.parse(self.output/"CivilopediaScreen.xml").getroot()
        close=root.find(".//*[@ID='CloseButton']")
        self.assertEqual(close.tag,"GridButton")
        self.assertEqual(close.get("Offset"),"36,-76")
        self.assertEqual(close.find("Label").get("String"),"X")

    def test_eui_civilopedia_provider_keeps_its_own_hierarchy(self) -> None:
        eui=self.root/"EUI";folder=eui/"Civilopedia";folder.mkdir(parents=True)
        (folder/"CivilopediaScreen.lua").write_text("-- EUI-owned context\n")
        CONFIGURE_UI.configure(self.lekmod,"eui",eui)
        self.assertFalse((self.output/"CivilopediaScreen.xml").exists())

    def test_eui_city_view_uses_matching_lua_and_xml(self) -> None:
        eui = self.root / "EUI"
        (eui / "CityView").mkdir(parents=True)
        (eui / "UnitPanel").mkdir(parents=True)
        shutil.copy2(
            self.lekmod / "Lua" / "tmp" / "eui" / "CityView" / "CityView.lua.ignore",
            eui / "CityView" / "CityView.lua",
        )
        (eui / "UnitPanel" / "UnitPanel.lua").write_text(
            "-- unsupported EUI UnitPanel variant\n", encoding="utf-8"
        )

        _, mode = CONFIGURE_UI.configure(self.lekmod, "eui", eui)

        self.assertEqual(mode, "eui")
        for output_name, template_name in (
            ("CityView.lua", "CityView.lua.ignore"),
            ("CityView.xml", "CityView.xml.IGNORE"),
            ("CityView_small.xml", "CityView_small.xml.IGNORE"),
        ):
            self.assertEqual(
                (self.output / output_name).read_bytes(),
                (
                    self.lekmod
                    / "Lua"
                    / "tmp"
                    / "eui"
                    / "CityView"
                    / template_name
                ).read_bytes(),
            )
        self.assertEqual(
            (self.output / "UnitPanel.lua").read_bytes(),
            (
                self.lekmod
                / "Lua"
                / "tmp"
                / "ui"
                / "UnitPanel"
                / "UnitPanel.lua.ignore"
            ).read_bytes(),
        )

    def test_supported_eui_unit_panel_and_production_popup(self) -> None:
        eui = self.root / "EUI"
        (eui / "UnitPanel").mkdir(parents=True)
        (eui / "CityView").mkdir(parents=True)
        shutil.copy2(
            self.lekmod / "Lua" / "tmp" / "eui" / "UnitPanel" / "UnitPanel.lua.ignore",
            eui / "UnitPanel" / "UnitPanel.lua",
        )
        (eui / "CityView" / "ProductionPopup.lua").write_text(
            "-- EUI owns this context\n", encoding="utf-8"
        )

        CONFIGURE_UI.configure(self.lekmod, "eui", eui)

        self.assertEqual(
            (self.output / "UnitPanel.lua").read_bytes(),
            (
                self.lekmod
                / "Lua"
                / "tmp"
                / "eui"
                / "UnitPanel"
                / "UnitPanel.lua.ignore"
            ).read_bytes(),
        )
        self.assertFalse((self.output / "ProductionPopup.lua").exists())
        self.assertFalse((self.output / "ProductionPopup.xml").exists())


if __name__ == "__main__":
    unittest.main()
