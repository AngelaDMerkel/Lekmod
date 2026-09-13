#!/usr/bin/env python3
"""Opt-in local Steam socket lookup workaround. Steam must be closed.

Changes only the lookup command literal in steamui/steamclient dylibs, then
ad-hoc signs those libraries. Original Valve-signed copies and exact hashes
are retained. No global utility, Docker setting, or connection check changes.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path.home() / "Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS"
STATE = Path.home() / ".steam-socket-compat"
HELPER = Path.home() / ".steam-ls"
NEEDLE = b"/usr/sbin/lsof -F up -i TCP@%s"
NAMES = ("steamui.dylib", "steamclient.dylib")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(*args):
    subprocess.run(args, check=True)


def verify(path):
    # Explicit slices avoid an intermittent codesign universal-file error.
    for arch in ("arm64", "x86_64"):
        run("codesign", "--verify", "--arch", arch, str(path))


def sign_slices(path):
    # Valve's fat-library layout cannot always be re-signed directly. Sign
    # each Mach-O slice, then let lipo construct a valid universal layout.
    slices = []
    for arch in ("arm64", "x86_64"):
        thin = path.with_name(path.name + "." + arch)
        run("lipo", str(path), "-thin", arch, "-output", str(thin))
        run("codesign", "--force", "--sign", "-", str(thin))
        slices.append(str(thin))
    run("lipo", "-create", *slices, "-output", str(path))
    verify(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["install", "restore", "status"])
    args = parser.parse_args()
    manifest_path = STATE / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else None
    if args.action == "status":
        print(json.dumps({"manifest": manifest, "current_sha256": {
            name: digest(ROOT / name) for name in NAMES},
            "helper_exists": HELPER.exists()}, indent=2))
        return
    if subprocess.run(["pgrep", "-x", "steam_osx"], capture_output=True).returncode != 1:
        raise SystemExit("Steam must be closed; unable to proceed")
    if args.action == "restore":
        if not manifest:
            raise SystemExit("No patch manifest exists")
        for name in NAMES:
            if digest(ROOT / name) != manifest["patched_sha256"][name]:
                raise SystemExit("Steam changed since patching; refusing to overwrite " + name)
            if digest(Path(manifest["backup"]) / name) != manifest["original_sha256"][name]:
                raise SystemExit("Backup checksum mismatch: " + name)
        for name in NAMES:
            shutil.copy2(Path(manifest["backup"]) / name, ROOT / name)
        manifest["restored"] = True
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        print("Restored original Valve-signed libraries. Backup and helper retained.")
        return

    replacement = ("'" + str(HELPER) + "' %s").encode()
    if "'" in str(HELPER) or len(replacement) > len(NEEDLE):
        raise SystemExit("Home path cannot fit safely in the existing command literal")
    if manifest and not manifest.get("restored"):
        if all(digest(ROOT / name) == manifest["patched_sha256"][name] for name in NAMES):
            print("Patch already installed")
            return
        if not all(digest(ROOT / name) == manifest["original_sha256"][name] for name in NAMES):
            raise SystemExit("Steam has updated; preserve/review the old manifest before applying a new patch")
        print("Steam restored the verified originals; reapplying the same patch")
    if HELPER.exists() and not manifest:
        raise SystemExit("Refusing to overwrite an existing untracked helper")
    originals = {}
    for name in NAMES:
        path = ROOT / name
        verify(path)
        data = path.read_bytes()
        if data.count(NEEDLE + b"\0") != 2:
            raise SystemExit("Unexpected command literals/architecture in " + name)
        originals[name] = data
    STATE.mkdir(mode=0o700, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup = STATE / ("original-" + stamp)
    backup.mkdir(mode=0o700)
    staged = STATE / ("staged-" + stamp)
    staged.mkdir(mode=0o700)
    for name in NAMES:
        shutil.copy2(ROOT / name, backup / name)
        (staged / name).write_bytes(originals[name].replace(
            NEEDLE + b"\0", replacement.ljust(len(NEEDLE), b" ") + b"\0"))
        sign_slices(staged / name)
    helper_build = staged / "socket-lookup"
    run("clang", "-O2", "-arch", "arm64", "-arch", "x86_64",
        str(Path(__file__).with_name("socket-lookup.c")), "-o", str(helper_build))
    run("codesign", "--force", "--sign", "-", str(helper_build))
    manifest = {"installed_utc": stamp, "backup": str(backup), "helper": str(HELPER),
                "replacement": replacement.decode(), "original_sha256": {
                    name: digest(backup / name) for name in NAMES},
                "patched_sha256": {name: digest(staged / name) for name in NAMES}}
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    try:
        shutil.copy2(helper_build, HELPER)
        HELPER.chmod(0o755)
        for name in NAMES:
            shutil.copy2(staged / name, ROOT / name)
            verify(ROOT / name)
    except BaseException:
        for name in NAMES:
            shutil.copy2(backup / name, ROOT / name)
        manifest["restored"] = True
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        raise
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
