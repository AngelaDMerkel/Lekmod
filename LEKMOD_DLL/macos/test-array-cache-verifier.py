#!/usr/bin/env python3
"""Ensure absent, malformed or contradictory native data cannot count as parity."""
import hashlib,json,sqlite3,subprocess,sys,tempfile,unittest
from pathlib import Path
from contextlib import closing
VERIFIER=Path(__file__).with_name('verify-array-cache-log.py')
class VerifierTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name);self.db=self.root/'fixture.db'
  with closing(sqlite3.connect(self.db))as c, c:
   c.executescript('CREATE TABLE Owners(ID INTEGER,Type TEXT); INSERT INTO Owners VALUES(0,"A"),(1,"B");CREATE TABLE Axes(ID INTEGER,Type TEXT);INSERT INTO Axes VALUES(0,"X"),(2,"Z");CREATE TABLE Relations(OwnerType TEXT,AxisType TEXT,Value INTEGER);INSERT INTO Relations VALUES("A","X",7),("A","Z",-3);')
  common=dict(table='Owners',relation_table='Relations',index_table='Axes',index_column='AxisType',owner_column='OwnerType',length=3,value_column=None)
  self.bindings=[dict(common,key='values',mode='indexed-value',default=5,value_column='Value'),dict(common,key='mask',mode='membership',default=0),dict(common,key='list',mode='compact-ids',default=-1)]
  self.rows={('values',0):[7,5,-3],('values',1):[5,5,5],('mask',0):[True,False,True],('mask',1):[False]*3,('list',0):[2,-1,0],('list',1):[-1]*3}
 def run_case(self,expected=True,extra='',run='test',wrong_hash=False):
  meta=self.root/'bindings.json';meta.write_text(json.dumps(dict(bindings=self.bindings,warnings=[],rejected=[])))
  log=self.root/'native.log';lines=[]
  for (key,owner),values in self.rows.items():
   raw={str(i+1):v for i,v in enumerate(values)};lines.append('[LEKMOD_ARRAY_CACHE] run='+run+' key='+key+' id='+str(owner)+' data='+json.dumps(raw))
  log.write_text('\n'.join(lines)+'\n'+extra)
  digest=hashlib.sha256(self.db.read_bytes()).hexdigest()
  cmd=[sys.executable,str(VERIFIER),'--log',str(log),'--run','test','--bindings',str(meta),'--database',str(self.db),'--database-sha256','0'*64 if wrong_hash else digest,'--output',str(self.root/'result.json')]
  r=subprocess.run(cmd,capture_output=True,text=True);self.assertEqual(r.returncode==0,expected,r.stdout+r.stderr)
 def test_values_membership_compact_order_and_defaults(self):self.run_case()
 def test_missing_owner_rejected(self):del self.rows[('mask',1)];self.run_case(False)
 def test_wrong_value_rejected(self):self.rows[('values',0)][1]=0;self.run_case(False)
 def test_boolean_type_not_interchangeable_with_zero(self):self.rows[('mask',0)][1]=0;self.run_case(False)
 def test_compact_duplicate_not_a_set(self):self.rows[('list',0)]=[0,0,-1];self.run_case(False)
 def test_missing_element_rejected(self):self.rows[('values',0)].pop();self.run_case(False)
 def test_wrong_run_cannot_supply_evidence(self):self.run_case(False,run='other')
 def test_conflicting_repeated_row_rejected(self):self.run_case(False,extra='[LEKMOD_ARRAY_CACHE] run=test key=values id=0 data={"1":7,"2":6,"3":-3}\n')
 def test_conflicting_sql_duplicates_rejected(self):
  with closing(sqlite3.connect(self.db))as c, c:c.execute('insert into Relations values("A","X",8)')
  self.run_case(False)
 def test_database_identity_required(self):self.run_case(False,wrong_hash=True)
if __name__=='__main__':unittest.main()
