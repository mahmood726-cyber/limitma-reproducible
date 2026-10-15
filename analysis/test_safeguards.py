"""Paired clean/damaged evidence tests for the archive comparison and R gate."""
from pathlib import Path
import copy,json,subprocess,unittest,tempfile,os,csv
from checks import read,compare,REFUSAL,pairs
ROOT=Path(__file__).resolve().parents[1]
class Safeguards(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.c=read(ROOT/'data/corpus.json');cls.r=read(ROOT/'results/reference.json');cls.a=read(ROOT/'results/app-patched.json')
 def test_clean_and_damaged_evidence(self):
  self.assertEqual(sum(x['passed'] for x in compare(self.c,self.r,self.a)),55524)
  mutations={
   'missing configuration':lambda c,r,a:a.pop(),
   'duplicate app ID':lambda c,r,a:a[1].update(id=a[0]['id']),
   'duplicate corpus ID':lambda c,r,a:c[1].update(id=c[0]['id']),
   'duplicate reference ID':lambda c,r,a:r[1].update(id=r[0]['id']),
   'extra ID':lambda c,r,a:a[0].update(id='unexpected'),
   'absent estimate':lambda c,r,a:a[0]['values'].pop('limit_est'),
   'null estimate':lambda c,r,a:a[0]['values'].update(limit_est=None),
   'NaN':lambda c,r,a:a[0]['values'].update(limit_est=float('nan')),
   'Infinity':lambda c,r,a:a[0]['values'].update(limit_est=float('inf')),
   'numeric string':lambda c,r,a:a[0]['values'].update(limit_est='1'),
   'boolean number':lambda c,r,a:a[0]['values'].update(limit_est=True),
   'absent nullable G':lambda c,r,a:a[0]['values'].pop('G_squared'),
   'study vector':lambda c,r,a:a[0]['values']['te_limit'].pop(),
   'geometry':lambda c,r,a:a[0]['regression'].pop(),
   'table type':lambda c,r,a:a[0].update(table_ok=1),
   'negative SE':lambda c,r,a:c[0]['se'].__setitem__(0,-1),
   'duplicate source row':lambda c,r,a:c[0]['source_rows'].__setitem__(1,c[0]['source_rows'][0]),
   'changed refusal':lambda c,r,a:next(x for x in r if x['id']==REFUSAL).update(reason='changed'),
   'disappearing refusal':lambda c,r,a:next(x for x in r if x['id']==REFUSAL).update(status='ok'),
  }
  for name,mutate in mutations.items():
   with self.subTest(name=name):
    c,r,a=copy.deepcopy((self.c,self.r,self.a));mutate(c,r,a)
    with self.assertRaises((AssertionError,ValueError,KeyError,TypeError)):compare(c,r,a)
  # A finite changed numerical result must become an additional failure, never be hidden.
  a=copy.deepcopy(self.a);a[0]['values']['limit_est']+=1
  self.assertEqual(sum(not x['passed'] for x in compare(self.c,self.r,a)),2)
 def test_json_duplicates_and_nonfinite(self):
  self.assertEqual(pairs([('a',1)]),{'a':1})
  with self.assertRaises(ValueError):pairs([('a',1),('a',2)])
  with tempfile.TemporaryDirectory(dir=ROOT,prefix='.verify-') as d:
   p=Path(d)/'bad.json'
   for content in ['{"a":1,"a":2}','{"a":NaN}','{"a":Infinity}']:
    p.write_text(content,encoding='utf-8')
    with self.assertRaises(ValueError):read(p)
 def test_native_r_safeguards(self):
  # Uses the same functions as validate.R; no substitute Python version of its gates.
  p=subprocess.run(['Rscript','analysis/test_safeguards.R'],cwd=ROOT,text=True,capture_output=True)
  self.assertEqual(p.returncode,0,p.stdout+p.stderr);self.assertIn('R SAFEGUARDS PASS',p.stdout)
 def test_inventory_includes_new_source_but_ignores_git(self):
  from verify_archive import source_files
  baseline=set(source_files())
  with tempfile.TemporaryDirectory(prefix='.verify-',dir=ROOT) as tmp:
   (Path(tmp)/'ignored').write_text('test');self.assertEqual(set(source_files()),baseline)
  p=ROOT/'negative-test-extra-source.txt'
  try:
   p.write_text('test',encoding='utf-8');self.assertIn(p,source_files());self.assertNotEqual(set(source_files()),baseline)
  finally:p.unlink()
 def test_tampered_hashes_tables_and_images(self):
  from verify_archive import check_inventory,check_table,check_images,sha
  from PIL import Image
  with tempfile.TemporaryDirectory(prefix='.verify-',dir=ROOT) as tmp:
   d=Path(tmp);p=d/'source.txt';p.write_text('original');pins={'source.txt':sha(p)}
   check_inventory([p],d,pins);p.write_text('changed')
   with self.assertRaises(AssertionError):check_inventory([p],d,pins)
   with self.assertRaises(AssertionError):check_inventory([],d,pins)
   table=list(csv.DictReader((ROOT/'outputs/table1_by_quantity.csv').open(encoding='utf-8')));check_table(table)
   table[0]['passed_after']='0'
   with self.assertRaises(AssertionError):check_table(table)
   png=ROOT/'outputs/visual_abstract.png';tif=ROOT/'outputs/visual_abstract.tif';check_images(png,tif)
   with Image.open(png) as im:im.save(d/'bad.tif',dpi=(72,72))
   with self.assertRaises(AssertionError):check_images(png,d/'bad.tif')
if __name__=='__main__':unittest.main(verbosity=2)
