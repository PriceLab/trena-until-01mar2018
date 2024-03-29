#' @import methods
#'
#' @name FootprintFinder-class
#' @rdname FootprintFinder-class
#' @aliases FootprintFinder
#'
#' @slot genome.db The address of a genome database for use in filtering
#' @slot project.db The address of a project database for use in filtering
#' @slot quiet A logical argument denoting whether the FootprintFinder object should behave quietly

#----------------------------------------------------------------------------------------------------
.FootprintFinder <- setClass("FootprintFinder",
                             slots = c(genome.db="DBIConnection",
                                       project.db="DBIConnection",
                                       quiet="logical")
                             )
#----------------------------------------------------------------------------------------------------
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
setGeneric("getChromLoc", signature="obj",
           function(obj, name, biotype="protein_coding",moleculetype="gene")
               standardGeneric("getChromLoc"))
setGeneric("getGenePromoterRegion", signature="obj",
           function(obj,  gene, size.upstream=1000, size.downstream=0,
                    biotype="protein_coding", moleculetype="gene")
               standardGeneric("getGenePromoterRegion"))
setGeneric("getFootprintsForGene", signature="obj",
           function(obj,  gene, size.upstream=1000, size.downstream=0,
                    biotype="protein_coding", moleculetype="gene")
               standardGeneric("getFootprintsForGene"))
setGeneric("getFootprintsInRegion", signature="obj",
           function(obj, chromosome, start, end) standardGeneric("getFootprintsInRegion"))
setGeneric("getGtfGeneBioTypes", signature="obj",
           function(obj) standardGeneric("getGtfGeneBioTypes"))
setGeneric("getGtfMoleculeTypes", signature="obj",
           function(obj) standardGeneric("getGtfMoleculeTypes"))
setGeneric("closeDatabaseConnections", signature="obj",
           function(obj) standardGeneric("closeDatabaseConnections"))
setGeneric("getPromoterRegionsAllGenes",signature="obj",
           function(obj ,size.upstream=10000 , size.downstream=10000 , use_gene_ids = TRUE )
               standardGeneric("getPromoterRegionsAllGenes"))
#----------------------------------------------------------------------------------------------------
#' @title Class FootprintFinder
#' @name FootprintFinder-class
#' @rdname FootprintFinder-class
#'
#' @description
#' The FootprintFinder class is designed to query 2 supplied footprint databases (a genome database
#' and a project database) for supplied genes or regions. Within the TReNA package, the
#' FootprintFinder class is mainly used by the FootprintFilter class, but the FootprintFinder class
#' offers more flexibility in constructing queries.
#'
#' @param genome.database.uri The address of a genome database for use in filtering. This database
#' must contain the tables "gtf" and "motifsgenes" at a minimum. The URI format is as follows:
#' "dbtype://host/database" (e.g. "postgres://localhost/genomedb")
#' @param project.database.uri The address of a project database for use in filtering. This database
#' must contain the tables "regions" and "hits" at a minimum. The URI format is as follows:
#' "dbtype://host/database" (e.g. "postgres://localhost/projectdb")
#' @param quiet A logical denoting whether or not the FootprintFinder object should print output
#'
#' @return An object of the FootprintFinder class
#'
#' @export
#'
#' @seealso \code{\link{FootprintFilter}}
#'
#' @family FootprintFinder methods

