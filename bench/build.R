.libPaths(c(.libPaths(), Sys.getenv('EXTRA_R_LIB')))
suppressPackageStartupMessages(library(metafor))
suppressPackageStartupMessages(library(metadat))
suppressPackageStartupMessages(library(meta))
options(warn=1)
source('json17.R')
datasets <- sort(unique(data(package='metadat')$results[,'Item']))
corpus <- list(); ledger <- list(); attempts <- list(); current <- ''; source_expr <- ''
add <- function(d, definition) {
 if (!is.data.frame(d) || !all(c('yi','vi') %in% names(d))) return(invisible(NULL))
 if (!is.numeric(d$yi) || !is.numeric(d$vi)) return(invisible(NULL))
 good <- is.finite(d$yi) & is.finite(d$vi) & d$vi>0
 k <- sum(good)
 reason <- if(k<3) 'fewer than 3 finite effects with positive variance' else 'eligible'
 attempts[[length(attempts)+1]] <<- list(dataset=current,definition=definition,k=k,omitted=which(!good),reason=reason)
 if(k<3) return(invisible(NULL))
 te <- unname(d$yi[good]); se <- unname(sqrt(d$vi[good]))
 same <- vapply(corpus,function(x) identical(x$dataset,current) && identical(x$te,te) && identical(x$se,se),logical(1))
 if(any(same)) {
  j <- which(same)[1]; corpus[[j]]$aliases <<- unique(c(corpus[[j]]$aliases,definition))
  return(invisible(NULL))
 }
 key <- paste(current,sprintf('%03d',sum(vapply(corpus,function(x)x$dataset==current,logical(1)))+1),sep='::')
 corpus[[length(corpus)+1]] <<- list(id=key,dataset=current,definition=definition,k=k,source_rows=which(good),omitted_rows=which(!good),te=te,se=se)
 invisible(NULL)
}
capture_es <- function(...) {
 cl <- match.call(expand.dots=TRUE); cl[[1]] <- quote(metafor::escalc)
 z <- eval(cl,parent.frame())
 yn <- attr(z,'yi.names'); vn <- attr(z,'vi.names')
 if(length(yn) && length(vn)) add(data.frame(yi=z[[tail(yn,1)]],vi=z[[tail(vn,1)]]),source_expr) else add(z,source_expr)
 z
}
capture_meta <- function(...) {
 cl <- match.call(expand.dots=TRUE); fn <- as.character(cl[[1]])
 cl[[1]] <- as.call(list(as.name('::'),as.name('meta'),as.name(fn)))
 cl$method.tau <- 'DL'; cl$method.tau.ci <- ''
 if(fn %in% c('metabin','metaprop')) cl$method <- 'Inverse'
 z <- eval(cl,parent.frame()); add(data.frame(yi=z$TE,vi=z$seTE^2),source_expr); z
}
capture_pairwise <- function(...) {
 cl <- match.call(expand.dots=TRUE); cl[[1]] <- quote(meta::pairwise)
 z <- eval(cl,parent.frame()); add(data.frame(yi=z$TE,vi=z$seTE^2),source_expr); z
}
capture_rma <- function(...) {
 cl <- match.call(expand.dots=TRUE)
 fn <- as.character(cl[[1]])
 aa <- as.list(cl)[-1]; nn <- names(aa); if(is.null(nn)) nn <- rep('',length(aa))
 pos <- which(nn==''); if(length(pos)>0) nn[pos] <- c('yi','vi')[seq_along(pos)]
 names(aa) <- nn
 aa <- aa[names(aa) %in% setdiff(names(formals(metafor::escalc)),c('subset','include'))]
 if(is.null(aa$measure)) aa$measure <- if(fn=='rma.peto') 'PETO' else if(fn=='rma.mh') 'OR' else 'GEN'
 cl <- as.call(c(list(quote(metafor::escalc)),aa))
 z <- eval(cl,parent.frame()); add(z,source_expr); z
}
for(nm in datasets) {
 meta::settings.meta('reset')
 current <- nm; errors <- list(); e <- new.env(parent=globalenv())
 data(list=nm,package='metadat',envir=e)
 d <- e[[nm]]; add(d,'stored yi/vi')
 e$escalc <- capture_es; e$rma <- capture_rma; e$rma.uni <- capture_rma
 e$rma.mh <- capture_rma; e$rma.peto <- capture_rma
 for(fn in c('metagen','metabin','metacont','metaprop')) e[[fn]] <- capture_meta
 e$pairwise <- capture_pairwise
 f <- file.path('documentation',paste0(nm,'.R'))
 if(file.exists(f)) {
  txt <- sub('^##D ?', '',readLines(f,warn=FALSE))
  exprs <- tryCatch(parse(text=txt),error=function(ex) {errors[[length(errors)+1]] <<- conditionMessage(ex); expression()})
  for(ex in exprs) {
   source_expr <- paste(deparse(ex,width.cutoff=500),collapse=' ')
   # Evaluate only data preparation and direct effect-size/pairwise model calls.
   if(any(all.names(ex) %in% c('rma.mv','rma.glmm','bayesmeta','jags','stan','plot','forest','funnel','predict','anova','summary','print','library','require','install.packages','download.file','url','source','setwd','write','save','sink','pdf','png','par','system','netmeta','netmetabin','netcomb','netbind','rankogram','update','function','regplot','robust','cumul'))) next
   if(!(is.call(ex) && (as.character(ex[[1]])[1] %in% c('<-','=','escalc','rma','rma.uni','rma.mh','rma.peto','metagen','metabin','metacont','metaprop','pairwise','settings.meta')))) next
   tryCatch(withCallingHandlers(eval(ex,e),warning=function(w){errors[[length(errors)+1]] <<- paste('warning',source_expr,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(er){errors[[length(errors)+1]] <<- paste(source_expr,conditionMessage(er))})
  }
 }
 # Documented nonstandard stored columns and preparations not passed to escalc.
 if(nm=='dat.bakdash2021') add(data.frame(yi=d$es.z,vi=d$vi.z),'stored Fisher z: es.z / vi.z')
 if(nm=='dat.maire2019') add(data.frame(yi=d$dat$s1,vi=d$dat$vars1),'stored slope s1 / vars1; marginal numerical check ignoring spatial correlation')
 if(nm=='dat.ishak2007') for(i in 1:4) add(data.frame(yi=d[[paste0('y',i,'i')]],vi=d[[paste0('v',i,'i')]]),paste('stored occasion',i))
 if(nm=='dat.lopez2019' && exists('dat',e,inherits=FALSE)) add(e$dat,'documented to.wide contrast: diff1-diff2 / se1^2+se2^2')
 if(nm=='dat.craft2003') add(metafor::escalc(measure='ZCOR',ri=d$ri,ni=d$ni),'Fisher z correlations: ri / ni; escalc ZCOR')
 if(nm %in% c('dat.roever2022','dat.ursino2021')) add(metafor::escalc(measure='PLO',xi=d$events,ni=d$total),'logit arm event proportions: events / total; escalc PLO')
 if(nm=='dat.hartmannboyce2018') add(metafor::escalc(measure='RR',ai=d$x.nrt,n1i=d$n.nrt,ci=d$x.ctrl,n2i=d$n.ctrl),'documented log RR: x.nrt/n.nrt vs x.ctrl/n.ctrl')
 if(nm=='dat.yusuf1985') add(metafor::escalc(measure='PETO',ai=d$ai,n1i=d$n1i,ci=d$ci,n2i=d$n2i),'documented Peto log OR; complete dataset without subgroup loop')
 if(nm=='dat.huber2000') {
  studies <- split(d,d$study)
  z <- do.call(rbind,lapply(studies,function(s){
   a <- s$recurrences[s$treatment=='Uro-Vaxom']; b <- s$recurrences[s$treatment=='Placebo']
   metafor::escalc(measure='MD',m1i=mean(a),sd1i=sd(a),n1i=length(a),m2i=mean(b),sd2i=sd(b),n2i=length(b))
  }))
  add(z,'IPD recurrence mean difference: Uro-Vaxom minus Placebo; escalc MD from group means, SDs and sizes')
 }
 n <- sum(vapply(corpus,function(x)x$dataset==nm,logical(1)))
 ledger[[nm]] <- list(dataset=nm,status=if(n>0)'used' else 'excluded',configurations=n,columns=names(d),reason=if(n>0)'stored or documented effect-size definition' else 'no successful eligible stored/documented effect-size construction; see preparation messages',preparation_messages=errors)
 if(nm=='dat.metap') ledger[[nm]]$reason <- 'p-value collections; no effect sizes with sampling variances or raw outcome summaries for escalc'
}
write_json17(corpus,'corpus.json')
write_json17(ledger,'coverage.json')
write_json17(attempts,'construction-attempts.json')
cat(length(datasets),'datasets enumerated;',length(corpus),'configurations;',sum(vapply(ledger,function(x)x$status=='used',logical(1))),'datasets used\n')
