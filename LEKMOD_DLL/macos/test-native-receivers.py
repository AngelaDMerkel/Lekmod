#!/usr/bin/env python3
"""Prevent a city method being accepted for a unit by the global name union."""
import unittest
from playtest_native_methods import receiver_method_errors, registered_methods

class ReceiverTests(unittest.TestCase):
    def test_real_city_method_is_rejected_on_unit(self):
        self.assertIn('CanHurry',registered_methods())
        self.assertEqual(receiver_method_errors('-- @native-receiver u Unit\nu:CanHurry(plot)'),['u:CanHurry is not registered on Unit'])
    def test_native_unit_mission_and_city_methods_pass(self):
        self.assertEqual(receiver_method_errors('-- @native-receiver u Unit\n-- @native-receiver c City\nu:CanStartMission(1,0,0,plot,0);c:CanHurry(1,0)'),[])
    def test_quotes_and_comments_do_not_create_calls(self):
        self.assertEqual(receiver_method_errors('-- @native-receiver u Unit\n-- u:CanHurry(p)\nprint("u:CanHurry(p)")'),[])
    def test_unknown_or_conflicting_classes_fail(self):
        self.assertTrue(receiver_method_errors('-- @native-receiver u Missing\nu:CanHurry(p)'))
        self.assertTrue(receiver_method_errors('-- @native-receiver u Unit\n-- @native-receiver u City\nu:CanHurry(p)'))
    def test_unannotated_receiver_is_not_inferred(self):
        self.assertEqual(receiver_method_errors('u:CanHurry(p)'),[])
    def test_receiver_matching_is_exact(self):
        self.assertEqual(receiver_method_errors('-- @native-receiver u Unit\ncityu:CanHurry(p)'),[])
if __name__=='__main__':unittest.main()
