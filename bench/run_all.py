"""Rebuild evidence using installed local tools; no network or source writes."""
import os,subprocess,pathlib,sys,json,hashlib
def run(args,log,expected=(0,)):
    p=subprocess.run(args,capture_output=True,text=True,encoding='utf-8',errors='replace')
    pathlib.Path(log).write_text(p.stdout+p.stderr,encoding='utf-8')
    print(' '.join(args), 'exit',p.returncode,flush=True)
    print('\n'.join(p.stdout.splitlines()[-2:]),flush=True)
    if p.returncode not in expected:raise RuntimeError(f'Command failed; see {log}')
manifest=json.load(open('source-manifest.json'))
for rel,digest in manifest['sha256'].items():
    assert hashlib.sha256((pathlib.Path('original')/rel).read_bytes()).hexdigest()==digest,rel
assert os.environ.get('PLAYWRIGHT_MODULE'),'Set PLAYWRIGHT_MODULE to the installed Playwright module'
assert os.environ.get('EXTRA_R_LIB'),'Set EXTRA_R_LIB to the local library containing metasens and jsonlite'
run(['Rscript','build.R'],'build.log')
run(['Rscript','reference.R'],'reference.log')
run(['node','run-app.cjs','original','app.json'],'app.log')
run([sys.executable,'compare.py','app.json','baseline'],'baseline.log',(0,1))
run([sys.executable,'make-patch.py'],'patch.log')
run(['node','run-app.cjs','patched','app-patched.json'],'app-patched.log')
run([sys.executable,'compare.py','app-patched.json','patched'],'patched.log',(0,1))
run(['node','test-ui.cjs','original'],'original-ui.log')
run(['node','test-ui.cjs','patched'],'patched-ui.log')
print('Full corpus and UI evidence regenerated.',flush=True)
