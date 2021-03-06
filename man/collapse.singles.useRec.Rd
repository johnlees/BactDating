% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods.R
\name{collapse.singles.useRec}
\alias{collapse.singles.useRec}
\title{Modified collapse.singles() from package ape which deletes the single nodes (i.e., with a single
descendant) in a tree, respecting the rec function. Internal, used by drop.tip.rec}
\usage{
collapse.singles.useRec(tree, root.edge = FALSE)
}
\arguments{
\item{tree}{an object of class \code{"phylo"}.}
}
\value{
tree with rec data
}
\description{
Modified collapse.singles() from package ape which deletes the single nodes (i.e., with a single
descendant) in a tree, respecting the rec function. Internal, used by drop.tip.rec
}
