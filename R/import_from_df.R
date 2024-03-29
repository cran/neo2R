#' Imports a data.frame in the neo4j graph database
#'
#' This function only works with localhost Neo4j instances.
#'
#' @param graph the neo4j connection
#' @param cql the CQL query to be applied on each row of toImport.
#' Use the 'row' prefix to refer to the data.frame column.
#' @param toImport the data.frame to be imported as "row".
#' Use "row.FIELD" in the cql query to refer to one FIELD of the toImport
#' data.frame
#' @param periodicCommit use periodic commit when loading the data
#' (default: 10000).
#' @param by number of rows to send by batch (default: Inf).
#' Can be an alternative to periodic commit.
#' @param ... further parameters for [cypher()]
#'
#' @seealso [cypher()]
#'
#' @export
#'
import_from_df <- function(
   graph, cql, toImport,
   periodicCommit=1000,
   by=Inf, ...
){
   stopifnot(
      is.data.frame(toImport),
      length(by)==1, is.numeric(by), by > 0,
      length(periodicCommit)==1,
      is.na(periodicCommit) ||
         (is.numeric(periodicCommit) && periodicCommit > 0)
   )
   importPath <- graph$importPath
   stopifnot(
      !is.null(importPath),
      !is.na(importPath)
   )
   if(!file.exists(importPath)){
      stop(sprintf("Import path (%s) does not exist.", importPath))
   }
   tf <- tempfile(tmpdir=importPath)
   for(cn in colnames(toImport)){
      toImport[,cn] <- as.character(toImport[, cn, drop=TRUE])
   }
   # pc <- c()
   # if(is.numeric(periodicCommit) && length(periodicCommit)==1){
   #    if(graph$version[[1]]!=5){
   #       pc <- sprintf("USING PERIODIC COMMIT %s", periodicCommit)
   #    }else{
   #       warning(
   #          "Periodic commit not supported for Neo4j >= 5.\n",
   #          "Consider the 'by' parameter."
   #       )
   #    }
   # }
   # cql <- prepCql(c(
   #    pc,
   #    paste0(
   #       'LOAD CSV WITH HEADERS FROM "file:',
   #       ifelse(
   #          !is.null(importPath),
   #          file.path("", basename(tf)),
   #          tf
   #       ),
   #       '" AS row '# FIELDTERMINATOR "\\t"'
   #    ),
   #    cql
   # ))
   load_string <- paste0(
      'LOAD CSV WITH HEADERS FROM "file:',
      ifelse(
         !is.null(importPath),
         file.path("", basename(tf)),
         tf
      ),
      '" AS row '# FIELDTERMINATOR "\\t"'
   )
   if(!is.na(periodicCommit)){
      if(graph$version[[1]]!=5){
         cql <- prepCql(c(
            sprintf("USING PERIODIC COMMIT %s", periodicCommit),
            load_string,
            cql
         ))
      }else{
         cql <- prepCql(c(
            load_string,
            "CALL {WITH row",
            cql,
            "}",
            sprintf("IN TRANSACTIONS OF %s ROWS RETURN count(*)", periodicCommit)
         ))
      }
   } else {
      cql <- prepCql(c(
         load_string,
         cql
      ))
   }
   if(nrow(toImport)<=1000){
      taken <- 0
      while(taken < nrow(toImport)){
         totake <- min(taken+by, nrow(toImport))
         utils::write.table(
            toImport[(taken+1):totake, , drop=FALSE],
            file=tf,
            sep=",", #"\t",
            quote=T,
            na='',
            row.names=F, col.names=T
         )
         on.exit(file.remove(tf))
         toRet <- cypher(graph=graph, query=cql, ...)
         taken <- totake
      }
      invisible(toRet)
   }else{
      utils::write.table(
         toImport[c(1:1000), , drop=FALSE],
         file=tf,
         sep=",", #"\t",
         quote=T,
         na='',
         row.names=F, col.names=T
      )
      on.exit(file.remove(tf))
      toRet <- cypher(graph=graph, query=cql, ...)
      cypher(graph=graph, query='CALL db.resampleOutdatedIndexes();')
      taken <- 1000
      while(taken < nrow(toImport)){
         totake <- min(taken+by, nrow(toImport))
         utils::write.table(
            toImport[(taken+1):totake, , drop=FALSE],
            file=tf,
            sep=",", #"\t",
            quote=T,
            na='',
            row.names=F, col.names=T
         )
         on.exit(file.remove(tf))
         toRet <- cypher(graph=graph, query=cql, ...)
         taken <- totake
      }
      invisible(toRet)

   }
}
