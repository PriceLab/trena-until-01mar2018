library(trena)
library(RUnit)
library(MotifDb)
library(RPostgreSQL)
#----------------------------------------------------------------------------------------------------
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
if(!exists("mtx")){
    load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
    mtx <- asinh(mtx.sub)
    mtx.var <- apply(mtx, 1, var)
    deleters <- which(mtx.var < 0.01)
    if(length(deleters) > 0)   # 15838 x 638
        mtx <- mtx[-deleters,]
}
#----------------------------------------------------------------------------------------------------
runTests <- function()
{
    test_basicConstructor()

    test_getRegulatoryRegions_oneFootprintSource()
    test_getRegulatoryRegions_encodeDHS()
    test_getRegulatoryRegions_twoFootprintSources()

    test_createGeneModel()

    test_getProximalPromoterHuman()
    test_getProximalPromoterMouse()

    checkEquals(openPostgresConnections(), 0)

} # runTests
#------------------------------------------------------------------------------------------------------------------------
test_basicConstructor <- function()
{
    printf("--- test_basicConstructor")

    trena <- Trena("hg38")
    checkEquals(is(trena), "Trena")

    checkException(Trena("hg00"), silent=TRUE)
    checkException(Trena(""), silent=TRUE)
    checkEquals(openPostgresConnections(), 0)

} # test_basicConstructor
#----------------------------------------------------------------------------------------------------
test_getRegulatoryRegions_oneFootprintSource <- function()
{
    printf("--- test_getRegulatoryRegions_oneFootprintSource")

    trena <- Trena("hg38")
    # the package's demo sqlite database is limited to in and around hg38 MEF2C
    chromosome <- "chr5"
    mef2c.tss <- 88904257   # minus strand

    database.filename <- system.file(package="trena", "extdata", "mef2c.neigborhood.hg38.footprints.db")
    database.uri <- sprintf("sqlite://%s", database.filename)
    sources <- c(database.uri)

    loc.start <- mef2c.tss - 1000
    loc.end   <- mef2c.tss + 1000

    x <- getRegulatoryChromosomalRegions(trena, chromosome, mef2c.tss-1000, mef2c.tss+1000, sources, "MEF2C", mef2c.tss)

    checkTrue(is(x, "list"))
    # only one source, thus only one element in the result list
    checkEquals(length(x), 1)
    checkEquals(names(x), as.character(sources))
    checkTrue(all(unlist(lapply(x, function(element) is(element, "data.frame")), use.names=FALSE)))

    tbl.reg <- x[[sources[[1]]]]
    checkEquals(colnames(tbl.reg), getRegulatoryTableColumnNames(trena))

    checkEquals(unique(tbl.reg$chrom), chromosome)
    checkTrue(nrow(tbl.reg) > 20)

    checkTrue(all(tbl.reg$motifStart >= loc.start))
    checkTrue(all(tbl.reg$motifStart <= loc.end))
    checkTrue(all(tbl.reg$motifEnd   >= loc.start))
    checkTrue(all(tbl.reg$motifEnd   <= loc.end))
    checkTrue(all(tbl.reg$distance.from.tss >= -1000))
    checkTrue(all(tbl.reg$distance.from.tss <=  1000))

    checkEquals(openPostgresConnections(), 0)

} # test_getRegulatoryRegions_oneFootprintSource
#----------------------------------------------------------------------------------------------------
test_getRegulatoryRegions_encodeDHS <- function()
{
    printf("--- test_getRegulatoryRegions_encodeDHS")

    trena <- Trena("hg38")
    #chromosome <- "chr5"
    #mef2c.tss <- 88904257   # minus strand
    #loc.start <- mef2c.tss - 10000
    #loc.end   <- mef2c.tss + 10000
    #sources <- c("encodeHumanDHS")

    aqp4.tss <- 26865884
    chromosome <- "chr18"
    sources <- c("encodeHumanDHS")

    # first submit a tiny region with no regulatory regions
    tbl <- getRegulatoryChromosomalRegions(trena, chromosome, aqp4.tss-1, aqp4.tss+3, sources, "AQP4", aqp4.tss)
    checkEquals(nrow(tbl[["encodeHumanDHS"]]), 0)

    # now a larger region
    x <- getRegulatoryChromosomalRegions(trena, chromosome, aqp4.tss-100, aqp4.tss+100, sources, "AQP4", aqp4.tss)

    checkTrue(is(x, "list"))
    checkEquals(names(x), as.character(sources))
    checkTrue(all(unlist(lapply(x, function(element) is(element, "data.frame")), use.names=FALSE)))

    tbl.reg <- x[[sources[[1]]]]
    checkTrue(all(colnames(tbl.reg) == getRegulatoryTableColumnNames(trena)))
    checkTrue(nrow(tbl.reg) > 20)
    checkEquals(length(grep("AQP4.dhs", tbl.reg$id)), nrow(tbl.reg))

    checkEquals(openPostgresConnections(), 0)

} # test_getRegulatoryRegions_encodeDHS
#----------------------------------------------------------------------------------------------------
# for quick testing, we use only the small (mef2c-centered) sqlite database distributed
# with the package.  so this "two-source" test uses that one source twice, producing
# a list of length 2, each with the same name, each with the same contents
test_getRegulatoryRegions_twoFootprintSources <- function()
{
    printf("--- test_getRegulatoryRegions_twoFootprintSources")

    trena <- Trena("hg38")
    # the package's demo sqlite database is limited to in and around hg38 MEF2C
    chromosome <- "chr5"
    mef2c.tss <- 88904257   # minus strand

    database.filename <- system.file(package="trena", "extdata", "mef2c.neigborhood.hg38.footprints.db")
    database.uri <- sprintf("sqlite://%s", database.filename)
    sources <- c(database.uri,  database.uri)

    loc.start <- mef2c.tss - 1000
    loc.end   <- mef2c.tss + 1000

    x <- getRegulatoryChromosomalRegions(trena, chromosome, mef2c.tss-1000, mef2c.tss+1000, sources, "MEF2C", mef2c.tss)

    checkTrue(is(x, "list"))
    checkEquals(length(x), 2)
    checkEquals(names(x), sources)
    checkTrue(all(unlist(lapply(x, function(element) is(element, "data.frame")), use.names=FALSE)))

    tbl.reg <- x[[sources[[1]]]]
    checkEquals(colnames(tbl.reg), getRegulatoryTableColumnNames(trena))

    checkEquals(unique(tbl.reg$chrom), chromosome)
    checkTrue(nrow(tbl.reg) > 20)

    checkTrue(all(tbl.reg$motifStart >= loc.start))
    checkTrue(all(tbl.reg$motifStart <= loc.end))
    checkTrue(all(tbl.reg$motifEnd   >= loc.start))
    checkTrue(all(tbl.reg$motifEnd   <= loc.end))
    checkTrue(all(tbl.reg$distance.from.tss >= -1000))
    checkTrue(all(tbl.reg$distance.from.tss <=  1000))

    checkEquals(openPostgresConnections(), 0)

} # test_getRegulatoryRegions_twoFootprintSources
#----------------------------------------------------------------------------------------------------
# temporary hack.  the database-accessing classes should clean up after themselves
openPostgresConnections <- function()
{
    connections <- RPostgreSQL::dbListConnections(RPostgreSQL::PostgreSQL())
    length(connections)

} # openPostgresConnections
#----------------------------------------------------------------------------------------------------
test_createGeneModel <- function()
{
    printf("--- test_createGeneModel")

    targetGene <- "MEF2C"
    jaspar.human.pfms <- as.list(query(query(MotifDb, "jaspar2016"), "sapiens"))
    motifMatcher <- MotifMatcher(genomeName="hg38", pfms=jaspar.human.pfms)

    # pretend that all motifs are potentially active transcription sites - that is, ignore
    # what could be learned from open chromatin or dnasei footprints
    # use MEF2C, and 100 bases downstream, and 500 bases upstream of one of its transcripts TSS chr5:88825894

    tss <- 88825894
    tbl.region <- data.frame(chrom="chr5", start=tss-100, end=tss+500, stringsAsFactors=FALSE)
    tbl.motifs <- findMatchesByChromosomalRegion(motifMatcher, tbl.region, pwmMatchMinimumAsPercentage=92)
    tbl.motifs.tfs <- associateTranscriptionFactors(MotifDb, tbl.motifs, source="MotifDb", expand.rows=FALSE)
    fixer <- grep("motifStart", colnames(tbl.motifs.tfs))
    if(length(fixer) == 1)
       colnames(tbl.motifs.tfs)[fixer] <- "start"
    fixer <- grep("motifEnd", colnames(tbl.motifs.tfs))
    if(length(fixer) == 1)
       colnames(tbl.motifs.tfs)[fixer] <- "end"

    solver.names <- c("lasso", "lassopv", "pearson", "randomForest", "ridge", "spearman")
    trena <- Trena("hg38")

    tbl.geneModel <- createGeneModel(trena, targetGene, solver.names, tbl.motifs.tfs, mtx)

    checkTrue(is.data.frame(tbl.geneModel))

    expected.colnames <- c("gene", "betaLasso", "lassoPValue", "pearsonCoeff", "rfScore", "betaRidge",
                           "spearmanCoeff", "concordance", "pcaMax", "bindingSites")
    checkTrue(all(expected.colnames %in% colnames(tbl.geneModel)))
    checkTrue(nrow(tbl.geneModel) == 3)
    checkTrue("FOXC1" %in% tbl.geneModel$gene)

    checkEquals(openPostgresConnections(), 0)

} # test_createGeneModel
#----------------------------------------------------------------------------------------------------
test_getProximalPromoterHuman <- function()
{
    printf("--- test_getProximalPromoterHuman")

    trena <- Trena("hg38")

    # Designate the MEF2C gene and a shoulder size of 1000
    geneSymbol <- "MEF2C"
    tssUpstream <- 1000
    tssDownstream <- 1000

    # Pull the regions for MEF2C
    regions <- getProximalPromoter(trena, geneSymbol, tssUpstream, tssDownstream)

    # Check the type of data returned and its size
    checkEquals(dim(regions), c(1,4))
    checkEquals(class(regions), "data.frame")

    # Check the nominal values (tss = 88904257 OR 88883464)
    tss <- 88904257
    checkEquals(regions$chrom, "chr5")
    checkTrue(regions$start > 88882000)
    checkTrue(regions$end < 88906000)

    # check with bogus gene symbol
    checkTrue(is.na(getProximalPromoter(trena, "bogus", tssUpstream, tssDownstream)))

    # Test it on a list, with one real and one bogus, and make sure its the same as the first
    regions.2 <- getProximalPromoter(trena, c(geneSymbol, "bogus"), tssUpstream, tssDownstream)
    checkEquals(regions, regions.2)

} # test_getProximalPromoterHuman
#----------------------------------------------------------------------------------------------------
test_getProximalPromoterMouse <- function(){

    printf("--- test_getProximalPromoterMouse")

    trena <- Trena("mm10")

    # Designate the Twist2 gene and a shoulder size of 1000
    geneSymbol <- "Twist2"
    tssUpstream <- 1000
    tssDownstream <- 1000

    # Pull the regions for Twist2
    regions <- getProximalPromoter(trena, geneSymbol, tssUpstream, tssDownstream)

    # Check the type of data returned and its size
    checkEquals(dim(regions), c(1,4))
    checkEquals(class(regions), "data.frame")

    # Check the nominal values (tss = 88904257)
    tss <- 91801461
    checkEquals(regions$chrom, "chr1")
    checkEquals(regions$start, tss - tssUpstream)
    checkEquals(regions$end, tss + tssDownstream)

    # check with bogus gene symbol
    checkTrue(is.na(getProximalPromoter(trena, "bogus", tssUpstream, tssDownstream)))

    # Test it on a list, with one real and one bogus, and make sure its the same as the first
    regions.2 <- getProximalPromoter(trena, c(geneSymbol, "bogus"), tssUpstream, tssDownstream)
    checkEquals(regions, regions.2)

} # test_getProximalPromoterMouse
#----------------------------------------------------------------------------------------------------
test_assessSnp <- function()
{
    printf("--- test_assessSnp")

    trena <- Trena("hg38")
    jaspar.human.pfms <- as.list(query(query(MotifDb, "jaspar2016"), "sapiens"))

    # first check for bogus variant name
    bogus.variant <- "rsBogus"
    checkEquals(assessSnp(trena, jaspar.human.pfms, bogus.variant, shoulder=5, pwmMatchMinimumAsPercentage=65),
                data.frame())

    variant <- "rs3875089"   # chr18:26865469  T->C

    # a shoulder of 3 gives us a search region of chr18:26865466-26865472
    shoulder <- 3
    # a 65% match is relaxed enough to get these results, good fodder for testing. tbl.wt then tbl.mut

    #                           motifName chrom motifStart motifEnd strand motifScore motifRelativeScore
    #   Hsapiens-jaspar2016-ETS1-MA0098.1 chr18   26865467 26865472      +   3.825000          0.8843931
    #   Hsapiens-jaspar2016-SPI1-MA0080.1 chr18   26865467 26865472      -   3.684211          0.7865169
    #  Hsapiens-jaspar2016-GATA2-MA0036.1 chr18   26865467 26865471      -   3.509434          0.9489796
    #  Hsapiens-jaspar2016-GATA3-MA0037.1 chr18   26865466 26865471      -   3.047619          0.6808511
    #  Hsapiens-jaspar2016-GATA2-MA0036.1 chr18   26865466 26865470      +   2.547170          0.6887755
    #
    #                            motifName chrom motifStart motifEnd strand motifScore motifRelativeScore
    # Hsapiens-jaspar2016-ZNF354C-MA0130.1 chr18   26865467 26865472      +    3.50000          0.6913580
    #    Hsapiens-jaspar2016-ETS1-MA0098.1 chr18   26865467 26865472      +    2.87500          0.6647399
    #   Hsapiens-jaspar2016-GATA2-MA0036.1 chr18   26865467 26865471      -    2.54717          0.6887755
    #
    # ma0098+  wt=0.884  mut=0.664
    # ma0036-  wt=0.948 only
    # ma0036+  wt=mut=0.688
    # ma0037-  wt only
    # ma0130+  mut only
    # ma0080-  wt only

    tbl.assay <- assessSnp(trena, jaspar.human.pfms, variant, shoulder, pwmMatchMinimumAsPercentage=65)
    checkEquals(dim(tbl.assay), c(8, 12))

    expected.colnames <- c("motifName", "status", "assessed", "motifRelativeScore", "delta", "signature",
                           "chrom", "motifStart", "motifEnd", "strand", "match", "variant")

    checkEquals(sort(colnames(tbl.assay)), sort(expected.colnames))
    # pull out crucial columns for checking
    tbl.test <- tbl.assay[, c("signature", "status", "assessed", "motifRelativeScore", "delta")]

    # all 3 categories should be present
    checkEquals(as.list(table(tbl.test$assessed)), list(in.both=4, mut.only=1, wt.only=3))

    # deltas are zero if both wt and mut for a motif/strand were found
    # in this case, the delta can be read off the two motifRelativeScore valus
    checkTrue(all(tbl.test$delta[grep("both", tbl.test$assessed)]==0))
    checkTrue(all(tbl.test$delta[grep("only", tbl.test$assessed)]!=0))

    tbl.ma0098 <- tbl.test[grep("MA0098.1;26865467;+", tbl.test$signature, fixed=TRUE),]
    checkEquals(nrow(tbl.ma0098), 2)
    checkTrue(all(tbl.ma0098$delta == 0))
    checkTrue(all(c("wt", "mut") %in% tbl.ma0098$status))
    checkEqualsNumeric(tbl.test[grep("MA0098", tbl.test$signature),"motifRelativeScore"],
                       c(0.8843931, 0.6647399), tol=1e-5)

    # now test for an empty table - no wt or mut motifs for this region at this minimum match
    suppressWarnings(tbl.assay.short <- assessSnp(trena, jaspar.human.pfms, "rs3875089", 3, pwmMatchMinimumAsPercentage=95))
    checkEquals(nrow(tbl.assay.short), 0)

} # test_assessSnp
#----------------------------------------------------------------------------------------------------
# in preparation for adding, and ongoing testing of, a delta column for all entries, here we use a snp which at the 80%
# match level # returns all three kinds of match: in.both. wt.only, mut.only
test_assessSnp_allTypesWithDeltas <- function()
{
    printf("--- test_assessSnp_allTypesWithDeltas")

    trena <- Trena("hg38")
    jaspar.human.pfms <- as.list(query(query(MotifDb, "jaspar2016"), "sapiens"))
    snp <- "rs3763043"
    shoulder <- 10

    tbl.assay <- assessSnp(trena, jaspar.human.pfms, snp, shoulder=shoulder, pwmMatchMinimumAsPercentage=80)
    checkEquals(sort(unique(tbl.assay$assessed)), c("in.both", "mut.only", "wt.only"))

    checkEquals(ncol(tbl.assay), 12)
    checkTrue("delta" %in% colnames(tbl.assay))
    checkEqualsNumeric(min(tbl.assay$delta), -0.0487, tol=1e-3)
    checkEqualsNumeric(max(tbl.assay$delta),  0.22, tol=1e-2)

} # test_assessSnp_allTypesWithDeltas
#----------------------------------------------------------------------------------------------------
# using footprints (979 rows × 10 columns) from all 4 skin databases (hint/wellington, seed=16/20) and the
# large skinProtectedAndExposed matrix, and chr17:50,201,013-50,205,194, to build a model
# for col1a1, this error results when run from the trenaGelinas jupyter notebook:
#    error in if (Cmax < eps * 100) { : missing value where TRUE/FALSE needed
# reproduce, explore, fix this here.
# dimensions of footprint
reproduce_cmaxError <- function()
{
   if(!exists("mtx.pAndE"))
      load("~/github/dockerizedMicroservices/trenaGelinas/trena/data/mtx.protectedAndExposed.RData",
           envir=.GlobalEnv)

   trena <- Trena("hg38")
   source.1 <- "postgres://bddsrds.globusgenomics.org/skin_wellington_16"
   source.2 <- "postgres://bddsrds.globusgenomics.org/skin_wellington_20"
   source.3 <- "postgres://bddsrds.globusgenomics.org/skin_hint_16"
   source.4 <- "postgres://bddsrds.globusgenomics.org/skin_hint_20"
   sources <- c(source.1, source.2, source.3, source.4)
   names(sources) <- c("well_16", "well_20", "hint_16", "hint_20")

   targetGene <- "COL1A1"
   tss <- 50201632
   roi <- "chr17:50,201,013-50,205,194"
   cls <- parseChromLocString(roi)   # a trena function

   x <- getRegulatoryChromosomalRegions(trena, cls$chrom, cls$start, cls$end, sources, targetGene, tss)
   names(x) <- names(sources)

      # append a column to each non-empty table, giving it the source name
   x2 <- lapply(names(x), function(name) {tbl <-x[[name]]; if(nrow(tbl) >0) tbl$db <- name; return(tbl)})
   tbl.reg <- do.call(rbind, x2)
   rownames(tbl.reg) <- NULL

      # be strict for now: just the 2016 jaspar human motifs
   tbl.reg <- unique(tbl.reg[grep("Hsapiens-jaspar2016", tbl.reg$motifName, ignore.case=TRUE),])
   tbl.reg <- tbl.reg[order(tbl.reg$motifStart),]
   tbl.reg$fpName <- paste(tbl.reg$motifName, tbl.reg$db, sep="_")

   solver.names <- c("lasso", "lassopv", "pearson", "randomForest", "ridge", "spearman")
   #solver.names <- c("lasso", "pearson", "randomForest", "ridge", "spearman")
   colnames(tbl.reg)[c(2,3)] <- c("start", "end")

   tbl.reg.tfs <- associateTranscriptionFactors(MotifDb, tbl.reg, source="MotifDb", expand.rows=FALSE)
   options(error=recover)
   tbl.geneModel <- createGeneModel(trena, targetGene, solver.names, tbl.reg.tfs, mtx)
   tbl.geneModel <- tbl.geneModel[order(tbl.geneModel$rfScore, decreasing=TRUE),]

} # reproduce_cmaxError
#----------------------------------------------------------------------------------------------------
if(!interactive()) runTests()
