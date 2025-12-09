#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
})

compute_roc <- function(y_true, y_score, n_thresholds = 100L) {
  # thresholds from 0 to 1
  ts <- seq(0, 1, length.out = n_thresholds)

  tpr <- numeric(length(ts))
  fpr <- numeric(length(ts))

  for (i in seq_along(ts)) {
    thr <- ts[i]
    y_pred <- ifelse(y_score >= thr, 1L, 0L)

    tp <- sum(y_true == 1L & y_pred == 1L)
    fp <- sum(y_true == 0L & y_pred == 1L)
    fn <- sum(y_true == 1L & y_pred == 0L)
    tn <- sum(y_true == 0L & y_pred == 0L)

    tpr[i] <- if ((tp + fn) > 0) tp / (tp + fn) else 0
    fpr[i] <- if ((fp + tn) > 0) fp / (fp + tn) else 0
  }

  data.frame(fpr = fpr, tpr = tpr)
}

compute_auc <- function(roc_df) {
  # trapezoidal rule, sort by fpr
  roc_df <- roc_df[order(roc_df$fpr), ]
  x <- roc_df$fpr
  y <- roc_df$tpr
  sum((x[-1] - x[-length(x)]) * (y[-1] + y[-length(y)]) / 2)
}

roc_plot <- function(df, output_path = "roc_curve.png") {
  if (!all(c("y_true", "y_score") %in% colnames(df))) {
    if (!("y_pred" %in% colnames(df))) {
      stop("Expected columns y_true and y_score (or y_pred) in input CSV.", call. = FALSE)
    }
    message("Column y_score not found, using y_pred as score (may degrade ROC).")
    df$y_score <- df$y_pred
  }

  y_true <- as.integer(df$y_true)
  y_score <- as.numeric(df$y_score)

  roc_df <- compute_roc(y_true, y_score)
  auc <- compute_auc(roc_df)

  p <- ggplot(roc_df, aes(x = fpr, y = tpr)) +
    geom_line(color = "#67a9cf", size = 1) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey60") +
    coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    labs(
      x = "False Positive Rate",
      y = "True Positive Rate",
      title = sprintf("ROC curve (AUC = %.3f)", auc)
    ) +
    theme_minimal()

  ggsave(output_path, plot = p, width = 6, height = 6, dpi = 300)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1) {
    stop("Usage: Rscript roc_curve.R <test_predictions.csv> [output_path]", call. = FALSE)
  }

  test_predictions <- args[1]
  output_path <- if (length(args) >= 2) args[2] else "roc_auc_curve.png"

  df <- read_csv(test_predictions, show_col_types = FALSE)
  roc_plot(df, output_path)
}

if (identical(environment(), globalenv())) {
  main()
}


