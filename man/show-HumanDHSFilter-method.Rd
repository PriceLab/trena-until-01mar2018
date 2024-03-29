% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/HumanDHSFilter.R
\docType{methods}
\name{show,HumanDHSFilter-method}
\alias{show,HumanDHSFilter-method}
\alias{show-HumanDHSFilter}
\title{Show the details of a human DHS filter}
\usage{
\S4method{show}{HumanDHSFilter}(object)
}
\arguments{
\item{object}{An object of class HumanDHSFilter}
}
\value{
A list, where one element a character vector of transcription factors that match
the GO term and the other is an empty data frame.
}
\description{
Show the details of a human DHS filter
}
\examples{
# Make a filter and show it
#' load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
targetGene <- "VRK2"
promoter.length <- 1000
genomeName <- "hg38"
db.address <- system.file(package="trena", "extdata")
genome.db.uri    <- paste("sqlite:/", db.address, "vrk2.neighborhood.hg38.gtfAnnotation.db",  sep = "/")
jaspar.human <- as.list(query(query(MotifDb, "sapiens"),"jaspar2016"))

# Grab regions for VRK2 using shoulder size of 1000
trena <- Trena(genomeName)
tbl.regions <- getProximalPromoter(trena, "VRK2", 1000, 1000)

hd.filter <- HumanDHSFilter(genomeName, pwmMatchPercentageThreshold = 85,
geneInfoDatabase.uri = genome.db.uri, regions = tbl.regions, pfms = jaspar.human)

show(hd.filter)
}
\seealso{
\code{\link{HumanDHSFilter}}
}
