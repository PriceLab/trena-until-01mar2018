% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/EnsembleSolver.R
\name{EnsembleSolver}
\alias{EnsembleSolver}
\title{Create a Solver class object using an ensemble of solvers}
\usage{
EnsembleSolver(mtx.assay = matrix(), targetGene, candidateRegulators,
  solverNames = c("lasso", "lassopv", "pearson", "randomForest", "ridge",
  "spearman"), geneCutoff = 0.1, alpha.lasso = 0.9, alpha.ridge = 0,
  lambda.lasso = numeric(0), lambda.ridge = numeric(0),
  lambda.sqrt = numeric(0), nCores.sqrt = 4, nOrderings.bayes = 10,
  quiet = TRUE)
}
\arguments{
\item{mtx.assay}{An assay matrix of gene expression data}

\item{targetGene}{A designated target gene that should be part of the mtx.assay data}

\item{candidateRegulators}{The designated set of transcription factors that could be associated
with the target gene}

\item{solverNames}{A character vector of strings denoting}

\item{geneCutoff}{A fraction (0-1) of the supplied candidate regulators to be included in the
fetaures output by the solver (default = 0.1)}

\item{alpha.lasso}{A fraction (0-1) denoting the LASSO-Ridge balance of the `glmnet` solver used
by the LASSO method (default = 0.9)}

\item{alpha.ridge}{A fraction (0-1) denoting the LASSO-Ridge balance of the `glmnet` solver used
by the Ridge method (default = 0)}

\item{lambda.lasso}{The penalty parameter for LASSO, used to determine how strictly to penalize
the regression coefficients. If none is supplied, this will be determined via permutation
testing (default = NULL).}

\item{lambda.ridge}{The penalty parameter for Ridge, used to determine how strictly to penalize
the regression coefficients. If none is supplied, this will be determined via permutation
testing (default = NULL).}

\item{lambda.sqrt}{The penalty parameter for square root LASSO, used to determine how strictly
to penalize the regression coefficients. If none is supplied, this will be determined via
permutation testing (default = NULL).}

\item{nCores.sqrt}{An integer denoting the number of computational cores to devote to the
square root LASSO solver, which is the slowest of the solvers (default = 4)}

\item{nOrderings.bayes}{An integer denoting the number of random starts to use for the Bayes
Spike method (default = 10)}

\item{quiet}{A logical denoting whether or not the solver should print output}
}
\value{
A Solver class object with Ensemble as the solver
}
\description{
Create a Solver class object using an ensemble of solvers
}
\examples{
load(system.file(package="trena", "extdata/ampAD.154genes.mef2cTFs.278samples.RData"))
target.gene <- "MEF2C"
tfs <- setdiff(rownames(mtx.sub), target.gene)
ensemble.solver <- EnsembleSolver(mtx.sub, target.gene, tfs)
}
\seealso{
\code{\link{solve.Ensemble}}, \code{\link{getAssayData}}

Other Solver class objects: \code{\link{BayesSpikeSolver}},
  \code{\link{HumanDHSFilter-class}},
  \code{\link{LassoPVSolver}}, \code{\link{LassoSolver}},
  \code{\link{PearsonSolver}},
  \code{\link{RandomForestSolver}},
  \code{\link{RidgeSolver}}, \code{\link{Solver-class}},
  \code{\link{SpearmanSolver}},
  \code{\link{SqrtLassoSolver}}
}
