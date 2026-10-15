"""Strict primary-comparison contract; no missing evidence is an undefined value."""
import json,math,collections
SCALARS='k fe_est fe_se fe_ci_lo fe_ci_hi re_est re_se re_ci_lo re_ci_hi tau2_dl tau_dl limit_est limit_se limit_ci_lo limit_ci_hi slope alpha_r beta_r Q Q_small Q_resid G_squared'.split()
REFUSAL='dat.hartmannboyce2018::001'
REASON="Fisher scoring algorithm did not converge. See 'help(rma)' for possible remedies."
def pairs(items):
 d={}
 for k,v in items:
  if k in d:raise ValueError('Duplicate JSON key: '+k)
  d[k]=v
 return d
def read(p):
 def invalid(x):raise ValueError('Invalid JSON number '+x)
 return json.loads(p.read_text(encoding='utf-8'),object_pairs_hook=pairs,parse_constant=invalid)
def finite(x):return type(x) in (float,int) and math.isfinite(x)
def vector(x,k):
 assert type(x)==list and len(x)==k and all(finite(v) for v in x),'Invalid vector'
 return x
def index(x):
 assert type(x)==list and len(x)==169,'Expected exactly 169 configurations'
 d={}
 for r in x:
  assert isinstance(r,dict) and isinstance(r['id'],str) and r['id'] and r['id'] not in d,'Duplicate/invalid identifier'
  d[r['id']]=r
 return d
def validate(c,r,a):
 c,r,a=map(index,(c,r,a));assert c.keys()==r.keys()==a.keys(),'Coverage mismatch'
 for key,s in c.items():
  k=s['k'];assert type(k)==int and k>=3
  vector(s['te'],k);assert all(x>0 for x in vector(s['se'],k))
  rows=vector(s['source_rows'],k);assert len(set(rows))==k and all(type(x)==int and x>0 for x in rows)
  for obj,reference in [(r[key],True),(a[key],False)]:
   if reference and key==REFUSAL:
    assert obj['status']=='refused' and obj['reason']==REASON and obj['phase']=='limitmeta beta0 (including internal metagen call)','Documented refusal changed'
    continue
   assert obj['status']=='ok','Unexpected refusal/invalid output'
   v=obj['values'];assert set(v)==set(SCALARS+['te_limit'])|({'_schema'} if '_schema' in v else set()),'Quantity inventory mismatch'
   for q in SCALARS:assert finite(v[q]) or (q=='G_squared' and v[q] is None),'Invalid quantity '+q
   assert v['k']==k;vector(v['te_limit'],k)
   for field,n in [('points',k),('regression',65)]:
    if reference:
     assert set(obj[field])=={'x','y'}
     for axis in ['x','y']:vector(obj[field][axis],n)
    else:
     assert type(obj[field])==list and len(obj[field])==n,'Geometry cardinality'
     for p in obj[field]:assert set(p)=={'x','y'} and all(finite(p[axis]) for axis in ['x','y'])
   if not reference:assert type(obj['table_ok'])==bool
 return c,r,a
def compare(c,r,a):
 c,r,a=validate(c,r,a);out=[]
 def check(key,q,x,y,i=0):
  diff=0 if q=='G_squared' and x is None and y is None else abs(x-y)/max(1,abs(y)) if finite(x) and finite(y) else math.inf
  out.append(dict(id=key,quantity=q,row=i,app=x,reference=y,difference=diff,passed=diff<=1e-9,tolerance=1e-9))
 for key in c:
  rr,aa=r[key],a[key];check(key,'status',int(rr['status']==aa['status']),1)
  if rr['status']!='ok':continue
  for q in SCALARS:check(key,q,aa['values'][q],rr['values'][q])
  av,rv=aa['values']['te_limit'],rr['values']['te_limit'];check(key,'te_limit_length',len(av),len(rv))
  for i,(x,y) in enumerate(zip(av,rv)):check(key,'te_limit',x,y,i)
  check(key,'table_render',int(aa['table_ok']),1)
  for f in ['points','regression']:
   check(key,f+'_length',len(aa[f]),len(rr[f]['x']))
   for i,p in enumerate(aa[f]):
    for axis in ['x','y']:check(key,f+'_'+axis,p[axis],rr[f][axis][i],i)
 assert len(out)==55525 and len({(x['id'],x['quantity'],x['row']) for x in out})==55525
 return out
def summarize(rows):
 out={}
 for x in rows:
  s=out.setdefault(x['quantity'],dict(checks=0,passed=0,max_difference=0,tolerance=x['tolerance']))
  s['checks']+=1;s['passed']+=x['passed'];s['max_difference']=max(s['max_difference'],x['difference'])
 return out
