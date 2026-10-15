const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE);
(async()=>{
 const root=process.argv[2]||'original', outfile=process.argv[3]||'app.json';
 const corpus=JSON.parse(fs.readFileSync('corpus.json','utf8'));
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage(); const errors=[];
 await page.route(/^https?:/,route=>route.abort());
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(pathToFileURL(path.resolve(root,'limit-ma/index.html')).href);
 await page.waitForFunction(()=>typeof window._almLastLimit==='function');
 const output=[];
 for(const c of corpus){
  const value=await page.evaluate(c=>{
   const src=document.getElementById('src');
   src.value=c.te.map((t,i)=>`${t}, ${c.se[i]}, row ${c.source_rows[i]}`).join('\n');
   document.getElementById('btn-run').click();
   const r=window._almLastLimit();
   const body=document.getElementById('body').innerText;
   if(!r) return {id:c.id,status:'refused',reason:'page returned no results',body};
   const invalid=Object.keys(r).filter(k=>k!=='_schema' && (Array.isArray(r[k])?r[k]:[r[k]]).some(x=>typeof x!=='number'||!Number.isFinite(x)));
   const xmin=Math.min(r.limit_est,...c.te)-.1, xmax=Math.max(r.limit_est,...c.te)+.1, ymax=Math.max(...c.se)*1.1;
   const X=x=>xmin+(x-60)/520*(xmax-xmin),Y=y=>(y-20)/280*ymax;
   const points=[...document.querySelectorAll('#plot circle')].map(n=>({x:X(+n.getAttribute('cx')),y:Y(+n.getAttribute('cy'))}));
   const curve=document.querySelector('#plot polyline[data-regression]');
   let regression=[];
   if(curve) regression=curve.getAttribute('points').trim().split(/\s+/).map(p=>{const [x,y]=p.split(',').map(Number);return{x:X(x),y:Y(y)}});
   else {
    const line=document.querySelector('#plot line[stroke-dasharray="4 3"]');
    if(line){const x1=+line.getAttribute('x1'),x2=+line.getAttribute('x2'),y1=+line.getAttribute('y1'),y2=+line.getAttribute('y2');regression=Array.from({length:65},(_,i)=>({x:X(x1+(x2-x1)*i/64),y:Y(y1+(y2-y1)*i/64)}))}
   }
   // Corpus probes stay at 65 positions on the visible rendered polyline.
   // No estimator equation is used to reconstruct missing/off-screen geometry.
   if(document.querySelectorAll('#plot polyline[data-regression]').length!==1) throw new Error('Expected one connected automatic-bound curve');
   const vertices=regression;
   if(vertices.length<2) throw new Error('Missing visible regression');
   regression=Array.from({length:65},(_,i)=>{
     const y=vertices[0].y+(vertices.at(-1).y-vertices[0].y)*(i/64);
     let j=1; while(j<vertices.length-1 && vertices[j].y<y) j++;
     const a=vertices[j-1],b=vertices[j];
     const t=(y-a.y)/(b.y-a.y);
     return {x:a.x+(b.x-a.x)*t,y};
   });
   const table=[...document.querySelectorAll('#body tr')].map(n=>n.innerText);
   const expected=[['fe_est','fe_se','fe_ci_lo','fe_ci_hi'],['re_est','re_se','re_ci_lo','re_ci_hi'],['limit_est','limit_se','limit_ci_lo','limit_ci_hi']];
   const table_ok=table.length===3&&table.every((t,i)=>expected[i].every(k=>t.includes(Number.isFinite(r[k])?r[k].toFixed(3):'â€”')));
   return {id:c.id,status:invalid.length?'invalid':'ok',reason:invalid.length?'nonfinite fields '+invalid.join(','):'',values:r,points,regression,table_ok,body};
  },c); output.push(value);
 }
 fs.writeFileSync(outfile,JSON.stringify(output,null,2));
 fs.writeFileSync(outfile.replace('.json','-browser.json'),JSON.stringify({errors,version:await browser.version()},null,2));
 console.log(`${output.length} app configurations; ${output.filter(x=>x.status==='ok').length} valid; ${output.filter(x=>x.status!=='ok').length} refused/invalid; ${errors.length} page errors`);
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