FootprintFinder <- function(genome.database.uri, project.database.uri, quiet=TRUE)
{
    genome.db.info <- parseDatabaseUri(genome.database.uri)
    project.db.info <- parseDatabaseUri(project.database.uri)
    stopifnot(genome.db.info$brand %in% c("postgres","sqlite"))
    
    # open the genome database
    if(genome.db.info$brand == "postgres"){
        host <- genome.db.info$host
        dbname <- genome.db.info$name
        driver <- RPostgreSQL::PostgreSQL()
        genome.db <- DBI::dbConnect(driver, user= "trena", password="trena", dbname=dbname, host=host)
        existing.databases <- DBI::dbGetQuery(genome.db, "select datname from pg_database")[,1]
        DBI::dbDisconnect(genome.db)
        stopifnot(dbname %in% existing.databases)
        genome.db <- DBI::dbConnect(driver, user="trena", password="trena", dbname=dbname, host=host)
        expected.tables <- c("gtf", "motifsgenes")
        stopifnot(all(expected.tables %in% DBI::dbListTables(genome.db)))
        if(!quiet){
            row.count <- DBI::dbGetQuery(genome.db, "select count(*) from gtf")[1,1]
            printf("%s: %d rows", sprintf("%s/gtf", genome.database.uri), row.count)
            row.count <- DBI::dbGetQuery(genome.db, "select count(*) from motifsgenes")[1,1]
            printf("%s: %d rows", sprintf("%s/motifsgenes", genome.database.uri), row.count)            
        }
    } # if postgres
    
    # open the project database
    if(project.db.info$brand == "postgres"){
        host <- project.db.info$host
        dbname <- project.db.info$name
        driver <- RPostgreSQL::PostgreSQL()
        project.db <- DBI::dbConnect(driver, user= "trena", password="trena", dbname=dbname, host=host)
        existing.databases <- DBI::dbGetQuery(project.db, "select datname from pg_database")[,1]
        stopifnot(dbname %in% existing.databases)
        DBI::dbDisconnect(project.db)
        project.db <- DBI::dbConnect(driver, user="trena", password="trena", dbname=dbname, host=host)
        expected.tables <- c("regions", "hits")
        stopifnot(all(expected.tables %in% DBI::dbListTables(project.db)))
        if(!quiet){
            row.count <- DBI::dbGetQuery(project.db, "select count(*) from regions")[1,1]
            printf("%s: %d rows", sprintf("%s/regions", project.database.uri), row.count)
        }
    } # if postgres
    
    # open the genome database
    if(genome.db.info$brand == "sqlite"){
        dbname <- paste(genome.db.info$host, genome.db.info$name, sep = "/")
        driver <- RSQLite::SQLite()
        genome.db <- DBI::dbConnect(driver, dbname=dbname)
        stopifnot(file.exists(dbname))
        expected.tables <- c("gtf", "motifsgenes")
        stopifnot(all(expected.tables %in% DBI::dbListTables(genome.db)))
        if(!quiet){
            row.count <- DBI::dbGetQuery(genome.db, "select count(*) from gtf")[1,1]
            printf("%s: %d rows", sprintf("%s/gtf", genome.database.uri), row.count)
            row.count <- DBI::dbGetQuery(genome.db, "select count(*) from motifsgenes")[1,1]
            printf("%s: %d rows", sprintf("%s/motifsgenes", genome.database.uri), row.count)            
        }
    } # if sqlite
    
    # open the project database
    if(project.db.info$brand == "sqlite"){
        dbname <- paste(project.db.info$host, project.db.info$name, sep = "/")
        driver <- RSQLite::SQLite()
        project.db <- DBI::dbConnect(driver, dbname = dbname)
        stopifnot(file.exists(dbname))
        expected.tables <- c("regions", "hits")
        stopifnot(all(expected.tables %in% DBI::dbListTables(project.db)))
        if(!quiet){
            row.count <- DBI::dbGetQuery(project.db, "select count(*) from regions")[1,1]
            printf("%s: %d rows", sprintf("%s/regions", project.database.uri), row.count)
        }
    } # if sqlite
    
    .FootprintFinder(genome.db=genome.db, project.db=project.db, quiet=quiet)
    
} # FootprintFinder, the constructor
#----------------------------------------------------------------------------------------------------
#' Close a Footprint Database Connection
#'
#' This method takes a FootprintFinder object and closes connections to the footprint databases
#' if they are currently open.
#'
#' @rdname closeDatabaseConnections
#' @aliases closeDatabaseConnections
#'
#' @param obj An object of class FootprintFinder
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @return Closes the specified database connection

