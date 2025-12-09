#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(readr)
  library(dplyr)
  library(stringr)
})

main <- function(results_dir, output_path = "boxplot.png") {
  files <- list.files(results_dir, pattern = "cv_result", full.names = TRUE)
  if (length(files) == 0) {
    message("No valid cv_result files found in: ", results_dir)
    quit(status = 0)
  }

  fold_cols <- c(
    "split0_test_roc_auc",
    "split1_test_roc_auc",
    "split2_test_roc_auc",
    "split3_test_roc_auc",
    "split4_test_roc_auc"
  )

  dfs <- list()

  for (f in files) {
    data <- read_csv(f, show_col_types = FALSE)

    # Skip empty files or those without mean_test_roc_auc
    if (nrow(data) == 0 || !("mean_test_roc_auc" %in% colnames(data))) {
      next
    }

    # Row with best mean_test_roc_auc
    best_idx <- which.max(data$mean_test_roc_auc)
    best_model <- data[best_idx, , drop = FALSE]

    # Ensure all ROC AUC fold columns are present
    if (!all(fold_cols %in% colnames(best_model))) {
      next
    }

    # Extract the 5 ROC AUC values
    auc_values <- unlist(best_model[fold_cols], use.names = FALSE)
    df_file <- data.frame(roc_auc = auc_values, stringsAsFactors = FALSE)

    file_name <- basename(f)
    parts <- str_split(file_name, "\\.", simplify = TRUE)

    df_file$feature_extractor <- parts[1]
    df_file$algorithm <- parts[2]

    dfs[[length(dfs) + 1]] <- df_file
  }

  if (length(dfs) == 0) {
    message("No valid cv_result files with ROC AUC structure in: ", results_dir)
    quit(status = 0)
  }

  df <- bind_rows(dfs)
  print(df)

  theme_set(theme_bw())

  p <- ggplot(df, aes(x = feature_extractor, y = roc_auc, fill = algorithm)) +
    geom_boxplot() +
    theme_minimal() +
    labs(x = "Feature extractor", y = "ROC AUC", title = "Benchmark (ROC AUC)")

  ggsave(output_path, plot = p, width = 15, height = 6, dpi = 300)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: Rscript boxplot_auc.R <results_dir> [output_path]", call. = FALSE)
}

results_dir <- args[1]
output_path <- if (length(args) >= 2) args[2] else "boxplot.png"

main(results_dir, output_path)


