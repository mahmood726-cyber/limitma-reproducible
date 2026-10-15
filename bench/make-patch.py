from pathlib import Path
import shutil,difflib
original=Path('original/limit-ma/index.html')
text=original.read_text(encoding='utf-8')
before="""      // Rücker regression line: te = limit + slope * SE
      var e1 = lim.limit, e2 = lim.limit + lim.slope * seMax;
      __svgParts.push('<line x1="' + X(e1) + '" y1="' + Y(0) + '" x2="' + X(e2) + '" y2="' + Y(seMax) + '" stroke="var(--warn)" stroke-dasharray="4 3" opacity="0.7"/>');"""
after="""      // Radial regression maps to TE = beta.r + alpha.r * sqrt(SE^2 + tau^2).
      // On raw-SE axes this is a curve, with beta0 at SE = 0.
      var curve = [];
      for (var j = 0; j <= 64; j++) {
        var s = seMax * j / 64;
        var fitted = lim.beta_r + lim.alpha_r * Math.sqrt(s * s + lim.tau2);
        curve.push(X(fitted) + ',' + Y(s));
      }
      __svgParts.push('<polyline data-regression="true" points="' + curve.join(' ') + '" fill="none" stroke="var(--warn)" stroke-dasharray="4 3" opacity="0.7"/>');"""
assert text.count(before)==1
fixed=text.replace(before,after)
fixed=fixed.replace('R&#252;cker et al., Stat Med 2011.', 'R&#252;cker et al., Biostatistics 2011.',1)
fixed=fixed.replace('      <table>','      <div id="limit-error" role="alert"></div>\n      <table>',1)
fixed=fixed.replace('    function run() {', '''    function refuse(message) {
      _lastResults = null;
      document.getElementById('body').innerHTML = '';
      document.getElementById('plot').innerHTML = '';
      document.getElementById('limit-error').textContent = message;
    }

    function run() {
      document.getElementById('limit-error').textContent = '';''',1)
fixed=fixed.replace("      if (rows.length < 3) { _lastResults = null; return; }", """      if (rows.length < 3) { refuse('At least three valid studies are required.'); return; }
      if (rows.every(function (r) { return r.se === rows[0].se; })) {
        refuse('Limit meta-analysis requires variation in study SEs.'); return;
      }""")
fixed=fixed.replace("      var body = document.getElementById('body');", """      var valid = Object.keys(_lastResults).every(function (key) {
        if (key === '_schema') return true;
        var values = Array.isArray(_lastResults[key]) ? _lastResults[key] : [_lastResults[key]];
        return values.every(Number.isFinite);
      });
      if (!valid) { refuse('Limit meta-analysis is numerically undefined for these studies.'); return; }

      var body = document.getElementById('body');""")
fixed=fixed.replace('      var X = function (v)', '      var seMin = yMin !== null ? yMin : 0;\n      var X = function (v)',1)
fixed=fixed.replace('(s / seMax) * plotH','((s - seMin) / (seMax - seMin)) * plotH',1)
fixed=fixed.replace('var s = seMax * j / 64;', 'var s = seMin + (seMax - seMin) * j / 64;',1)
fixed=fixed.replace('    window.alm.resultsExport({', '''    // This plot implements linear effect/SE axes only.
    document.querySelectorAll('#alm-axis-mount [data-edge="log"]').forEach(function (input) {
      input.disabled = true;
      input.parentNode.title = 'Log axes are not supported for this plot.';
    });

    window.alm.resultsExport({''',1)
shutil.copytree('original','patched',dirs_exist_ok=True)
newline = '\r\n' if b'\r\n' in original.read_bytes() else '\n'
Path('patched/limit-ma/index.html').write_bytes(fixed.replace('\n',newline).encode('utf-8'))
Path('fix.patch').write_text(''.join(difflib.unified_diff(text.splitlines(True),fixed.splitlines(True),fromfile='a/limit-ma/index.html',tofile='b/limit-ma/index.html')),encoding='utf-8',newline='')
print('Created fix.patch for the funnel regression geometry')