setMethod("closeDatabaseConnections", "FootprintFinder",
          
          function(obj){
              if(!obj@quiet) printf("-- FootprintFinder::closeDataConnections")
              if("DBIConnection" %in% is(obj@genome.db)){
                  if(!obj@quiet) printf("closing genome.db")
                  DBI::dbDisconnect(obj@genome.db)
              }
              if("DBIConnection" %in% is(obj@project.db)){
                  if(!obj@quiet) printf("closing project.db")
                  DBI::dbDisconnect(obj@project.db)
              }
          })
#----------------------------------------------------------------------------------------------------
#' Get the List of Biotypes
#'
#' Using the gtf table in the genome database contained in a FootprintFinder object, get the list of
#' different types of biological units (biotypes) contained in the table.
#'
#' @rdname getGtfGeneBioTypes
#' @aliases getGtfGeneBioTypes
#'
#' @param obj An object of class FootprintFinder
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @return A sorted list of the types of biological units contained in the gtf table of the genome
#' database.
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' biotypes <- getGtfGeneBioTypes(fp)

setMethod("getGtfGeneBioTypes", "FootprintFinder",
          
          function(obj){
              sort(DBI::dbGetQuery(obj@genome.db, "select distinct gene_biotype from gtf")[,1])
          })
#----------------------------------------------------------------------------------------------------
#' Get the List of Molecule Types
#'
#' Using the gtf table in the genome database contained in a FootprintFinder object, get the list of
#' different types of molecules contained in the table.
#'
#' @rdname getGtfMoleculeTypes
#' @aliases getGtfMoleculeTypes
#'
#' @param obj An object of class FootprintFinder
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @return A sorted list of the types of molecules contained in the gtf table of the genome
#' database.
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' mol.types <- getGtfMoleculeTypes(fp)

setMethod("getGtfMoleculeTypes", "FootprintFinder",
          
          function(obj){
              sort(DBI::dbGetQuery(obj@genome.db, "select distinct moleculetype from gtf")[,1])
          })
#----------------------------------------------------------------------------------------------------
#' Get Chromosome Location
#'
#' Using the gtf table in the genome database contained in a FootprintFinder object, get the locations
#' of chromosomes with the specified gene name, biological unit type, and molecule type
#'
#' @rdname getChromLoc
#' @aliases getChromLoc
#'
#' @param obj An object of class FootprintFinder
#' @param name A gene name or ID
#' @param biotype A type of biological unit (default="protein_coding")
#' @param moleculetype A type of molecule (default="gene")
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @return A dataframe containing the results of a database query pertaining to the specified name,
#' biotype, and molecule type. This dataframe contains the following columns: gene_id, gene_name,
#' chr, start, endpos, strand
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' chrom.locs <- getChromLoc(fp, name = "MEF2C")

setMethod("getChromLoc", "FootprintFinder",
          
          function(obj, name, biotype="protein_coding", moleculetype="gene"){
              query <- paste("select gene_id, gene_name, chr, start, endpos, strand from gtf where ",
                             sprintf("(gene_name='%s' or gene_id='%s') ", name, name),
                             sprintf("and gene_biotype='%s' and moleculetype='%s'", biotype, moleculetype),
                             collapse=" ")
              DBI::dbGetQuery(obj@genome.db, query)
          })
#----------------------------------------------------------------------------------------------------
#' Get Gene Promoter Region
#'
#' Using the \code{\link{getChromLoc}} function in conjunction with the gtf table inside the genome
#' database specified by the FootprintFinder object, get the chromosome, starting location,
#' and ending location for gene promoter region.
#'
#' @rdname getGenePromoterRegion
#' @aliases getGenePromoterRegion
#'
#' @param obj An object of class FootprintFinder
#' @param gene A gene name of ID
#' @param size.upstream An integer denoting the distance upstream of the target gene to look for footprints
#' (default = 1000)
#' @param size.downstream An integer denoting the distance downstream of the target gene to look for footprints
#' (default = 0)
#' @param biotype A type of biological unit (default="protein_coding")
#' @param moleculetype A type of molecule (default="gene")
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @return A list containing 3 elements:
#' 1) chr : The name of the chromosome containing the promoter region for the specified gene
#' 2) start : The starting location of the promoter region for the specified gene
#' 3) end : The ending location of the promoter region for the specified gene
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' prom.region <- getGenePromoterRegion(fp, gene = "MEF2C")

