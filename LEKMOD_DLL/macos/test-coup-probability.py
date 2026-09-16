#!/usr/bin/env python3
"""Count accepted RNG outcomes in the actual product coup comparison."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / "LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvEspionageClasses.cpp").read_bytes().decode("latin1")
function = source[source.index("bool CvPlayerEspionage::AttemptCoup("):]
comparison = re.search(r"if\((iRandRoll\s*<=?\s*GetCoupChanceOfSuccess\(uiSpyIndex\))\)", function)
assert comparison, "product coup comparison not found"
program = r'''
#include <iostream>
int chance;
int GetCoupChanceOfSuccess(int) { return chance; }
bool accept(int iRandRoll) { int uiSpyIndex=0; return CONDITION; }
int main() {
 int failed=0;
 for(chance=0;chance<=85;++chance) {
  int wins=0;
  // getJonRandNum(100) yields the integers 0 through 99.
  for(int roll=0;roll<100;++roll) wins+=accept(roll);
  if(wins!=chance) { ++failed; if(chance==0||chance==85)
   std::cout<<"FAIL quoted="<<chance<<" actual="<<wins<<" of 100\n"; }
 }
 std::cout<<"86 quoted probabilities, "<<failed<<" mismatches across all 100 possible rolls each\n";
 return failed?1:0;
}
'''.replace("CONDITION", comparison.group(1))
with tempfile.TemporaryDirectory(prefix="lekmod-coup-probability-") as d:
    path = Path(d)
    (path / "test.cpp").write_text(program)
    subprocess.run(["clang++", "-std=c++11", "-fsanitize=address,undefined", str(path / "test.cpp"), "-o", str(path / "test")], check=True)
    raise SystemExit(subprocess.run([str(path / "test")]).returncode)
