
# function to merge and remap a list of netcdf files

#' @title merge and remap a list of ncdf files
#' @description This function allows you to remap a netcdf horizontally and vertically to a specific latlon box
#' @param ff_list This is a character vector of files to merge
#' @param merge This is the merge type. Use "merge" to combine files, "mergetime" to merge based on time.
#' @param expr This is a cdo expression to apply to the merged files.
#' @param remap_point This is the remap_point. Set to "pre" if you want to remap the files before merging, or "post" if you want to remap post-merging. The default is pre as this insures against horizontal grids being slightly different.
#' @param out_file The name of the file output. If this is not stated, a data frame will be the output.
#' @param zip_file Do you want any output file to be zipped to save space. Default is FALSE.
#' @param cdo_output Set to TRUE if you want to see the cdo output
#' @param overwrite Do you want to overwrite out_file if it exists? Defaults to FALSE
#' @param ... Arguments to be sent to nc_remap.
#' @return data frame or netcdf file.
#' @export
#'
#'
#'
#' @examples
#'
# Regridding NOAA temperature data to a depth of 5 and 30 metres in the waters around the UK
#' ff1 <- system.file("extdata", "icec.mon.ltm.1981-2010.nc", package = "rcdo")
#' ff2 <- system.file("extdata", "sst.mon.ltm.1981-2010.nc", package = "rcdo")

#' ff_list <- c(ff1, ff2)
#' uk_coords <- expand.grid(Longitude = seq(-20, 10, 1), Latitude = seq(48, 62, 1))

#' nc_merge_remap(ff_list, coords = uk_coords, cdo_output = TRUE)

nc_merge_remap <- function(ff_list, merge = "merge", expr = NULL, remap_point = "pre", out_file = NULL, zip_file = FALSE, cdo_output = FALSE, overwrite = FALSE, ...) {
  if (remap_point %nin% c("pre", "post")) {
    stop(stringr::str_glue("error: remap_point = {remap_point} is not valid"))
  }

  # loop through the files
  for (ff in ff_list)
    if (!file_valid(ff)) {
      stop(stringr::str_glue("error: {ff} does not exist or is not netcdf"))
    }

  # take note of the working directory, so that it can be reset to this on exit

  init_dir <- getwd()
  on.exit(setwd(init_dir))

  # Create a temporary directory and move the file we are manipulating to it...
  temp_dir <- random_temp()

  # copy the file to the temporary

  new_ens <- c()

  tracker <- 1
  for (ff in ff_list) {
    ens_file <- stringr::str_glue("raw{tracker}.nc")
    new_ens <- c(new_ens, ens_file)
    tracker <- tracker + 1
    file.copy(ff, stringr::str_c(temp_dir, "/", ens_file), overwrite = TRUE)
  }

  setwd(temp_dir)

  if (getwd() == init_dir) {
    stop("error: there was a problem changing the directory")
  }

  if (getwd() != temp_dir) {
    stop("error: there was a problem changing the directory")
  }

  temp_dir <- stringr::str_c(temp_dir, "/")


  # Now, we possibly need to remap the data pre-merging. Do this.

  if (length(list(...)) >= 1 & remap_point == "pre") {
    for (ff in new_ens) {
      nc_remap(ff, out_file = "dummy.nc", ...)
      file.rename("dummy.nc", ff)
    }
  }

  # OK. We now need to merge the files...

  ens_string <- stringr::str_flatten(new_ens, collapse = " ")

  system(stringr::str_glue("cdo {merge} {ens_string} merged.nc"), ignore.stderr = (cdo_output == FALSE))

  # throw an error message if merging fails

  if (!file.exists("merged.nc")) {
    stop("error: problem merging files. Please set cdo_output = TRUE and rerun")
  }

  # now, apply the expression if it has been supplied.....
  # First we need to make sure the expression has no spaces

  if (!is.null(expr)) {
    expr <- stringr::str_replace_all(expr, " ", "")
    print(expr)
    system(stringr::str_glue("cdo aexpr,'{expr}' merged.nc dummy.nc"), ignore.stderr = (cdo_output == FALSE))

    # throw an error message if apply expr fails

    if (!file.exists("dummy.nc")) {
      stop("error: problem applying expr to merged files. Please check expr and then consider setting cdo_output = TRUE and rerun")
    }

    file.rename("dummy.nc", "merged.nc")
  }

  # Now, remap the merged files if needed
  if (length(list(...)) >= 1 & remap_point == "post") {
    nc_remap("merged.nc", out_file = "dummy.nc", ...)
    file.rename("dummy.nc", "merged.nc")
  }

  # read in the merged file to a data frame if there is no out_file
  if (is.null(out_file)) {
    result <- nc_read("merged.nc")

    # remove the temporary files created
    setwd(temp_dir)
    if (length(dir(temp_dir)) < 6 & temp_dir != init_dir) {
      unlink(temp_dir, recursive = TRUE)
    }

    return(result)
  }

  # if out_file is given, save the merged nc file to this
  # zip the file if requested
  if (zip_file) {
    nc_zip("merged.nc", overwrite = TRUE)
  }
  setwd(init_dir)
  file.copy(stringr::str_c(temp_dir, "/merged.nc"), out_file, overwrite = overwrite)

  # remove the temporary files created
  setwd(temp_dir)
  if (length(dir(temp_dir)) < 6 & temp_dir != init_dir) {
    unlink(temp_dir, recursive = TRUE)
  }
}
