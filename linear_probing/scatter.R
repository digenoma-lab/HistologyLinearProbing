#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
})

scatterplot <- function(df, output_path = "scatterplot.png") {
  # Calcular R2
  ss_res <- sum((df$y_true - df$y_pred)^2)
  ss_tot <- sum((df$y_true - mean(df$y_true))^2)
  r2 <- 1 - ss_res / ss_tot

  max_value <- max(df$y_true) + 1
  min_value <- min(df$y_true) - 1

  p <- ggplot(df, aes(x = y_true, y = y_pred)) +
    geom_point(alpha = 0.6, color="#67a9cf") +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    coord_cartesian(xlim = c(min_value, max_value), ylim = c(min_value, max_value)) +
    labs(
      x = "True Value",
      y = "Predicted Value",
      title = sprintf("Scatter Plot of True vs Predicted Values (R2 Score: %.2f)", r2)
    ) +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave(output_path, plot = p, width = 6, height = 6, dpi = 300)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1) {
    stop("Usage: Rscript scatter.R <test_predictions.csv> [output_path]", call. = FALSE)
  }

  test_predictions <- args[1]
  output_path <- if (length(args) >= 2) args[2] else "scatterplot.png"

  df <- read_csv(test_predictions, show_col_types = FALSE)
  scatterplot(df, output_path)
}

if (identical(environment(), globalenv())) {
  main()
}