const fs=require('fs'),path=require('path'),{pathToFileURL}=require('url');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE);
(async()=>{
 const root=process.argv[2]||'original';const b=await chromium.launch({channel:'chrome',headless:true});const p=await b.newPage();
 await p.route(/^https?:/,route=>route.abort());
 await p.goto(pathToFileURL(path.resolve(root,'limit-ma/index.html')).href);
 await p.waitForFunction(()=>typeof window._almLastLimit==='function');
 const checks=[];
 const record=(name,actual,expected)=>checks.push({name,actual,expected,pass:JSON.stringify(actual)===JSON.stringify(expected)});
 const initial=await p.evaluate(()=>window._almLastLimit());
 record('default fixture k',initial.k,10);
 await p.locator('[data-axis="y"][data-edge="min"]').fill('0.05');
 await p.locator('[data-axis="y"][data-edge="min"]').dispatchEvent('change');
 const cy=await p.locator('#plot circle').first().getAttribute('cy');
 record('SE minimum applies to point coordinates',Math.abs(+cy-(20+(.08-.05)/(.22-.05)*280))<1e-9,true);
 record('unsupported log axes disabled',await p.locator('[data-edge="log"]:enabled').count(),0);
 await p.locator('#src').fill('0.1, 0.1\n0.2, 0.2');await p.locator('#btn-run').click();
 record('minimum k refuses exported result',await p.evaluate(()=>window._almLastLimit()),null);
 checks.at(-1).reason=await p.evaluate(()=>document.getElementById('limit-error')?.textContent || 'No explicit reason displayed; fewer than three parsed rows.');
 record('minimum k clears stale table',await p.locator('#body tr').count(),0);
 record('minimum k clears stale plot',await p.locator('#plot circle').count(),0);
 // Explicit robustness probes, separate from the real-data corpus.
 await p.locator('#src').fill('0.1, 0.2\n0.2, 0.2\n0.3, 0.2');await p.locator('#btn-run').click();
 record('equal SE singularity refuses result',await p.evaluate(()=>window._almLastLimit()),null);
 checks.at(-1).reason=await p.evaluate(()=>document.getElementById('limit-error')?.textContent || 'No explicit refusal displayed for equal-SE singularity.');
 fs.writeFileSync(root+'-ui.json',JSON.stringify(checks,null,2));
 console.log(`${checks.filter(x=>x.pass).length}/${checks.length} UI checks pass (${root})`);
 await b.close();
})().catch(e=>{console.error(e);process.exit(1)});
