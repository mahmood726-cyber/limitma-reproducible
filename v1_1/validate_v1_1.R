# v1.1.0 layer of limitma-reproducible. Called by ../validate.R (or run directly from the archive root:
#   Rscript v1_1/validate_v1_1.R). Fails closed (nonzero exit) on any hash, version, count or comparison failure.
# Tiers (copied byte-exactly from allmeta 9b232cc, see v1_1/PROVENANCE.json):
#   LOO  limit-ma/validate/loo/  leave-one-out limit estimate vs R composite loop       31,514 checks
#   PLUS limit-ma/validate/plus/ bias-sensitivity panel (allmeta v1.7.0)                16,097 checks
# Steps: (1) versions, (2) file hashes, (3) full R regeneration of both references compared with the stored ones,
# (4) node replay of the page engine against the stored references (N/N), (5) summary.
# ARCHIVE_V1_1_PLANT=loo|plus|loo-rref|plus-rref plants one in-memory defect (after the hash checks) and must FAIL.
v11_main <- function() {
 started <- proc.time()[['elapsed']]
 for (cat_ in c('LC_COLLATE', 'LC_CTYPE')) Sys.setlocale(cat_, 'English_United States.utf8')
 cat('v1.1 locale: LC_COLLATE=', Sys.getlocale('LC_COLLATE'), '; LC_CTYPE=', Sys.getlocale('LC_CTYPE'), '\n', sep = '')
 if (Sys.getlocale('LC_COLLATE') != 'English_United States.utf8' || Sys.getlocale('LC_CTYPE') != 'English_United States.utf8')
  stop('v1.1: could not set LC_COLLATE/LC_CTYPE to English_United States.utf8')
 userlibs <- strsplit(Sys.getenv('R_LIBS_USER'), .Platform$path.sep, fixed = TRUE)[[1]]
 .libPaths(c(userlibs[nzchar(userlibs)], .libPaths()))
 want <- c(meta = '8.5.0', metasens = '1.5.3', metafor = '5.2.1', metadat = '1.6.0', jsonlite = '2.0.0')
 for (p in c(names(want), 'digest')) if (!requireNamespace(p, quietly = TRUE)) stop('v1.1: missing package ', p)
 got <- vapply(names(want), function(p) as.character(packageVersion(p)), '')
 cat('v1.1 versions: R', as.character(getRversion()), paste(names(got), got), '\n')
 if (!identical(got, want) || as.character(getRversion()) != '4.6.0') stop('v1.1: wrong R/package versions; need R 4.6.0, ', paste(names(want), want, collapse = ', '))
 node <- Sys.which('node'); if (!nzchar(node)) stop('v1.1: node not found on PATH')
 nv <- system2(node, '--version', stdout = TRUE); cat('v1.1 node:', nv, '\n')
 if (as.integer(sub('^v([0-9]+)\\..*$', '\\1', nv)) < 18) stop('v1.1: node >= 18 required (structuredClone, node: imports)')
 plant <- Sys.getenv('ARCHIVE_V1_1_PLANT')
 if (nzchar(plant)) { if (!plant %in% c('loo', 'plus', 'loo-rref', 'plus-rref')) stop('v1.1: unknown ARCHIVE_V1_1_PLANT ', plant); cat('v1.1 PLANT MODE:', plant, '(this run must fail)\n') }
 sha <- function(p) digest::digest(file = p, algo = 'sha256')
 read <- function(p) jsonlite::fromJSON(p, simplifyVector = FALSE)
 V <- 'v1_1'; A <- file.path(V, 'allmeta')
 fail <- character()

 # (2) hashes: every copied file against PROVENANCE.json; tier manifests against their own pins.
 prov <- read(file.path(V, 'PROVENANCE.json')); ok <- 0L
 for (f in prov$files) {
  p <- file.path(V, f$path); want_sha <- if (is.null(f$archived_sha256)) f$sha256 else f$archived_sha256
  if (file.exists(p) && sha(p) == want_sha) ok <- ok + 1L else fail <- c(fail, paste('hash', f$path))
  if (!is.null(f$substitutions)) {  # undo placeholders -> must give the git blob bytes
   raw <- readBin(p, 'raw', file.info(p)$size); txt <- rawToChar(raw)
   for (s in f$substitutions) txt <- gsub(s$placeholder, paste(unlist(s$original_parts), collapse = if (identical(s$sep, 'backslash')) '\\' else '/'), txt, fixed = TRUE)
   if (digest::digest(charToRaw(txt), algo = 'sha256', serialize = FALSE) != f$sha256) fail <- c(fail, paste('unsubstituted hash', f$path))
  }
 }
 cat(sprintf('V1.1 PROVENANCE %d/%d copied files match their recorded sha256 (allmeta %s)\n', ok, length(prov$files), substr(names(prov$commits)[1], 1, 7)))
 loo <- file.path(A, 'limit-ma/validate/loo'); lm <- read(file.path(loo, 'MANIFEST.json')); mok <- 0L
 for (f in lm$files) {
  p <- file.path(loo, f$path); raw <- readBin(p, 'raw', file.info(p)$size)
  if (sha(p) == f$sha256 && length(raw) == f$bytes) { mok <- mok + 1L; next }
  # allmeta defect: loo/MANIFEST.json pinned corpus.json from a CRLF working tree; git stores LF. Accept only an exact
  # LF->CRLF equivalence, never any other byte change.
  crlf <- charToRaw(gsub('\n', '\r\n', rawToChar(raw), fixed = TRUE))
  if (!any(raw == as.raw(13)) && digest::digest(crlf, algo = 'sha256', serialize = FALSE) == f$sha256 && length(crlf) == f$bytes) {
   mok <- mok + 1L; cat('  note: ', f$path, ' matches the LOO MANIFEST pin after LF->CRLF (git blob is LF; MANIFEST was pinned on a CRLF checkout)\n', sep = '')
  } else fail <- c(fail, paste('LOO manifest hash', f$path))
 }
 pm <- read(file.path(A, 'limit-ma/validate/MANIFEST-plus.json'))
 for (f in pm$files) { p <- file.path(A, 'limit-ma', f$path); if (sha(p) == f$sha256 && file.info(p)$size == f$bytes) mok <- mok + 1L else fail <- c(fail, paste('PLUS manifest hash', f$path)) }
 if (sha(file.path(A, 'limit-ma/validate/corpus/corpus.json')) == pm$source_sha256) mok <- mok + 1L else fail <- c(fail, 'PLUS source corpus hash')
 pins <- readLines(file.path(A, 'limit-ma/validate/plus-pins.js'), warn = FALSE)
 if (identical(jsonlite::fromJSON(sub(';$', '', sub('^window.AlmLimitPlusManifest=', '', pins)), simplifyVector = FALSE), pm)) mok <- mok + 1L else fail <- c(fail, 'plus-pins.js != MANIFEST-plus.json')
 cat(sprintf('V1.1 TIER PINS %d/%d (LOO MANIFEST 3, PLUS MANIFEST 2 + source corpus + browser pins)\n', mok, length(lm$files) + length(pm$files) + 2L))
 if (length(fail)) stop('v1.1 hash failures: ', paste(fail, collapse = '; '))
 stopifnot(lm$comparison_checks == 31514, lm$deletions == 5304, pm$checks == 16097, pm$configurations == 169)

 work <- normalizePath(file.path('.validate-work', 'v1_1'), mustWork = FALSE); unlink(work, recursive = TRUE); dir.create(work, recursive = TRUE)
 # Plant mode runs only the stage the plant targets (loo/plus: node replay; *-rref: that R regeneration).
 # (3a) LOO: full regeneration with the tier's own generate.R (unchanged), 165 configurations / 5,304 deletions.
 if (plant %in% c('', 'loo-rref')) {
 t0 <- proc.time()[['elapsed']]; cand <- file.path(work, 'loo-reference-candidate.csv')
 e <- new.env(parent = globalenv()); e$commandArgs <- function(trailingOnly = FALSE) c(file.path(loo, 'corpus.json'), cand)
 log <- file(file.path(work, 'loo-generate.log'), 'w'); sink(log); sink(log, type = 'message')
 res <- tryCatch({ sys.source(file.path(loo, 'generate.R'), envir = e); NULL }, error = function(err) conditionMessage(err))
 sink(type = 'message'); sink(); close(log)
 if (!is.null(res)) stop('v1.1 LOO generate.R failed: ', res)
 stored <- readLines(file.path(loo, 'reference.csv'), warn = FALSE); regen <- readLines(cand, warn = FALSE)
 if (plant == 'loo-rref') { i <- grep(',ok,', stored)[1]; f <- strsplit(stored[i], ',', fixed = TRUE)[[1]]; f[5] <- format(as.numeric(f[5]) * (1 + 1e-8), digits = 17); stored[i] <- paste(f, collapse = ','); cat('PLANTED: stored LOO reference row', i - 1L, 'limit_est * (1 + 1e-8)\n') }
 same <- length(stored) == length(regen) && length(stored) == 5305L
 nsame <- if (same) sum(stored == regen) - 1L else 0L
 cat(sprintf('LOO R REGEN %d/%d deletion rows identical to the stored reference.csv (generate.R, R %s; %.0f s; %s)\n',
  nsame, lm$deletions, getRversion(), proc.time()[['elapsed']] - t0, if (same && nsame == lm$deletions && sha(cand) == sha(file.path(loo, 'reference.csv'))) 'file byte-identical' else 'NOT identical'))
 if (!same || nsame != lm$deletions) fail <- c(fail, 'LOO R regeneration differs from stored reference')

 }
 # (3b) PLUS: full regeneration with generate-plus.R + generate-peters.R + generate-peters-or.R (unchanged), run in a
 if (plant %in% c('', 'plus-rref')) {
 # scratch copy laid out as limit-ma/; pin-plus.py's two shape normalisations applied in R before comparison.
 t0 <- proc.time()[['elapsed']]; pw <- file.path(work, 'plus', 'limit-ma'); dir.create(file.path(pw, 'validate', 'corpus'), recursive = TRUE)
 file.copy(file.path(A, 'limit-ma/validate/corpus/corpus.json'), file.path(pw, 'validate/corpus/corpus.json'))
 for (g in c('generate-plus.R', 'generate-peters.R', 'generate-peters-or.R')) file.copy(file.path(A, 'limit-ma/validate', g), file.path(pw, 'validate', g))
 old <- setwd(pw); log <- file(file.path(work, 'plus-generate.log'), 'w'); sink(log); sink(log, type = 'message')
 res <- tryCatch({ for (g in c('generate-plus.R', 'generate-peters.R', 'generate-peters-or.R')) sys.source(file.path('validate', g), envir = new.env(parent = globalenv())); NULL },
  error = function(err) conditionMessage(err))
 sink(type = 'message'); sink(); close(log); setwd(old)
 if (!is.null(res)) stop('v1.1 PLUS generators failed: ', res)
 rr <- read(file.path(pw, 'validate/plus/reference.json')); rc <- read(file.path(pw, 'validate/plus/corpus.json'))
 for (i in seq_along(rr)) { s <- rr[[i]]$methods$selection
  if (s$status == 'ok') { if (is.list(s$values$mu)) { stopifnot(length(s$values$mu) == 1L); s$values$mu <- s$values$mu[[1]] }
   if (any(vapply(s$values, is.null, TRUE))) s <- list(status = 'refused', reason = 'selection-fit-undefined') }
  rr[[i]]$methods$selection <- s }
 sr <- read(file.path(A, 'limit-ma/validate/plus/reference.json')); sc <- read(file.path(A, 'limit-ma/validate/plus/corpus.json'))
 if (plant == 'plus-rref') { sr[[1]]$methods$RE$values$mu <- sr[[1]]$methods$RE$values$mu * (1 + 1e-8); cat('PLANTED: stored PLUS reference', sr[[1]]$id, 'RE.mu * (1 + 1e-8)\n') }
 cnt <- new.env(); cnt$n <- 0L; cnt$exact <- 0L; cnt$close <- 0L; cnt$bad <- character(); cnt$max <- 0
 cmp <- function(a, b, path) {
  if (is.list(a) || is.list(b)) {
   if (!is.list(a) || !is.list(b) || length(a) != length(b) || !identical(names(a), names(b))) { cnt$bad <- c(cnt$bad, path); return(invisible()) }
   for (j in seq_along(a)) cmp(a[[j]], b[[j]], paste0(path, '/', if (is.null(names(a))) j else names(a)[j])); return(invisible())
  }
  cnt$n <- cnt$n + 1L
  if (is.numeric(a) && is.numeric(b) && length(a) == 1L && length(b) == 1L) {
   d <- abs(a - b) / max(1, abs(b)); cnt$max <- max(cnt$max, d)
   if (identical(as.numeric(a), as.numeric(b))) cnt$exact <- cnt$exact + 1L else if (d <= 1e-12) cnt$close <- cnt$close + 1L else cnt$bad <- c(cnt$bad, path)
  } else if (identical(a, b)) cnt$exact <- cnt$exact + 1L else cnt$bad <- c(cnt$bad, path)
 }
 cmp(rr, sr, 'reference'); ref <- c(n = cnt$n, exact = cnt$exact); cmp(rc, sc, 'corpus')
 cat(sprintf('PLUS R REGEN %d/%d stored values reproduced (reference.json + corpus.json, 169 configurations; %d bit-identical, %d within 1e-12 normalised; max %.3g; %.0f s)\n',
  cnt$exact + cnt$close, cnt$n, cnt$exact, cnt$close, cnt$max, proc.time()[['elapsed']] - t0))
 # generate-plus.R re-serialises the input corpus with jsonlite (15 significant digits); pin-plus.py keeps the original
 # input values, so input effects/SEs may differ in the last bits there. R reference values are reported separately.
 cat(sprintf('  R reference values: %d/%d bit-identical; corpus (jsonlite re-serialised inputs): %d/%d bit-identical\n',
  ref[['exact']], ref[['n']], cnt$exact - ref[['exact']], cnt$n - ref[['n']]))
 if (length(cnt$bad)) { cat('  differing:', head(cnt$bad, 5), '\n'); fail <- c(fail, 'PLUS R regeneration differs from stored reference') }

 }
 # (4) node replays of the page engine against the stored references.
 run_node <- function(script, extra, pattern) {
  out <- suppressWarnings(system2(node, c(file.path(V, 'run', script), A, extra), stdout = TRUE, stderr = TRUE))
  st <- attr(out, 'status'); cat(paste0(out, '\n'), sep = '')
  if (!is.null(st) && st != 0L || !any(grepl(pattern, out))) fail <<- c(fail, paste('node', script))
 }
 if (plant %in% c('', 'loo', 'plus')) {
 run_node('loo_replay_compare.cjs', if (plant == 'loo') '--plant', '^LOO NODE REPLAY 31514/31514 checks')
 run_node('plus_replay.cjs', if (plant == 'plus') '--plant', '^PLUS NODE REPLAY 15928/15928 ')
 }
 cat(sprintf('V1.1 runtime %.0f s\n', proc.time()[['elapsed']] - started))
 if (!length(fail) && !identical(Sys.getenv('ARCHIVE_V1_1_KEEP'), '1')) {
  unlink(file.path('.validate-work', 'v1_1'), recursive = TRUE)
  if (!length(list.files('.validate-work', all.files = TRUE, no.. = TRUE))) unlink('.validate-work', recursive = TRUE)
  cat('scratch .validate-work/v1_1 removed (ARCHIVE_V1_1_KEEP=1 keeps it)' , sep = '', fill = TRUE)
 }
 if (length(fail)) stop('v1.1 FAILED: ', paste(fail, collapse = '; '))
 cat('V1.1 PASS: LOO 31,514/31,514 (node) + R regeneration 5,304/5,304; PLUS 15,928/15,928 (node) + 169/169 render (archived browser) = 16,097 + R regeneration (every R reference value bit-identical)\n')
 0L
}
if (sys.nframe() == 0L) { status <- tryCatch(v11_main(), error = function(e) { cat('Validation failed: ', conditionMessage(e), '\n', sep = '', file = stderr()); 1L }); quit(save = 'no', status = status) }
