#!/usr/bin/env python3
"""Protocol, persistence, fixture-integrity and fail-closed batch regression tests."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import signal
import sys
import time
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
        return batch.Session(self.load(),out,app,data,'test',save_writer_open=lambda path:False,save_settle_seconds=0)
    def message(self,mode='run',failed=False):
        return dict(index=1,mode=mode,id='one',failed=failed,turns=0,outcomes={},state='{}',save_name='Lekmod-Batch-test-one-'+mode)
    def event(self,row):return '[LEKMOD_BATCH] run=test event=checkpoint value='+json.dumps(row)+'\n'
    def save(self,session,row):
        (session.data/'Saves/single'/(row['save_name']+'.Civ5Save')).write_bytes(b'checkpoint')
        return '[LEKMOD_BATCH] run=test event=saved value='+json.dumps(row['save_name'])+'\n'
    def expected_report(self, **changes):
        p=self.root/'expected.json'
        row=dict(status='passed-scenario-checks-only',normal_exit_verified=True,scenario='inventory',saved_sha256=batch.sha(self.fixture),saved_state='{}')
        row.update(changes);p.write_text(json.dumps(row))
        self.raw['stages'][0].update(expected_report='expected.json',expected_report_sha256=batch.sha(p),max_turns=0)
        return p
    def test_replay_only_starts_with_validated_snapshot_and_finishes_once(self):
        self.expected_report();s=self.session()
        self.assertEqual(s.mode,'reload');self.assertEqual(s.pending_expected,'{}')
        self.assertEqual(s.plan['stages'][0]['items'],[])
        self.assertIn('["mode"]="reload"',s.initial_control())
        r=self.message('reload');s.update(self.event(r)+self.save(s,r),'')
        self.assertTrue(s.done);self.assertEqual(len(s.results),1);self.assertEqual(s.turns,0)
    def test_replay_requires_matching_passing_report_and_hash(self):
        p=self.expected_report();p.write_text(p.read_text()+' ')
        with self.assertRaisesRegex(ValueError,'report hash'):self.load()
        self.expected_report(scenario='other')
        with self.assertRaisesRegex(ValueError,'scenario/save'):self.load()
        self.expected_report(saved_sha256='0'*64)
        with self.assertRaisesRegex(ValueError,'scenario/save'):self.load()
        self.expected_report(status='failed-stall')
        with self.assertRaisesRegex(ValueError,'passing native'):self.load()
        self.expected_report();self.raw['stages'][0]['max_turns']=1
        with self.assertRaisesRegex(ValueError,'zero turns'):self.load()
    def test_replay_rejects_partial_configuration_and_nonobject_snapshot(self):
        self.expected_report();del self.raw['stages'][0]['expected_report_sha256']
        with self.assertRaisesRegex(ValueError,'both expected'):self.load()
        self.expected_report(saved_state='[]')
        with self.assertRaisesRegex(ValueError,'snapshot object'):self.load()
    def test_next_replay_stage_receives_its_pinned_expectation(self):
        self.expected_report();self.raw['stages'].append({**self.raw['stages'][0],'id':'two'})
        s=self.session();r=self.message('reload');s.update(self.event(r)+self.save(s,r),'abc')
        c=json.loads((s.output/'batch-control.json').read_text())
        self.assertEqual(c['index'],2);self.assertEqual(c['mode'],'reload');self.assertEqual(c['expected'],'{}')
        self.assertFalse(s.done)
    def test_new_completed_check_advances_progress_without_completing_stage(self):
        s=self.session()
        one='[LEKMOD_FUNCTIONAL] run=test item=one::created-A status=PASS native-event\n'
        self.assertTrue(s.update(one,''))
        self.assertFalse(s.update(one,''))
        self.assertFalse(s.update(one+one,''))
        two='[LEKMOD_FUNCTIONAL] run=test item=one::created-B status=PASS native-event\n'
        self.assertTrue(s.update(one+two,''))
        self.assertFalse(s.update(two,''))  # A log reset cannot recount a check.
        self.assertFalse(s.done);self.assertEqual(s.results,[]);self.assertEqual(s.turns,0)
    def test_progress_ignores_other_runs_stages_failures_and_observations(self):
        s=self.session()
        for line in (
            '[LEKMOD_FUNCTIONAL] run=old item=one::check status=PASS old',
            '[LEKMOD_FUNCTIONAL] run=test item=two::check status=PASS future',
            '[LEKMOD_FUNCTIONAL] run=test item=one::check status=FAIL error',
            '[LEKMOD_BATCH] run=test event=observation value={"index":1,"mode":"run","event":"waiting"}',
        ):
            self.assertFalse(s.update(line,''),line)
        self.assertEqual(s.progress_items,set());self.assertFalse(s.done)
    def test_wrapper_interrupt_allows_real_child_finally_cleanup(self):
        self.check_owned_cleanup(False)
    def test_terminal_group_interrupt_allows_real_child_finally_cleanup(self):
        self.check_owned_cleanup(True)
    def check_owned_cleanup(self, group_interrupt):
        port=Path(__file__).resolve().parent
        ready=self.root/'ready';clean=self.root/'clean'
        child=self.root/'child.py';child.write_text('from pathlib import Path\nimport time\ntry:\n Path('+repr(str(ready))+').write_text("ready")\n time.sleep(60)\nfinally:\n Path('+repr(str(clean))+').write_text("restored")\n')
        controller=self.root/'controller.py';controller.write_text('import sys\nsys.path.insert(0,'+repr(str(port))+')\nimport playtest_batch\ncode=playtest_batch.run_owned_runner([sys.executable,'+repr(str(child))+'])\nprint("child-exit",code)\n')
        process=subprocess.Popen([sys.executable,str(controller)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,start_new_session=True)
        try:
            deadline=time.monotonic()+5
            while not ready.exists() and time.monotonic()<deadline:time.sleep(0.02)
            self.assertTrue(ready.exists())
            if group_interrupt:os.killpg(process.pid,signal.SIGINT)
            else:process.send_signal(signal.SIGINT)
            out,err=process.communicate(timeout=10)
            self.assertEqual(process.returncode,0,err)
            self.assertIn('child-exit',out)
            self.assertEqual(clean.read_text(),'restored')
        finally:
            if process.poll() is None:process.kill();process.wait()
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
    def test_save_ack_does_not_advance_while_writer_is_open(self):
        from playtest_save import CheckpointCopier
        s=self.session();r=self.message();text=self.event(r)+self.save(s,r);writing=[True]
        s.save_copier=CheckpointCopier(lambda path:writing[0],0)
        self.assertFalse(s.update(text,''));self.assertEqual(s.mode,'run');self.assertEqual(s.results,[])
        source=s.data/'Saves/single'/(r['save_name']+'.Civ5Save');source.write_bytes(b'complete asynchronous save');writing[0]=False
        self.assertTrue(s.update(text,''));self.assertEqual(s.mode,'reload')
        self.assertEqual(Path(s.results[0]['saved_copy']).read_bytes(),source.read_bytes())
        self.assertTrue(s.results[0]['save_verification']['source_copy_match'])

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
