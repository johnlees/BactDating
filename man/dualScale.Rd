% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dualScale.R
\name{dualScale}
\alias{dualScale}
\title{Rescaling function using dual scale}
\usage{
dualScale(tree, minDate = 1990, squash = 5)
}
\arguments{
\item{tree}{Timed tree}

\item{minDate}{Date before which dates are to be compressed}

\item{squash}{Interval of time to give to all dates prior to minDate}
}
\value{
Rescaled timed tree
}
\description{
Rescaling function using dual scale
}
