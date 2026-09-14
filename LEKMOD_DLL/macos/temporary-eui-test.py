#!/usr/bin/env python3
"""Run one bounded playtest with private EUI assets, then restore standard UI.

GameCore and LEKMOD payload changes belong to the central installer. Only the
separate, previously absent UI_bc1 directory and EUI text files are temporary
test inputs here. The original EUI archive is not redistributed by this tool.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("playtest", Path(__file__).with_name("automated-playtest.py"))
playtest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(playtest)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tree(path):
    return {p.relative_to(path).as_posix(): digest(p) for p in path.rglob("*") if p.is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--installer", type=Path, required=True)
    parser.add_argument("--eui-root", type=Path, required=True)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--restore-package", type=Path, required=True)
    parser.add_argument("playtest_args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    rest = args.playtest_args[1:] if args.playtest_args[:1] == ["--"] else args.playtest_args
    if not rest or playtest.game_pids():
        raise SystemExit("Supply playtest arguments and close Civ V first")
    eui = playtest.APP / "Contents/Assets/Assets/DLC/UI_bc1"
    if eui.exists():
        raise SystemExit("An existing EUI installation must not be overwritten")
    source = args.eui_root.resolve()
    if not (source / "UI_bc1").is_dir() or "Version 1.28g" not in (source / "Readme.txt").read_text(errors="replace"):
        raise SystemExit("Expected the extracted EUI 1.28g archive")
    for p in source.rglob("*"):
        if p.is_symlink():
            raise SystemExit("EUI test inputs cannot contain symlinks")
    with zipfile.ZipFile(args.restore_package) as archive:
        manifest = json.loads(archive.read("manifest.json"))
    prefix = "payload/LEKMOD/"
    expected = {k[len(prefix):]: v for k, v in manifest["files"].items() if k.startswith(prefix)}
    installed = playtest.APP / "Contents/Assets/Assets/DLC/LEKMOD"
    binary = playtest.APP / "Contents/MacOS/libCvGameCoreDLL_Expansion2_DLL.dylib"
    if tree(installed) != expected or digest(binary) != manifest["gamecore_sha256"]:
        raise SystemExit("Restore archive does not exactly match the current installation")
    evidence = ROOT / "build/macos/eui-tests" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    evidence.mkdir(parents=True)
    text_dir = playtest.DATA / "Text"
    if text_dir.is_symlink():
        raise SystemExit("Do not replace text files through a symlink")
    text_existed = text_dir.exists()
    originals = {}
    for p in source.glob("EUI_text_*.xml"):
        target = text_dir / p.name
        if target.is_symlink():
            raise SystemExit("Do not replace an EUI text symlink: " + str(target))
        originals[target] = target.read_bytes() if target.exists() else None
        if target.exists():
            (evidence / target.name).write_bytes(originals[target])
    option_originals = {}
    option_backup = evidence / "options-original"
    option_backup.mkdir()
    for suffix in ("", "-journal", "-wal", "-shm"):
        path = playtest.DATA / "ModUserData" / ("Enhanced User Interface Options-1.db" + suffix)
        if path.is_symlink():
            raise SystemExit("Do not replace an EUI options symlink: " + str(path))
        option_originals[path] = path.read_bytes() if path.exists() else None
        if path.exists():
            (option_backup / path.name).write_bytes(option_originals[path])
    state = {"eui_input_files": tree(source), "standard_archive": str(args.restore_package.resolve()),
             "standard_archive_sha256": digest(args.restore_package), "eui_archive": str(args.package.resolve()),
             "eui_archive_sha256": digest(args.package), "text_originals": {str(p): data is not None for p, data in originals.items()},
             "text_directory_existed": text_existed, "restored": False}
    state["option_originals"] = {str(p): data is not None for p, data in option_originals.items()}
    state_file = evidence / "state.json"
    state_file.write_text(json.dumps(state, indent=2) + "\n")

    def install(package):
        subprocess.run(["python3", str(args.installer.resolve()), "--gamecore", "lekmod", "--gamecore-package",
                        str(package.resolve()), "--gamecore-sha256", digest(package), "--yes"], check=True)

    eui_created = False
    try:
        install(args.package)
        eui.mkdir()
        eui_created = True
        shutil.copytree(source / "UI_bc1", eui, dirs_exist_ok=True)
        text_dir.mkdir(exist_ok=True)
        for target in originals:
            shutil.copy2(source / target.name, target)
        result = subprocess.run(["python3", str(Path(__file__).with_name("automated-playtest.py")), *rest])
        state["playtest_returncode"] = result.returncode
    finally:
        if playtest.game_pids():
            raise RuntimeError("Civ V is still running; retained EUI and restoration evidence at " + str(evidence))
        if eui_created and eui.exists():
            state["eui_files_after"] = tree(eui)
            shutil.rmtree(eui)
        for target, data in originals.items():
            if data is None:
                target.unlink(missing_ok=True)
            else:
                target.write_bytes(data)
        if not text_existed and text_dir.exists() and not any(text_dir.iterdir()):
            text_dir.rmdir()
        for path, data in option_originals.items():
            if data is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(data)
        install(args.restore_package)
        state["restored"] = tree(installed) == expected and digest(binary) == manifest["gamecore_sha256"] and not eui.exists()
        state["text_restored"] = all((not p.exists()) if data is None else p.read_bytes() == data for p, data in originals.items())
        state["options_restored"] = all((not p.exists()) if data is None else p.read_bytes() == data for p, data in option_originals.items())
        state_file.write_text(json.dumps(state, indent=2) + "\n")
        print(json.dumps({"event": "eui-test-cleanup", "evidence": str(evidence),
                          "restored": state["restored"], "text_restored": state["text_restored"],
                          "options_restored": state["options_restored"]}), flush=True)
    if not state["restored"] or not state["text_restored"] or not state["options_restored"]:
        raise SystemExit("EUI cleanup verification failed")
    return state["playtest_returncode"]


if __name__ == "__main__":
    raise SystemExit(main())
