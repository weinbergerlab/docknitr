#' @importFrom knitr engine_output knit_engines
#' @importFrom rstudioapi versionInfo

docker_engine = function(options) {
  command = ifelse(is.null(options$engine.path), "docker", options$engine.path)
  params = c("run", "--interactive")
  if (!is.null(options$share.files) && options$share.files) {
    params = c(params, "--volume", sprintf("%s:/workdir", getwd()), "--workdir", "/workdir")
  }
  params = c(params, options$image)
  if (!is.null(options$command)) {
    params = c(params, options$command)
  }
  input = options$code

  # Newline conversion -- NA = leave alone, NULL = default = "\n" (UNIX newlines)
  if (is.null(options$input.sep)) {
    options$input.sep = "\n"
  }

  # Run docker if options$eval
  inputFile = tempfile()
  on.exit(unlink(inputFile))
  if (!is.na(options$input.sep)) {
    con <- file(inputFile, "w+b")
    writeLines(input, con, sep=options$input.sep)
    close(con)
  } else {
    writeLines(input, inputFile)
  }

  outputFile = tempfile()
  on.exit(unlink(outputFile))
  output = ""
  if (options$eval) {
    message(sprintf('running: %s %s', command, paste0(params, collapse=" ")))
    result = sys::exec_wait(command, params, std_out = outputFile, std_err = outputFile, std_in = inputFile)
    output = readLines(outputFile)
    if (result != 0) {
      message = sprintf('Error in running command %s %s: %s', command, paste0(params, collapse=" "), paste0(output, collapse="\n"))
      # chunk option error=FALSE means we need to signal the error
      if (!options$error) {
        stop(message)
      } else {
        warning(message)
      }
    }
  }

  knitr::engine_output(options, options$code, output)
}

#' Create an alias for a Docker Rmarkdown engine
#'
#' After writing
#'
#' docker_alias("ubuntu", image="ubuntu:latest", command="bash")
#'
#' you can use ```{ubuntu} to process Rmarkdown chunks through Ubuntu bash using Docker
#'
#' The alias name must consist entirely of letters, digits, and underscores, or else `knitr` will not recognize it as a valid code chunk in RMarkdown. 
#'
#' @param name The name of a new Docker Rmarkdown engine
#' @param ... options for the new Docker Rmarkdown engine
#' @examples
#' docker_alias("ubuntu", image="ubuntu:latest", command="bash")
#' @export
docker_alias = function(name, ...) {
  if (!any(grep ("^[A-Za-z0-9_]+$", name))) {
  	warning(sprintf("For best compatibility, your docker alias name should consist entirely of letters, numbers, and underscores; the alias '%s' will not work in R markdown unless you change knitr settings.", name))
  }

  alias_engine = list()
  alias_engine[[name]] = function(options) {
    docker_engine(c(list(...), options))
  }
  knitr::knit_engines$set(alias_engine)
}

.onLoad = function(libname, pkgname) {
  rsRequired = "1.2"
  rsOutdated = tryCatch(rstudioapi::versionInfo()$version < rsRequired, error=function(e) FALSE)
  if (rsOutdated) {
  	stop(sprintf("Your RStudio is outdated. Please update to RStudio version %s or later before continuing.", rsRequired))
  }
  knitr::knit_engines$set(docker=docker_engine)
}