setMethod("getGenePromoterRegion", "FootprintFinder",
          
          function(obj, gene, size.upstream=1000, size.downstream=0, biotype="protein_coding", moleculetype="gene"){
              
              tbl.loc <- getChromLoc(obj, gene, biotype=biotype, moleculetype=moleculetype)
              if(nrow(tbl.loc) < 1){
                  warning(sprintf("no chromosomal location for %s (%s, %s)", gene, biotype, moleculetype))
                  return(NA)
              }
              
              chrom <- tbl.loc$chr[1]
              start.orig <- tbl.loc$start[1]
              end.orig   <- tbl.loc$endpos[1]
              strand     <- tbl.loc$strand[1]
              
              if(strand == "-"){ # reverse (minus) strand.  TSS is at "end" position
                  start.loc <- end.orig - size.downstream
                  end.loc   <- end.orig + size.upstream
              }
              else{ #  forward (plus) strand.  TSS is at "start" position
                  start.loc <- start.orig - size.upstream
                  end.loc   <- start.orig + size.downstream
              }
              return(list(chr=chrom, start=start.loc, end=end.loc))
          })
#----------------------------------------------------------------------------------------------------
#' Get Footprints for Gene
#'
#' Using the \code{\link{getGenePromoterRegion}} and \code{\link{getFootprintsInRegion}} functions
#' in conjunction with the gtf table inside the genome database specified by the FootprintFinder object,
#' retrieve a dataframe containing the footprints for a specified gene
#'
#' @rdname getFootprintsForGene
#' @aliases getFootprintsForGene
#'
#' @param obj An object of class FootprintFinder
#' @param gene A gene name of ID
#' @param size.upstream An integer denoting the distance upstream of the target gene to look for footprints
#' (default = 1000)
#' @param size.downstream An integer denoting the distance downstream of the target gene to look for footprints
#' (default = 0)
#' @param biotype A type of biological unit (default="protein_coding")
#' @param moleculetype A type of molecule (default="gene")
#'
#' @return A dataframe containing all footprints for the specified gene and accompanying parameters
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' footprints <- getFootprintsForGene(fp, gene = "MEF2C")

setMethod("getFootprintsForGene", "FootprintFinder",
          
          function(obj,  gene, size.upstream=1000, size.downstream=0,
                   biotype="protein_coding", moleculetype="gene"){
              stopifnot(length(gene) == 1)
              loc <- getGenePromoterRegion(obj, gene, size.upstream, size.downstream,
                                           biotype=biotype, moleculetype=moleculetype)
              if(!obj@quiet) print(loc)
              getFootprintsInRegion(obj, loc$chr, loc$start, loc$end)
          }) # getFootprintsForGene
#----------------------------------------------------------------------------------------------------
#' Get Footprints in a Region
#'
#' Using the regions and hits tables inside the project database specified by the FootprintFinder
#' object, return the location, chromosome, starting position, and ending positions of all footprints
#' for the specified region.
#'
#' @rdname getFootprintsInRegion
#' @aliases getFootprintsInRegion
#'
#' @param obj An object of class FootprintFinder
#' @param chromosome The name of the chromosome of interest
#' @param start An integer denoting the start of the desired region
#' @param end An integer denoting the end of the desired region
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @return A dataframe containing all footprints for the specified region
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' footprints <- getFootprintsInRegion(fp, chromosome = "chr5",
#' start = 88903305, end = 88903319 )

