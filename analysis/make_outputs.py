"""Recompute all output numbers and figures from archived primary evidence."""
from pathlib import Path
import csv,json,math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PIL import Image
from checks import read,compare,summarize,REFUSAL
ROOT=Path(__file__).resolve().parents[1]
def dump(p,x):p.write_text(json.dumps(x,indent=2,ensure_ascii=False,allow_nan=False)+'\n',encoding='utf-8',newline='\n')
def csvwrite(p,rows):
 with p.open('w',encoding='utf-8',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def save(fig,out,name):
 for ext in ['png','tif']:fig.savefig(out/(name+'.'+ext),dpi=300)
 plt.close(fig)
def build(out):
 out.mkdir(parents=True,exist_ok=True)
 c=read(ROOT/'data/corpus.json');r=read(ROOT/'results/reference.json')
 after=compare(c,r,read(ROOT/'results/app-patched.json'));before=compare(c,read(ROOT/'results/reference-before.json'),read(ROOT/'results/app.json'))
 new=summarize(after);old=summarize(before)
 n=dict(configurations=len(c),datasets_used=len({x['dataset'] for x in c}),effect_rows=sum(x['k'] for x in c),checks=len(after),passed=sum(x['passed'] for x in after),before_checks=len(before),before_passed=sum(x['passed'] for x in before))
 assert n==read(ROOT/'expected/paper_values.json')
 bad=[x for x in after if not x['passed']];expected=read(ROOT/'expected/documented_differences.json')
 assert list(expected)==[REFUSAL] and len(bad)==1 and bad[0]['id']==REFUSAL and bad[0]['quantity']=='status'
 for stats,name in [(new,'patched'),(old,'baseline')]:
  ledger=read(ROOT/f'results/{name}-results.json')
  assert set(stats)==set(ledger['quantities'])
  for q,s in stats.items():
   t=ledger['quantities'][q];assert (s['checks'],s['passed'],s['max_difference'],s['tolerance'])==(t['checks'],t['pass'],t['max_difference'],t['tolerance']),(q,name)
 rows=[dict(quantity=q,checks_before=old[q]['checks'],passed_before=old[q]['passed'],checks_after=s['checks'],passed_after=s['passed'],largest_difference_before=old[q]['max_difference'],largest_difference_after=s['max_difference'],tolerance=s['tolerance']) for q,s in new.items()]
 rows.append(dict(quantity='TOTAL',checks_before=len(before),passed_before=n['before_passed'],checks_after=len(after),passed_after=n['passed'],largest_difference_before='',largest_difference_after='',tolerance='1e-9'))
 csvwrite(out/'table1_by_quantity.csv',rows)
 csvwrite(out/'table2_datasets.csv',[dict(configuration=x['id'],dataset=x['dataset'],effect_definition=x['definition'],k=x['k'],source_rows=';'.join(map(str,x['source_rows'])),reference_status=next(y['status'] for y in r if y['id']==x['id'])) for x in c])
 dump(out/'numbers.json',{key:dict(value=value,source='data/corpus.json; results/reference-before.json; results/reference.json; results/app.json; results/app-patched.json',transformation='strict primary comparison / exact corpus aggregation; historical before uses round-5 curve, after uses round-6 clipped curve',validation='expected/paper_values.json and original per-quantity ledgers') for key,value in n.items()})
 plt.rcParams.update({'font.family':'DejaVu Sans','font.size':8,'axes.labelsize':8,'xtick.labelsize':8,'ytick.labelsize':8,'legend.fontsize':8})
 fig,ax=plt.subplots(figsize=(170/25.4,8))
 for j,q in enumerate(new):
  good=[math.log10(max(x['difference'],1e-16)) for x in after if x['quantity']==q]
  bad=[math.log10(max(x['difference'],1e-16)) for x in before if x['quantity']==q and not x['passed']]
  ax.scatter(good,[j+.1]*len(good),s=5,color='#24658a',alpha=.35,rasterized=True)
  ax.scatter(bad,[j-.1]*len(bad),s=9,marker='x',color='#bd4c2f',alpha=.6,rasterized=True)
 ax.axvline(-9,color='#444',ls='--',lw=1,label='Tolerance 1e-9')
 ax.scatter([],[],s=12,color='#24658a',label='After (all checks)');ax.scatter([],[],s=16,marker='x',color='#bd4c2f',label='Before failures')
 ax.set_yticks(range(len(new)),list(new));ax.invert_yaxis();ax.set_xlim(-16.5,3)
 ax.set_xlabel('log10 normalized difference (zeros / <1e-16 at -16)');ax.set_title('Limit meta-analysis: agreement with metasens',fontsize=10)
 ax.legend(loc='center right');ax.grid(axis='x',alpha=.2)
 fig.text(.5,.02,'DL + beta0. Status failure: R non-convergence.\nBefore: round-5 curve; after: round-6 clipped visible-curve probes.',ha='center',fontsize=8)
 fig.tight_layout(rect=(0,.06,1,1));save(fig,out,'figure2_agreement')
 fig=plt.figure(figsize=(170/25.4,3.6));fig.patch.set_facecolor('#f7f9fb')
 fig.text(.5,.88,'Limit meta-analysis in the browser',ha='center',fontsize=14,weight='bold')
 fig.text(.5,.73,'DL + beta0 against R meta 8.5-0 / metasens 1.5-3',ha='center',fontsize=10)
 fig.text(.5,.55,f"{n['configurations']} configurations  |  {n['datasets_used']} datasets  |  {n['effect_rows']:,} effect rows",ha='center',fontsize=10)
 fig.text(.5,.35,f"{n['passed']:,} of {n['checks']:,} checks pass;\n1 documented R non-convergence",ha='center',fontsize=13,weight='bold',linespacing=1.5,color='#24658a')
 fig.text(.5,.12,'Plotting corrections do not alter estimates. Arithmetic validation only.',ha='center',fontsize=8)
 save(fig,out,'visual_abstract')
 sizes={}
 for p in sorted(out.iterdir()):
  if p.suffix in ['.png','.tif']:
   with Image.open(p) as im:sizes[p.name]=dict(width_pixels=im.width,height_pixels=im.height,dpi=list(map(float,im.info['dpi'])))
 dump(out/'sizes.json',sizes)
 (out/'reproduction_report.md').write_text(f"Recomputed: {n['passed']}/{n['checks']} after; {n['before_passed']}/{n['before_checks']} before. Both use the same primary denominator. One documented R refusal remains: {REFUSAL}. The global-DL 158/158 diagnostic is not substituted.\n\nTables reconcile with the archived ledgers. Figures are 170 mm wide, 300 dpi, minimum text 8 pt; values below 1e-16 are floored for display only. Run Rscript validate.R for fresh R fits; table rendering and browser geometry remain archived app evidence in that command.\n",encoding='utf-8',newline='\n')
 return n
if __name__=='__main__':
 n=build(ROOT/'outputs');print(f"OUTPUTS: {n['passed']}/{n['checks']} after; {n['before_passed']}/{n['before_checks']} before")
