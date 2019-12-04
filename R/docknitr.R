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
  outputFile = tempfile()
  output = ""
  if (options$eval) {
    message(sprintf('running: %s %s', command, paste0(params, collapse=" ")))
    result = system2.sep(command, shQuote(params), stdout = outputFile, stderr = outputFile, input = input, env = options$engine.env, sep=options$input.sep)
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

# This is the built-in system2, with sep argument added
system2.sep = function (command, args = character(), stdout = "", stderr = "",
          stdin = "", input = NULL, env = character(), wait = TRUE,
          minimized = FALSE, invisible = TRUE, timeout = 0, sep = NA)
{
  if (!missing(minimized) || !missing(invisible))
    message("arguments 'minimized' and 'invisible' are for Windows only")
  if (!is.logical(wait) || is.na(wait))
    stop("'wait' must be TRUE or FALSE")
  intern <- FALSE
  command <- paste(c(env, shQuote(command), args), collapse = " ")
  if (is.null(stdout))
    stdout <- FALSE
  if (is.null(stderr))
    stderr <- FALSE
  else if (isTRUE(stderr)) {
    if (!isTRUE(stdout))
      warning("setting stdout = TRUE")
    stdout <- TRUE
  }
  if (identical(stdout, FALSE))
    command <- paste(command, ">/dev/null")
  else if (isTRUE(stdout))
    intern <- TRUE
  else if (is.character(stdout)) {
    if (length(stdout) != 1L)
      stop("'stdout' must be of length 1")
    if (nzchar(stdout)) {
      command <- if (identical(stdout, stderr))
        paste(command, ">", shQuote(stdout), "2>&1")
      else paste(command, ">", shQuote(stdout))
    }
  }
  if (identical(stderr, FALSE))
    command <- paste(command, "2>/dev/null")
  else if (isTRUE(stderr)) {
    command <- paste(command, "2>&1")
  }
  else if (is.character(stderr)) {
    if (length(stderr) != 1L)
      stop("'stderr' must be of length 1")
    if (nzchar(stderr) && !identical(stdout, stderr))
      command <- paste(command, "2>", shQuote(stderr))
  }
  if (!is.null(input)) {
    if (!is.character(input))
      stop("'input' must be a character vector or 'NULL'")
    f <- tempfile()
    on.exit(unlink(f))
    if (!is.na(sep)) {
      con <- file(f, "w+b")
      writeLines(input, con, sep=sep)
      close(con)
    } else {
      writeLines(input, f)
    }
    command <- paste(command, "<", shQuote(f))
  }
  else if (nzchar(stdin))
    command <- paste(command, "<", stdin)
  if (!wait && !intern)
    command <- paste(command, "&")
  system(command, intern=intern, timeout=timeout)
}
