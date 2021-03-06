#' Evaluates a condition
#'
#' Evaluates the \code{\link{condition}} object to return a \code{\link{graded}} value.
#'
#' @param condition a \code{\link{condition}} object
#' @param grader_args at minimum, a list that just contains the value for \code{solution_quo}
#' @param learnr_args at minimum, a list that just contains the value for \code{envir_prep}
#'
#' @return a \code{\link{graded}} value if \code{condi$x} is \code{TRUE} or
#'   \code{NULL} if \code{condi$x} is \code{FALSE}
#' @export
#'
#' @examples
#'  condi_formula_t <- condition(~ identical(.result, 5),
#'                               message = "my correct message",
#'                               correct = TRUE)
#'  grader_args <- list()
#'  learnr_args <- list(last_value = quote(5), envir_prep = new.env())
#'  evaluate_condition(condi_formula_t, grader_args, learnr_args)
evaluate_condition <- function(condition, grader_args, learnr_args) {
  checkmate::assert_class(condition, "grader_condition")

  res <- switch(condition$type,
           "formula" = evaluate_condi_formula(condition$x, learnr_args$last_value, learnr_args$envir_prep), # nolint
           "function" = evaluate_condi_function(condition$x, learnr_args$last_value),
           "value" = evaluate_condi_value(condition$x, learnr_args$last_value)
         )

  # if we compare something like a vector or dataframes to one another
  # we need to collapse the result down to a single boolean value
  if (length(res) > 1) {
    ## this isn't the best way to handle NA values so we raise a warning.
    ## https://github.com/rstudio-education/grader/issues/46 # nolint
    warning(glue::glue("I got a length of {length(res)}, instead of 1 during the conditional check.\n Did you use == ? If so, consider using idential()")) # nolint
    res <- !all(is.na(res)) && all(res, na.rm = TRUE)
  }

  # implement when we add a `exec`/`expect` api to check_result
  # will account for function returns
  # if (inherits(res, 'grader_graded')) {return(res)} # nolint
  if (is.null(res)) return(NULL)

  checkmate::assert_logical(res, len = 1, null.ok = FALSE)
  if (res) {
    return(graded(correct = condition$correct, message = condition$message))
  } else {
    return(NULL)
  }
}

evaluate_condi_formula <- function(formula, user_answer, env) {
  form_result <- rlang::eval_tidy(
    formula[[2]],
    data = list(.result = user_answer, . = user_answer),
    env = env
  )
  return(form_result)
}

evaluate_condi_function <- function(fxn, user_answer) {
  fxn_result <- fxn(user_answer)
  return(fxn_result)
}

evaluate_condi_value <- function(val, user_answer) {
  val_result <- identical(val, user_answer)
  return(val_result)
}
