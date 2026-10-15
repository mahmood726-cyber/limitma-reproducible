# JSON numbers are emitted with 17 significant digits for binary64 round trips.
write_json17 <- function(x, file) {
 encode <- function(v) {
  if(is.null(v)) return('null')
  if(is.list(v)) {
   z <- vapply(v,encode,character(1))
   if(!is.null(names(v))) return(paste0('{',paste(paste0(vapply(names(v),function(s)as.character(jsonlite::toJSON(s,auto_unbox=TRUE)),character(1)),':',z),collapse=','),'}'))
   return(paste0('[',paste(z,collapse=','),']'))
  }
  atom <- function(a) {
   if(is.na(a)) return('null')
   if(is.numeric(a)) return(if(is.finite(a))sprintf('%.17g',a) else 'null')
   if(is.logical(a)) return(if(a)'true' else 'false')
   as.character(jsonlite::toJSON(as.character(a),auto_unbox=TRUE))
  }
  z <- vapply(v,atom,character(1))
  if(length(z)==1) z else paste0('[',paste(z,collapse=','),']')
 }
 writeLines(encode(x),file,useBytes=TRUE)
}
