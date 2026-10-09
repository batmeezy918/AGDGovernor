import importlib.util
from pathlib import Path
import unittest
p=Path(__file__).with_name('device_governor.py')
spec=importlib.util.spec_from_file_location('device_governor',p)
mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
class GovernorPolicyTests(unittest.TestCase):
 def test_no_sensor_fails_closed(self):
  d=mod.governor_decision([{'thermal_sysfs':{'max_c':None}}]); self.assertEqual(d['mode'],'OBSERVE_ONLY'); self.assertIn('NO_AUTONOMOUS_STRESS',d['allowed_action'])
 def test_hot_sensor_stops(self): self.assertEqual(mod.governor_decision([{'thermal_sysfs':{'max_c':43.0}}],42.0)['mode'],'COOLDOWN')
 def test_rapid_rise_stops(self): self.assertEqual(mod.governor_decision([{'thermal_sysfs':{'max_c':35.0}},{'thermal_sysfs':{'max_c':38.1}}],42.0)['mode'],'COOLDOWN')
 def test_safe_sensor_allows_paced_work(self): self.assertEqual(mod.governor_decision([{'thermal_sysfs':{'max_c':34.0}},{'thermal_sysfs':{'max_c':34.5}}],42.0)['mode'],'PACE')
 def test_no_zero_fabrication(self):
  snap=mod.snapshot()
  if not snap['thermal_sysfs']['available']: self.assertIsNone(snap['thermal_sysfs']['max_c'])
 def test_no_sysfs_write_contract(self):
  src=p.read_text().lower(); self.assertIn('no sysfs writes',src); self.assertIn('no_autonomous_stress',src); self.assertNotIn('write_text(',src)
if __name__=='__main__': unittest.main(verbosity=2)
