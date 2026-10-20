// Node replay of the limit-ma bias-sensitivity ("plus") tier, allmeta v1.7.0 / 9b232cc.
// Follows limit-ma/validate/loo/replay.cjs (actual first inline page script in a VM with minimal DOM stubs)
// and the replay loop of limit-ma/validate/plus-adapter.js. The comparison helpers (methods, fields, validate,
// flatten, tolerance) and AlmValidate.compare are extracted VERBATIM from the archived source files at run time.
// The per-configuration 'render' check (169 checks: DOM text, SVG geometry, computed styles) needs a browser;
// it is NOT recomputed here and is reported separately from the archived browser evidence (evidence-replay.json).
// Usage: node plus_replay.cjs <allmeta_copy_root> [--plant]
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(process.argv[2] || path.join(__dirname, '..', 'allmeta'));
const plant = process.argv.includes('--plant');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
function slice(text, start, end, file) {
  const a = text.indexOf(start), b = text.indexOf(end, a + 1);
  if (a < 0 || b < 0) throw Error('Cannot extract ' + start + ' from ' + file);
  return text.slice(a, b);
}
function load() {
  const html = read('limit-ma/index.html');
  const nodes = {};
  function node() {
    return {value: '', innerHTML: '', textContent: '', attrs: {}, parentNode: {}, hidden: false, disabled: false,
      addEventListener(event, fn) { const prev = this[event]; this[event] = async (...args) => { if (prev) await prev(...args); return fn(...args); }; },
      setAttribute(k, v) { this.attrs[k] = v; }, getAttribute(k) { return this.attrs[k]; },
      removeAttribute(k) { delete this.attrs[k]; }};
  }
  for (const m of html.matchAll(/<([a-z][\w-]*)\b[^>]*\bid="([^"]+)"[^>]*>([^<]*)/gi)) {
    nodes[m[2]] = node(); nodes[m[2]].textContent = m[3];
  }
  nodes.src.value = html.match(/<textarea[^>]*>([\s\S]*?)<\/textarea>/)[1];
  const document = {getElementById: id => nodes[id] || null,
    querySelectorAll: selector => {
      if (selector !== '#alm-axis-mount [data-edge="log"]') throw Error('Unexpected selector: ' + selector);
      return [node(), node()];
    }};
  const noop = () => {};
  const alm = {analysisLifecycle: run => run, csvUpload: noop, plotExport: noop, axisControls: noop,
    resultsExport: opts => { alm.exportOptions = opts; }, urlState: Object.assign(noop, {read: () => null}),
    resetUndo: noop, tooltips: noop};
  // Difference from loo/replay.cjs: window is the VM global, so that the shared modules' exports
  // (window.AlmMaCore, window.AlmTrimFill, ...) are visible to plus.js as free identifiers, as in a browser.
  const sandbox = {alm, document, structuredClone, setTimeout, Blob, URL, console};
  sandbox.window = sandbox;
  const context = vm.createContext(sandbox);
  vm.runInContext(html.match(/<script>\s*([\s\S]*?)<\/script>/)[1], context, {filename: 'index.html:inline'});
  // Page script order (index.html lines 791-797): ma-core, trimfill, (selmodel: legacy, not used by plus), plus-opt,
  // (loo-limit), plus-selmodel, plus.
  for (const file of ['shared/ma-core.js', 'shared/trimfill.js', 'limit-ma/plus-opt.js', 'limit-ma/plus-selmodel.js', 'limit-ma/plus.js'])
    vm.runInContext(read(file), context, {filename: file});
  const adapterSrc = read('limit-ma/validate/plus-adapter.js');
  const helpers = slice(adapterSrc, 'const methods=', 'const fitMethods=', 'plus-adapter.js');
  const validateSrc = read('shared/alm-validate.js');
  const compare = slice(validateSrc, 'const KINDS', '  function node(', 'alm-validate.js');
  vm.runInContext(`(function(){${helpers}\n${compare}\nwindow.__plusContract={methods,fields,validate,flatten,tolerance,compare};})();`, context,
    {filename: 'extracted-helpers'});
  return context;
}
function main() {
  const w = load(), C = w.__plusContract;
  const corpus = JSON.parse(read('limit-ma/validate/plus/corpus.json'));
  const refs = JSON.parse(read('limit-ma/validate/plus/reference.json'));
  const manifest = JSON.parse(read('limit-ma/validate/MANIFEST-plus.json'));
  C.validate(corpus, refs);
  if (plant) {  // planted defect: one R reference value (first finite RE.mu) moved by 1e-8 relative
    refs[0].methods.RE.values.mu *= 1 + 1e-8;
    console.log('PLANTED: ' + refs[0].id + ' RE.mu * (1 + 1e-8)');
  }
  let checks = 0, passed = 0; const failed = [], maxima = {};
  function check(id, q, a, r, exact = false) {
    const tol = C.tolerance(q), d = C.compare(a, r, exact ? 'exact' : 'rel', tol);
    checks++; if (d.pass) passed++; else failed.push({id, quantity: q, app: a, ref: r, tol, ...d});
    maxima[q] = Math.max(maxima[q] || 0, d.diff);
  }
  for (let i = 0; i < corpus.length; i++) {
    const c = corpus[i];
    w.__almLimitValidationRun(c.te.map((v, j) => v + ',' + c.se[j] + ',row ' + c.source_rows[j]).join('\n'), true);
    const limit = w._almLastLimit(), a = w.AlmLimitPlus.compute(c, limit, .1), ref = refs[i].methods;
    const af = C.flatten(a), rf = C.flatten(ref);
    for (const [q, v] of Object.entries(rf)) check(c.id, q, af[q], v, typeof v !== 'number' || /\.(df|k0|length)$/.test(q));
  }
  const renderChecks = corpus.length;
  const evidence = JSON.parse(read('limit-ma/validate/plus/evidence-replay.json'));
  const numericExpected = manifest.checks - renderChecks;
  console.log(`PLUS NODE REPLAY ${passed}/${checks} numerical/status/refusal checks (manifest ${manifest.checks} = ${numericExpected} + ${renderChecks} render)`);
  const top = Object.entries(maxima).filter(([, v]) => Number.isFinite(v)).sort((x, y) => y[1] - x[1]).slice(0, 3);
  console.log('  largest normalised differences: ' + top.map(([k, v]) => `${k} ${v.toExponential(2)}`).join(', '));
  for (const f of failed.slice(0, 5)) console.log('  FAIL ' + JSON.stringify(f));
  const ok = checks === numericExpected && passed === checks;
  const evOk = evidence.checks === manifest.checks && evidence.passed === manifest.checks && evidence.failed.length === 0;
  console.log(`PLUS RENDER CHECKS (archived browser evidence, not recomputed in node): ${evOk ? renderChecks : 0}/${renderChecks}; archived browser total ${evidence.passed}/${evidence.checks}`);
  if (!ok || !evOk) { console.log('PLUS NODE REPLAY FAILED'); process.exitCode = 1; }
}
main();
