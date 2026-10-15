import json,math,sys,collections,pathlib
appfile=sys.argv[1] if len(sys.argv)>1 else 'app.json'
prefix=sys.argv[2] if len(sys.argv)>2 else 'baseline'
corpus=json.load(open('corpus.json')); refs=json.load(open('reference.json')); apps=json.load(open(appfile))
def keyed(xs):
    out={x['id']:x for x in xs}; assert len(out)==len(xs),'duplicate configuration key'; return out
c,r,a=map(keyed,(corpus,refs,apps)); assert c.keys()==r.keys()==a.keys(),'exact coverage mismatch'
stats={}; failures=[]
def check(key,q,x,y,tol=1e-9):
    s=stats.setdefault(q,{'checks':0,'pass':0,'max_difference':0.,'tolerance':tol,'worst_id':None})
    s['checks']+=1
    finite=isinstance(x,(int,float)) and isinstance(y,(int,float)) and math.isfinite(x) and math.isfinite(y)
    diff=abs(x-y)/max(1,abs(y)) if finite else None
    ok=finite and diff<=tol
    if ok:s['pass']+=1
    else: failures.append({'id':key,'quantity':q,'app':x,'reference':y,'difference':diff})
    if diff is not None and diff>s['max_difference']:s.update(max_difference=diff,worst_id=key)
for key in c:
    rr,aa=r[key],a[key]
    # Invalid numerical output is never a refusal match/pass.
    if rr['status']!='ok' or aa['status']!='ok':
        match=rr['status']=='refused' and aa['status']=='refused'
        check(key,'status',1 if match else 0,1)
        if not match:failures[-1].update(reference_reason=rr.get('reason'),app_reason=aa.get('reason'))
        continue
    check(key,'status',1,1)
    for q,y in rr['values'].items():
        x=aa['values'].get(q)
        if isinstance(y,list):
            check(key,q+'_length',len(x) if isinstance(x,list) else None,len(y))
            for i,v in enumerate(y):check(key,q,x[i] if isinstance(x,list) and i<len(x) else None,v)
        else:check(key,q,x,y)
    check(key,'table_render',int(aa.get('table_ok',False)),1)
    for field in ('points','regression'):
        check(key,field+'_length',len(aa.get(field,[])),len(rr[field]['x']))
        for i in range(len(rr[field]['x'])):
            for axis in ('x','y'):
                obs=aa[field][i].get(axis) if i<len(aa.get(field,[])) else None
                check(key,field+'_'+axis,obs,rr[field][axis][i])
passed=sum(s['pass'] for s in stats.values()); total=sum(s['checks'] for s in stats.values())
result={'configurations':len(c),'datasets_used':len({x['dataset'] for x in corpus}),'checks':total,'pass':passed,'failed':total-passed,'quantities':stats,'failures':failures}
pathlib.Path(prefix+'-results.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
lines=[]
for q,s in stats.items():lines.append(f"{q}: {s['pass']}/{s['checks']} pass; max difference {s['max_difference']:.17g}; tolerance {s['tolerance']}")
lines.append(f'{passed}/{total} checks pass')
print('\n'.join(lines));pathlib.Path(prefix+'-comparison.txt').write_text('\n'.join(lines)+'\n',encoding='utf-8')
sys.exit(0 if passed==total else 1)
