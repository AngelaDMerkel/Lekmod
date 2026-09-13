#!/usr/bin/env python3
"""ASan regression for the actual unit GetScriptData Lua binding body.

The surrounding engine/Lua types are minimal stand-ins. This tests C++ lifetime,
not the host ABI; the native functional suite separately checks real Lua calls.
"""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1] / "CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp"
PREFIX = r'''
#include <cassert>
#include <string>
using CvString = std::string;
struct CvUnit {
    std::string data;
    std::string getScriptData() const { return data; }
};
struct lua_State { CvUnit *unit; std::string pushed; };
void lua_pushstring(lua_State *state, const char *value) { state->pushed.assign(value); }
struct CvLuaUnit {
    static CvUnit *GetInstance(lua_State *state) { return state->unit; }
    static int lGetScriptData(lua_State *state);
};
'''
SUFFIX = r'''
int main() {
    CvUnit unit;
    lua_State state{&unit, ""};
    for (const auto &value : {std::string(8192, 'x'), std::string("short"), std::string("")}) {
        unit.data = value;
        assert(CvLuaUnit::lGetScriptData(&state) == 1);
        assert(state.pushed == value);
    }
}
'''
OLD_BODY = r'''
int CvLuaUnit::lGetScriptData(lua_State* L)
{
    CvUnit* pkUnit = GetInstance(L);
    const char* szScriptData = pkUnit->getScriptData().c_str();
    lua_pushstring(L, szScriptData);
    return 1;
}
'''


class ScriptDataLifetimeTests(unittest.TestCase):
    def compile_and_run(self, body):
        with tempfile.TemporaryDirectory(prefix="lekmod-script-data-test-") as temp:
            source, binary = Path(temp) / "binding.cpp", Path(temp) / "binding"
            source.write_text(PREFIX + body + SUFFIX)
            subprocess.run(["clang++", "-std=c++11", "-O1", "-g", "-fsanitize=address",
                            "-fno-omit-frame-pointer", str(source), "-o", str(binary)],
                           check=True, capture_output=True, text=True)
            env = {**os.environ, "ASAN_OPTIONS": "detect_leaks=0:abort_on_error=0:exitcode=42"}
            return subprocess.run([str(binary)], capture_output=True, text=True, env=env)

    def test_previous_binding_reproduces_use_after_free(self):
        result = self.compile_and_run(OLD_BODY)
        self.assertEqual(result.returncode, 42, result.stderr)
        self.assertIn("heap-use-after-free", result.stderr)

    def test_current_binding_keeps_the_returned_string_alive(self):
        match = re.search(r"int CvLuaUnit::lGetScriptData\(lua_State\* L\)\n\{.*?\n\}",
                          SOURCE.read_text(), re.S)
        self.assertIsNotNone(match)
        result = self.compile_and_run(match.group())
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
