#!/usr/bin/env python3
"""Prevent the observed UnitCreated coordinate/type callback mismatch."""
import unittest
from playtest_native_methods import event_arity_errors

class CallbackArityTests(unittest.TestCase):
    def test_observed_five_parameter_callback_is_rejected(self):
        self.assertTrue(event_arity_errors('GameEvents.UnitCreated.Add(function(owner,id,kind,x,y) end)'))
    def test_actual_signature_and_short_observers_are_accepted(self):
        for args in ('owner,id,x,y','owner,id','', 'owner,id,...'):
            self.assertEqual(event_arity_errors('GameEvents.UnitCreated.Add(function('+args+') end)'),[])
    def test_quoted_example_is_not_a_callback(self):
        self.assertEqual(event_arity_errors('print("GameEvents.UnitCreated.Add(function(a,b,c,d,e) end)")'),[])
    def test_comments_and_other_hooks_are_not_misclassified(self):
        self.assertEqual(event_arity_errors('-- GameEvents.UnitCreated.Add(function(a,b,c,d,e) end)\nGameEvents.UnitPrekill.Add(function(a,b,c,d,e,f,g) end)'),[])
if __name__=='__main__':unittest.main()
