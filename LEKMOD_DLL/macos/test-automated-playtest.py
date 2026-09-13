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
    def test_foreground_exception_is_bounded_and_ui_only(self):
        script = str(Path(__file__).with_name("automated-playtest.py"))
        for mode, timeout in (("human-turns", "180"), ("ui-interaction", "181")):
            result = subprocess.run([sys.executable, script, "--foreground-attachment-test",
                                     "--mode", mode, "--timeout", timeout],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertIn("Foreground attachment tests require", result.stderr)

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