setMethod("getFootprintsInRegion", "FootprintFinder",
          
          function(obj, chromosome, start, end){
              query.p0 <- "select loc, chrom, start, endpos from regions"
              query.p1 <- sprintf("where chrom='%s' and start >= %d and endpos <= %d", chromosome, start, end)
              query.regions <- paste(query.p0, query.p1)
              tbl.regions <- DBI::dbGetQuery(obj@project.db, query.regions)
              if(nrow(tbl.regions) == 0)
                  return(data.frame())
              loc.set <- sprintf("('%s')", paste(tbl.regions$loc, collapse="','"))
              query.hits <- sprintf("select * from hits where loc in %s", loc.set)
              tbl.hits <- DBI::dbGetQuery(obj@project.db, query.hits)
              tbl.out <- merge(tbl.regions, tbl.hits, on="loc")
              unique(tbl.out)

          }) # getFootprintsInRegion
#----------------------------------------------------------------------------------------------------
#' Get Promoter Regions for All Genes
#'
#' Using the gtf table inside the genome database specified by the FootprintFinder object, return the
#' promoter regions for every protein-coding gene in the database.
#'
#' @rdname getPromoterRegionsAllGenes
#' @aliases getPromoterRegionsAllGenes
#'
#' @param obj An object of class FootprintFinder
#' @param size.upstream An integer denoting the distance upstream of each gene's transcription start
#' site to include in the promoter region (default = 1000)
#' @param size.downstream An integer denoting the distance downstream of each gene's transcription start
#' site to include in the promoter region (default = 1000)
#' @param use_gene_ids A binary indicating whether to return gene IDs or gene names (default = T)
#'
#' @return A GRanges object containing the promoter regions for all genes
#'
#' @export
#'
#' @family FootprintFinder methods
#'
#' @examples
#' db.address <- system.file(package="trena", "extdata")
#' genome.db.uri <- paste("sqlite:/",db.address,"mef2c.neighborhood.hg38.gtfAnnotation.db", sep = "/")
#' project.db.uri <- paste("sqlite:/",db.address,"mef2c.neigborhood.hg38.footprints.db", sep = "/")
#' fp <- FootprintFinder(genome.db.uri, project.db.uri)
#'
#' footprints <- getPromoterRegionsAllGenes(fp)

setMethod("getPromoterRegionsAllGenes","FootprintFinder",

          function( obj , size.upstream=10000 , size.downstream=10000 , use_gene_ids = TRUE ) {

              query <-
                  paste( "select gene_name, gene_id, chr, start, endpos, strand from gtf where" ,
                        "gene_biotype='protein_coding' and moleculetype='gene'" , sep=" " )
              
              genes = DBI::dbGetQuery( obj@genome.db , query )
              
              # function to get each transcript's TSS
              get_tss <-
                  function( t ) {
                      chrom <- genes$chr[t]
                      start.orig <- genes$start[t]
                      end.orig   <- genes$endpos[t]
                      strand     <- genes$strand[t]
                      
                      if(strand == "-"){ # reverse (minus) strand.  TSS is at "end" position
                          tss <- end.orig
                      }
                      else{ #  forward (plus) strand.  TSS is at "start" position
                          tss <- start.orig
                      }
                      return( tss )
                  }
              # apply get_tss to all transcripts
              tss = sapply( 1:nrow(genes) , get_tss )
              
              # assemble a bed file for the TSSs
              promoter_regions = unique( data.frame(
                  chr = genes$chr ,
                  start = tss - size.upstream , end = tss + size.downstream ,
                  gene_name = genes$gene_name ,
                  gene_id = genes$gene_id ))
              # GRanges obj
              gr = GenomicRanges::makeGRangesFromDataFrame( promoter_regions , keep.extra.columns = TRUE )
              if( use_gene_ids == FALSE ) names(gr) = promoter_regions$gene_name
              if( use_gene_ids == TRUE ) names(gr) = promoter_regions$gene_id
              return( gr )

          }) # getPromoterRegionsAllGenes
#----------------------------------------------------------------------------------------------------
