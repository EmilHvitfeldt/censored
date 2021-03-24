library(testthat)
library(survival)
library(glmnet)
library(rlang)

# ------------------------------------------------------------------------------

context("Cox Regression - glmnet")

# ------------------------------------------------------------------------------

lung2 <- lung[-14, ]

cox_spec <- proportional_hazards() %>% set_engine("glmnet")

exp_f_fit <- glmnet(x = as.matrix(lung2[, c(4, 6)]),
                    y = Surv(lung2$time, lung2$status),
                    family = "cox")

# ------------------------------------------------------------------------------

test_that("model object", {

  # formula method
  expect_error(f_fit <- fit(cox_spec, Surv(time, status) ~ age + ph.ecog, data = lung2), NA)

  # Removing call element
  expect_equal(f_fit$fit$fit[-11], exp_f_fit[-11])
})

# ------------------------------------------------------------------------------

test_that("linear_pred predictions", {
  # formula method
  expect_error(f_fit <- fit(cox_spec, Surv(time, status) ~ age + ph.ecog, data = lung2), NA)
  f_pred <- predict(f_fit, lung2, type = "linear_pred", penalty = 0.01)
  exp_f_pred <- unname(predict(exp_f_fit, newx = as.matrix(lung2[, c(4, 6)]), s = 0.01))

  expect_s3_class(f_pred, "tbl_df")
  expect_true(all(names(f_pred) == ".pred_linear_pred"))
  expect_equivalent(f_pred$.pred_linear_pred, unname(exp_f_pred))
  expect_equal(nrow(f_pred), nrow(lung2))
})

# ------------------------------------------------------------------------------

test_that("api errors", {
  expect_error(
    proportional_hazards() %>% set_engine("lda"),
    regexp = "Engine 'lda' is not available"
  )
})

# ------------------------------------------------------------------------------

test_that("primary arguments", {

  # penalty ------------------------------------------------------
  penalty <- proportional_hazards(penalty = 0.05) %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")

  expect_equal(translate(penalty)$method$fit$args,
               list(
                 x = expr(missing_arg()),
                 y = expr(missing_arg()),
                 weights = expr(missing_arg())
               )
  )

  # mixture -----------------------------------------------------------
  mixture <- proportional_hazards(mixture = 0.34) %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")

  expect_equal(translate(mixture)$method$fit$args,
               list(
                 x = expr(missing_arg()),
                 y = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 alpha = new_empty_quosure(0.34)
               )
  )

  mixture_v <- proportional_hazards(mixture = varying()) %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")

  expect_equal(translate(mixture_v)$method$fit$args,
               list(
                 x = expr(missing_arg()),
                 y = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 alpha = new_empty_quosure(varying())
               )
  )
})

# ------------------------------------------------------------------------------

test_that("updating", {
  expr1 <- proportional_hazards() %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")
  expr1_exp <- proportional_hazards(mixture = 0.76) %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")

  expr2 <- proportional_hazards() %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")
  expr2_exp <- proportional_hazards(penalty = 0.123) %>%
    set_mode("censored regression") %>%
    set_engine("glmnet")


  expect_equal(update(expr1, mixture = 0.76), expr1_exp)
  expect_equal(update(expr2, penalty = 0.123), expr2_exp)
})