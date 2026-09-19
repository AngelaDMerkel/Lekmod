#!/usr/bin/env python3
"""Bounded native Civ V tests with settings, saves and failure evidence preserved.

Run only while Civ V is closed. Autorun, scripted functional checks, and native
mouse interaction are separate coverage levels; none certifies the full port.
See TESTING.md and docs/macos-testing-handoff.md before launching a test.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time


DATA = Path.home() / "Library/Application Support/Sid Meier's Civilization 5"
APP = Path.home() / "Library/Application Support/Steam/steamapps/common/Sid Meier's Civilization V/Civilization V.app"
REPO = Path(__file__).resolve().parents[2]


def command(args, timeout=15):
    return subprocess.run(args, text=True, capture_output=True, timeout=timeout)


def game_pids():
    result = command(["pgrep", "-x", "Civilization V"])
    if result.returncode not in (0, 1):
        raise RuntimeError("Cannot inspect processes: " + result.stderr)
    return [int(pid) for pid in result.stdout.split()]


def window_helper():
    helper = REPO / "build/macos/test-windows"
    source = Path(__file__).with_name("list-test-windows.m")
    if not helper.exists() or source.stat().st_mtime > helper.stat().st_mtime:
        helper.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["clang", "-framework", "AppKit", "-framework", "CoreGraphics",
                        str(source), "-o", str(helper)], check=True)
    return helper


def require_unlocked_desktop():
    status = json.loads(command([str(window_helper()), "--session-status"]).stdout)
    if not status.get("available") or status.get("on_console") is not True:
        raise SystemExit("No active local graphical session; leaving all game settings unchanged")
    if status.get("locked") is True:
        raise SystemExit("Desktop is locked; wait for unlock before launching Civ V. No settings changed")


def require_existing_steam_session():
    """Do not implicitly launch Steam/updater while preparing a game test."""
    result = command(["pgrep", "-x", "steam_osx"])
    if result.returncode != 0:
        raise RuntimeError("Steam must already be running and signed in; the runner will not start it")
    connection_log = Path.home() / "Library/Application Support/Steam/logs/connection_log.txt"
    with connection_log.open("rb") as stream:
        stream.seek(max(0, connection_log.stat().st_size - 65536))
        recent = stream.read().decode(errors="replace")
    states = re.findall(r"\[(Logged On|Logged Off|Logging On|Logging Off),", recent)
    if not states or states[-1] != "Logged On":
        raise RuntimeError("Steam has no confirmed signed-in session; test startup is disabled")


def edit_ini(text, updates):
    section = None
    found = set()
    lines = []
    for line in text.splitlines(keepends=True):
        match = re.match(r"\s*\[([^]]+)\]", line)
        if match:
            section = match.group(1)
        match = re.match(r"(\s*([^;=]+?)\s*=\s*)(.*?)(\r?\n)?$", line)
        key = (section, match.group(2).strip()) if match else None
        if key in updates:
            line = match.group(1) + str(updates[key]) + (match.group(4) or "")
            found.add(key)
        lines.append(line)
    missing = set(updates) - found
    if missing:
        raise RuntimeError("Missing configuration keys: " + str(missing))
    return "".join(lines)


def parse_window_size(value):
    match = re.fullmatch(r"(\d+)x(\d+)", value)
    if not match:
        raise argparse.ArgumentTypeError("Use WIDTHxHEIGHT, for example 1280x800")
    width, height = map(int, match.groups())
    if not 800 <= width <= 3840 or not 600 <= height <= 2160:
        raise argparse.ArgumentTypeError("Window size must be between 800x600 and 3840x2160")
    return width, height


def records(text):
    return [dict(re.findall(r"(\w+)=([^\s]+)", line))
            for line in text.splitlines() if "[LEKMOD_RENDER]" in line]


def summarize(text):
    rows = records(text)
    turns = [int(row["detail"]) for row in rows
             if row.get("event") == "game-turn.end"]
    human_turn_starts = [int(row["detail"]) for row in rows
                         if row.get("event") == "player-turn.end" and row.get("owner") == "0"]
    rollbacks = [(a, b) for a, b in zip(turns, turns[1:]) if b != a + 1]
    # Completion must include consecutive game turn ends, not callbacks merely
    # returning, barbarian phase starts, or a file's modification timestamp.
    return {"completed_turns": turns, "turn_discontinuities": rollbacks,
            "player_zero_turn_starts": human_turn_starts,
            "last_record": rows[-1] if rows else None}


def synchronization_failures(text):
    return {"rng_sync_failure": "Game Random Number Generators are out of sync" in text,
            "forced_resync": "NetForceResync" in text,
            "protocol_error": "PROTOCOL ERROR" in text}


def localization_startup_failure(database_text):
    return (bool(re.search(r"unable to open database: .*Localization-Merged\.db", database_text)) or
            ("Failed to Load database." in database_text and
             "no such table: Languages" in database_text))


def process_exit_status(mode, returncode):
    # pgrep can lose a terminating process before Popen has its exit status.
    # An unavailable status is still pending, not an early-exit failure.
    if returncode is None:
        return None
    return "ended-manual-ui-session" if mode == "ui-interaction" and returncode == 0 else "failed-early-exit"


def unresolved_driver_error(text):
    return text.rfind("[LEKMOD_TEST] ERROR") > text.rfind("[LEKMOD_TEST] driver-reloaded")


def human_turn_results(text):
    result = {"new_order_verified": "[LEKMOD_TEST] production-verified" in text,
              "inherited_order_observed": "[LEKMOD_TEST] production-inherited" in text,
              "end_turn_clicked": "[LEKMOD_TEST] end-turn-click" in text,
              "unresolved_driver_error": unresolved_driver_error(text)}
    result["verified"] = (result["end_turn_clicked"] and not result["unresolved_driver_error"] and
                          (result["new_order_verified"] or result["inherited_order_observed"]))
    return result


FUNCTIONAL_ITEMS = {"script-data", "science-overflow", "unit-position-flags", "city-focus", "avoid-growth", "tech-tree",
                    "production-unit", "production-building", "production-wonder", "production-process"}
PRODUCTION_COMPLETION_ITEMS = {"production-completion-unit", "production-completion-building"}
SCENARIO_ITEMS = {"inventory": {"system-inventory"},
                  "ideology-inventory": {"ideology-input-inventory"},
                  "setup": {"setup-configuration", "setup-options", "setup-two-human-turns"},
                  "uae-raider": {"uae-sea-plunder", "uae-raider-experience", "uae-raider-movement"},
                  "aksum-heal-domain": {"church-land-faith", "church-sea-exclusion", "church-air-exclusion", "church-distance-exclusion"},
                  "great-person-builds": {"academy", "manufactory", "customs-house", "holy-site", "citadel", "great-person-build-restrictions", "spent-prophet-build-rejection"},
                  "anarchy-expiry": {"anarchy-yield-restrictions", "anarchy-natural-expiry"},
                  "budget-science": {"budget-science-boundaries", "treasury-restored"},
                  "budget-settlement": {"deficit-gold-floor", "deficit-research-floor", "budget-recovery-settlement"},
                  "mexico-discovery": {"mexico-starting-locations", "mexico-start-human", "mexico-start-ai", "mexico-distance-control"},
                  "mexico-pottery": {"mexico-human-worker", "mexico-AI-worker", "mexico-worker-no-repeat"},
                  "mexico-ranchero": {"ranchero-selection", "ranchero-growth-during-training"},
                  "mexico-hacienda": {"hacienda-construction", "hacienda-resource-classes", "hacienda-no-maintenance"},
                  "mexico-influence": {"mexico-afraid-rate", "mexico-afraid-accrual", "mexico-tribute-boundary"},
                  "phoenicia-founding": {"phoenicia-before-Optics", "phoenicia-after-Optics", "phoenicia-existing-city", "phoenicia-AI-owner", "phoenicia-other-owner"},
                  "philippines-founding": {"philippines-capital", "philippines-first-two", "philippines-third-excluded", "philippines-other-owner"},
                  "philippines-loss": {"philippines-real-city-loss", "philippines-lifetime-quota"},
                  "philippines-movement": {"philippines-civilian-move-limits", "philippines-move-refresh", "philippines-move-controls"},
                  "philippines-church": {"church-prerequisites", "church-construction-yields", "church-production-XP"},
                  "philippines-gerilya": {"gerilya-strength-control", "gerilya-normal-embark", "gerilya-embarked-refresh"},
                  "philippines-gerilya-return": {"gerilya-normal-disembark", "gerilya-land-move-boundary"},
                  "oman-minaa": {"minaa-enemy-sea", "minaa-embarked", "minaa-lethal-stack", "minaa-own-land-distance-controls"},
                  "ottoman-promotions": {"ottoman-human-first", "ottoman-human-second", "ottoman-AI-faith", "promotion-other-owner-no-faith"},
                  "kilwa-expiry": {"kilwa-natural-expiry", "kilwa-expiry-markers", "kilwa-returned-caravans", "kilwa-expired-cargo"},
                  "kilwa-routes": {"kilwa-first-route", "kilwa-second-route", "kilwa-internal-exclusion", "kilwa-internal-gold", "kilwa-owner-city-controls", "kilwa-food-settlement"},
                  "greatwork-exchange-verify": {"exchange-controllers", "exchange-slot-counts", "exchange-theme-yields", "exchange-offers-cleared"},
                  "greatwork-exchange-prep": {"foreign-works-created", "foreign-work-offer", "exchange-ready"},
                  "trade-incoming": {"incoming-route-creation", "incoming-route-identity", "incoming-route-accounting", "incoming-route-tooltip", "incoming-route-tourism"},
                  "trade-tooltip": {"trade-tooltip-food-precision", "trade-tooltip-production-precision", "trade-tooltip-data-preserved"},
                  "nuclear": {"nuclear-range-restrictions", "nuclear-unit-blast-radius", "nuclear-immunity", "nuclear-fallout-pillage", "nuclear-missile-consumption"},
                  "admiral-repair": {"admiral-fleet-heal", "admiral-embarked-heal", "admiral-owner-domain-radius-controls", "admiral-consumption"},
                  "moors-eras": {"moors-Medieval-human-AI", "moors-Renaissance-team-isolation", "moors-Renaissance-founding", "moors-Industrial-expiry", "moors-Roman-control"},
                  "moors-founding": {"moors-immediate-founded-city-bonus"},
                  "cuba-capital": {"cuba-unmet-capital", "cuba-met-capital-counts", "cuba-capital-bonus-decrease", "cuba-capital-owner-control"},
                  "maori-gift-repair": {"maori-inherited-save-expiry"},
                  "maori-gift": {"maori-gift-owner-transfer", "maori-gift-maori-expiry", "maori-gift-foreign-expiry"},
                  "maori-era": {"maori-later-era-opening-window", "maori-later-era-expiry"},
                  "maori-trained": {"maori-trained-first-turn", "maori-trained-next-turn"},
                  "maori-stack": {"maori-worker-stack-preserved", "maori-general-stack-preserved"},
                  "maori-refresh": {"maori-expired-move-budget"},
                  "maori-movement": {"maori-initial-moves-sight", "maori-recon-air-controls", "maori-first-five-expiry", "maori-late-created-bonus", "maori-late-next-turn-expiry", "maori-AI-owner-expiry"},
                  "tonga-vision": {"tonga-singleton-islands", "tonga-near-islands", "tonga-native-area-identity", "tonga-other-owner-vision"},
                  "diversity-yields": {"candi-minority-faith", "candi-minority-removal", "gurdwara-minority-yields", "diversity-building-other-owner"},
                  "ottoman-diversity": {"ottoman-pantheon-excluded", "ottoman-one-religion", "ottoman-minority-happiness", "ottoman-three-religions", "ottoman-diversity-removal", "diversity-other-owner-control"},
                  "ideology-pressure": {"foreign-concert-pressure", "pressure-below-victory"},
                  "ideology-switch": {"revolution-cancel", "revolution-confirm", "revolution-tenets-culture", "revolution-content-rejection"},
                  "espionage": {"spy-home", "spy-recall", "spy-foreign", "spy-diplomat"},
                  "religion": {"pantheon", "religion-found", "religion-enhance", "faith-purchase", "religion-spread"},
                  "religion-defense": {"inquisitor-purchase", "inquisitor-defense", "foreign-religion-spread", "remove-heresy", "inquisitor-retention", "inquisitor-restrictions"},
                  "religion-benefits": {"religion-purchase-restrictions", "first-conversion-gold", "faith-building-purchase", "mandir-luxury-yields", "holy-warriors-purchase"},
                  "religion-reconversion": {"prophet-foreign-conversion", "conversion-bonus-no-repeat", "religious-building-retained"},
                  "trade": {"gold-unit-purchase", "trade-route", "trade-yield", "trade-income"},
                  "congress": {"congress-found", "congress-propose", "congress-vote", "congress-resolve", "wonder-completion", "process-income"},
                  "unit-owners": {"minor-defender", "minor-hover", "barbarian-hover"},
                  "unit-actions": {"unit-promotion", "unit-upgrade", "unit-healing", "unit-embark", "unit-disembark", "unit-restrictions"},
                  "worker": {"worker-farm", "worker-road", "worker-repair", "worker-restrictions"},
                  "buganda-lake": {"buganda-lake-build", "buganda-lake-freshwater", "buganda-lake-restrictions"},
                  "combat": {"land-ranged", "land-melee", "combat-unit-death", "civilian-capture", "city-ranged", "naval-ranged", "air-strike", "combat-restrictions"},
                  "unit-utility": {"unit-disband-cancel", "unit-disband", "unit-gift", "gift-restrictions", "merchant-mission", "scientist-discovery", "engineer-hurry"},
                  "air-operations": {"air-interception", "air-sweep", "carrier-rebase", "carrier-capacity", "carrier-movement"},
                  "pillage-road": {"own-pillage-rejection", "farm-pillage", "road-pillage", "road-repair", "road-travel"},
                  "georgia": {"georgia-before-golden-age", "georgia-existing-golden-age", "georgia-new-golden-age", "georgia-golden-age-expired"},
                  "georgia-upgrade": {"georgia-paid-upgrade", "georgia-upgrade-golden-age", "georgia-gift-away"},
                  "greatworks": {"art-created", "museum-themed", "great-work-swap", "great-work-cross-city", "theming-removed", "theming-restored"},
                  "cuba-greatworks": {"cuba-music-bonus", "cuba-music-removal", "cuba-music-return", "cuba-occupied-swap"},
                  "archaeology": {"artifact-dig", "archaeology-cancel", "artifact-created", "landmark-dig", "landmark-created", "landmark-yield-preview", "archaeology-restrictions"},
                  "cuba-ideology": {"ideology-cancel", "ideology-selected", "tenet-cancel", "cuba-first-tenet-reward", "cuba-later-tenet-no-repeat", "tenet-restrictions"},
                  "diplomacy-assets": {"resource-gift", "gpt-gift", "mutual-embassies", "open-borders-gift", "diplomacy-trade-restrictions", "gpt-settlement"},
                  "diplomacy-expiry": {"diplomatic-contract-expiry", "expired-diplomatic-accounting", "embassies-permanent"},
                  "diplomacy-friendship": {"friendship-request", "friendship-agreement", "duplicate-friendship-rejected"},
                  "diplomacy-friendship-prepared": {"friendship-request", "friendship-agreement", "duplicate-friendship-rejected"},
                  "diplomacy-friendship-mature": {"friendship-request", "friendship-agreement", "duplicate-friendship-rejected"},
                  "friendship-observe": {"friendship-dialog-result"},
                  "diplomacy-denounce": {"denounce-cancel", "denounce-confirm", "denounce-state"},
                  "diplomacy-pact": {"research-agreement-configured-off", "research-agreement-ui", "pact-create", "pact-war-restriction"},
                  "pact-expiry": {"pact-duration", "pact-expiry", "war-eligibility-restored"},
                  "disabled-agreements": {"disabled-research-ui", "disabled-trade-ui"},
                  "diplomacy-peace": {"peace-negotiation", "peace-accepted", "peace-war-restriction"},
                  "peace-expiry": {"peace-duration", "peace-expiry", "post-peace-war-eligibility"},
                  "trade-internal": {"trade-rebase-cancel", "trade-rebase", "internal-land-food", "internal-sea-production", "internal-route-restrictions"},
                  "trade-expiry": {"trade-expiry", "expired-trade-units-return", "expired-trade-yields-cleared"},
                  "trade-progress": {"trade-progress-observed"},
                  "trade-countdown": {"trade-list-countdowns"},
                  "trade-plunder": {"plunder-peace-rejection", "plunder-own-rejection", "plunder-noncombat-rejection", "trade-plunder", "plunder-yields-cleared"},
                  "palmyra": {"palmyra-founded-water", "palmyra-capture-water"},
                  "venice": {"venice-first-compass", "venice-second-compass", "venice-idempotent-tech"},
                  "venice-known-compass": {"venice-known-compass-awards"},
                  "italy": {"italy-human-points", "italy-AI-points", "italy-human-extension", "italy-AI-extension"},
                  "city-basics": {"additional-city", "building-purchase", "building-sale-cancel", "building-sale", "city-growth", "city-starvation"},
                  "city-capture": {"secondary-capture", "city-puppet", "city-annex", "city-raze", "city-liberation"},
                  "minor-greeting": {"minor-personality-greeting"},
                  "espionage-mission": {"spy-surveillance", "spy-science", "spy-return"},
                  "espionage-election": {"counterspy-arrival", "minor-spy-surveillance", "spy-election", "spy-coup-outcome", "coup-restrictions"},
                  "espionage-coup-zero": {"coup-zero-chance", "coup-failure", "dead-spy-restrictions"},
                  "spy-replacement": {"dead-spy-wait", "spy-replacement"},
                  "diplomat-arrival": {"diplomat-arrival"},
                  "diplomacy": {"diplomacy-open", "diplomacy-gift"},
                  "city-queue": {"city-queue-ready"},
                  "endgame": {"score-victory", "endgame-panel"},
                  "bolivia": {"colorado-created", "bolivia-artist", "bolivia-writer"},
                  "mughals": {"mughal-conversion", "mughal-conversion-cleanup", "mughal-reconversion"},
                  "domination": {"war-declaration", "capital-combat", "capital-capture", "domination-victory", "victory-panel"},
                  "culture-prelaunch": {"great-work", "passive-tourism", "concert-tourism", "concert-location-rejection", "culture-prelaunch"},
                  "culture-launch": {"culture-threshold", "cultural-victory", "victory-panel"},
                  "diplo-victory-prelaunch": {"city-state-gifts", "city-state-gift-rejection", "un-session", "world-leader-ready"},
                  "diplo-victory-resume": {"un-session", "world-leader-ready"},
                  "diplo-victory-launch": {"world-leader-choices", "world-leader-vote", "diplomatic-victory", "victory-panel"},
                  "science-prelaunch": {"apollo-completion", "space-parts-production", "space-assembly", "space-location-rejection", "space-prelaunch"},
                  "science-launch": {"science-final-part", "science-victory", "victory-panel"}}


def functional_results(text, run, required=FUNCTIONAL_ITEMS):
    rows = [dict(re.findall(r"(\w+)=([^\s]+)", line)) for line in text.splitlines()
            if "[LEKMOD_FUNCTIONAL]" in line]
    rows = [row for row in rows if row.get("run") == run]
    outcomes = {row["item"]: row["status"] for row in rows if "item" in row and "status" in row}
    failed = any(row.get("status") == "FAIL" for row in rows)
    complete = any(row.get("event") == "complete" for row in rows)
    verified = (complete and not failed and required <= outcomes.keys()
                and all(outcomes[item] in ("PASS", "SKIP") for item in required))
    return {"outcomes": outcomes, "failed": failed, "complete": complete, "verified": verified,
            "skipped": [item for item in sorted(outcomes) if outcomes[item] == "SKIP"]}


def production_completion_results(text, run):
    result = functional_results(text, run, PRODUCTION_COMPLETION_ITEMS)
    result["verified"] = result["verified"] and not result["skipped"]
    return result


def state_fingerprints(text, run):
    return re.findall(r"\[LEKMOD_FUNCTIONAL\] run=" + re.escape(run) +
                      r" event=save-state value=([^\r\n]+)", text)


def congress_resolution_results(render_text, lua_text, run):
    found = {}
    for event in ("congress-proposal", "congress-resolved"):
        matches = re.findall(r"\[LEKMOD_FUNCTIONAL\] run=" + re.escape(run) +
            r" event=" + event + r" value=([^\r\n]+)", lua_text)
        if matches:
            found[event] = json.loads(matches[-1])
    if len(found) != 2:
        return {"verified": False, "reason": "missing proposal/resolution snapshot"}
    proposal, outcome = found["congress-proposal"], found["congress-resolved"]
    rows = [row for row in records(render_text) if row.get("event") in ("league-enact.passed", "league-enact.failed")
        and row.get("owner") == "0" and row.get("id") == str(proposal["id"]) and row.get("type") == str(proposal["type"])]
    if len(rows) != 1:
        return {"verified": False, "reason": "expected one matching engine resolution result", "matches": rows}
    passed = rows[0]["event"] == "league-enact.passed"
    return {"verified": outcome["id"] == proposal["id"] and outcome["active"] == passed,
            "proposal": proposal, "engine_passed": passed, "active_after_session": outcome["active"]}


def refresh_live_driver(evidence):
    evidence = evidence.resolve()
    evidence.relative_to(REPO / "build/macos/playtests")
    state = json.loads((evidence / "run-state.json").read_text())
    if not state.get("live_driver_control") or state.get("pid") not in game_pids():
        raise SystemExit("No live, controllable test instance in this evidence directory")
    ui_dir = APP / "Contents/Assets/Assets/DLC/LEKMOD/Lua/UI"
    driver = ui_dir / "LekmodTestDriver.lua"
    commands = ui_dir / "LekmodTestCommands.lua"
    if not driver.is_file() or not commands.is_file():
        raise SystemExit("Temporary live-control files are missing; refusing to create them for an unrelated game")
    revision = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    driver.write_bytes(Path(__file__).with_name("playtest-human.lua").read_bytes())
    token = json.dumps(revision)
    commands.write_text("if LEKMOD_TEST_COMMAND_REVISION ~= " + token + " then\n"
                        "  LEKMOD_TEST_COMMAND_REVISION = " + token + "\n"
                        '  include("LekmodTestDriver.lua")\n'
                        '  print("[LEKMOD_TEST] driver-reloaded revision=" .. LEKMOD_TEST_COMMAND_REVISION)\n'
                        "end\n")
    print(json.dumps({"event": "driver-refresh-requested", "revision": revision, "pid": state["pid"]}), flush=True)
    return 0


def preserve_injected_ui(evidence, app, path, contents):
    """Retain exact initial test-hook bytes, including rendered run parameters."""
    relative = path.relative_to(app)
    destination = evidence / "ui-injected" / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(contents)
    return {"path": relative.as_posix(), "sha256": hashlib.sha256(contents).hexdigest(),
            "size": len(contents)}


def capture_game_window(pid, destination):
    """Capture only the test PID's window, without activation or desktop capture."""
    helper = window_helper()
    result = command([str(helper)])
    windows = [w for w in json.loads(result.stdout) if w.get("kCGWindowOwnerPID") == pid]
    windows = [w for w in windows if w.get("kCGWindowBounds", {}).get("Width", 0) > 100
               and w.get("kCGWindowBounds", {}).get("Height", 0) > 100]
    if windows:
        window = max(windows, key=lambda w: w["kCGWindowBounds"]["Width"] * w["kCGWindowBounds"]["Height"])
        result = command(["screencapture", "-x", "-o", "-l", str(window["kCGWindowNumber"]), str(destination)])
        if result.returncode == 0:
            return True
    independent = REPO / "build/macos/capture-test-window"
    if independent.exists():
        return command([str(independent), str(pid), str(destination)]).returncode == 0
    return False



