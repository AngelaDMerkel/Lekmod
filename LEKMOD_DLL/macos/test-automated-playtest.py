#!/usr/bin/env python3
"""Offline tests for evidence classification; never launches or alters Civ V."""
import importlib.util
from pathlib import Path
import unittest
import subprocess
import sys
import tempfile
from unittest import mock
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("playtest", Path(__file__).with_name("automated-playtest.py"))
playtest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(playtest)


class PlaytestEvidenceTests(unittest.TestCase):
    def test_exit_classification_waits_for_actual_process_status(self):
        self.assertIsNone(playtest.process_exit_status("ui-interaction",None))
        self.assertIsNone(playtest.process_exit_status("single-player-smoke",None))
        self.assertEqual(playtest.process_exit_status("ui-interaction",0),"ended-manual-ui-session")
        for code in (-9,1,255):
            self.assertEqual(playtest.process_exit_status("ui-interaction",code),"failed-early-exit")
        self.assertEqual(playtest.process_exit_status("single-player-smoke",0),"failed-early-exit")

    def test_localization_startup_failure_is_distinct_from_duplicate_data_warnings(self):
        self.assertTrue(playtest.localization_startup_failure("unable to open database: C:\\Emu\\cache\\Localization-Merged.db"))
        self.assertTrue(playtest.localization_startup_failure("Failed to Load database.\nno such table: Languages"))
        self.assertFalse(playtest.localization_startup_failure("UNIQUE constraint failed: ArtDefine_StrategicView"))
        self.assertFalse(playtest.localization_startup_failure("Failed to Load database."))

    def test_inherited_production_does_not_claim_a_new_order(self):
        text = "[LEKMOD_TEST] production-inherited city=8192 order=3 item=0\n[LEKMOD_TEST] end-turn-click turn=214"
        result = playtest.human_turn_results(text)
        self.assertTrue(result["verified"])
        self.assertTrue(result["inherited_order_observed"])
        self.assertFalse(result["new_order_verified"])
        self.assertFalse(playtest.human_turn_results("[LEKMOD_TEST] end-turn-click")["verified"])
        self.assertFalse(playtest.human_turn_results(text + "\n[LEKMOD_TEST] ERROR broken")["verified"])
        self.assertFalse(playtest.human_turn_results("[LEKMOD_TEST] production-verified")["verified"])

    def test_congress_result_requires_matching_engine_outcome(self):
        lua = ('[LEKMOD_FUNCTIONAL] run=current event=congress-proposal value={"id":7,"type":15}\n'
               '[LEKMOD_FUNCTIONAL] run=current event=congress-resolved value={"id":7,"active":true}\n')
        passed = '[LEKMOD_RENDER] event=league-enact.passed owner=0 id=7 type=15\n'
        failed = passed.replace('passed','failed')
        self.assertTrue(playtest.congress_resolution_results(passed,lua,'current')['verified'])
        self.assertFalse(playtest.congress_resolution_results(failed,lua,'current')['verified'])
        self.assertFalse(playtest.congress_resolution_results('',lua,'current')['verified'])
        self.assertFalse(playtest.congress_resolution_results(passed.replace('id=7','id=8'),lua,'current')['verified'])
        self.assertTrue(playtest.congress_resolution_results(failed,lua.replace('true','false'),'current')['verified'])

    def test_window_size_is_explicit_and_bounded(self):
        self.assertEqual(playtest.parse_window_size("1280x800"), (1280, 800))
        for value in ("auto", "1280", "100x100", "9000x800"):
            with self.assertRaises(playtest.argparse.ArgumentTypeError):
                playtest.parse_window_size(value)

    def test_scenario_turns_cannot_enable_unbounded_or_unscoped_play(self):
        script = str(Path(__file__).with_name("automated-playtest.py"))
        for value in ("-1", "1", "31"):
            result = subprocess.run([sys.executable, script, "--mode", "single-player-smoke",
                "--turns", "3", "--timeout", "60", "--scenario-turns", value],capture_output=True,text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn("--scenario-turns requires",result.stderr)

    def test_scenario_recovery_timeout_stays_bounded(self):
        with tempfile.TemporaryDirectory() as directory:
            fixture=Path(directory)/"fixture.Civ5Save";fixture.touch()
            result=subprocess.run([sys.executable,str(Path(__file__).with_name("automated-playtest.py")),
                "--mode","single-player-smoke","--scenario","inventory","--load-save",str(fixture),
                "--timeout","1801"],capture_output=True,text=True)
            self.assertEqual(result.returncode,2)
            self.assertIn("timeout at most 1800",result.stderr)

    def test_scenario_fingerprint_retains_spaces_and_escaped_strings(self):
        snapshot = '{"city":"New York","message":"quote \\\" newline \\n","value":42}'
        log = '[1.0] ActionInfoPanel: [LEKMOD_FUNCTIONAL] run=current event=save-state value=' + snapshot + '\r\n'
        self.assertEqual(playtest.state_fingerprints(log, "current"), [snapshot])
        self.assertEqual(playtest.state_fingerprints(log, "other"), [])

    def test_production_completion_is_bounded_and_uses_a_loaded_human_fixture(self):
        script = str(Path(__file__).with_name("automated-playtest.py"))
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "fixture.Civ5Save"
            fixture.touch()  # Invalid argument combinations must never launch it.
            for mode, turns, timeout, use_save in (("ui-interaction", 3, 300, True),
                    ("human-turns", 4, 300, True), ("human-turns", 3, 601, True),
                    ("human-turns", 3, 300, False)):
                args = [sys.executable, script, "--production-completion", "--mode", mode,
                        "--turns", str(turns), "--timeout", str(timeout)]
                if use_save:
                    args += ["--load-save", str(fixture)]
                result = subprocess.run(args, capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn("Production completion requires", result.stderr)

    def test_production_selection_is_not_completion(self):
        prefix = "[LEKMOD_FUNCTIONAL] run=current "
        selection = [prefix + "item=" + item + " status=PASS" for item in playtest.FUNCTIONAL_ITEMS]
        selection.append(prefix + "event=complete")
        required = playtest.PRODUCTION_COMPLETION_ITEMS
        self.assertFalse(playtest.functional_results("\n".join(selection), "current", required)["verified"])
        completed = [prefix + "item=" + item + " status=PASS" for item in required]
        self.assertFalse(playtest.functional_results("\n".join(completed), "current", required)["verified"])
        completed.append(prefix + "event=complete")
        self.assertTrue(playtest.functional_results("\n".join(completed), "current", required)["verified"])
        completed.append(prefix + "item=production-completion status=FAIL")
        self.assertFalse(playtest.functional_results("\n".join(completed), "current", required)["verified"])

    def test_skipped_production_outcomes_never_verify_completion(self):
        for skipped in playtest.PRODUCTION_COMPLETION_ITEMS:
            rows = ["[LEKMOD_FUNCTIONAL] run=current item=" + item + " status=" +
                    ("SKIP" if item == skipped else "PASS") for item in playtest.PRODUCTION_COMPLETION_ITEMS]
            rows.append("[LEKMOD_FUNCTIONAL] run=current event=complete")
            self.assertFalse(playtest.production_completion_results("\n".join(rows), "current")["verified"])
    def test_foreground_exception_is_bounded_and_non_autoplay(self):
        script = str(Path(__file__).with_name("automated-playtest.py"))
        for mode, timeout in (("human-turns", "180"), ("ui-interaction", "3601")):
            result = subprocess.run([sys.executable, script, "--foreground-attachment-test",
                                     "--mode", mode, "--timeout", timeout],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn("Foreground UI tests require", result.stderr)
        with mock.patch.object(sys, "argv", [script, "--foreground-ui-test", "--mode", "ui-interaction", "--timeout", "1200"]), \
             mock.patch.object(playtest, "game_pids", return_value=[123]):
            with self.assertRaisesRegex(SystemExit, "already open"):
                playtest.main()  # Accepted bound; the existing-process guard prevents any launch.

    def test_unmodified_process_requires_explicit_bounded_foreground_scope(self):
        script = str(Path(__file__).with_name("automated-playtest.py"))
        for extra in ([], ["--activation-only", "--foreground-ui-test"], ["--foreground-ui-test", "--mode", "human-turns"], ["--foreground-ui-test", "--timeout", "3601"]):
            result = subprocess.run([sys.executable, script, "--no-process-adapter"] + extra, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
        with mock.patch.object(sys, "argv", [script, "--no-process-adapter", "--foreground-ui-test", "--mode", "single-player-smoke", "--timeout", "600"]), mock.patch.object(playtest, "game_pids", return_value=[123]):
            with self.assertRaisesRegex(SystemExit, "already open"):
                playtest.main()

    def test_startup_control_settings_accept_only_binary_values(self):
        script = str(Path(__file__).with_name("automated-playtest.py"))
        for flag in ("--quick-start", "--skip-intro"):
            for value in ("-1", "2", "yes"):
                result = subprocess.run([sys.executable, script, flag, value], capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)

    def test_starting_era_aliases_use_shipped_identifiers(self):
        self.assertEqual(playtest.parse_start_era("ERA_ATOMIC"), "ERA_POSTMODERN")
        self.assertEqual(playtest.parse_start_era("ERA_INFORMATION"), "ERA_FUTURE")
        self.assertEqual(playtest.parse_start_era("ERA_MODERN"), "ERA_MODERN")
        with self.assertRaises(playtest.argparse.ArgumentTypeError):
            playtest.parse_start_era("ERA_UNKNOWN")

    def test_setup_options_are_single_player_bounded_values(self):
        self.assertEqual(playtest.parse_game_option("GAMEOPTION_NO_BARBARIANS=1"), ("GAMEOPTION_NO_BARBARIANS", 1))
        for value in ("GAMEOPTION_NO_SCIENCE=2", "GAMEOPTION_NO_SCIENCE=true", "GAMEOPTION_SIMULTANEOUS_TURNS=1", "NO_BARBARIANS=1", "GAMEOPTION_UNKNOWN=0"):
            with self.assertRaises(playtest.argparse.ArgumentTypeError):
                playtest.parse_game_option(value)
        script = str(Path(__file__).with_name("automated-playtest.py"))
        result = subprocess.run([sys.executable, script, "--game-option", "GAMEOPTION_NO_SCIENCE=0", "--game-option", "GAMEOPTION_NO_SCIENCE=1"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("more than once", result.stderr)

    def test_capture_uses_large_game_window_not_thin_title_bar(self):
        import json
        windows=[{"kCGWindowOwnerPID":77,"kCGWindowNumber":10,"kCGWindowBounds":{"Width":1280,"Height":828}},
                 {"kCGWindowOwnerPID":88,"kCGWindowNumber":11,"kCGWindowBounds":{"Width":3000,"Height":2000}},
                 {"kCGWindowOwnerPID":77,"kCGWindowNumber":12,"kCGWindowBounds":{"Width":1512,"Height":33}}]
        def command(args, **kwargs):
            return SimpleNamespace(returncode=0,stdout=json.dumps(windows) if args==["helper"] else "")
        with mock.patch.object(playtest,"window_helper",return_value="helper"), mock.patch.object(playtest,"command",side_effect=command) as run:
            self.assertTrue(playtest.capture_game_window(77,Path("image.png")))
            self.assertEqual(run.call_args_list[-1].args[0], ["screencapture","-x","-o","-l","10","image.png"])

    def test_functional_completion_requires_all_items_from_this_run(self):
        prefix = "[LEKMOD_FUNCTIONAL] run=current "
        rows = [prefix + "item=" + item + " status=PASS" for item in playtest.FUNCTIONAL_ITEMS]
        complete = prefix + "event=complete"
        self.assertFalse(playtest.functional_results("\n".join(rows), "current")["verified"])
        self.assertTrue(playtest.functional_results("\n".join(rows + [complete]), "current")["verified"])
        self.assertFalse(playtest.functional_results("\n".join(rows + [complete]), "other")["verified"])
        self.assertFalse(playtest.functional_results("\n".join(rows[1:] + [complete]), "current")["verified"])

    def test_functional_failures_are_not_erased_by_later_passes(self):
        rows = ["[LEKMOD_FUNCTIONAL] run=current item=" + item + " status=PASS" for item in playtest.FUNCTIONAL_ITEMS]
        rows += ["[LEKMOD_FUNCTIONAL] run=current event=complete"]
        rows.insert(0, "[LEKMOD_FUNCTIONAL] run=current item=tech-tree status=FAIL")
        self.assertFalse(playtest.functional_results("\n".join(rows), "current")["verified"])

    def test_unavailable_functional_items_remain_explicitly_skipped(self):
        rows = ["[LEKMOD_FUNCTIONAL] run=current item=" + item + " status=" +
                ("SKIP" if item == "production-process" else "PASS") for item in playtest.FUNCTIONAL_ITEMS]
        rows += ["[LEKMOD_FUNCTIONAL] run=current event=complete"]
        result = playtest.functional_results("\n".join(rows), "current")
        self.assertTrue(result["verified"])
        self.assertEqual(result["skipped"], ["production-process"])

    def test_driver_error_requires_a_subsequent_acknowledged_refresh(self):
        error = "[LEKMOD_TEST] ERROR unhandled prompt\n"
        refresh = "[LEKMOD_TEST] driver-reloaded revision=1\n"
        self.assertTrue(playtest.unresolved_driver_error(error))
        self.assertFalse(playtest.unresolved_driver_error(error + refresh))
        self.assertTrue(playtest.unresolved_driver_error(refresh + error))

    def test_normal_sync_messages_are_not_errors(self):
        self.assertFalse(any(playtest.synchronization_failures(
            "NetRandomNumberGeneratorSyncCheck(Player=0, seed=123)\nNetLoopBarrierComplete").values()))

    def test_resync_and_protocol_errors_are_rejected(self):
        for message in ("Game Random Number Generators are out of sync", "NetForceResync", "PROTOCOL ERROR"):
            self.assertTrue(any(playtest.synchronization_failures(message).values()))

    def test_visual_callbacks_are_not_turn_completion(self):
        result = playtest.summarize("[LEKMOD_RENDER] event=unit-created.end detail=9\n")
        self.assertEqual(result["completed_turns"], [])

    def test_consecutive_turns_and_human_return_are_distinct(self):
        result = playtest.summarize(
            "[LEKMOD_RENDER] event=game-turn.end detail=1\n"
            "[LEKMOD_RENDER] event=game-turn.end detail=2\n"
            "[LEKMOD_RENDER] event=player-turn.end owner=0 detail=2\n")
        self.assertEqual(result["completed_turns"], [1, 2])
        self.assertEqual(result["player_zero_turn_starts"], [2])
        self.assertEqual(result["turn_discontinuities"], [])

    def test_replays_and_skipped_turns_are_rejected(self):
        for turns in ([1, 2, 1], [1, 1], [1, 3]):
            text = "\n".join(f"[LEKMOD_RENDER] event=game-turn.end detail={turn}" for turn in turns)
            self.assertTrue(playtest.summarize(text)["turn_discontinuities"])

    def test_ini_edits_preserve_other_sections_and_line_endings(self):
        before = "[DEBUG]\r\nAutorun = 0\r\n[GAME]\r\nAutorun = untouched\r\n"
        expected = "[DEBUG]\r\nAutorun = 1\r\n[GAME]\r\nAutorun = untouched\r\n"
        self.assertEqual(playtest.edit_ini(before, {("DEBUG", "Autorun"): 1}), expected)

    def test_missing_ini_key_is_an_error(self):
        with self.assertRaises(RuntimeError):
            playtest.edit_ini("[DEBUG]\n", {("DEBUG", "Autorun"): 1})

    def test_locked_desktop_does_not_launch_a_test(self):
        with mock.patch.object(playtest, "window_helper", return_value=Path("/tmp/test-windows")), \
             mock.patch.object(playtest, "command", return_value=SimpleNamespace(
                 stdout='{"available":true,"on_console":true,"locked":true}')):
            with self.assertRaisesRegex(SystemExit, "Desktop is locked"):
                playtest.require_unlocked_desktop()

    def test_unlocked_desktop_is_accepted(self):
        with mock.patch.object(playtest, "window_helper", return_value=Path("/tmp/test-windows")), \
             mock.patch.object(playtest, "command", return_value=SimpleNamespace(
                 stdout='{"available":true,"on_console":true,"locked":false}')):
            playtest.require_unlocked_desktop()


if __name__ == "__main__":
    unittest.main()
