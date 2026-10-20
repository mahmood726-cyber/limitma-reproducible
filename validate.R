# One-command fresh R validation. Run from the archive root.
field <- function(x,k) {if(!is.list(x)||!(k %in% names(x)))stop('Missing field: ',k);x[[k,exact=TRUE]]}
finite <- function(x) is.numeric(x)&&length(x)==1L&&is.finite(x)
scalars <- strsplit('k fe_est fe_se fe_ci_lo fe_ci_hi re_est re_se re_ci_lo re_ci_hi tau2_dl tau_dl limit_est limit_se limit_ci_lo limit_ci_hi slope alpha_r beta_r Q Q_small Q_resid G_squared',' ',fixed=TRUE)[[1]]
refusal_id <- 'dat.hartmannboyce2018::001'
refusal_reason <- "Fisher scoring algorithm did not converge. See 'help(rma)' for possible remedies."
check_tree <- function(x) {if(is.list(x)){if(!is.null(names(x))&&(anyDuplicated(names(x))||any(!nzchar(names(x)))))stop('Duplicate/empty keys');invisible(lapply(x,check_tree))}}
vec <- function(x,k) {if(!is.list(x)||length(x)!=k||!all(vapply(x,finite,TRUE)))stop('Invalid vector');unlist(x)}
keyed <- function(x) {
 if(!is.list(x)||length(x)!=169L)stop('Expected exactly 169 configurations')
 ids<-vapply(x,function(y){id<-field(y,'id');if(!is.character(id)||length(id)!=1L||!nzchar(id))stop('Invalid ID');id},'')
 if(anyDuplicated(ids))stop('Duplicate configuration key');setNames(x,ids)
}
check_inputs <- function(corpus,app) {
 check_tree(corpus);check_tree(app);c<-keyed(corpus);a<-keyed(app)
 if(!setequal(names(c),names(a)))stop('Coverage mismatch')
 for(id in names(c)){
  s<-field(c,id);k<-field(s,'k');stopifnot(finite(k),k>=3,k==floor(k))
  vec(field(s,'te'),k);stopifnot(all(vec(field(s,'se'),k)>0))
  rows<-vec(field(s,'source_rows'),k);stopifnot(!anyDuplicated(rows),all(rows>0),all(rows==floor(rows)))
  aa<-field(a,id);stopifnot(identical(field(aa,'status'),'ok'));v<-field(aa,'values')
  if(!setequal(names(v),c(scalars,'te_limit',if('_schema' %in% names(v))'_schema')))stop('Quantity inventory mismatch')
  for(q in scalars){x<-field(v,q);if(!(finite(x)||(q=='G_squared'&&is.null(x))))stop('Invalid app quantity: ',q)}
  stopifnot(field(v,'k')==k);vec(field(v,'te_limit'),k)
  stopifnot(is.logical(field(aa,'table_ok')),length(field(aa,'table_ok'))==1L,!is.na(field(aa,'table_ok')))
  for(f in c('points','regression')){ps<-field(aa,f);stopifnot(is.list(ps),length(ps)==if(f=='points')k else 65L);for(p in ps){stopifnot(setequal(names(p),c('x','y')));for(axis in c('x','y'))stopifnot(finite(field(p,axis)))}}
 }
 list(corpus=c,app=a)
}
check_versions <- function(versions,rversion) {
 want<-c(meta='8.5.0',metasens='1.5.3',metadat='1.6.0',metafor='5.2.1')
 if(!identical(versions,want)||rversion!='4.6.0')stop('Wrong package/R versions; required meta 8.5-0, metasens 1.5-3, metadat 1.6-0, metafor 5.2-1, R 4.6.0')
}
required_inputs<-c('data/corpus.json','results/app-patched.json','expected/documented_differences.json')
check_pins <- function(pins) {
 check_tree(pins)
 if(!is.list(pins)||!setequal(names(pins),required_inputs)||length(pins)!=length(required_inputs))stop('Input hash manifest coverage mismatch')
 for(p in required_inputs){h<-field(pins,p);if(!is.character(h)||length(h)!=1L||!grepl('^[0-9a-f]{64}$',h)||!file.exists(p)||digest::digest(file=p,algo='sha256')!=h)stop('SHA-256 mismatch: ',p)}
}
visible_curve <- function(x,y,lo,hi) {
 xx<-yy<-numeric()
 for(i in seq_len(length(x)-1L)){
  a<-x[i];b<-x[i+1L];ya<-y[i];yb<-y[i+1L]
  if((a<lo&&b<lo)||(a>hi&&b>hi))next
  left<-max(lo,min(hi,a));right<-max(lo,min(hi,b))
  t0<-if(a==b)0 else (left-a)/(b-a);t1<-if(a==b)1 else (right-a)/(b-a)
  xx<-c(xx,left,right);yy<-c(yy,ya+t0*(yb-ya),ya+t1*(yb-ya))
 }
 stopifnot(length(xx)>=2);keep<-!duplicated(yy);xx<-xx[keep];yy<-yy[keep];grid<-seq(min(yy),max(yy),length.out=65)
 list(x=unname(approx(yy,xx,xout=grid,rule=2)[['y',exact=TRUE]]),y=grid)
}
refit <- function(s) {
 te<-unlist(field(s,'te'));se<-unlist(field(s,'se'))
 m<-meta::metagen(te,se,method.tau='DL',method.random.ci='classic',level=.95,level.ma=.95,method.tau.ci='')
 l<-metasens::limitmeta(m,method.adjust='beta0')
 v<-list(k=field(m,'k'))
 mp<-c(fe_est='TE.common',fe_se='seTE.common',fe_ci_lo='lower.common',fe_ci_hi='upper.common',re_est='TE.random',re_se='seTE.random',re_ci_lo='lower.random',re_ci_hi='upper.random',tau2_dl='tau2',tau_dl='tau')
 for(q in names(mp))v[[q]]<-field(m,mp[[q,exact=TRUE]])
 mp<-c(limit_est='TE.adjust',limit_se='seTE.adjust',limit_ci_lo='lower.adjust',limit_ci_hi='upper.adjust',slope='beta.r',alpha_r='alpha.r',beta_r='beta.r',Q='Q',Q_small='Q.small',Q_resid='Q.resid',G_squared='G.squared')
 for(q in names(mp))v[[q]]<-field(l,mp[[q,exact=TRUE]])
 v[['te_limit']]<-unname(field(l,'TE.limit'))
 # Primary paper corpus has finite G-squared; no invalid number is coerced to null here.
 stopifnot(all(vapply(v,function(x)length(x)>0&&all(is.finite(x)),TRUE)))
 grid<-seq(0,max(se)*1.1,length.out=65)
 list(values=v,points=list(x=te,y=se),regression=visible_curve(field(l,'beta.r')+field(l,'alpha.r')*sqrt(grid^2+field(m,'tau2')),grid,min(field(l,'TE.adjust'),te)-.1,max(field(l,'TE.adjust'),te)+.1))
}
judge <- function(tab,refusals,expected) {
 check_tree(expected)
 stopifnot(identical(names(expected),refusal_id),identical(names(refusals),refusal_id))
 d<-field(expected,refusal_id);stopifnot(identical(field(d,'quantity'),'status'),identical(field(d,'reference_status'),'refused'),identical(field(d,'app_status'),'ok'),identical(field(d,'reason'),refusal_reason),identical(field(d,'phase'),'limitmeta beta0 (including internal metagen call)'),identical(field(refusals,refusal_id),refusal_reason))
 stopifnot(nrow(tab)==55525L,!anyDuplicated(tab[c('configuration','quantity','row')]))
 bad<-tab[tab[['Result',exact=TRUE]]!='PASS',]
 stopifnot(nrow(bad)==1L,bad[['configuration',exact=TRUE]]==refusal_id,bad[['quantity',exact=TRUE]]=='status')
}
main <- function() {
 started<-proc.time()[['elapsed',exact=TRUE]]
 userlibs<-strsplit(Sys.getenv('R_LIBS_USER'),.Platform$path.sep,fixed=TRUE)[[1]];.libPaths(c(userlibs[nzchar(userlibs)],.libPaths()))
 cat('.libPaths():\n');print(.libPaths())
 for(p in c('meta','metasens','metadat','metafor','jsonlite','digest'))if(!requireNamespace(p,quietly=TRUE))stop('Missing package: ',p)
 versions<-vapply(c('meta','metasens','metadat','metafor'),function(p)as.character(packageVersion(p)),'');print(versions);cat(R.version.string,'\n');check_versions(versions,as.character(getRversion()))
 read<-function(p)jsonlite::fromJSON(p,simplifyVector=FALSE)
 check_pins(read('INPUT_SHA256.json'));inputs<-check_inputs(read('data/corpus.json'),read('results/app-patched.json'))
 expected<-read('expected/documented_differences.json')
 if('--preflight' %in% commandArgs(TRUE)){cat('PREFLIGHT PASS\n');return(0L)}
 corpus<-field(inputs,'corpus');app<-field(inputs,'app');chunks<-list();refusals<-list()
 add<-function(id,q,a,r,row=0L,mode='fresh R vs archived browser'){
  diff<-if(q=='G_squared'&&is.null(a)&&is.null(r))0 else if(finite(a)&&finite(r))abs(a-r)/max(1,abs(r)) else Inf
  val<-function(x)if(is.null(x))'null' else sprintf('%.17g',x)
  chunks[[length(chunks)+1L]]<<-data.frame(configuration=id,quantity=q,row=row,App=val(a),R=val(r),Difference=diff,Tolerance=1e-9,Result=if(diff<=1e-9)'PASS' else 'FAIL',Mode=mode)
 }
 # Preserve the default REML for metasens' internal fit, exactly as reference.R.
 meta::settings.meta(method.tau='REML')
 for(id in names(corpus)){
  s<-field(corpus,id);a<-field(app,id);error<-NULL
  rr<-tryCatch(refit(s),error=function(e){error<<-conditionMessage(e);NULL})
  add(id,'status',if(is.null(error))1 else 0,1)
  if(!is.null(error)){refusals[id]<-list(error);cat('REFUSED ',id,': ',error,'\n',sep='');next}
  av<-field(a,'values');rv<-field(rr,'values')
  for(q in scalars)add(id,q,field(av,q),field(rv,q))
  x<-field(av,'te_limit');y<-field(rv,'te_limit');add(id,'te_limit_length',length(x),length(y))
  for(i in seq_along(y))add(id,'te_limit',x[[i]],y[i],i-1L)
  add(id,'table_render',as.numeric(field(a,'table_ok')),1,mode='replayed archived browser DOM; not freshly rendered')
  for(f in c('points','regression')){ap<-field(a,f);rp<-field(rr,f);add(id,paste0(f,'_length'),length(ap),length(field(rp,'x')));for(i in seq_along(ap))for(axis in c('x','y'))add(id,paste0(f,'_',axis),field(ap[[i]],axis),field(rp,axis)[i],i-1L)}
 }
 tab<-do.call(rbind,chunks);dir.create('outputs',showWarnings=FALSE);write.csv(tab,'outputs/validate_R_table.csv',row.names=FALSE)
 for(q in unique(tab[['quantity',exact=TRUE]])){s<-tab[tab[['quantity',exact=TRUE]]==q,];cat(sprintf('%s | %d/%d | %.17g | 1e-9\n',q,sum(s[['Result',exact=TRUE]]=='PASS'),nrow(s),max(s[['Difference',exact=TRUE]])))}
 cat(sprintf('%d/%d checks pass\n',sum(tab[['Result',exact=TRUE]]=='PASS'),nrow(tab)))
 judge(tab,refusals,expected)
 cat(sprintf('Runtime: %.3f seconds\n',proc.time()[['elapsed',exact=TRUE]]-started))
 cat('55,524/55,525 pass; 1 documented, 0 unexpected\n');0L
}
# Layer 1.1.0 (v1_1/): LOO and bias-sensitivity tiers. Runs after v1 in a fresh R process (v1 changes meta settings);
# ARCHIVE_V1_1_ONLY=1 skips the v1 part above. See v1_1/validate_v1_1.R and README.
rscript <- function() file.path(R.home('bin'),if(.Platform$OS.type=='windows')'Rscript.exe' else 'Rscript')
v1_1 <- function() {cat('--- layer 1.1.0 (v1_1/validate_v1_1.R) ---\n');system2(rscript(),c('--vanilla','v1_1/validate_v1_1.R'))}
if(sys.nframe()==0L){
 status<-if(identical(Sys.getenv('ARCHIVE_V1_1_ONLY'),'1')){
  cat('ARCHIVE_V1_1_ONLY=1: v1 refit (55,525 checks) skipped; running the v1 input preflight only\n')
  Sys.unsetenv('ARCHIVE_V1_1_ONLY');system2(rscript(),c('--vanilla','validate.R','--preflight'))
 } else tryCatch(main(),error=function(e){cat('Validation failed: ',conditionMessage(e),'\n',sep='',file=stderr());1L})
 if(status==0L&&!('--preflight' %in% commandArgs(TRUE)))status<-v1_1()
 quit(save='no',status=status)
}