SINGLE_PLAYER_SETUP_OPTIONS = frozenset({
    "GAMEOPTION_NO_BARBARIANS", "GAMEOPTION_RAGING_BARBARIANS", "GAMEOPTION_NO_GOODY_HUTS",
    "GAMEOPTION_NO_SCIENCE", "GAMEOPTION_NO_POLICIES", "GAMEOPTION_NO_RELIGION",
    "GAMEOPTION_NO_ESPIONAGE", "GAMEOPTION_ONE_CITY_CHALLENGE", "GAMEOPTION_NO_CITY_RAZING",
    "GAMEOPTION_ALWAYS_PEACE",
})

def parse_slot_civilization(value):
    match = re.fullmatch(r"([1-9]|1[01])=(CIVILIZATION_[A-Z0-9_]+)", value)
    if not match:
        raise argparse.ArgumentTypeError("Use AI_SLOT=CIVILIZATION_TYPE with an AI slot from 1 to 11")
    return int(match[1]), match[2]


def parse_start_era(value):
    # The shipped Atomic/Information UI eras retain their older internal IDs.
    value = {"ERA_ATOMIC": "ERA_POSTMODERN", "ERA_INFORMATION": "ERA_FUTURE"}.get(value, value)
    if value not in {"ERA_ANCIENT", "ERA_CLASSICAL", "ERA_MEDIEVAL", "ERA_RENAISSANCE", "ERA_INDUSTRIAL", "ERA_MODERN", "ERA_POSTMODERN", "ERA_FUTURE"}:
        raise argparse.ArgumentTypeError("Unknown normal starting era")
    return value

