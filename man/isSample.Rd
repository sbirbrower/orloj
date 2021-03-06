% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fcs.R
\name{isSample}
\alias{isSample}
\title{Test if a given object is an Astrolabe sample.}
\usage{
isSample(sample)
}
\arguments{
\item{sample}{Object to be tested.}
}
\value{
TRUE if the object is an Astrolabe sample, FALSE otherwise.
}
\description{
Check whether the given object is a list, and whether it includes all of the
fields that we would expect from the default importFcsFile.
}
