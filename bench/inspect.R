.libPaths(c(.libPaths(), Sys.getenv('EXTRA_R_LIB')))
library(metadat)
library(metafor)
library(meta)
library(metasens)
writeLines(deparse(metasens::limitmeta), 'limitmeta-source.txt')
writeLines(deparse(metasens:::radialregression), 'radial-source.txt')
cat(R.version.string, '\n')
for (p in c('metadat','metafor','meta','metasens','jsonlite')) cat(p, as.character(packageVersion(p)), '\n')
ds <- unique(data(package='metadat')$results[,'Item'])
out <- list()
rd <- tools::Rd_db('metadat')
dir.create('documentation',showWarnings=FALSE)
for (nm in ds) {
 e <- new.env(); data(list=nm,package='metadat',envir=e)
 d <- e[[nm]]
 out[[nm]] <- list(class=class(d), n=nrow(d), columns=names(d))
 rr <- rd[[paste0(nm,'.Rd')]]
 if (!is.null(rr)) {tools::Rd2ex(rr,out=file.path('documentation',paste0(nm,'.R')))}
}
jsonlite::write_json(out,'inventory.json',pretty=TRUE,auto_unbox=TRUE)
