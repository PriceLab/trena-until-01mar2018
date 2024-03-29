% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Trena.R
\docType{methods}
\name{getRegulatoryChromosomalRegions,Trena-method}
\alias{getRegulatoryChromosomalRegions,Trena-method}
\alias{getRegulatoryChromosomalRegions}
\title{Get the regulatory chromosomal regions for a Trena object}
\usage{
\S4method{getRegulatoryChromosomalRegions}{Trena}(obj, chromosome, chromStart,
  chromEnd, regulatoryRegionSources, targetGene, targetGeneTSS,
  combine = FALSE)
}
\arguments{
\item{obj}{An object of class Trena}

\item{chromosome}{A choromosome of interest}

\item{chromStart}{The beginning of the desired region}

\item{chromEnd}{The end of the desired region}

\item{regulatoryRegionSources}{A vector containing the names of sources for chromosome information. These can be
addresses of footprint databases or the names of DHS databases}

\item{targetGene}{A target gene of interest}

\item{targetGeneTSS}{An integer giving the location of the target gene's transcription start site}

\item{combine}{A logical indicating whether or not to combine the output into one data frame (default = FALSE)}
}
\value{
A list of regulatory regions for the supplied target gene. If \code{combine} is set to \code{TRUE},
the list is converted into a data frame.
}
\description{
Get the regulatory chromosomal regions for a Trena object
}
\examples{
# Get regulatory regions for MEF2C from a footprint database
database.filename <- system.file(package="trena", "extdata", "mef2c.neigborhood.hg38.footprints.db")
database.uri <- sprintf("sqlite://\%s", database.filename)
sources <- c(database.uri)

trena <- Trena("hg38")
chromosome <- "chr5"
mef2c.tss <- 88904257
loc.start <- mef2c.tss - 1000
loc.end   <- mef2c.tss + 1000

regions <- getRegulatoryChromosomalRegions(trena, chromosome, mef2c.tss-1000, mef2c.tss+1000,
sources, "MEF2C", mef2c.tss)

# Get regulatory regions for AQP4 from a Human DHS source
trena <- Trena("hg38")
aqp4.tss <- 26865884
chromosome <- "chr18"
sources <- c("encodeHumanDHS")

regions <- getRegulatoryChromosomalRegions(trena, chromosome, aqp4.tss-1, aqp4.tss+3, sources, "AQP4", aqp4.tss)
}
