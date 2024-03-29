% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/FootprintFinder.R
\docType{methods}
\name{getFootprintsForGene,FootprintFinder-method}
\alias{getFootprintsForGene,FootprintFinder-method}
\alias{getFootprintsForGene}
\title{Get Footprints for Gene}
\usage{
\S4method{getFootprintsForGene}{FootprintFinder}(obj, gene,
  size.upstream = 1000, size.downstream = 0, biotype = "protein_coding",
  moleculetype = "gene")
}
\arguments{
\item{obj}{An object of class FootprintFinder}

\item{gene}{A gene name of ID}

\item{size.upstream}{An integer denoting the distance upstream of the target gene to look for footprints
(default = 1000)}

\item{size.downstream}{An integer denoting the distance downstream of the target gene to look for footprints
(default = 0)}

\item{biotype}{A type of biological unit (default="protein_coding")}

\item{moleculetype}{A type of molecule (default="gene")}
}
\value{
A dataframe containing all footprints for the specified gene and accompanying parameters
}
\description{
Using the \code{\link{getGenePromoterRegion}} and \code{\link{getFootprintsInRegion}} functions
in conjunction with the gtf table inside the genome database specified by the FootprintFinder object,
retrieve a dataframe containing the footprints for a specified gene
}
\examples{
db.address <- system.file(package="trena", "extdata")
genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
fp <- FootprintFinder(genome.db.uri, project.db.uri)

footprints <- getFootprintsForGene(fp, gene = "MEF2C")
}
\seealso{
Other FootprintFinder methods: \code{\link{FootprintFinder-class}},
  \code{\link{closeDatabaseConnections,FootprintFinder-method}},
  \code{\link{getChromLoc,FootprintFinder-method}},
  \code{\link{getFootprintsInRegion,FootprintFinder-method}},
  \code{\link{getGenePromoterRegion,FootprintFinder-method}},
  \code{\link{getGtfGeneBioTypes,FootprintFinder-method}},
  \code{\link{getGtfMoleculeTypes,FootprintFinder-method}},
  \code{\link{getPromoterRegionsAllGenes,FootprintFinder-method}}
}
