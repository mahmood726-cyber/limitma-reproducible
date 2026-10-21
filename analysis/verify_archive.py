"""Fail-closed source inventory, assets, table and figure verification."""
from pathlib import Path
import hashlib,re,tempfile,csv
from PIL import Image
from make_outputs import ROOT,build
from checks import read,REFUSAL
EXCLUDED={'.git','__pycache__','.pytest_cache','outputs','.validate-work'}
def source_files():
 return sorted(p for p in ROOT.rglob('*') if p.is_file() and not any(x in EXCLUDED or x.startswith('.verify-') for x in p.relative_to(ROOT).parts) and p.name not in {'SOURCE_SHA256.json','PROGRESS.md'})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def check_inventory(paths,base,pins):
 assert {p.relative_to(base).as_posix():sha(p) for p in paths}==pins,'Source inventory/hash mismatch'
def check_table(table):
 assert table and table[-1]['quantity']=='TOTAL'
 for key,want in [('checks_after',55525),('passed_after',55524),('checks_before',55525),('passed_before',44772)]:assert int(table[-1][key])==sum(int(x[key]) for x in table[:-1])==want
def check_images(png,tif):
 with Image.open(png) as a,Image.open(tif) as b:
  assert a.convert('RGB').tobytes()==b.convert('RGB').tobytes();assert abs(a.width/300*25.4-170)<.1
  assert all(abs(float(v)-300)<.001 for v in a.info['dpi']) and all(abs(float(v)-300)<.001 for v in b.info['dpi'])
def verify():
 check_inventory(source_files(),ROOT,read(ROOT/'SOURCE_SHA256.json'))
 app=ROOT/'app';pins=read(app/'app-sha256.json')
 assert pins=={p.relative_to(app).as_posix():sha(p) for p in app.rglob('*') if p.is_file() and p.name!='app-sha256.json'},'App inventory/hash mismatch'
 for p in source_files():
  if p.suffix.lower() in {'.json','.js','.mjs','.py','.r','.md','.csv','.txt','.html','.cff','.patch','.css'}:
   raw=p.read_bytes();assert not raw.startswith(b'\xef\xbb\xbf'),p
   text=raw.decode('utf-8');assert not re.search(r'\b[A-Za-z]:[\\/](?:Users|Projects|claude-temp|Program Files|E156|ProjectIndex)[\\/]',text),f'Machine path: {p}'
  assert p.name not in {'paper.md','paper_v2_dictated_text.md'},'Manuscript draft'
 page=app/'limit-ma/index.html'
 for rel in re.findall(r'(?:src|href)="([^"]+)"',page.read_text(encoding='utf-8')):
  if not rel.startswith(('http:','https:','#')) and rel.endswith(('.js','.css')):assert (page.parent/rel).is_file(),rel
 for rel in read(app/'request-assets.json'):assert (app/rel).is_file(),rel
 for f in read(app/'limit-ma/validate/MANIFEST.json')['files']:
  p=app/'limit-ma'/f['path'];assert sha(p)==f['sha256'] and p.stat().st_size==f['bytes'] and b'\r' not in p.read_bytes()
 base=app/'r-shiny/shinylive/webr'
 manifest=read(base/'repo/manifest.json')
 for f in manifest['packages']:
  p=base/f.get('path','repo/'+manifest['layout']+f['file']);assert sha(p)==f['sha256'] and p.stat().st_size==f['bytes']
 z=read(ROOT/'.zenodo.json');cff=(ROOT/'CITATION.cff').read_text(encoding='utf-8')
 assert z['title']=='Limit meta-analysis in the browser: validation against the R package metasens'
 assert z['creators']==[{'name':'Ahmad, Mahmood'}] and z['license']=='MIT' and z['version']=='1.1.0'
 assert 'family-names: Ahmad' in cff and 'given-names: Mahmood' in cff and '4a053dd' in cff and 'e431057' in cff and '<ALLMETA_COMMIT>' not in cff
 assert {(x['identifier'],x['relation']) for x in z['related_identifiers']}=={('https://github.com/mahmood726-cyber/allmeta','isDerivedFrom'),('10.5281/zenodo.23330389','isDerivedFrom'),('10.5281/zenodo.23515177','isDerivedFrom')}
 for name in ['README.md','CITATION.cff','.zenodo.json','CHANGELOG.md']:
  text=(ROOT/name).read_text(encoding='utf-8')
  assert '<ALLMETA_RELEASE' not in text,'Unfilled release token: '+name
  assert 'v1.8.0' in text and '10.5281/zenodo.23515177' in text,'allmeta v1.8.0 tag/DOI missing: '+name
 eq=(ROOT/'RELEASE_EQUIVALENCE.md').read_text(encoding='utf-8')
 assert '1cb3f8409c7af75ed41f7e1811f9c502f900fc79' in eq and 'byte-identical' in eq and '31,514/31,514' in eq and '15,928/15,928' in eq,'Release equivalence record missing'
 assert next(iter(read(ROOT/'v1_1/PROVENANCE.json')['commits']))=='1cb3f8409c7af75ed41f7e1811f9c502f900fc79','v1_1 provenance not pinned to allmeta v1.8.0'
 table=list(csv.DictReader((ROOT/'outputs/table1_by_quantity.csv').open(encoding='utf-8')))
 check_table(table)
 c=read(ROOT/'data/corpus.json');t2=list(csv.DictReader((ROOT/'outputs/table2_datasets.csv').open(encoding='utf-8')))
 assert len(t2)==169 and {x['configuration'] for x in t2}=={x['id'] for x in c}
 coverage=read(ROOT/'data/coverage.json');inventory=read(ROOT/'data/inventory.json');assert set(coverage)==set(inventory)
 for name,x in coverage.items():assert x['configurations']==sum(s['dataset']==name for s in c)
 for stem in ['figure2_agreement','visual_abstract']:
  check_images(ROOT/'outputs'/f'{stem}.png',ROOT/'outputs'/f'{stem}.tif')
 with tempfile.TemporaryDirectory(prefix='.verify-',dir=ROOT) as tmp:
  build(Path(tmp))
  for p in Path(tmp).iterdir():assert p.read_bytes()==(ROOT/'outputs'/p.name).read_bytes(),f'Nonreproducible output: {p.name}'
 rt=ROOT/'outputs/validate_R_table.csv'
 assert rt.is_file(),'Fresh R validation table missing'
 rows=list(csv.DictReader(rt.open(encoding='utf-8')));bad=[x for x in rows if x['Result']!='PASS']
 assert len(rows)==55525 and len({(x['configuration'],x['quantity'],x['row']) for x in rows})==55525
 assert len(bad)==1 and bad[0]['configuration']==REFUSAL and bad[0]['quantity']=='status'
 assert {x['configuration'] for x in rows}=={x['id'] for x in c}
 assert {q:sum(x['quantity']==q for x in rows) for q in {x['quantity'] for x in rows}}=={x['quantity']:int(x['checks_after']) for x in table[:-1]}
 for x in rows:
  diff=abs(float(x['App'])-float(x['R']))/max(1,abs(float(x['R'])))
  assert abs(diff-float(x['Difference']))<1e-12 and (diff<=float(x['Tolerance']))==(x['Result']=='PASS')
 print('ARCHIVE VERIFIED: source/app hashes, exact coverage, regenerated tables, 300-dpi figures and fresh R ledger')
if __name__=='__main__':verify()