def parse_game_option(value):
    match = re.fullmatch(r"(GAMEOPTION_[A-Z0-9_]+)=([01])", value)
    if not match or match[1] not in SINGLE_PLAYER_SETUP_OPTIONS:
        raise argparse.ArgumentTypeError("Use an allowed single-player GAMEOPTION_TYPE=0|1")
    return match[1], int(match[2])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--turns", type=int, default=100)
    parser.add_argument("--timeout", type=int, default=7200)
    parser.add_argument("--stall-seconds", type=int, default=90)
    parser.add_argument("--startup-timeout", type=int, default=60)
    parser.add_argument("--quick-start", type=int, choices=(0, 1), default=0, help="Temporary QuickStart setting; use normal menu startup by default")
    parser.add_argument("--skip-intro", type=int, choices=(0, 1), default=1, help="Temporary SkipIntroVideo setting for startup controls")
    parser.add_argument("--world-size", default="WORLDSIZE_HUGE")
    parser.add_argument("--map-script", choices=("Continents.lua", "Pangaea.lua", "Archipelago.lua", "Fractal.lua", "SmallContinents.lua", "Lakes.lua"), default="Continents.lua")
    parser.add_argument("--game-speed", choices=tuple("GAMESPEED_" + s for s in ("QUICK", "STANDARD", "EPIC", "MARATHON")), default="GAMESPEED_QUICK")
    parser.add_argument("--handicap", choices=tuple("HANDICAP_" + s for s in ("SETTLER", "CHIEFTAIN", "WARLORD", "PRINCE", "KING", "EMPEROR", "IMMORTAL", "DEITY")), default="HANDICAP_PRINCE", help="Normal human difficulty selection; AI slot defaults remain Prince")
    parser.add_argument("--game-option", action="append", type=parse_game_option, default=[], help="Explicit single-player setup option, GAMEOPTION_TYPE=0|1; repeat for distinct options")
    parser.add_argument("--start-era", type=parse_start_era, default="ERA_ANCIENT", help="Normal starting era; Atomic/Information aliases map to POSTMODERN/FUTURE; ignored when loading")
    parser.add_argument("--civilization", default="CIVILIZATION_ROME", help="Normal player-zero civilization selection for new fixtures")
    parser.add_argument("--opponent-civilization", default="", help="Optional normal AI slot-one civilization selection for new single-player fixtures")
    parser.add_argument("--slot-civilization", action="append", type=parse_slot_civilization, default=[], help="Normal civilization selection for a specific AI slot, SLOT=CIVILIZATION_TYPE")
    parser.add_argument("--window-size", type=parse_window_size, help="Temporary windowed resolution, with GraphicsSettingsDX9.ini restored afterward")
    parser.add_argument("--majors", type=int, default=12)
    parser.add_argument("--minors", type=int, default=40)
    parser.add_argument("--mode", choices=("autorun", "human-turns", "single-player-smoke", "ui-interaction"), default="autorun")
    parser.add_argument("--load-save", type=Path, help="Load a fixture in a human test mode; --turns counts additional completions only in human-turns mode")
    parser.add_argument("--refresh-driver", type=Path, metavar="EVIDENCE", help="Refresh only an existing test's Lua driver; does not launch or activate anything")
    parser.add_argument("--save-and-exit", action="store_true", help="After functional checks, use the normal local save and exit callbacks")
    parser.add_argument("--capture-panels", action="store_true", help="Capture only the test game's tech-tree and production windows during functional checks")
    parser.add_argument("--city-controls", action="store_true", help="Exercise all nine city-focus callbacks and avoid-growth in the actual CityView context")
    parser.add_argument("--production-completion", action="store_true", help="Bounded Worker/Water Mill completion fixture through normal orders and at most three scripted human turns")
    parser.add_argument("--scenario", choices=tuple(SCENARIO_ITEMS), help="Focused standard-UI scenario; inventory is read-only")
    parser.add_argument("--scenario-turns", type=int, default=0, help="Explicit maximum turns a scenario may request through the normal human driver (0-30)")
    parser.add_argument("--expect-human-victory", action="store_true", help="Require the endgame scenario's naturally resolved score winner to be the human")
    parser.add_argument("--foreground-ui-test", "--foreground-attachment-test", dest="foreground_attachment_test", action="store_true", help="Explicitly approved foreground UI test; specify --timeout (at most one hour)")
    parser.add_argument("--no-process-adapter", action="store_true", help="Explicit foreground startup control with no injected process library; requires --foreground-ui-test")
    parser.add_argument("--trace-loaded-libraries", action="store_true", help="Record dyld image loading in the test process log for startup diagnosis")
    parser.add_argument("--activation-only", action="store_true", help="Startup diagnostic control: retain background activation guard without syscall/stream observers or a log-flush timer")
    parser.add_argument("--expected-state", type=Path, help="Verify the saved-state fingerprint from an earlier --save-and-exit report before any functional mutations")
    args = parser.parse_args()
    if len(dict(args.game_option)) != len(args.game_option):
        parser.error("Do not specify a game option more than once")
    if len(dict(args.slot_civilization)) != len(args.slot_civilization):
        parser.error("Do not assign an AI civilization slot more than once")
    if any(slot >= args.majors for slot, _ in args.slot_civilization):
        parser.error("AI civilization overrides require an enabled major slot")
    if args.opponent_civilization and 1 in dict(args.slot_civilization):
        parser.error("Do not combine --opponent-civilization with a slot-one override")
    if args.refresh_driver:
        return refresh_live_driver(args.refresh_driver)
    if args.turns < 3 or args.timeout < 30 or args.stall_seconds < 5 or args.startup_timeout < 5:
        parser.error("Use at least three turns, a total timeout of 30 seconds, and other timeouts of five seconds")
    if not 2 <= args.majors <= 12 or not 0 <= args.minors <= 41:
        parser.error("Use 2-12 major civilizations and 0-41 city states")
    if not re.fullmatch(r"CIVILIZATION_[A-Z0-9_]+", args.civilization):
        parser.error("--civilization requires a CIVILIZATION_TYPE identifier")
    if args.opponent_civilization and not re.fullmatch(r"CIVILIZATION_[A-Z0-9_]+", args.opponent_civilization):
        parser.error("--opponent-civilization requires a CIVILIZATION_TYPE identifier")
    if args.load_save:
        args.load_save = args.load_save.resolve()
        if args.mode == "autorun" or not args.load_save.is_file() or args.load_save.suffix.lower() != ".civ5save":
            parser.error("--load-save requires an existing Civ5Save file and a human test mode")
    if (args.save_and_exit or args.expected_state or args.capture_panels or args.city_controls) and args.mode != "single-player-smoke":
        parser.error("Save/reload checks require --mode single-player-smoke")
    if args.no_process_adapter and (not args.foreground_attachment_test or args.activation_only):
        parser.error("--no-process-adapter requires explicit foreground control and cannot combine with --activation-only")
    if args.foreground_attachment_test and (args.mode not in ("ui-interaction", "single-player-smoke") or args.timeout > 3600):
        parser.error("Foreground UI tests require --mode ui-interaction or single-player-smoke and --timeout at most 3600; the flag does not grant user permission")
    if args.production_completion and (args.mode != "human-turns" or args.turns != 3 or not args.load_save or args.timeout > 600):
        parser.error("Production completion requires --mode human-turns, --turns 3, --load-save and --timeout at most 600")
    if args.scenario and (args.mode != "single-player-smoke" or (not args.load_save and args.scenario not in ("congress", "endgame", "bolivia", "mughals", "worker", "buganda-lake", "georgia", "georgia-upgrade", "cuba-greatworks", "cuba-ideology", "diplomacy-assets", "palmyra", "venice", "venice-known-compass", "italy", "setup", "uae-raider", "aksum-heal-domain", "budget-settlement", "mexico-discovery", "phoenicia-founding", "philippines-founding", "oman-minaa", "ottoman-promotions", "tonga-vision", "maori-movement", "maori-era", "cuba-capital", "moors-founding", "kilwa-routes")) or args.city_controls or args.timeout > 1800):
        parser.error("Scenarios require --mode single-player-smoke, --load-save (except congress/endgame/bolivia/mughals/worker/buganda-lake/georgia/georgia-upgrade/cuba-greatworks/cuba-ideology/diplomacy-assets/palmyra/venice/venice-known-compass/italy/setup/uae-raider/aksum-heal-domain/budget-settlement/mexico-discovery/phoenicia-founding/philippines-founding/oman-minaa/ottoman-promotions/tonga-vision/maori-movement/maori-era/cuba-capital/moors-founding/kilwa-routes), no --city-controls and --timeout at most 1800")
    if args.scenario == "endgame" and (args.load_save or args.expected_state or args.save_and_exit or args.scenario_turns != 2):
        parser.error("Endgame requires a new two-turn scenario, without save/reload options")
    if args.expect_human_victory and args.scenario != "endgame":
        parser.error("--expect-human-victory is only a score-endgame assertion")
    if args.scenario == "science-launch" and (args.save_and_exit or args.expected_state or not 1 <= args.scenario_turns <= 3):
        parser.error("Science launch requires a loaded prelaunch fixture, 1-3 ordinary turns and no save/reload options")
    if args.scenario == "domination" and (args.save_and_exit or args.expected_state or not 1 <= args.scenario_turns <= 6):
        parser.error("Domination requires a loaded Duel fixture, 1-6 ordinary turns and no save/reload options")
    if args.scenario == "culture-launch" and (args.save_and_exit or args.expected_state or not 1 <= args.scenario_turns <= 3):
        parser.error("Cultural launch requires a loaded pre-victory fixture, 1-3 ordinary turns and no save/reload options")
    if args.scenario == "diplo-victory-launch" and (args.save_and_exit or args.expected_state or not 1 <= args.scenario_turns <= 3):
        parser.error("Diplomatic launch requires a loaded ballot fixture, 1-3 ordinary turns and no save/reload options")
    if not 0 <= args.scenario_turns <= 30 or (args.scenario_turns and not args.scenario):
        parser.error("--scenario-turns requires a scenario and a bound from 0 to 30")
    eui_root = APP / "Contents/Assets/Assets/DLC/UI_bc1"
    has_eui = eui_root.is_dir()
    if has_eui and ((args.mode == "single-player-smoke" and args.scenario != "inventory") or args.production_completion):
        parser.error("Only read-only inventory with shared save/exit adapters, human-turns, and ui-interaction support EUI")
    required_functional_items = SCENARIO_ITEMS[args.scenario] if args.scenario else FUNCTIONAL_ITEMS
    if args.scenario and args.expected_state:
        required_functional_items = {"save-reload"}
    expected_state = None
    if args.expected_state:
        expected_state = json.loads(args.expected_state.read_text())["saved_state"]
    if game_pids():
        raise SystemExit("Civilization V is already open; refusing to disturb it")
    require_unlocked_desktop()
    require_existing_steam_session()
    config = DATA / "config.ini"
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    save_name = "Lekmod-Functional-" + stamp
    generated_save = DATA / "Saves/single" / (save_name + ".Civ5Save")
    if args.save_and_exit and generated_save.exists():
        raise SystemExit("Test save name already exists; refusing to overwrite it")
    output = REPO / "build/macos/playtests" / stamp
    output.mkdir(parents=True)
    original = config.read_bytes()
    (output / "config.ini.original").write_bytes(original)
    user_settings = DATA / "UserSettings.ini"
    original_user_settings = user_settings.read_bytes()
    (output / "UserSettings.ini.original").write_bytes(original_user_settings)
    graphics_settings = DATA / "GraphicsSettingsDX9.ini"
    original_graphics = graphics_settings.read_bytes() if args.window_size else None
    if original_graphics is not None:
        (output / "GraphicsSettingsDX9.ini.original").write_bytes(original_graphics)
    manual_saves = {path: path.read_bytes() for path in (DATA / "Saves/single").glob("*.Civ5Save")}
    manual_backup = output / "manual-saves-before"
    manual_backup.mkdir()
    for path, data in manual_saves.items():
        (manual_backup / path.name).write_bytes(data)
    frontend = APP / "Contents/Assets/Assets/UI/FrontEnd"
    menu_paths = [frontend / "MainMenu.lua",
                  APP / "Contents/Assets/Assets/DLC/LEKMOD/Lua/UI/MainMenu.lua"]
    ui_templates = {path: "playtest-start.lua" for path in menu_paths if path.exists()}
    loading_screen = eui_root / "GameSetup/LoadScreen.lua" if has_eui else frontend / "LoadScreen.lua"
    ui_templates[loading_screen] = "playtest-loaded.lua"
    if args.mode == "ui-interaction":
        observer_ui = APP / "Contents/Assets/Assets/DLC/LEKMOD/Lua/UI"
        observer_module = observer_ui / "LekmodTestObserver.lua"
        if observer_module.exists():
            raise SystemExit("Temporary observer module already exists")
        ui_templates[observer_ui / "InGame.lua"] = "playtest-ui-observer-bootstrap.lua"
        ui_templates[observer_module] = "playtest-ui-observer.lua"
    if args.mode == "single-player-smoke":
        ui_dir = APP / "Contents/Assets/Assets/DLC/LEKMOD/Lua/UI"
        base_templates = () if args.scenario else (("ActionInfoPanel.lua", "playtest-single-player.lua"),
                               ("ProductionPopup.lua", "playtest-production.lua"),
                               ("TechTree.lua", "playtest-tech-tree.lua"))
        for name, template in base_templates:
            if not (ui_dir / name).is_file():
                raise SystemExit("Focused suite currently requires standard UI: missing " + name)
            ui_templates[ui_dir / name] = template
        if args.city_controls:
            ui_templates[ui_dir / "CityView.lua"] = "playtest-city-view.lua"
        if args.scenario:
            ui_templates[ui_dir / "ActionInfoPanel.lua"] = "playtest-scenario-bootstrap.lua"
            for name, template in (("LekmodTestScenarioCore.lua", "playtest-scenario-core.lua"),
                                   ("LekmodTestScenario.lua", "playtest-scenario-" + args.scenario + ".lua")):
                if (ui_dir / name).exists():
                    raise SystemExit("Temporary scenario file already exists: " + str(ui_dir / name))
                ui_templates[ui_dir / name] = template
            if args.scenario == "religion":
                popups = APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/Popups"
                ui_templates[popups / "ChoosePantheonPopup.lua"] = "playtest-scenario-pantheon-popup.lua"
                ui_templates[popups / "ChooseReligionPopup.lua"] = "playtest-scenario-religion-popup.lua"
                ui_templates[ui_dir / "ProductionPopup.lua"] = "playtest-scenario-purchase-popup.lua"
            if args.scenario in ("religion-defense", "religion-benefits"):
                ui_templates[ui_dir / "ProductionPopup.lua"] = "playtest-scenario-purchase-popup.lua"
            if args.scenario == "trade":
                ui_templates[ui_dir / "ProductionPopup.lua"] = "playtest-scenario-purchase-popup.lua"
                ui_templates[ui_dir / "ChooseInternationalTradeRoutePopup.lua"] = "playtest-scenario-trade-popup.lua"
            if args.scenario == "trade-internal":
                ui_templates[ui_dir / "ChooseInternationalTradeRoutePopup.lua"] = "playtest-scenario-trade-popup.lua"
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/Popups/ChooseTradeUnitNewHome.lua"] = "playtest-scenario-trade-home-popup.lua"
            if args.scenario == "city-basics":
                ui_templates[ui_dir / "ProductionPopup.lua"] = "playtest-scenario-purchase-popup.lua"
                ui_templates[ui_dir / "CityView.lua"] = "playtest-scenario-city-sale.lua"
            if args.scenario in ("city-capture", "palmyra"):
                ui_templates[APP / "Contents/Assets/Assets/UI/InGame/Popups/GenericPopup.lua"] = "playtest-scenario-city-capture-popup.lua"
            if args.scenario == "unit-utility":
                ui_templates[APP / "Contents/Assets/Assets/UI/InGame/Popups/GenericPopup.lua"] = "playtest-scenario-unit-confirm.lua"
            if args.scenario == "minor-greeting":
                ui_templates[ui_dir / "CityStateGreetingPopup.lua"] = "playtest-scenario-minor-greeting-popup.lua"
            if args.scenario == "archaeology":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/Popups/ChooseArchaeologyPopup.lua"] = "playtest-scenario-archaeology-popup.lua"
            if args.scenario == "ideology-switch":
                ui_templates[ui_dir / "SocialPolicyPopup.lua"] = "playtest-scenario-revolution-popup.lua"
            if args.scenario == "cuba-ideology":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/Popups/ChooseIdeologyPopup.lua"] = "playtest-scenario-ideology-popup.lua"
                ui_templates[ui_dir / "SocialPolicyPopup.lua"] = "playtest-scenario-tenet-popup.lua"
            if args.scenario == "congress":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/Popups/LeagueOverview.lua"] = "playtest-scenario-league-popup.lua"
            if args.scenario == "espionage-mission":
                ui_templates[ui_dir / "TechPopup.lua"] = "playtest-scenario-spy-tech.lua"
            if args.scenario == "diplomacy":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-diplo-root.lua"
                ui_templates[ui_dir / "TradeLogic.lua"] = "playtest-scenario-diplo-trade.lua"
                ui_templates[ui_dir / "DiscussionDialog.lua"] = "playtest-scenario-diplo-reply.lua"
            if args.scenario == "diplomacy-assets":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-diplo-assets-root.lua"
                ui_templates[ui_dir / "TradeLogic.lua"] = "playtest-scenario-diplo-assets-popup.lua"
                ui_templates[ui_dir / "DiscussionDialog.lua"] = "playtest-scenario-diplo-assets-reply.lua"
            if args.scenario in ("diplomacy-friendship", "diplomacy-friendship-prepared", "diplomacy-friendship-mature", "friendship-observe"):
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-friendship-root.lua"
                ui_templates[ui_dir / "DiscussionDialog.lua"] = "playtest-scenario-friendship-discussion.lua"
                if args.scenario in ("diplomacy-friendship-prepared", "diplomacy-friendship-mature"):
                    helper=ui_dir / "LekmodTestFriendship.lua"
                    if helper.exists(): raise SystemExit("Temporary friendship module already exists")
                    ui_templates[helper]="playtest-scenario-diplomacy-friendship.lua"
            if args.scenario == "diplomacy-denounce":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-friendship-root.lua"
                ui_templates[ui_dir / "DiscussionDialog.lua"] = "playtest-scenario-denounce-discussion.lua"
            if args.scenario == "diplomacy-pact":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-diplo-assets-root.lua"
                ui_templates[ui_dir / "TradeLogic.lua"] = "playtest-scenario-pact-popup.lua"
                ui_templates[ui_dir / "DiscussionDialog.lua"] = "playtest-scenario-pact-reply.lua"
            if args.scenario == "disabled-agreements":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-diplo-assets-root.lua"
                ui_templates[ui_dir / "TradeLogic.lua"] = "playtest-scenario-disabled-agreements-popup.lua"
            if args.scenario == "diplomacy-peace":
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/LeaderHead/LeaderHeadRoot.lua"] = "playtest-scenario-peace-root.lua"
                ui_templates[ui_dir / "TradeLogic.lua"] = "playtest-scenario-peace-popup.lua"
                ui_templates[ui_dir / "DiscussionDialog.lua"] = "playtest-scenario-peace-reply.lua"
            if args.scenario == "unit-owners":
                ui_templates[ui_dir.parent / "Lekmod_units.lua"] = "playtest-scenario-unit-owner-observer.lua"
            if args.scenario == "endgame":
                ui_templates[ui_dir / "EndGameMenu.lua"] = "playtest-scenario-endgame-popup.lua"
                ui_templates[frontend / "ExitConfirm.lua"] = "playtest-exit-confirm.lua"
            if args.scenario in ("science-prelaunch", "science-launch"):
                science_module = ui_dir / "LekmodTestScience.lua"
                if science_module.exists():
                    raise SystemExit("Temporary science module already exists")
                ui_templates[science_module] = "playtest-science-common.lua"
            if args.scenario == "science-launch":
                ui_templates[ui_dir / "EndGameMenu.lua"] = "playtest-scenario-science-victory-popup.lua"
                ui_templates[frontend / "ExitConfirm.lua"] = "playtest-exit-confirm.lua"
            if args.scenario == "domination":
                ui_templates[ui_dir / "EndGameMenu.lua"] = "playtest-scenario-domination-victory-popup.lua"
                ui_templates[frontend / "ExitConfirm.lua"] = "playtest-exit-confirm.lua"
            if args.scenario.startswith("greatwork-exchange"):
                exchange_module = ui_dir / "LekmodTestGreatWorkExchange.lua"
                if exchange_module.exists():
                    raise SystemExit("Temporary Great Work exchange module already exists")
                ui_templates[exchange_module] = "playtest-great-work-exchange-common.lua"
            if args.scenario in ("culture-prelaunch", "culture-launch"):
                culture_module = ui_dir / "LekmodTestCulture.lua"
                if culture_module.exists():
                    raise SystemExit("Temporary culture module already exists")
                ui_templates[culture_module] = "playtest-culture-common.lua"
            if args.scenario == "culture-launch":
                ui_templates[ui_dir / "EndGameMenu.lua"] = "playtest-scenario-culture-victory-popup.lua"
                ui_templates[frontend / "ExitConfirm.lua"] = "playtest-exit-confirm.lua"
            if args.scenario in ("culture-prelaunch", "greatworks", "cuba-greatworks"):
                ui_templates[APP / "Contents/Assets/Assets/DLC/Expansion2/UI/InGame/Popups/GreatWorkPopup.lua"] = "playtest-culture-great-work-popup.lua"
            if args.scenario in ("diplo-victory-prelaunch", "diplo-victory-resume", "diplo-victory-launch"):
                diplo_module = ui_dir / "LekmodTestDiploVictory.lua"
                if diplo_module.exists():
                    raise SystemExit("Temporary diplomatic victory module already exists")
                ui_templates[diplo_module] = "playtest-diplo-victory-common.lua"
            if args.scenario == "diplo-victory-resume":
                resume_module = ui_dir / "LekmodTestDiploPrelaunch.lua"
                if resume_module.exists():
                    raise SystemExit("Temporary diplomatic preparation module already exists")
                ui_templates[resume_module] = "playtest-scenario-diplo-victory-prelaunch.lua"
            if args.scenario == "diplo-victory-launch":
                ui_templates[ui_dir / "EndGameMenu.lua"] = "playtest-scenario-diplo-victory-popup.lua"
                ui_templates[frontend / "ExitConfirm.lua"] = "playtest-exit-confirm.lua"
        if args.save_and_exit:
            ui_templates[ui_dir / "GameMenu.lua"] = "playtest-game-menu.lua"
            ui_templates[frontend.parent / "InGame/Menus/SaveMenu.lua"] = "playtest-save-menu.lua"
            ui_templates[frontend / "ExitConfirm.lua"] = "playtest-exit-confirm.lua"
    if args.mode == "human-turns" or args.scenario_turns:
        ui_dir = APP / "Contents/Assets/Assets/DLC/LEKMOD/Lua/UI"
        if args.mode == "human-turns":
            ui_templates[ui_dir / "ActionInfoPanel.lua"] = "playtest-human-bootstrap.lua"
        for name, template in (("LekmodTestDriver.lua", "playtest-human.lua"),
                               ("LekmodTestMovement.lua", "playtest-movement.lua"),
                               ("LekmodTestCommands.lua", "playtest-commands.lua")):
            if (ui_dir / name).exists():
                raise SystemExit("Temporary test-control filename already exists: " + str(ui_dir / name))
            ui_templates[ui_dir / name] = template
        if args.production_completion:
            completion_path = ui_dir / "LekmodTestCompletion.lua"
            if completion_path.exists():
                raise SystemExit("Temporary completion file already exists: " + str(completion_path))
            ui_templates[completion_path] = "playtest-production-completion.lua"
        ui_templates[APP / "Contents/Assets/Assets/UI/InGame/Popups/TechAwardPopup.lua"] = "playtest-tech-award.lua"
        informational_panels = {"WhosWinningPopup", "NewEraPopup", "NaturalWonderPopup", "GoodyHutPopup",
                                "BarbarianCampPopup", "GoldenAgePopup", "WonderPopup", "LeagueSplash", "GreatPersonRewardPopup", "CityStateGreetingPopup"}
        for path in (APP / "Contents/Assets/Assets").rglob("*.lua"):
            if path.stem in informational_panels:
                ui_templates[path] = "playtest-info-popup.lua"
            elif path.name == "LeaderHeadRoot.lua":
                ui_templates.setdefault(path, "playtest-leader-root.lua")
            elif path.name == "DiploTrade.lua" and args.scenario not in ("diplomacy", "diplomacy-assets", "diplomacy-pact", "disabled-agreements", "diplomacy-peace"):
                ui_templates[path] = "playtest-trade.lua"
            elif path.name == "DiscussionDialog.lua":
                ui_templates.setdefault(path, "playtest-discussion.lua")
    ui_backups = {path: path.read_bytes() if path.exists() else None for path in ui_templates}
    for path, data in ui_backups.items():
        relative = path.relative_to(APP)
        backup = output / "ui-original" / relative
        backup.parent.mkdir(parents=True, exist_ok=True)
        if data is not None:
            backup.write_bytes(data)
    autosaves = DATA / "Saves/single/auto"
    if autosaves.exists():
        shutil.copytree(autosaves, output / "autosaves-before")
    logs = DATA / "Logs"
    if logs.exists():
        shutil.copytree(logs, output / "logs-before")
    diagnostic_dir = Path.home() / "Library/Logs/DiagnosticReports"
    before_reports = set(diagnostic_dir.glob("*"))
    render_log = logs / "LekmodRender.log"
    offset = render_log.stat().st_size if render_log.exists() else 0
    updates = {("CONFIG", "QuickStart"): args.quick_start,
               ("CONFIG", "SyncRandSeed"): 12345,
               ("CONFIG", "MapRandSeed"): 67890,
               ("DEBUG", "Autorun"): int(args.mode == "autorun"),
               ("DEBUG", "AutorunTurnLimit"): args.turns + 2 if args.mode == "autorun" else 0,
               ("DEBUG", "LoggingEnabled"): 1,
               ("DEBUG", "AILog"): 1,
               ("DEBUG", "AIPerfLog"): 1,
               ("GAME", "WorldSize"): args.world_size,
               ("GAME", "GameType"): "singlePlayer",
               ("GAME", "FileName"): ""}
    report = {"mode": args.mode, "requested_turns": args.turns,
              "ui_variant": "eui" if has_eui else "standard",
              "production_completion": args.production_completion,
              "quick_start": args.quick_start, "skip_intro": args.skip_intro,
              "trace_loaded_libraries": args.trace_loaded_libraries,
              "process_observer": "none" if args.no_process_adapter else "activation-only" if args.activation_only else "full-diagnostics",
              "scenario": args.scenario,
              "scenario_turn_limit": args.scenario_turns,
              "temporary_autosave_interval": 1 if args.scenario_turns else None,
              "expected_human_score_victory": args.expect_human_victory,
              "requested_window_size": args.window_size,
              "live_driver_control": args.mode == "human-turns",
              "runner_pid": os.getpid(),
              "status": "incomplete", "pid": None, "world_size": args.world_size,
              "major_civilizations": args.majors, "city_states": args.minors,
              "started_utc": stamp, "evidence": str(output),
              "start_era": args.start_era if not args.load_save else None,
              "map_script": args.map_script if not args.load_save else None,
              "game_speed": args.game_speed if not args.load_save else None,
              "human_handicap": args.handicap if not args.load_save else None,
              "requested_game_options": dict(args.game_option) if not args.load_save else None,
              "civilization": args.civilization if not args.load_save else None,
              "opponent_civilization": args.opponent_civilization if not args.load_save else None,
              "slot_civilizations": dict(args.slot_civilization) if not args.load_save else None,
              "binary_sha256": hashlib.sha256((APP / "Contents/MacOS/libCvGameCoreDLL_Expansion2_DLL.dylib").read_bytes()).hexdigest()}
    if args.load_save:
        report["loaded_from"] = str(args.load_save)
        report["save_sha256"] = hashlib.sha256(args.load_save.read_bytes()).hexdigest()
    pid = None
    game_process = None
    display_domain = "com.aspyr.civ5xp.steam"
    display_setting = command(["defaults", "read", display_domain, "DisplayFullScreen"])
    background_lib = REPO / "build/macos" / ("background-activation-only.dylib" if args.activation_only else "foreground-attachment.dylib" if args.foreground_attachment_test
                                             else "background-playtest.dylib")
    if not args.no_process_adapter:
        subprocess.run(["clang", "-arch", "x86_64", "-dynamiclib", "-framework", "AppKit",
                        "-framework", "Foundation", str(Path(__file__).with_name("background-playtest.m")),
                        "-o", str(background_lib)] + (["-DLEKMOD_TEST_ALLOW_FOREGROUND"] if args.foreground_attachment_test else []) + (["-DLEKMOD_TEST_ACTIVATION_ONLY"] if args.activation_only else []), check=True)
    current_text = ""
    start = time.monotonic()
    last_progress = start
    previous_count = 0
    engine_started = False
    captured_ui_turns = set()
    captured_panels = set()
    ui_ready_announced = False
    held_reason = None
    seen_driver_revision = None

    def hold_for_driver(reason, state):
        nonlocal held_reason
        report["status"] = "waiting-for-driver"
        if held_reason == reason:
            return
        held_reason = reason
        report.setdefault("driver_holds", []).append({"reason": reason,
            "game_turn": state["completed_turns"][-1] if state["completed_turns"] else None})
        index = len(report["driver_holds"])
        capture_game_window(pid, output / f"driver-hold-{index}.png")
        (output / f"driver-hold-{index}-render.log").write_text(current_text)
        lua_log = logs / "Lua.log"
        if lua_log.exists():
            shutil.copy2(lua_log, output / f"driver-hold-{index}-lua.log")
        (output / "run-state.json").write_text(json.dumps({**report, **state}, indent=2) + "\n")
        print(json.dumps({"event": "waiting-for-driver", "reason": reason, "pid": pid}), flush=True)
    try:
        config.write_bytes(edit_ini(original.decode(), updates).encode())
        test_user_settings = re.sub(rb"(?m)^(SkipIntroVideo\s*=\s*)[^\r\n]*",
                                    lambda match: match.group(1) + str(args.skip_intro).encode(), original_user_settings)
        if args.scenario_turns:
            # Bounded scenarios should recover from their latest ordinary
            # autosave. The original preference bytes are restored in finally.
            test_user_settings = edit_ini(test_user_settings.decode(), {
                ("AutoSave", "TurnsBetweenAutosave"): 1}).encode()
        user_settings.write_bytes(test_user_settings)
        if original_graphics is not None:
            graphics_settings.write_bytes(edit_ini(original_graphics.decode(), {
                ("UserSettings", "WindowResX"): args.window_size[0],
                ("UserSettings", "WindowResY"): args.window_size[1]}).encode())
        replacements = {"__TEST_WORLD_SIZE__": args.world_size,
                        "__TEST_CIVILIZATION__": args.civilization,
                        "__TEST_OPPONENT_CIVILIZATION__": args.opponent_civilization,
                        "__TEST_SLOT_CIVILIZATIONS__": "{" + ",".join("[" + str(slot) + "]=" + json.dumps(civ) for slot, civ in args.slot_civilization) + "}",
                        "__TEST_START_ERA__": args.start_era,
                        "__TEST_MAP_SCRIPT__": args.map_script,
                        "__TEST_GAME_SPEED__": args.game_speed,
                        "__TEST_HANDICAP__": args.handicap,
                        "__TEST_GAME_OPTIONS__": "{" + ",".join("[" + json.dumps(name) + "]=" + str(value) for name, value in args.game_option) + "}",
                        "__TEST_RUN__": stamp,
                        "__TEST_SCENARIO_TURN_LIMIT__": str(args.scenario_turns),
                        "__TEST_GAME_TURN_LIMIT__": "2" if args.scenario == "endgame" else "0",
                        "__TEST_EXPECT_HUMAN_VICTORY__": "true" if args.expect_human_victory else "false",
                        "__TEST_FUNCTIONAL__": "true" if args.mode in ("single-player-smoke", "ui-interaction") else "false",
                        "__TEST_SAVE_NAME__": json.dumps(save_name) if args.save_and_exit else "nil",
                        "__TEST_CAPTURE_PANELS__": "true" if args.capture_panels else "false",
                        "__TEST_CITY_CONTROLS__": "true" if args.city_controls else "false",
                        "__TEST_PRODUCTION_COMPLETION__": "true" if args.production_completion else "false",
                        "__TEST_EXPECTED_STATE__": json.dumps(expected_state) if expected_state else "nil",
                        "__TEST_LOAD_PATH__": json.dumps(str(args.load_save), ensure_ascii=False) if args.load_save else "nil",
                        "__TEST_MAJORS__": str(args.majors),
                        "__TEST_MINORS__": str(args.minors),
                        "__TEST_AUTOPLAY__": "true" if args.mode == "autorun" else "false",
                        "__TEST_TURNS__": str(args.turns + 2)}
        report["initial_ui_hooks"] = []
        for path, template in ui_templates.items():
            code = Path(__file__).with_name(template).read_text()
            for key, value in replacements.items():
                code = code.replace(key, value)
            contents = (ui_backups[path] or b"") + b"\n" + code.encode()
            hook = preserve_injected_ui(output, APP, path, contents)
            report["initial_ui_hooks"].append({**hook, "adapter": template})
            path.write_bytes(contents)
        command(["defaults", "write", display_domain, "DisplayFullScreen", "-bool", "false"])
        environment = os.environ.copy()
        if args.no_process_adapter:
            environment.pop("DYLD_INSERT_LIBRARIES", None)
        else:
            environment["DYLD_INSERT_LIBRARIES"] = str(background_lib)
        if args.trace_loaded_libraries:
            environment["DYLD_PRINT_LIBRARIES"] = "1"
        environment["SteamAppId"] = "8930"
        environment["SteamGameId"] = "8930"
        # Preparation can copy many saved artifacts; check again at launch.
        require_unlocked_desktop()
        with (output / "process.log").open("w") as process_log:
            game_process = subprocess.Popen([str(APP / "Contents/MacOS/Civilization V")],
                cwd=APP / "Contents/MacOS", env=environment, stdin=subprocess.DEVNULL,
                stdout=process_log, stderr=subprocess.STDOUT)
        pid = game_process.pid
        report["pid"] = pid
        report["background"] = not args.foreground_attachment_test
        (output / "run-state.json").write_text(json.dumps({**report, "status": "running"}, indent=2) + "\n")
        print(json.dumps({"event": "launched-foreground-attachment" if args.foreground_attachment_test else "launched-background",
                          "pid": pid, "evidence": str(output)}), flush=True)
        while time.monotonic() - start < args.timeout:
            pids = game_pids()
            process_output = (output / "process.log").read_text(errors="replace")
            if "SteamAPI_Init() failed" in process_output:
                report["status"] = "failed-steam-initialization"
                break
            if pid is None and pids:
                pid = pids[0]
                report["pid"] = pid
                print(json.dumps({"event": "process-started", "pid": pid}), flush=True)
            if pid is None and time.monotonic() - start > args.startup_timeout:
                report["status"] = "failed-startup"
                break
            if render_log.exists():
                raw = render_log.read_bytes()
                if len(raw) < offset:
                    offset = 0
                current_text = raw[offset:].decode(errors="replace")
            state = summarize(current_text)
            if state["last_record"] and not engine_started:
                engine_started = True
                last_progress = time.monotonic()
            count = len(state["completed_turns"])
            if count != previous_count:
                print(json.dumps({"event": "turn-progress", "completed_count": count,
                                  "latest_turn": state["completed_turns"][-1],
                                  "turn_discontinuities": state["turn_discontinuities"]}), flush=True)
                last_progress = time.monotonic()
                previous_count = count
                held_reason = None
                report["status"] = "running"
                (output / "run-state.json").write_text(json.dumps({**report, **state, "status": "running"}, indent=2) + "\n")
            if state["turn_discontinuities"]:
                report["status"] = "failed-rollback"
                break
            net_log = logs / "net_message_debug.log"
            if engine_started and net_log.exists():
                checks = synchronization_failures(net_log.read_text(errors="replace"))
                if any(checks.values()):
                    report["synchronization_checks"] = checks
                    report["status"] = "failed-synchronization-check"
                    break
            latest_turn = state["completed_turns"][-1] if count else None
            human_returned = args.mode != "human-turns" or latest_turn in state["player_zero_turn_starts"]
            if not args.production_completion and args.mode in ("autorun", "human-turns") and count >= args.turns and human_returned:
                report["status"] = "passed-autorun-only" if args.mode == "autorun" else "passed-scripted-human-turns-only"
                break
            lua_path = logs / "Lua.log"
            current_lua = lua_path.read_text(errors="replace") if lua_path.exists() else ""
            recent_lua = current_lua[-16384:]
            if args.production_completion:
                completion = production_completion_results(recent_lua, stamp)
                report["production_completion_checks"] = completion
                if completion["failed"] or completion["complete"]:
                    report["status"] = ("passed-production-completion-only" if completion["verified"] and
                        1 <= count <= args.turns and human_returned else "failed-production-completion")
                    break
            if args.mode == "ui-interaction" and not ui_ready_announced and (
                    "[LEKMOD_UI_OBSERVE] run=" + stamp + " " in recent_lua):
                ui_ready_announced = True
                print(json.dumps({"event": "ui-observer-ready", "pid": pid, "evidence": str(output)}), flush=True)
                report["initial_ui_capture"] = capture_game_window(pid, output / "ui-ready.png")
            if has_eui and args.mode == "human-turns" and not ui_ready_announced and "[LEKMOD_TEST] human-active" in recent_lua:
                ui_ready_announced = True
                report["initial_eui_capture"] = capture_game_window(pid, output / "eui-first-human-turn.png")
            if args.mode == "single-player-smoke" and engine_started:
                for panel in re.findall(r"run=" + re.escape(stamp) + r" event=panel-visible name=([a-z-]+)", recent_lua):
                    if args.capture_panels and panel not in captured_panels:
                        captured_panels.add(panel)
                        success = capture_game_window(pid, output / (panel + ".png"))
                        report.setdefault("panel_captures", {})[panel] = success
                functional = functional_results(current_lua, stamp, required_functional_items)
                report["functional_checks"] = functional
                if functional["failed"] or functional["complete"]:
                    report["status"] = ("passed-available-functional-checks-only" if functional["verified"]
                                        else "failed-functional-checks")
                    if args.scenario and functional["verified"]:
                        report["status"] = "passed-scenario-reload-only" if args.expected_state else "passed-scenario-checks-only"
                    if (not args.save_and_exit and args.scenario not in ("endgame", "science-launch", "domination", "culture-launch", "diplo-victory-launch")) or functional["failed"]:
                        break
                    returncode = game_process.poll()
                    if returncode is not None:
                        exited_normally = returncode == 0
                        saved = generated_save.is_file() and generated_save.stat().st_size > 0
                        confirmed = "run=" + stamp + " event=exit-confirmed" in recent_lua
                        report["normal_exit_verified"] = exited_normally and confirmed
                        if args.save_and_exit:
                            report["save_file_verified"] = saved
                        if not (exited_normally and confirmed and (saved or args.scenario in ("endgame", "science-launch", "domination", "culture-launch", "diplo-victory-launch"))):
                            report["status"] = "failed-save-or-normal-exit"
                        break
            exit_status = process_exit_status(args.mode, game_process.poll()) if pid else None
            if exit_status is not None:
                report["status"] = exit_status
                break
            revisions = re.findall(r"\[LEKMOD_TEST\] driver-reloaded revision=(\S+)", recent_lua)
            if engine_started and revisions and revisions[-1] != seen_driver_revision:
                seen_driver_revision = revisions[-1]
                held_reason = None
                last_progress = time.monotonic()
                report["status"] = "running"
                report.setdefault("driver_refreshes", []).append(seen_driver_revision)
                (output / "run-state.json").write_text(json.dumps({**report, **state}, indent=2) + "\n")
            if ("UI thinks that we can't end turn" in recent_lua and count not in captured_ui_turns
                    and time.monotonic() - last_progress > 10):
                if not capture_game_window(pid, output / f"blocked-ui-after-{count}-turns.png"):
                    report.setdefault("window_capture_failures", []).append(count)
                captured_ui_turns.add(count)
            if engine_started and unresolved_driver_error(recent_lua):
                if report["live_driver_control"]:
                    hold_for_driver("failed-test-driver", state)
                    time.sleep(2)
                    continue
                report["status"] = "failed-test-driver"
                break
            if args.mode != "ui-interaction" and engine_started and time.monotonic() - last_progress > args.stall_seconds:
                if held_reason:
                    report["status"] = "waiting-for-driver"
                    time.sleep(2)
                    continue
                leader_pending = recent_lua.rfind("Handling LeaderMessage") > recent_lua.rfind("[LEKMOD_TEST] dismiss-leader")
                report["status"] = ("blocked-diplomacy" if leader_pending else
                                    "blocked-human-decision" if "[LEKMOD_TEST] human-blocked" in recent_lua else
                                    "blocked-human-ui" if "UI thinks that we can't end turn" in recent_lua else "failed-stall")
                if report["live_driver_control"]:
                    if report["status"] == "failed-stall":
                        report["unclassified_stall_requires_review"] = True
                        command(["sample", str(pid), "5", "-file", str(output / "unclassified-stall.sample.txt")], timeout=30)
                    hold_for_driver(report["status"], state)
                    time.sleep(2)
                    continue
                break
            time.sleep(2)
        else:
            report["status"] = ("ended-manual-ui-time-budget" if args.mode == "ui-interaction" else
                                "incomplete-time-budget" if previous_count and
                                time.monotonic() - last_progress < args.stall_seconds
                                else "failed-timeout")
        report.update(summarize(current_text))
        if report["status"].startswith(("failed", "blocked")) and pid in game_pids():
            report["failure_window_captured"] = capture_game_window(pid, output / "failure-window.png")
            command(["sample", str(pid), "5", "-file", str(output / "stall.sample.txt")], timeout=30)
    except KeyboardInterrupt:
        report["status"] = "interrupted"
        report.update(summarize(current_text))
    except Exception as exc:
        report["status"] = "failed-runner"
        report["error"] = str(exc)
    finally:
        # Terminate only the instance started by this test, never a pre-existing
        # game. The copied autosaves remain recoverable in the evidence folder.
        try:
            if pid and pid in game_pids():
                report["runner_requested_stop"] = True
                report["termination_signals"] = []
                try:
                    command(["osascript", "-e", 'tell application "Civilization V" to quit'], timeout=5)
                except subprocess.TimeoutExpired:
                    pass
                if game_process.poll() is None and pid in game_pids():
                    command(["kill", "-TERM", str(pid)])
                    report["termination_signals"].append("SIGTERM")
                    time.sleep(2)
                if game_process.poll() is None and pid in game_pids():
                    command(["kill", "-KILL", str(pid)])
                    report["termination_signals"].append("SIGKILL")
                    time.sleep(1)
        finally:
            if game_process:
                report["process_returncode"] = game_process.poll()
            config.write_bytes(original)
            user_settings.write_bytes(original_user_settings)
            if original_graphics is not None:
                graphics_settings.write_bytes(original_graphics)
            for path, data in ui_backups.items():
                if data is None:
                    path.unlink(missing_ok=True)
                else:
                    path.write_bytes(data)
            report["temporary_ui_hooks_restored"] = all(
                not path.exists() if data is None else path.read_bytes() == data for path, data in ui_backups.items())
            report["settings_restored"] = (config.read_bytes() == original and
                                           user_settings.read_bytes() == original_user_settings)
            if original_graphics is not None:
                report["graphics_settings_restored"] = graphics_settings.read_bytes() == original_graphics
                report["settings_restored"] = report["settings_restored"] and report["graphics_settings_restored"]
            if display_setting.returncode == 0:
                command(["defaults", "write", display_domain, "DisplayFullScreen", "-bool",
                         "true" if display_setting.stdout.strip() in ("1", "true") else "false"])
            else:
                command(["defaults", "delete", display_domain, "DisplayFullScreen"])
        report["duration_seconds"] = round(time.monotonic() - start, 1)
        report["manual_saves_preserved"] = all(path.is_file() and path.read_bytes() == data for path, data in manual_saves.items())
        report["new_manual_saves"] = [str(path) for path in (DATA / "Saves/single").glob("*.Civ5Save") if path not in manual_saves]
        if not report["manual_saves_preserved"]:
            report["status"] = "failed-manual-save-preservation"
        (output / "LekmodRender.log").write_text(current_text)
        if logs.exists():
            shutil.copytree(logs, output / "logs-after")
        database_log = logs / "Database.log"
        report["localization_startup_failure"] = (
            report.get("process_returncode") == 255 and database_log.exists() and
            localization_startup_failure(database_log.read_text(errors="replace")))
        net_log = logs / "net_message_debug.log"
        report["synchronization_checks"] = synchronization_failures(
            net_log.read_text(errors="replace") if net_log.exists() else "")
        if report["status"].startswith("passed") and any(report["synchronization_checks"].values()):
            report["status"] = "failed-synchronization-check"
        if args.mode in ("human-turns", "single-player-smoke", "ui-interaction"):
            lua_log = logs / "Lua.log"
            lua_text = lua_log.read_text(errors="replace") if lua_log.exists() else ""
            report["human_test_records"] = [line.strip() for line in lua_text.splitlines()
                                             if "[LEKMOD_TEST]" in line]
            report["lua_runtime_errors"] = [line.strip() for line in lua_text.splitlines()
                                             if "Runtime Error:" in line]
            if args.mode == "ui-interaction":
                report["ui_observations"] = [line.strip() for line in lua_text.splitlines()
                    if "[LEKMOD_UI_OBSERVE] run=" + stamp + " " in line]
            if args.production_completion:
                report["production_completion_checks"] = production_completion_results(lua_text, stamp)
                report["functional_records"] = [line.strip() for line in lua_text.splitlines()
                    if "[LEKMOD_FUNCTIONAL] run=" + stamp + " " in line]
                if report["status"].startswith("passed") and not report["production_completion_checks"]["verified"]:
                    report["status"] = "failed-production-completion"
            if report["status"].startswith("passed") and report["lua_runtime_errors"]:
                report["status"] = "failed-lua-runtime-error"
            if args.mode == "human-turns":
                report["human_validation"] = human_turn_results(lua_text)
                if report["status"].startswith("passed") and not report["human_validation"]["verified"]:
                    report["status"] = "failed-human-test-validation"
            if args.mode == "single-player-smoke":
                report["functional_checks"] = functional_results(lua_text, stamp, required_functional_items)
                report["functional_records"] = [line.strip() for line in lua_text.splitlines()
                                                  if "[LEKMOD_FUNCTIONAL]" in line]
                fingerprints = state_fingerprints(lua_text, stamp)
                if fingerprints:
                    report["saved_state"] = fingerprints[-1]
                if args.expected_state:
                    report["reload_state_verified"] = report["functional_checks"]["outcomes"].get("save-reload") == "PASS"
                    if report["status"].startswith("passed") and not report["reload_state_verified"]:
                        report["status"] = "failed-save-reload-validation"
                if args.save_and_exit and generated_save.is_file():
                    saved_copy = output / generated_save.name
                    shutil.copy2(generated_save, saved_copy)
                    report["generated_save"] = str(generated_save)
                    report["saved_copy"] = str(saved_copy)
                    report["saved_sha256"] = hashlib.sha256(saved_copy.read_bytes()).hexdigest()
                if report["status"].startswith("passed") and not report["functional_checks"]["verified"]:
                    report["status"] = "failed-functional-checks"
                if args.scenario == "congress" and not args.expected_state:
                    report["congress_resolution"] = congress_resolution_results(current_text, lua_text, stamp)
                    if report["status"].startswith("passed") and not report["congress_resolution"]["verified"]:
                        report["status"] = "failed-congress-resolution-evidence"
        if autosaves.exists():
            shutil.copytree(autosaves, output / "autosaves-after")
        new_reports = [p for p in set(diagnostic_dir.glob("*")) - before_reports
                       if re.search(r"civ|civilization", p.name, re.I)]
        report["new_diagnostics"] = [str(p) for p in new_reports]
        if new_reports and report["status"].startswith("passed"):
            report["status"] = "failed-diagnostic"
        if report["status"].startswith("passed") and report.get("unclassified_stall_requires_review"):
            report["status"] = "completed-needs-stall-review"
        for path in new_reports:
            if path.is_file():
                shutil.copy2(path, output / path.name)
        (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        (output / "run-state.json").write_text(json.dumps(report, indent=2) + "\n")
        print(json.dumps(report, indent=2), flush=True)
    return 0 if report["status"].startswith("passed") else 1


if __name__ == "__main__":
    raise SystemExit(main())
