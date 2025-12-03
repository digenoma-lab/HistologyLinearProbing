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
    "split0_test_r2",
    "split1_test_r2",
    "split2_test_r2",
    "split3_test_r2",
    "split4_test_r2"
  )

  dfs <- list()

  for (f in files) {
    data <- read_csv(f, show_col_types = FALSE)

    # Saltar ficheros vacíos o sin mean_test_r2
    if (nrow(data) == 0 || !("mean_test_r2" %in% colnames(data))) {
      next
    }

    # Fila con mejor mean_test_r2
    best_idx <- which.max(data$mean_test_r2)
    best_model <- data[best_idx, , drop = FALSE]

    # Comprobar que están todas las columnas de folds
    if (!all(fold_cols %in% colnames(best_model))) {
      next
    }

    # Extraer los 5 valores de R2
    r2_values <- unlist(best_model[fold_cols], use.names = FALSE)
    df_file <- data.frame(r2 = r2_values, stringsAsFactors = FALSE)

    file_name <- basename(f)
    parts <- str_split(file_name, "\\.", simplify = TRUE)

    df_file$feature_extractor <- parts[1]
    df_file$algorithm <- parts[2]

    dfs[[length(dfs) + 1]] <- df_file
  }

  if (length(dfs) == 0) {
    message("No valid cv_result files with expected structure in: ", results_dir)
    quit(status = 0)
  }

  df <- bind_rows(dfs)
  print(df)

  # Estilo parecido a seaborn whitegrid + ggplot
  theme_set(theme_bw())

  p <- ggplot(df, aes(x = feature_extractor, y = r2, fill = algorithm)) +
    geom_boxplot() +
    theme_minimal() +
    labs(x="Feature extractor", y="R2", title="Benchmark")

  ggsave(output_path, plot = p, width = 15, height = 6, dpi = 300)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: Rscript boxplot.R <results_dir> [output_path]", call. = FALSE)
}

results_dir <- args[1]
output_path <- if (length(args) >= 2) args[2] else "boxplot.png"

main(results_dir, output_path)