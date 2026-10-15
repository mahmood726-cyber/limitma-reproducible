source('validate.R')
userlibs<-strsplit(Sys.getenv('R_LIBS_USER'),.Platform$path.sep,fixed=TRUE)[[1]];.libPaths(c(userlibs[nzchar(userlibs)],.libPaths()))
read<-function(p)jsonlite::fromJSON(p,simplifyVector=FALSE)
reject<-function(f){failed<-FALSE;tryCatch(f(),error=function(e){failed<<-TRUE});if(!failed)stop('UNSAFE PASS')}
c<-read('data/corpus.json');a<-read('results/app-patched.json');invisible(check_inputs(c,a))
mutations<-list(
 function(x)x[-1],
 function(x){x[[2]][['id']]<-field(x[[1]],'id');x},
 function(x){x[[1]][['id']]<-'unexpected';x},
 function(x){x[[1]][['values']][['limit_est']]<-NULL;x},
 function(x){x[[1]][['values']]['limit_est']<-list(NULL);x},
 function(x){x[[1]][['values']][['limit_est']]<-NaN;x},
 function(x){x[[1]][['values']][['limit_est']]<-Inf;x},
 function(x){x[[1]][['values']][['limit_est']]<-'1';x},
 function(x){x[[1]][['values']][['te_limit']]<-x[[1]][['values']][['te_limit']][-1];x},
 function(x){x[[1]][['table_ok']]<-1;x},
 function(x){x[[1]][['regression']]<-x[[1]][['regression']][-1];x}
)
for(m in mutations)reject(function()check_inputs(c,m(a)))
bad<-c;bad[[1]][['se']][[1]]<-0;reject(function()check_inputs(bad,a))
bad<-c;bad[[1]][['source_rows']][[2]]<-bad[[1]][['source_rows']][[1]];reject(function()check_inputs(bad,a))
reject(function()check_tree(structure(list(1,2),names=c('x','x'))))
reject(function()field(list(estimate=1),'est'))
versions<-c(meta='8.5.0',metasens='1.5.3',metadat='1.6.0',metafor='5.2.1');check_versions(versions,'4.6.0')
bad<-versions;bad[['metafor']]<-'4.8.0';reject(function()check_versions(bad,'4.6.0'));reject(function()check_versions(versions,'4.5.0'))
pins<-read('INPUT_SHA256.json');check_pins(pins)
reject(function()check_pins(list()));reject(function()check_pins(pins[-1]));bad<-pins;bad[[1]]<-paste(rep('0',64),collapse='');reject(function()check_pins(bad))
tab<-read.csv('outputs/validate_R_table.csv',stringsAsFactors=FALSE);expected<-read('expected/documented_differences.json');refusals<-setNames(list(refusal_reason),refusal_id);judge(tab,refusals,expected)
reject(function()judge(tab[-1,],refusals,expected));reject(function()judge(rbind(tab[-1,],tab[2,]),refusals,expected))
bad<-tab;bad[['Result']][bad[['Result']]=='FAIL']<-'PASS';reject(function()judge(bad,list(),expected))
bad<-tab;bad[['Result']][2]<-'FAIL';reject(function()judge(bad,refusals,expected))
reject(function()judge(tab,setNames(list('changed'),refusal_id),expected))
bad<-expected;bad[[refusal_id]][['reason']]<-'changed';reject(function()judge(tab,refusals,bad))
cat('R SAFEGUARDS PASS: clean evidence accepted; malformed inputs, pins, versions, coverage and changed/disappearing refusal rejected\n')
