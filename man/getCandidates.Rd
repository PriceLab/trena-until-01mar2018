% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CandidateFilter.R
\name{getCandidates}
\alias{getCandidates}
\title{Get candidate genes using a CandidateFilter object}
\usage{
getCandidates(obj)
}
\arguments{
\item{obj}{An object of a CandidateFilter class}
}
\value{
A vector containing genes from the assay matrix that are selected by the filter
}
\description{
Get candidate genes using a CandidateFilter object
}
\seealso{
Other getCandidate Methods: \code{\link{getCandidates,FootprintFilter-method}},
  \code{\link{getCandidates,GeneOntologyFilter-method}},
  \code{\link{getCandidates,HumanDHSFilter-method}},
  \code{\link{getCandidates,VarianceFilter-method}}
}
