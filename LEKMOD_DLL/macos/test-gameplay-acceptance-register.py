#!/usr/bin/env python3
"""Acceptance gates must reject missing, changed or contradictory evidence."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('check',Path(__file__).with_name('check-gameplay-acceptance.py'))
check=importlib.util.module_from_spec(spec);spec.loader.exec_module(check)


class RegisterTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name)
        self.put('discovery.json',{'candidates':[{'id':'data:Traits.Bonus'}]})
        self.put('parameters.json',{'data:Traits.Bonus':[{'type':'TRAIT_TEST','value':2}]})
        self.put('source.lua','source');self.put('fixture.Civ5Save','fixture')
        self.case={'id':'CASE','group':'G4','title':'native bonus','status':'ready',
          'source_references':[self.ref('source.lua')],'owners':['human'],'expected_result':2,'units':'yield',
          'supplied_inputs':['prerequisite'],'actual_trigger':'native action','negative_controls':['no prerequisite'],
          'transitions':['action','reload'],'persistence_requirement':'exact snapshot','required_evidence_level':['native-gameplay-outcome'],
          'fixtures':[self.ref('fixture.Civ5Save')],'batch':'test','stage':'stage','evidence':[],'surface_ids':['data:Traits.Bonus']}
        self.reg={'schema_version':1,'gate_G0_passed':False,'discovery':{'report':self.ref('discovery.json'),'parameters':self.ref('parameters.json')},
          'cases':[self.case],'surface_review':[{'id':'data:Traits.Bonus','status':'mapped','case_ids':['CASE']}],
          'pending_doc_entries':[],'dependency_review':[]}
    def put(self,name,value):
        p=self.root/name;p.write_text(json.dumps(value));return p
    def ref(self,name):return {'path':name,'sha256':check.sha(self.root/name)}
    def evidence(self):
        report={'status':'passed-scenario-checks-only','normal_exit_verified':True,'process_returncode':0,'binary_sha256':'a'*64,
          'settings_restored':True,'temporary_ui_hooks_restored':True,'manual_saves_preserved':True,'lua_runtime_errors':[],
          'synchronization_checks':{'rng_sync_failure':False},'new_diagnostics':[]}
        self.put('checkpoint.Civ5Save','saved')
        common={'id':'stage','failed':False,'state':'{"value":2}','saved_copy':str(self.root/'checkpoint.Civ5Save'),'saved_sha256':check.sha(self.root/'checkpoint.Civ5Save')}
        batch={'complete':True,'failed':False,'results':[dict(common,mode='run',outcomes={'bonus':'PASS'}),dict(common,mode='reload',outcomes={'save-reload':'PASS'})]}
        self.put('report.json',report);self.put('batch.json',batch)
        self.case.update(status='covered-by-evidence',evidence=[self.ref('report.json'),self.ref('batch.json')],
          evidence_contract={'kind':'native-batch-stage','report':'report.json','batch_report':'batch.json','stage':'stage','required_assertions':['bonus'],'gamecore_sha256':'a'*64})
        return report,batch
    def repin(self):self.case['evidence']=[self.ref('report.json'),self.ref('batch.json')]
    def test_zero_is_a_valid_explicit_oracle(self):
        self.case['expected_result']=0
        self.assertTrue(check.validate(self.reg,self.root)['gate_G0_passed'])

    def test_unrecognized_review_status_cannot_hide_an_unfinished_row(self):
        self.reg['pending_doc_entries']=[{'id':'pending','status':'ignored','case_ids':[]}]
        with self.assertRaisesRegex(ValueError,'invalid document'):check.validate(self.reg,self.root)

    def test_valid_design_is_not_claimed_as_a_native_pass(self):
        result=check.validate(self.reg,self.root);self.assertTrue(result['gate_G0_passed']);self.assertEqual(result['case_statuses'],{'ready':1})
    def test_untriaged_case_blocks_g0(self):
        self.case['status']='untriaged';self.assertFalse(check.validate(self.reg,self.root)['gate_G0_passed'])
        self.reg['gate_G0_passed']=True
        with self.assertRaisesRegex(ValueError,'false G0'):check.validate(self.reg,self.root)
    def test_missing_surface_and_case_ids_are_rejected(self):
        self.reg['surface_review']=[]
        with self.assertRaisesRegex(ValueError,'cover discovery'):check.validate(self.reg,self.root)
    def test_changed_fixture_is_rejected(self):
        self.put('fixture.Civ5Save','changed')
        with self.assertRaisesRegex(ValueError,'changed/missing'):check.validate(self.reg,self.root)
    def test_ready_case_cannot_have_unresolved_design(self):
        self.case['missing_design']=['unknown oracle']
        with self.assertRaisesRegex(ValueError,'incomplete design'):check.validate(self.reg,self.root)
    def test_failed_native_report_cannot_be_reclassified_as_passed(self):
        report,batch=self.evidence();report['status']='failed-functional-checks';self.put('report.json',report);self.repin()
        with self.assertRaisesRegex(ValueError,'pass/exit'):check.validate(self.reg,self.root)
    def test_missing_assertion_or_failed_replay_is_rejected(self):
        report,batch=self.evidence();batch['results'][0]['outcomes']={};self.put('batch.json',batch);self.repin()
        with self.assertRaisesRegex(ValueError,'assertion/replay'):check.validate(self.reg,self.root)
    def test_corrupt_save_copy_is_rejected(self):
        self.evidence();self.put('checkpoint.Civ5Save','truncated')
        with self.assertRaisesRegex(ValueError,'checkpoint bytes'):check.validate(self.reg,self.root)
    def test_changed_saved_state_is_rejected(self):
        report,batch=self.evidence();batch['results'][1]['state']='{"value":3}';self.put('batch.json',batch);self.repin()
        with self.assertRaisesRegex(ValueError,'assertion/replay'):check.validate(self.reg,self.root)
    def test_passing_evidence_contract_is_verified(self):
        self.evidence();self.assertTrue(check.validate(self.reg,self.root)['gate_G0_passed'])
    def test_reference_cannot_escape_checkout(self):
        self.case['source_references']=[{'path':'../outside','sha256':'a'*64}]
        with self.assertRaisesRegex(ValueError,'inside the checkout'):check.validate(self.reg,self.root)


if __name__=='__main__':unittest.main()
