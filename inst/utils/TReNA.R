#' @name TReNA-class
#' @rdname TReNA-class
#' @aliases TReNA
#'
#' @import methods

.TReNA <- setClass ("TReNA",
                    representation = representation(solver="Solver",
                                                    quiet="logical")
                    )

#----------------------------------------------------------------------------------------------------
printf <- function(...) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
#' @export
setGeneric("solve",                    signature="obj", function(obj, target.gene, tfs,
                                                                 tf.weights=rep(1, length(tfs)), extraArgs=list())
    standardGeneric ("solve"))

#' Get the Solver Name from a TReNA Object
#'
#' @rdname getSolverName
#' @aliases getSolverName
#' 
#' @param obj An object of class TReNA
#'
#' @return The name of the solver subclass object contained by the given TReNA object
#'
#' @examples
#' # Create a LassoSolver object using the included Alzheimer's data and retrieve the solver name
#' load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
#' solver <- TReNA(mtx.sub, solver = "lasso")
#' mtx <- getSolverName(solver)
#' 
#' @export
setGeneric("getSolverName",   signature="obj", function(obj) standardGeneric ("getSolverName"))

#' Get the Solver Object from a TReNA Object
#'
#' @rdname getSolverObject
#' @aliases getSolverObject
#'
#' @param obj An object of class TReNA
#'
#' @export
#'
#' @return The Solver object contained by the given TReNA object
#'
#' @examples
#'
#' # Create a LassoSolver object using the included Alzheimer's data and retrieve the solver object
#' load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
#' solver <- TReNA(mtx.sub, solver = "lasso")
#' mtx <- getSolverObject(solver)
#' 
#' @export
setGeneric("getSolverObject", signature="obj", function(obj) standardGeneric ("getSolverObject"))
#----------------------------------------------------------------------------------------------------
#' @title Class TReNA
#'
#' @description
#' Class \code{TReNA} defines a TReNA object and contains an assay matrix, which contains expression data over a set of
#' samples for a group of genes, and a string representing the name of a chosen solver.
#'
#' @name TReNA-class
#' @rdname TReNA-class
#' @export
#'
#' @param mtx.assay An assay matrix of gene expression data
#' @param solver A string matching the designated solver for relating a target gene to transcription factors.
#' TReNA currently supports 9 solver strings (default = "lasso"):
#' \itemize{
#' \item{\link[=solve.Lasso]{"lasso"}}
#' \item{\link[=solve.Ridge]{"ridge"}}
#' \item{\link[=solve.RandomForest]{"randomForest"}}
#' \item{\link[=solve.BayesSpike]{"bayesSpike"}}
#' \item{\link[=solve.SqrtLasso]{"sqrtlasso"}}
#' \item{\link[=solve.LassoPV]{"lassopv"}}
#' \item{\link[=solve.Pearson]{"pearson"}}
#' \item{\link[=solve.Spearman]{"spearman"}}
#' \item{\link[=solve.Ensemble]{"ensemble"}}
#' }
#' @param quiet A logical denoting whether or not the TReNA object should print output
#'
#' @return An object of the TReNA class
#'
#' @seealso \code{\link{solve}}, \code{\link{Solver}}, \code{\link{getSolverName}}, \code{\link{getSolverObject}}

TReNA <- function(mtx.assay=matrix(), solverName="lasso", quiet=TRUE)
{
    browser()
    recognized.solvers <- c("lasso", "randomForest", "bayesSpike", "pearson",
                            "spearman","sqrtlasso","lassopv","ridge", "naive", "ensemble")

       # the solverName may be simple (e.g., "lasso")
       # or complex (e.g., "ensemble:lasso;ridge;randomForest")
       # extract the root, use it to figure out which solver to construct

    requested.solver.root <- strsplit(solverName, ":")[[1]][1]
    recognized.solver.found <-
       any(unlist(lapply(recognized.solvers, function(solverName) grepl(solverName, requested.solver.root))))

    stopifnot(recognized.solver.found)

    solver <- switch(requested.solver.root,
                     "lasso" = LassoSolver(mtx.assay, solverName),
                     "randomForest" = RandomForestSolver(mtx.assay, solverName),
                     "bayesSpike" = BayesSpikeSolver(mtx.assay, solverName),
                     "pearson" = PearsonSolver(mtx.assay, solverName),
                     "spearman" = SpearmanSolver(mtx.assay, solverName),
                     "sqrtlasso" = SqrtLassoSolver(mtx.assay, solverName),
                     "lassopv" = LassoPVSolver(mtx.assay, solverName),
                     "ridge" = RidgeSolver(mtx.assay, solverName),
                     "naive" = NaiveSolver(mtx.assay, solverName),
                     "ensemble" = EnsembleSolver(mtx.assay, solverName))

    .TReNA(solver=solver, quiet=quiet)

} # TReNA, the constructor
#----------------------------------------------------------------------------------------------------
#' Solve a TReNA Object
#'
#' A TReNA object contains an assay matrix with expression data for genes of interest and a string
#' representing the chosen solver. The \code{solve} method runs the specified solver given a target
#' gene and a designated set of transcription factors, returning a list of parameters that quantify
#' the relationship between the transcription factors and the target gene.
#'
#' @rdname solve
#' @aliases solve solve.TReNA
#'
#' @exportMethod solve
#'
#' @param obj An object of class TReNA
#' @param target.gene A designated target gene that should be part of the mtx.assay data
#' @param tfs The designated set of transcription factors that could be associated with the target gene.
#' @param tf.weights A set of weights on the transcription factors (default = rep(1, length(tfs)))
#' @param extraArgs Modifiers to the solver
#'
#' @return A data frame containing coefficients relating the target gene to each transcription factor
#'
#' @seealso \code{\link{TReNA}}
#'
#' @family solver methods
#'
#' @examples
#' # Load included Alzheimer's data, create a TReNA object with LASSO as the solver, and solve
#' load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
#' trena <- TReNA(mtx.assay = mtx.sub, solver = "lasso")
#' target.gene <- "MEF2C"
#' tfs <- setdiff(rownames(mtx.sub), target.gene)
#' tbl <- solve(trena, target.gene, tfs)

setMethod("solve", "TReNA",

   function (obj, target.gene, tfs, tf.weights=rep(1, length(tfs)), extraArgs=list()){
      # printf("entering TReNA::solve")
      run(getSolverObject(obj), target.gene, tfs, tf.weights, extraArgs)
      })
#----------------------------------------------------------------------------------------------------
#' @describeIn TReNA Retrieve the name of the solver specified in a TReNA object
#'
#' @param obj An object of class TReNA
#' 
#' @examples
#'
#' # Create a LassoSolver object using the included Alzheimer's data and retrieve the solver name
#' load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
#' solver <- TReNA(mtx.sub, solver = "lasso")
#' mtx <- getSolverName(solver)

setMethod("getSolverName", "TReNA",

          function(obj){
              # Return the solver name stored in the object
              return(class(obj@solver)[1])
          })

#----------------------------------------------------------------------------------------------------
#' @describeIn TReNA Retrieve the Solver object contained in a TReNA object
#'
#' @examples
#'
#' # Create a LassoSolver object using the included Alzheimer's data and retrieve the solver object
#' load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
#' solver <- TReNA(mtx.sub, solver = "lasso")
#' mtx <- getSolverObject(solver)

setMethod("getSolverObject", "TReNA",

          function(obj){
              # Return the solver name stored in the object
              return(obj@solver)                
          })
#----------------------------------------------------------------------------------------------------
