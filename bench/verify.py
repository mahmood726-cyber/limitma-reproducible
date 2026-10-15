"""Final integrity, patch application, and negative-evidence checks."""
import json,pathlib,hashlib,subprocess,sys,shutil,math
P=pathlib.Path
load=lambda f:json.loads(P(f).read_text(encoding='utf-8'))
c=load('corpus.json'); coverage=load('coverage.json'); inventory=load('inventory.json')
assert set(coverage)==set(inventory)
assert len({v['id'] for v in c})==len(c)
for name,item in coverage.items():
    assert item['configurations']==sum(x['dataset']==name for x in c)
    assert (item['status']=='used')==(item['configurations']>0)
for x in c:
    assert x['k']==len(x['te'])==len(x['se'])==len(x['source_rows'])
    assert x['k']>=3 and all(math.isfinite(v) for v in x['te'])
    assert all(math.isfinite(v) and v>0 for v in x['se'])
manifest=load('source-manifest.json')
for rel,digest in manifest['sha256'].items():assert hashlib.sha256((P('original')/rel).read_bytes()).hexdigest()==digest,rel
q=P('patch-check/limit-ma');q.mkdir(parents=True,exist_ok=True)
shutil.copyfile('original/limit-ma/index.html',q/'index.html')
applied=subprocess.run(['git','apply','--directory=patch-check','fix.patch'],capture_output=True,text=True)
assert applied.returncode==0,applied.stderr
assert (q/'index.html').read_bytes()==P('patched/limit-ma/index.html').read_bytes()
assert all(x['pass'] for x in load('patched-ui.json'))
assert not load('app-patched-browser.json')['errors']
# These deliberately damaged evidence files must be rejected; they are not corpus data.
base=load('app-patched.json'); good=next(i for i,x in enumerate(base) if x['status']=='ok')
tests=[]; directory=P('negative-checks');directory.mkdir(exist_ok=True)
for case in ('missing_configuration','duplicate_key','null_estimate','missing_vector'):
    data=json.loads(json.dumps(base))
    if case=='missing_configuration':data.pop()
    elif case=='duplicate_key':data.append(data[0])
    elif case=='null_estimate':data[good]['values']['limit_est']=None
    else:data[good]['values'].pop('te_limit')
    path=directory/(case+'.json');path.write_text(json.dumps(data),encoding='utf-8')
    proc=subprocess.run([sys.executable,'compare.py',str(path),str(directory/case)],capture_output=True,text=True)
    # Baseline may already contain an oracle refusal: require evidence that this mutation was detected.
    if case in ('missing_configuration','duplicate_key'):
        detected=proc.returncode!=0 and ('coverage mismatch' in proc.stderr or 'duplicate configuration key' in proc.stderr)
    else:
        result=load(str(directory/case)+'-results.json')
        target='limit_est' if case=='null_estimate' else 'te_limit_length'
        detected=proc.returncode!=0 and any(f['id']==data[good]['id'] and f['quantity']==target for f in result['failures'])
    assert detected,case
    tests.append({'case':case,'detected':detected})
P('verification.json').write_text(json.dumps({'coverage':'pass','source_hashes':'pass','patch_application':'pass','patched_ui':'pass','negative_evidence':tests},indent=2),encoding='utf-8')
print(f'Integrity checks pass; {len(tests)}/{len(tests)} damaged-evidence cases rejected; patch reproduces tested HTML.')
