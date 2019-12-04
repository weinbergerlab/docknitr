#' @importFrom knitr engine_output knit_engines

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
#' you can use ```{r engine="ubuntu"} to process Rmarkdown chunks through Ubuntu bash using Docker
#'
#' @param name The name of a new Docker Rmarkdown engine
#' @param ... options for the new Docker Rmarkdown engine
#' @examples
#' docker_alias("ubuntu", image="ubuntu:latest", command="bash")
#' @export
docker_alias = function(name, ...) {
  alias_engine = list()
  alias_engine[[name]] = function(options) {
    docker_engine(c(list(...), options))
  }
  knitr::knit_engines$set(alias_engine)
}

.onLoad = function(libname, pkgname) {
  knitr::knit_engines$set(docker=docker_engine)
}

