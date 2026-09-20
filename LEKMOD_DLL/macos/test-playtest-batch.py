#!/usr/bin/env python3
"""Protocol, persistence, fixture-integrity and fail-closed batch regression tests."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import playtest_batch as batch

class BatchTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name);self.code=self.root/'LEKMOD_DLL/macos';self.code.mkdir(parents=True)
        (self.code/'playtest-scenario-inventory.lua').write_text('LekmodScenario={step=function()end,snapshot=function()end}')
        self.fixture=self.root/'fixture.Civ5Save';self.fixture.write_bytes(b'fixture')
        self.raw={'schema':1,'name':'check','stages':[{'id':'one','scenario':'inventory','fixture':'fixture.Civ5Save','sha256':batch.sha(self.fixture),'max_turns':0}]}
        self.plan_path=self.root/'plan.json';self.items={'inventory':{'system-inventory'}}
    def load(self):
        self.plan_path.write_text(json.dumps(self.raw));return batch.load_plan(self.plan_path,self.root,self.items)
    def session(self):
        out=self.root/'evidence';out.mkdir();app=self.root/'app';data=self.root/'data'
        (app/'Contents/Assets/Assets/DLC/LEKMOD/Lua/UI').mkdir(parents=True)
        (data/'Saves/single').mkdir(parents=True)
        return batch.Session(self.load(),out,app,data,'test')
    def message(self,mode='run',failed=False):
        return dict(index=1,mode=mode,id='one',failed=failed,turns=0,outcomes={},state='{}',save_name='Lekmod-Batch-test-one-'+mode)
    def event(self,row):return '[LEKMOD_BATCH] run=test event=checkpoint value='+json.dumps(row)+'\n'
    def save(self,session,row):
        (session.data/'Saves/single'/(row['save_name']+'.Civ5Save')).write_bytes(b'checkpoint')
        return '[LEKMOD_BATCH] run=test event=saved value='+json.dumps(row['save_name'])+'\n'
    def test_hash_mismatch_rejected(self):
        self.fixture.write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError,'hash mismatch'):self.load()
    def test_unsupported_and_duplicate_stages_rejected(self):
        self.raw['stages']*=2
        with self.assertRaisesRegex(ValueError,'duplicate'):self.load()
        self.raw['stages']=self.raw['stages'][:1];self.raw['stages'][0]['scenario']='not-reviewed'
        with self.assertRaisesRegex(ValueError,'Unsupported'):self.load()
    def test_unprovided_ui_response_is_rejected_before_launch(self):
        source=self.code/'playtest-scenario-inventory.lua'
        source.write_text('LuaEvents.LekmodMissingResponse.Add(function()end)')
        with self.assertRaisesRegex(ValueError,'Missing UI response adapter'):self.load()
        source.write_text(source.read_text()+'\nLuaEvents.LekmodMissingResponse()')
        self.assertEqual(len(self.load()['stages']),1)
    def test_total_turns_bound(self):
        row=self.raw['stages'][0];row['max_turns']=19
        self.raw['stages'].append({**row,'id':'two'})
        with self.assertRaisesRegex(ValueError,'30 total'):self.load()
    def test_no_advance_before_save_and_ack(self):
        s=self.session();r=self.message();text=self.event(r)
        self.assertFalse(s.update(text,''));self.assertEqual(s.mode,'run')
        ack=self.save(s,r);self.assertFalse(s.update(text,''))
        self.assertTrue(s.update(text+ack,''));self.assertEqual(s.mode,'reload')
        self.assertFalse(s.done);self.assertEqual(s.results[0]['saved_sha256'],batch.sha(Path(s.results[0]['saved_copy'])))
    def test_success_requires_exact_reload_checkpoint(self):
        s=self.session();r=self.message();text=self.event(r)+self.save(s,r);s.update(text,'abc')
        self.assertEqual(json.loads((s.output/'batch-control.json').read_text())['expected'],'{}')
        reload=self.message('reload');text+=self.event(reload)+self.save(s,reload);s.update(text,'abcdef')
        self.assertTrue(s.done);self.assertFalse(s.failed);self.assertEqual(len(s.results),2)
        self.assertFalse(s.update(text,'abcdef'));self.assertEqual(len(s.results),2)
    def test_failure_stays_failed_without_false_reload_pass(self):
        s=self.session();r=self.message(failed=True);s.update(self.event(r)+self.save(s,r),'')
        self.assertTrue(s.done);self.assertTrue(s.failed);self.assertEqual(len(s.results),1)
    def test_unexpected_checkpoint_path_rejected(self):
        s=self.session();r=self.message();r['save_name']='../../outside'
        with self.assertRaisesRegex(ValueError,'filename'):s.update(self.event(r),'')
    def test_log_rollover_keeps_prior_failure(self):
        s=self.session();s.collect('first FAIL\n');s.collect('second\n')
        self.assertIn('first FAIL',s.transcript);self.assertIn('second',s.transcript)
        old=s.transcript;s.collect('second\n');self.assertEqual(old,s.transcript)
    def test_render_reset_requires_authorized_load(self):
        s=self.session();s.epoch_offset=10
        with self.assertRaisesRegex(ValueError,'authorized'):s.epoch_text('short')
        s.transitioning=True;self.assertEqual(s.epoch_text('short'),'short')
    def test_prior_game_log_is_not_part_of_new_batch_evidence(self):
        data=self.root/'data';(data/'Logs').mkdir(parents=True)
        (data/'Logs/Lua.log').write_text('old Runtime Error: not this run\n')
        s=self.session();self.assertEqual(s.collect('old Runtime Error: not this run\n'),'')
        self.assertEqual(s.collect('new session\n'),'\nnew session\n')
    def test_failed_stage_advances_only_to_independent_hashed_fixture(self):
        self.raw['stages'].append({**self.raw['stages'][0], 'id':'two'})
        s=self.session();r=self.message(failed=True)
        s.update(self.event(r)+self.save(s,r),'abc')
        control=json.loads((s.output/'batch-control.json').read_text())
        self.assertEqual(control['index'],2)
        self.assertEqual(control['path'],str(self.fixture.resolve()))
        self.assertFalse(s.done);self.assertTrue(s.failed)
    def test_changed_next_fixture_prevents_transition(self):
        self.raw['stages'].append({**self.raw['stages'][0], 'id':'two'})
        s=self.session();r=self.message(failed=True);self.fixture.write_bytes(b'tampered')
        with self.assertRaisesRegex(ValueError,'changed during batch'):
            s.update(self.event(r)+self.save(s,r),'abc')
        self.assertEqual(s.command,0)
    def test_adapter_bridge_preserves_print_and_forwards_only_this_run(self):
        root=Path(__file__).resolve().parents[2];interpreter=root/'build/macos/test-deps/lua-5.1.4/src/lua'
        p=self.root/'bridge.lua'
        setup='LuaEvents={LekmodBatchAssertion=function(item,status,detail)print("BRIDGE",item,status,detail)end}\n'
        code='function callback()print("[LEKMOD_FUNCTIONAL] run=test item=cancel status=PASS original-detail");print("[LEKMOD_FUNCTIONAL] run=old item=cancel status=FAIL stale")end'
        p.write_text(setup+batch.wrap_adapter(code).replace('__TEST_RUN__','test')+'callback()\n')
        out=subprocess.check_output([str(interpreter),str(p)],text=True)
        self.assertIn('run=test item=cancel status=PASS original-detail',out)
        self.assertIn('BRIDGE\tcancel\tPASS\toriginal-detail',out)
        self.assertEqual(out.count('BRIDGE'),1)
    def test_lua_serialization_roundtrips_utf8_and_escapes(self):
        root=Path(__file__).resolve().parents[2];interpreter=root/'build/macos/test-deps/lua-5.1.4/src/lua'
        value='quote"\\\nMāori\x00end';p=self.root/'literal.lua';p.write_text('io.write('+batch.lua(value)+')')
        self.assertEqual(subprocess.check_output([str(interpreter),str(p)]),value.encode())

if __name__=='__main__':unittest.main()
