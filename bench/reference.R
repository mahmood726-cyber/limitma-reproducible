.libPaths(c(.libPaths(), Sys.getenv('EXTRA_R_LIB')))
suppressPackageStartupMessages(library(meta))
suppressPackageStartupMessages(library(metasens))
source('json17.R')
# Independent R geometry oracle: clip each sampled segment to the X bounds,
# then probe the rendered piecewise-linear curve at 65 evenly spaced visible SEs.
visible_curve <- function(x,y,lo,hi) {
 xx <- yy <- numeric()
 for(i in seq_len(length(x)-1L)) {
  a <- x[i]; b <- x[i+1L]; ya <- y[i]; yb <- y[i+1L]
  if((a<lo && b<lo) || (a>hi && b>hi)) next
  left <- max(lo,min(hi,a)); right <- max(lo,min(hi,b))
  t0 <- if(a==b) 0 else (left-a)/(b-a)
  t1 <- if(a==b) 1 else (right-a)/(b-a)
  xx <- c(xx,left,right); yy <- c(yy,ya+t0*(yb-ya),ya+t1*(yb-ya))
 }
 stopifnot(length(xx)>=2)
 keep <- !duplicated(yy); xx <- xx[keep]; yy <- yy[keep]
 grid <- seq(min(yy),max(yy),length.out=65)
 list(x=unname(approx(yy,xx,xout=grid,rule=2)$y),y=grid)
}
corpus <- jsonlite::fromJSON('corpus.json',simplifyVector=FALSE)
refs <- list(); supplemental <- list()
for(c in corpus) {
 warnings <- character()
 phase <- 'metagen DL'
 calculate <- function() {
  te <- unlist(c$te); se <- unlist(c$se)
  m <- meta::metagen(te,se,method.tau='DL',method.random.ci='classic',level=0.95,level.ma=0.95,method.tau.ci='')
  phase <<- 'limitmeta beta0 (including internal metagen call)'
  l <- metasens::limitmeta(m,method.adjust='beta0')
  vals <- list(k=m$k,fe_est=m$TE.common,fe_se=m$seTE.common,fe_ci_lo=m$lower.common,fe_ci_hi=m$upper.common,
   re_est=m$TE.random,re_se=m$seTE.random,re_ci_lo=m$lower.random,re_ci_hi=m$upper.random,tau2_dl=m$tau2,tau_dl=m$tau,
   limit_est=l$TE.adjust,limit_se=l$seTE.adjust,limit_ci_lo=l$lower.adjust,limit_ci_hi=l$upper.adjust,
   slope=l$beta.r,alpha_r=l$alpha.r,beta_r=l$beta.r,Q=l$Q,Q_small=l$Q.small,Q_resid=l$Q.resid,G_squared=l$G.squared,te_limit=unname(l$TE.limit))
  invalid <- names(vals)[!vapply(vals,function(v)length(v)>0 && all(is.finite(v)),logical(1))]
  sgrid <- seq(0,max(se)*1.1,length.out=65)
  list(id=c$id,status=if(length(invalid))'invalid' else 'ok',reason=if(length(invalid))paste('nonfinite fields',paste(invalid,collapse=',')) else '',values=vals,
   points=list(x=te,y=se),regression=visible_curve(unname(l$beta.r+l$alpha.r*sqrt(sgrid^2+m$tau2)),sgrid,min(l$TE.adjust,te)-0.1,max(l$TE.adjust,te)+0.1),
   extra_reference_only=list(p_limit=l$pval.adjust,p_re=l$pval.random,p_small=pchisq(l$Q.small,1,lower.tail=FALSE)))
 }
 ans <- tryCatch(withCallingHandlers(calculate(),warning=function(w){warnings <<- c(warnings,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e)list(id=c$id,status='refused',reason=conditionMessage(e),phase=phase))
 ans$warnings <- warnings; refs[[length(refs)+1]] <- ans
 if(ans$status=='refused') {
  previous <- meta::settings.meta(method.tau='DL')
  diagnostic <- tryCatch(withCallingHandlers(calculate(),warning=function(w)invokeRestart('muffleWarning')),error=function(e)list(id=c$id,status='refused',reason=conditionMessage(e)))
  meta::settings.meta(previous)
  diagnostic$note <- 'Diagnostic only: global method.tau=DL also changes the unused internal shrunken-data heterogeneity fit. Primary refusal is retained, never replaced by this result.'
  supplemental[[length(supplemental)+1]] <- diagnostic
 }
}
write_json17(refs,'reference.json')
write_json17(supplemental,'reference-diagnostic.json')
versions <- lapply(c('meta','metasens','metafor','metadat','jsonlite'),function(p)as.character(packageVersion(p)))
names(versions) <- c('meta','metasens','metafor','metadat','jsonlite')
jsonlite::write_json(list(R=R.version.string,packages=versions),'versions.json',auto_unbox=TRUE,pretty=TRUE)
cat(length(refs),'reference configurations;',sum(vapply(refs,function(x)x$status=='ok',logical(1))),'valid;',sum(vapply(refs,function(x)x$status!='ok',logical(1))),'refused/invalid\n')
