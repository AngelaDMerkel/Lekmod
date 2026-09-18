#!/usr/bin/env python3
"""Verify retained state evidence for the two-Museum physical UI fixture.

This checks engine observations, saves and cleanup, not proof of mouse input.
Physical inputs and screenshots are separately recorded in the session report.
"""
import argparse
import hashlib
import json
from pathlib import Path


def read(path):
    return json.loads(path.read_text())


def report(directory):
    result = read(directory / "report.json")
    assert result["mode"] == "ui-interaction"
    assert result["process_returncode"] == 0
    for key in ("settings_restored", "graphics_settings_restored",
                "temporary_ui_hooks_restored", "manual_saves_preserved"):
        assert result[key], key
    assert not result["lua_runtime_errors"]
    assert not any(result["synchronization_checks"].values())
    return result


def state(directory, filename, mode):
    value = read(directory / (filename + ".json"))["state"]
    assert value.startswith("179:0:true:")
    fields = dict(part.split("=", 1) for part in value.split()[1:])
    slots = {}
    for row in fields["greatworks"].split(";"):
        city, building, slot, work = map(int, row.split(","))
        slots[city, building, slot] = work
    expected = {
        "pair": {(8192, 40, 0): 1, (8192, 40, 1): 0, (16385, 40, 0): -1},
        "split": {(8192, 40, 0): -1, (8192, 40, 1): 0, (16385, 40, 0): 1},
        "swapped": {(8192, 40, 0): -1, (8192, 40, 1): 1, (16385, 40, 0): 0},
    }[mode]
    assert all(slots[key] == work for key, work in expected.items())
    assert sorted(work for work in slots.values() if work >= 0) == [0, 1]
    cities = {int(row.split(",")[0]): list(map(int, row.split(",")[1:]))
              for row in fields["culture_cities"].split(";")}
    assert cities == ({8192: [2, 2, 6], 16385: [0, 0, 0]} if mode == "pair"
                      else {8192: [1, 0, 2], 16385: [1, 0, 2]})
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--eui-run", type=Path, required=True)
    parser.add_argument("--standard-run", type=Path, required=True)
    args = parser.parse_args()
    eui = report(args.eui_run)
    standard = report(args.standard_run)
    assert eui["ui_variant"] == "eui" and standard["ui_variant"] == "standard"
    initial = read(args.eui_run / "initial-and-incompatible-state.json")
    assert initial["observed_state_count"] == 1
    split = state(args.eui_run, "first-split", "split")
    state(args.eui_run, "occupied-swap", "swapped")
    saved = state(args.eui_run, "saved-split", "split")
    assert split == saved
    pair = state(args.eui_run, "unsaved-pair", "pair")
    assert pair == initial["states"][0] and pair != saved
    assert state(args.eui_run, "quickloaded-split", "split") == saved
    assert state(args.standard_run, "standard-loaded-split", "split") == saved
    assert state(args.standard_run, "standard-incompatible", "split") == saved
    state(args.standard_run, "standard-occupied-swap", "swapped")
    state(args.standard_run, "standard-themed-pair", "pair")
    save = args.eui_run / "EUI-GreatWork-QuickSave.Civ5Save"
    digest = hashlib.sha256(save.read_bytes()).hexdigest()
    assert digest == read(args.eui_run / "greatwork-quicksave-hash.json")["sha256"]
    assert standard["save_sha256"] == digest
    assert eui["save_sha256"] != digest
    print(json.dumps({"verified": True, "quicksave_sha256": digest,
                      "checks": ["incompatible-slot-preservation", "occupied-swap",
                                 "theme-removal-and-restoration", "exact-quickload",
                                 "exact-cross-ui-load", "normal-exit-and-cleanup"]}, indent=2))


if __name__ == "__main__":
    main()
