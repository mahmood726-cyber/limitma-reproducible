// LOO tier (allmeta 9b232cc, limit-ma/validate/loo): replay the page engine with the tier's own replay.cjs and
// compare with the pinned R reference.csv using the rules of the tier's compare.py, ported line by line to node
// (identity/coverage, k, exact status, refusal = null numbers + exact R message, 4 numeric fields at
// abs(app-R)/max(1,abs(R)) <= 1e-9). Usage: node loo_replay_compare.cjs <allmeta_copy_root> [reference.csv] [--plant]
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(process.argv[2] || path.join(__dirname, '..', 'allmeta'));
const dir = path.join(root, 'limit-ma/validate/loo');
const refPath = process.argv[3] && !process.argv[3].startsWith('--') ? process.argv[3] : path.join(dir, 'reference.csv');
const plant = process.argv.includes('--plant');
const NUMERIC = ['limit_est', 'limit_se', 're_est', 'tau2'];
function parseCsv(text) {
  const lines = text.split(/\r?\n/).filter(l => l.length);  // the pinned file has CRLF (R on Windows); csv.DictReader accepts both
  const header = lines[0].split(',');
  return lines.slice(1).map(line => {
    const cells = []; let cur = '', q = false;
    for (const ch of line) { if (ch === '"') q = !q; else if (ch === ',' && !q) { cells.push(cur); cur = ''; } else cur += ch; }
    cells.push(cur);
    if (cells.length !== header.length) throw Error('Malformed reference row: ' + line);
    return Object.fromEntries(header.map((h, i) => [h, cells[i]]));
  });
}
function compare(app, reference, corpus) {
  const expected = new Map();
  for (const c of corpus) c.te.forEach((_, i) => expected.set(c.id + '\u0000' + (i + 1), c.te.length));
  const failures = []; let checks = 0, passed = 0; const maxima = {};
  const check = (ok, d) => { checks++; if (ok) passed++; else failures.push(d); };
  function index(rows, label) {
    const result = new Map();
    for (const row of rows) {
      const key = row.id + '\u0000' + parseInt(row.dropped, 10);
      if (result.has(key)) failures.push(`${label}: duplicate ${key}`);
      result.set(key, row);
    }
    const same = result.size === expected.size && [...expected.keys()].every(k => result.has(k));
    check(same && rows.length === expected.size, `${label}: coverage mismatch`);
    return result;
  }
  const a = index(app, 'app'), r = index(reference, 'R');
  for (const [key, k] of expected) {
    if (!a.has(key) || !r.has(key)) continue;
    const x = a.get(key), y = r.get(key);
    check(parseInt(x.k, 10) === parseInt(y.k, 10) && parseInt(y.k, 10) === k, `${key}: k mismatch`);
    check(x.status === y.status && ['ok', 'refused'].includes(y.status), `${key}: status mismatch`);
    if (y.status === 'refused') {
      check([...NUMERIC, 'change', 'ci_low', 'ci_high'].every(f => f in x && x[f] === null), `${key}: refusal contains numbers`);
      check(Boolean(x.reason) && x.reason === y.reason, `${key}: refusal reason mismatch`);
    } else {
      for (const field of NUMERIC) {
        const av = typeof x[field] === 'number' ? x[field] : NaN, rv = Number(y[field]);
        let delta = Math.abs(av - rv) / Math.max(1, Math.abs(rv)); if (!Number.isFinite(delta)) delta = Infinity;
        const ok = Number.isFinite(av) && Number.isFinite(rv) && y[field] !== '' && delta <= 1e-9;
        maxima[field] = Math.max(maxima[field] || 0, delta);
        check(ok, `${key}: ${field} relative error ${delta}`);
      }
    }
  }
  return {passed, checks, failures, maxima, app_rows: app.length, reference_rows: reference.length};
}
const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'MANIFEST.json'), 'utf8'));
const corpus = JSON.parse(fs.readFileSync(path.join(dir, 'corpus.json'), 'utf8'));
if (corpus.length !== manifest.configurations || corpus.reduce((n, c) => n + c.te.length, 0) !== manifest.deletions)
  throw Error('Pinned corpus counts changed');
const {replay} = require(path.join(dir, 'replay.cjs'));
const app = replay(corpus);
const reference = parseCsv(fs.readFileSync(refPath, 'utf8'));
if (plant) {  // planted defect (same as the tier's defects.py 'estimate'): one app limit estimate * (1 + 1e-8)
  const row = app.find(x => x.status === 'ok' && Math.abs(x.limit_est) >= 1); row.limit_est *= 1 + 1e-8;
  console.log(`PLANTED: app limit_est of ${row.id} dropped=${row.dropped} * (1 + 1e-8)`);
}
const res = compare(app, reference, corpus);
if (res.checks !== manifest.comparison_checks) res.failures.push('Comparison check count differs from pinned contract');
const refused = app.filter(x => x.status === 'refused').length;
console.log(`LOO NODE REPLAY ${res.passed}/${res.checks} checks; ${res.app_rows}/${res.reference_rows} rows; ${refused} refused (manifest ${manifest.comparison_checks})`);
console.log('  max normalised error: ' + NUMERIC.map(f => `${f} ${(res.maxima[f] || 0).toExponential(2)}`).join(', '));
for (const f of res.failures.slice(0, 5)) console.log('  FAIL ' + f.split('\u0000').join(' dropped='));
if (res.failures.length || res.passed !== res.checks) { console.log('LOO NODE REPLAY FAILED'); process.exitCode = 1; }
