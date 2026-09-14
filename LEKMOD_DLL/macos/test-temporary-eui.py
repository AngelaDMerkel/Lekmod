#!/usr/bin/env python3
"""Verify restoration on a failed EUI test without touching the real game."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location("eui_test", Path(__file__).with_name("temporary-eui-test.py"))
eui_test = importlib.util.module_from_spec(spec)
spec.loader.exec_module(eui_test)


class RestorationTests(unittest.TestCase):
    def test_failed_runner_restores_existing_text_and_managed_payload(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            app, data = root / "game.app", root / "data"
            payload = app / "Contents/Assets/Assets/DLC/LEKMOD"
            payload.mkdir(parents=True)
            (payload / "UI.lua").write_bytes(b"standard")
            binary = app / "Contents/MacOS/libCvGameCoreDLL_Expansion2_DLL.dylib"
            binary.parent.mkdir(parents=True)
            binary.write_bytes(b"gamecore")
            text = data / "Text/EUI_text_en_us.xml"
            text.parent.mkdir(parents=True)
            text.write_bytes(b"original user text")
            options = data / "ModUserData/Enhanced User Interface Options-1.db"
            options.parent.mkdir()
            options.write_bytes(b"original user options")
            source = root / "eui-source"
            (source / "UI_bc1").mkdir(parents=True)
            (source / "UI_bc1/EUI.lua").write_bytes(b"temporary eui")
            (source / "Readme.txt").write_text("Version 1.28g")
            (source / text.name).write_bytes(b"temporary text")
            package, restore = root / "variant.zip", root / "standard.zip"
            package.write_bytes(b"mock installer input")
            manifest = {"gamecore_sha256": eui_test.digest(binary),
                        "files": {"payload/LEKMOD/UI.lua": hashlib.sha256(b"standard").hexdigest()}}
            with zipfile.ZipFile(restore, "w") as archive:
                archive.writestr("manifest.json", json.dumps(manifest))
            argv = ["test", "--installer", str(root / "installer.py"), "--eui-root", str(source),
                    "--package", str(package), "--restore-package", str(restore), "--", "--mode", "ui-interaction"]
            def run(command, **kwargs):
                if "--gamecore-package" in command:
                    selected = Path(command[command.index("--gamecore-package") + 1])
                    (payload / "UI.lua").write_bytes(b"standard" if selected == restore.resolve() else b"eui overlay")
                    return subprocess.CompletedProcess(command, 0)
                self.assertEqual(text.read_bytes(), b"temporary text")
                self.assertTrue((payload.parent / "UI_bc1/EUI.lua").exists())
                options.write_bytes(b"test changed options")
                options.with_name(options.name + "-journal").write_bytes(b"test journal")
                return subprocess.CompletedProcess(command, 42)
            with patch.object(eui_test, "ROOT", root), patch.object(eui_test.playtest, "APP", app), \
                 patch.object(eui_test.playtest, "DATA", data), patch.object(eui_test.playtest, "game_pids", return_value=[]), \
                 patch("sys.argv", argv), patch.object(eui_test.subprocess, "run", side_effect=run):
                self.assertEqual(eui_test.main(), 42)
            self.assertEqual(text.read_bytes(), b"original user text")
            self.assertEqual(options.read_bytes(), b"original user options")
            self.assertFalse(options.with_name(options.name + "-journal").exists())
            self.assertEqual((payload / "UI.lua").read_bytes(), b"standard")
            self.assertFalse((payload.parent / "UI_bc1").exists())
            state = json.loads(next((root / "build/macos/eui-tests").glob("*/state.json")).read_text())
            self.assertTrue(state["restored"] and state["text_restored"] and state["options_restored"])


if __name__ == "__main__":
    unittest.main()
