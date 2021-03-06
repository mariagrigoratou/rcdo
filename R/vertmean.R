
# to be added: generalize this to cover vertical min, max etc.

# the function should perhaps be modified so that it takes ..., and then sends ... to remap


#' @title Calculate vertical mean from a netcdf file.
#' @description This function allows you to remap a netcdf horizontally and vertically to a specific latlon box. It outputs a data frame with the mean value and the maximum depth used for the calculation.
#' @param ff This is the file to analyze.
#' @param vars Select the variables you want to regrid. If this is not given, all variables will be regridded.
#' @param vert_scale This is the vertical scale you want. c(min_depth, max_depth, vertical_resolution).
#' @param coords A 2 column matrix or data frame of the form (longitude, latitude) with coordinates for regridding. This can be regular or irregular. The function will calculate which it is.
#' @param out_file The name of the file output. If this is not stated, a data frame will be the output.
#' @param zip_file Do you want any output file to be zipped to save space. Default is FALSE.
#' @param expr This is a cdo expression to apply to the data before a vertical mean is calculated.
#' @param cdo_output set to TRUE if you want to see the cdo output
#' @param na_value This is a value in the raw netcdf file that needs to be treated as an na.
#' @param overwrite Do you want to overwrite out_file if it exists? Defaults to FALSE
#' @param ... Additional terms to be sent to nc_remap2
#' @return data frame or netcdf file.
#' @export

# need an option for cacheing results...

#' @examples
#'
#' # Calculating vertical mean NOAA world ocean atlas data to the region around the UK
#' ff <- system.file("extdata", "woa18_decav_t01_01.nc", package = "rcdo")
#' # calculate vertical mean of temperature between 5 and 30 m, using a resolution of 5 for vertical interpolation
#' nc_vertmean(ff, vars = "t_an", vert_scale = c(5, 30, 5))
nc_vertmean <- function(ff, vars = NULL, vert_scale = NULL, coords = NULL, expr = NULL, na_value = NULL, out_file = NULL, zip_file = FALSE, cdo_output = FALSE, overwrite = FALSE, ...) {
  nc_vertstat(metric = "mean", ff = ff, vars = vars, vert_scale = vert_scale, coords = coords, expr = expr, na_value = na_value, out_file = out_file, zip_file = zip_file, cdo_output = cdo_output, overwrite = overwrite, ...)
}
