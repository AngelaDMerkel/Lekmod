#!/usr/bin/env python3
"""Configure Lekmod's flattened UI directory for standard UI or EUI."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path
from typing import Optional, Tuple


PRESERVED_FILES = (
    "CityStatePersonalityHelper.lua",
    "LegalScreen.lua",
    "LegalScreen.xml",
)


def copy_template(source: Path, destination: Path, name: Optional[str] = None) -> None:
    if not source.is_file():
        return
    output_name = name or source.name[: -len(".ignore")]
    shutil.copy2(source, destination / output_name)


def copy_standard_templates(source_root: Path, destination: Path) -> None:
    for source in sorted(
        path
        for path in source_root.rglob("*")
        if path.is_file() and path.name.lower().endswith(".ignore")
    ):
        # Aspyr's MainMenu hierarchy differs from the Windows XML. The Lekmod
        # Lua override works with Aspyr's native XML; replacing the XML crashes
        # while TTManager constructs the frontend controls.
        if source.relative_to(source_root).as_posix().lower() == "frontend/mainmenu.xml.ignore":
            continue
        copy_template(source, destination)


def contains(path: Path, marker: str) -> bool:
    if not path.is_file():
        return False
    return marker in path.read_text(encoding="utf-8", errors="ignore")


def configure_eui(eui_root: Path, template_root: Path, destination: Path) -> None:
    city_banners = eui_root / "CityBanners" / "CityBannerManager.lua"
    variant = "1" if contains(city_banners, "CityBannerProductionBox = function( city )") else "2"
    if city_banners.is_file():
        copy_template(
            template_root / "CityBanners" / f"CityBannerManager_{variant}.lua.ignore",
            destination,
            "CityBannerManager.lua",
        )
        copy_template(
            template_root / "CityBanners" / f"CityBannerManager_{variant}.xml.ignore",
            destination,
            "CityBannerManager.xml",
        )

    conditional_overlays = (
        ("CityStatePopup/CityStateDiploPopup.lua", "CityStatePopup/CityStateDiploPopup.lua.ignore", None),
        ("Core/CityStateStatusHelper.lua", "Core/CityStateStatusHelper.lua.ignore", None),
        ("Core/EUI_tooltip_library.lua", "Core/EUI_tooltip_library.lua.ignore", None),
        ("Core/EUI_unit_include.lua", "Core/EUI_unit_include.lua.ignore", None),
        ("EconomicGeneralInfo.lua", "EconomicGeneralInfo.lua.ignore", None),
        ("EconomicGeneralInfo.lua", "EconomicGeneralInfo.xml.ignore", None),
        ("GameSetup/SelectCivilization.lua", "GameSetup/SelectCivilization.lua.ignore", None),
        ("Improvements/SocialPolicyPopup.lua", "Improvements/SocialPolicyPopup.lua.ignore", None),
        ("Improvements/WorldView.lua", "Improvements/WorldView.lua.ignore", None),
        ("LeaderHead/TradeLogic.lua", "LeaderHead/TradeLogic.lua.ignore", None),
        ("NotificationPanel/DiploCorner.xml", "NotificationPanel/DiploCorner.lua.ignore", None),
        ("NotificationPanel/DiploCorner.xml", "NotificationPanel/DiploCorner.xml.ignore", None),
        ("NotificationPanel/NotificationPanel.lua", "NotificationPanel/NotificationPanel.lua.ignore", None),
        ("NotificationPanel/NotificationPanel.lua", "NotificationPanel/NotificationPanel.xml.ignore", None),
        ("Options/OptionsMenu.lua", "Options/OptionsMenu.lua.ignore", None),
        ("Options/OptionsMenu.lua", "Options/OptionsMenu.xml.ignore", None),
        ("TechTree/TechTree.lua", "TechTree/TechPopup.lua.ignore", None),
        ("TechTree/TechTree.lua", "TechTree/TechPopup.xml.ignore", None),
        ("TechTree/TechTree.lua", "TechTree/TechTree.lua.ignore", None),
        ("TechTree/TechTree.lua", "TechTree/TechTree.xml.ignore", None),
        ("ToolTips/InfoTooltipInclude.lua", "ToolTips/InfoTooltipInclude.lua.ignore", None),
        ("ToolTips/TechButtonInclude.lua", "ToolTips/TechButtonInclude.lua.ignore", None),
        ("TopPanel/TopPanel.lua", "TopPanel.lua.ignore", None),
        ("TopPanel/TopPanel.lua", "TopPanel.xml.IGNORE", None),
        ("Improvements/YieldIconManager.lua", "Improvements/YieldIconManager.lua.IGNORE", None),
        ("UnitFlagManager/UnitFlagManager.lua", "UnitFlagManager/UnitFlagManager.lua.ignore", None),
        ("UnitFlagManager/UnitFlagManager.lua", "UnitFlagManager/UnitFlagManager.xml.ignore", None),
    )
    for trigger, template, output_name in conditional_overlays:
        if (eui_root / trigger).is_file():
            copy_template(template_root / template, destination, output_name)

    eui_city_view = eui_root / "CityView" / "CityView.lua"
    if contains(eui_city_view, "-- coded by bc1 from 1.0.3.276 brave new world code"):
        for name in ("CityView.lua.ignore", "CityView.xml.IGNORE", "CityView_small.xml.IGNORE"):
            copy_template(template_root / "CityView" / name, destination)

    eui_unit_panel = eui_root / "UnitPanel" / "UnitPanel.lua"
    if contains(eui_unit_panel, "-- modified by bc1 from Civ V 1.0.3.276 code"):
        copy_template(template_root / "UnitPanel" / "UnitPanel.lua.ignore", destination)

    if (eui_root / "CityView" / "ProductionPopup.lua").is_file():
        for name in ("ProductionPopup.lua", "ProductionPopup.xml"):
            (destination / name).unlink(missing_ok=True)


def configure(
    lekmod_dir: Path,
    mode: str,
    eui_dir: Optional[Path],
) -> Tuple[int, str]:
    lua_dir = lekmod_dir / "Lua"
    standard_templates = lua_dir / "tmp" / "ui"
    eui_templates = lua_dir / "tmp" / "eui"
    destination = lua_dir / "UI"
    if not standard_templates.is_dir():
        raise SystemExit(f"Missing UI templates: {standard_templates}")

    if mode == "auto":
        mode = "eui" if eui_dir and eui_dir.is_dir() else "standard"
    if mode == "eui" and (not eui_dir or not eui_dir.is_dir()):
        raise SystemExit("EUI mode requested, but no valid --eui-dir was supplied")

    preserved = {
        name: (destination / name).read_bytes()
        for name in PRESERVED_FILES
        if (destination / name).is_file()
    }
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)

    copy_standard_templates(standard_templates, destination)
    if mode == "eui":
        configure_eui(eui_dir, eui_templates, destination)

    for name, data in preserved.items():
        (destination / name).write_bytes(data)

    marker = "LekmodUiConfigured = true\n"
    (destination / "LekmodUiConfigured.lua").write_text(marker, encoding="utf-8")
    utilities = lua_dir / "Utilities"
    utilities.mkdir(exist_ok=True)
    (utilities / "LekmodUiConfigured.lua").write_text(marker, encoding="utf-8")

    frontend = destination / "FrontEnd.lua"
    if frontend.is_file():
        text = frontend.read_text(encoding="utf-8")
        frontend.write_text(
            text.replace(
                "local LEKMOD_UI_CHECK_DONE = false",
                "local LEKMOD_UI_CHECK_DONE = true",
            ),
            encoding="utf-8",
        )

    return len(tuple(destination.iterdir())), mode


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lekmod-dir", type=Path, required=True)
    parser.add_argument("--mode", choices=("auto", "standard", "eui"), default="auto")
    parser.add_argument("--eui-dir", type=Path)
    args = parser.parse_args()
    count, resolved_mode = configure(
        args.lekmod_dir.resolve(),
        args.mode,
        args.eui_dir,
    )
    print(f"Configured {count} Lekmod UI files for {resolved_mode} UI")


if __name__ == "__main__":
    main()
