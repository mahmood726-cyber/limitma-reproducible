"""Copy only page dependencies into the audit folder; source is read-only."""
import pathlib, re, shutil, sys, json, hashlib, subprocess
src=pathlib.Path(sys.argv[1]); dst=pathlib.Path('original')
pending=[pathlib.Path('limit-ma/index.html')]; seen=set()
while pending:
    rel=pending.pop()
    if str(rel) in seen: continue
    seen.add(str(rel)); p=src/rel
    if not p.is_file(): continue
    q=dst/rel; q.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(p,q)
    if p.suffix in ('.html','.css'):
        for link in re.findall(r'(?:src|href)=["\']([^"\']+)["\']',p.read_text(encoding='utf-8')):
            if ':' in link or link.startswith('#'): continue
            target=(p.parent/link).resolve()
            if target.is_file() and target.is_relative_to(src.resolve()): pending.append(target.relative_to(src.resolve()))
manifest={str(p.relative_to(dst)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in dst.rglob('*') if p.is_file()}
json.dump({'commit':subprocess.check_output(['git','-C',str(src),'rev-parse','HEAD'],text=True).strip(),'sha256':manifest},open('source-manifest.json','w'),indent=2)
