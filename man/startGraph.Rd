% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/startGraph.R
\name{startGraph}
\alias{startGraph}
\title{Prepare connection to neo4j database}
\usage{
startGraph(
  url,
  database = NA,
  username = NA,
  password = NA,
  importPath = NA,
  .opts = list(),
  check = TRUE
)
}
\arguments{
\item{url}{the DB url}

\item{database}{the name of the database. If NA (default) it will use "data"
with versions 3.. of Neo4j and "neo4j" with versions 4..}

\item{username}{the neo4j user name
(default: NA; works only if authentication has been disabled in neo4j by
setting NEO4J.AUTH=none)}

\item{password}{the neo4j user password
(default: NA; works only if authentication has been disabled in neo4j by
setting NEO4J.AUTH=none)}

\item{importPath}{path to the import directory
(default: NA => no import directory). Import only works with local neo4j
instance.}

\item{.opts}{a named list identifying the curl
options for the handle (see \code{\link[httr:config]{httr::config()}} and \code{\link[httr:httr_options]{httr::httr_options()}}
for a complete list of available options;
for example: \code{.opts = list(ssl_verifypeer = 0)}). Moreover, this parameter
can be used to pass additional headers to the graph requests as
"extendedHeaders": it is useful, for example, for OAuth access
delegation (see details).}

\item{check}{check the connection before returning it (default: TRUE).
Set to false when connection to the "system" database}
}
\value{
A connection to the graph DB:
a list with the url and necessary headers
}
\description{
Prepare connection to neo4j database
}
\details{
The "ssl.verifypeer" logical option available in the RCurl package
used in former versions of neo2R (<= 2.2.0) is
not recognized by \code{\link[httr:config]{httr::config()}}.
However, for backward compatibility, if it used, it is translated into
"ssl_verifypeer" integer option recognized by the httr package with a
warning message.

Headers in \code{.opts$extendedHeaders} are added to, or overwrite,
the default Neo4j headers.
If there is a \code{.opts$extendedHeaders[["Authorization"]]} value, the
default Neo4j "Authorization" header (user credentials) is provided
automaticaly as "X-Authorization". This mechanism is used for OAuth access
delegation.
}
