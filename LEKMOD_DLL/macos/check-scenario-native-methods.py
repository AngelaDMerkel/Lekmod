#!/usr/bin/env python3
"""Reject unknown native colon-call names in explicitly selected scenario files.

This is a necessary binding-name check, not a receiver/signature/type checker.
Select scenarios that call only GameCore objects with colon syntax; UI contexts
and project Lua helper objects have APIs outside these registrations.
"""
import argparse
from pathlib import Path
import re

from playtest_native_methods import registered_methods, missing_methods

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('scenarios',nargs='+',type=Path)
    args=parser.parse_args();registered=registered_methods();failed=False
    # Regression for the real commissioning failure: C++ existence does not
    # mean the method is registered with Lua.
    assert missing_methods('u:IsGreatGeneral()',registered)==['IsGreatGeneral']
    assert not missing_methods('u:IsHasPromotion(id)',registered)
    for path in args.scenarios:
        missing=missing_methods(path.read_text(),registered)
        print(path.name+(': UNKNOWN '+', '.join(missing) if missing else ': native method names registered'))
        failed |= bool(missing)
    return int(failed)

if __name__=='__main__':raise SystemExit(main())
